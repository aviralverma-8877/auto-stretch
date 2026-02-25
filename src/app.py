import os
import tempfile
import subprocess
from flask import Flask, render_template, request, send_file, jsonify
from werkzeug.utils import secure_filename
from PIL import Image
import numpy as np
from datetime import datetime
import tifffile

# Get the directory where this script is located
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Initialize Flask with explicit template and static folder paths
app = Flask(__name__,
            template_folder=os.path.join(BASE_DIR, 'templates'),
            static_folder=os.path.join(BASE_DIR, 'static'))
app.config['MAX_CONTENT_LENGTH'] = 500 * 1024 * 1024  # 500MB max file size
app.config['UPLOAD_FOLDER'] = tempfile.gettempdir()

ALLOWED_EXTENSIONS = {'tif', 'tiff'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def stretch_image_with_params(input_path, output_path, params):
    """
    Apply auto-stretch with configurable parameters
    """
    # Load the image (use tifffile for better TIFF support)
    try:
        img_array = tifffile.imread(input_path).astype(np.float32)
    except Exception:
        # Fallback to PIL if tifffile fails
        img = Image.open(input_path)
        img_array = np.array(img, dtype=np.float32)

    # Normalize to 0-1 range
    if img_array.max() > 1:
        img_array = img_array / img_array.max()

    # Apply initial autostretch if values are very low (typical for raw astro images)
    # This replaces what Siril's autostretch would do
    needs_autostretch = img_array.max() < 0.9 and img_array.mean() < 0.1

    if needs_autostretch:
        # Aggressive histogram stretch for astronomical images
        # Use global percentiles but with very aggressive clipping
        for i in range(3):
            channel = img_array[:,:,i]

            # Use percentiles that focus on bringing out faint details
            # This is similar to what Siril's autostretch does
            low_percentile = np.percentile(channel, 0.001)  # Almost minimum
            high_percentile = np.percentile(channel, 99.999)  # Almost maximum

            # Clip and stretch
            channel = np.clip(channel, low_percentile, high_percentile)
            channel = (channel - low_percentile) / (high_percentile - low_percentile + 1e-10)
            img_array[:,:,i] = channel

        img_array = np.clip(img_array, 0, 1)

        # Apply an aggressive midtone stretch to bring up faint details
        img_array = np.power(img_array, 0.35)  # More aggressive midtone stretch

    # Split into RGB channels
    r, g, b = img_array[:,:,0], img_array[:,:,1], img_array[:,:,2]

    # Apply gamma correction per channel (configurable)
    r = np.power(r, params['gamma_red'])
    g = np.power(g, params['gamma_green']) * params['green_multiplier']
    b = np.power(b, params['gamma_blue']) * params['blue_multiplier']

    # Recombine
    img_array = np.stack([r, g, b], axis=-1)
    img_array = np.clip(img_array, 0, 1)

    # Apply tone curve only if NOT processing raw images
    # Raw images are already mostly dark, no need to darken further
    if not needs_autostretch:
        # Darken background while brightening bright areas
        # Create a luminosity mask
        luminosity = 0.299 * img_array[:,:,0] + 0.587 * img_array[:,:,1] + 0.114 * img_array[:,:,2]

        # Create a non-linear stretch curve (configurable)
        darkening_curve = np.where(luminosity < params['dark_threshold'],
                                     luminosity * params['dark_multiplier'],
                                     luminosity)
        darkening_curve = np.where((luminosity >= params['dark_threshold']) & (luminosity < params['mid_threshold']),
                                     params['dark_threshold'] * params['dark_multiplier'] + (luminosity - params['dark_threshold']) * params['mid_boost'],
                                     darkening_curve)
        darkening_curve = np.where(luminosity >= params['mid_threshold'],
                                     luminosity * params['bright_multiplier'],
                                     darkening_curve)

        # Apply curve while preserving color ratios
        ratio = np.divide(darkening_curve, luminosity + 1e-10)
        ratio = np.clip(ratio, 0, 3)
        ratio = np.expand_dims(ratio, axis=2)

        img_array = img_array * ratio
        img_array = np.clip(img_array, 0, 1)

    # Boost saturation by converting to HSV
    img_pil = Image.fromarray((img_array * 255).astype(np.uint8))

    # Convert to HSV
    hsv = img_pil.convert('HSV')
    h, s, v = hsv.split()

    # Boost saturation selectively (configurable)
    s_array = np.array(s, dtype=np.float32)
    v_array = np.array(v, dtype=np.float32)

    # More saturation in bright areas
    bright_mask = v_array / 255.0
    saturation_multiplier = 1.0 + (bright_mask ** 0.5) * params['saturation_boost']
    s_array = s_array * saturation_multiplier
    s_array = np.clip(s_array, 0, 255)
    s = Image.fromarray(s_array.astype(np.uint8))

    # Merge back
    result = Image.merge('HSV', (h, s, v))
    result = result.convert('RGB')

    # Save result
    result.save(output_path)
    return output_path

def run_siril_stretch(input_path, output_path):
    """
    Run siril-cli for basic stretching
    """
    try:
        # Get file directory and name
        file_dir = os.path.dirname(input_path)
        file_name = os.path.splitext(os.path.basename(input_path))[0]

        # Create siril script
        script_path = os.path.join(file_dir, 'stretch_temp.ssf')
        with open(script_path, 'w') as f:
            f.write('requires 1.2.0\n')
            f.write(f'load {file_name}\n')
            f.write('bg\n')
            f.write('autostretch\n')
            f.write(f'savetif {os.path.splitext(os.path.basename(output_path))[0]} -astro\n')

        # Run siril-cli
        result = subprocess.run(
            ['siril-cli', '-d', file_dir, '-s', script_path],
            capture_output=True,
            text=True,
            timeout=300
        )

        # Clean up script
        if os.path.exists(script_path):
            os.remove(script_path)

        return result.returncode == 0
    except Exception as e:
        print(f"Siril processing error: {e}")
        return False

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file uploaded'}), 400

    file = request.files['file']

    if file.filename == '':
        return jsonify({'error': 'No file selected'}), 400

    if not allowed_file(file.filename):
        return jsonify({'error': 'Only TIFF files are allowed'}), 400

    try:
        # Get parameters from form
        params = {
            'gamma_red': float(request.form.get('gamma_red', 0.7)),
            'gamma_green': float(request.form.get('gamma_green', 0.8)),
            'gamma_blue': float(request.form.get('gamma_blue', 0.75)),
            'green_multiplier': float(request.form.get('green_multiplier', 0.93)),
            'blue_multiplier': float(request.form.get('blue_multiplier', 1.08)),
            'dark_threshold': float(request.form.get('dark_threshold', 0.15)),
            'dark_multiplier': float(request.form.get('dark_multiplier', 0.3)),
            'mid_threshold': float(request.form.get('mid_threshold', 0.4)),
            'mid_boost': float(request.form.get('mid_boost', 1.5)),
            'bright_multiplier': float(request.form.get('bright_multiplier', 1.1)),
            'saturation_boost': float(request.form.get('saturation_boost', 1.0))
        }

        use_siril = request.form.get('use_siril', 'false') == 'true'

        # Save uploaded file
        filename = secure_filename(file.filename)
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        input_path = os.path.join(app.config['UPLOAD_FOLDER'], f'input_{timestamp}_{filename}')
        file.save(input_path)

        # Process image
        if use_siril:
            # Run siril first, then post-process
            basic_path = os.path.join(app.config['UPLOAD_FOLDER'], f'basic_{timestamp}_{filename}')
            if run_siril_stretch(input_path, basic_path):
                output_path = os.path.join(app.config['UPLOAD_FOLDER'], f'output_{timestamp}_{filename}')
                stretch_image_with_params(basic_path, output_path, params)
                os.remove(basic_path)
            else:
                # Fallback to direct processing if siril fails
                output_path = os.path.join(app.config['UPLOAD_FOLDER'], f'output_{timestamp}_{filename}')
                stretch_image_with_params(input_path, output_path, params)
        else:
            # Direct post-processing without siril
            output_path = os.path.join(app.config['UPLOAD_FOLDER'], f'output_{timestamp}_{filename}')
            stretch_image_with_params(input_path, output_path, params)

        # Convert to PNG for preview
        preview_path = os.path.join(app.config['UPLOAD_FOLDER'], f'preview_{timestamp}.png')
        img = Image.open(output_path)
        # Resize for preview (max 1200px width)
        max_width = 1200
        if img.width > max_width:
            ratio = max_width / img.width
            new_size = (max_width, int(img.height * ratio))
            img = img.resize(new_size, Image.Resampling.LANCZOS)
        img.save(preview_path, 'PNG')

        # Keep input file for reprocessing - don't delete it yet
        # It will be cleaned up when user resets or after timeout

        return jsonify({
            'success': True,
            'preview_url': f'/preview/{os.path.basename(preview_path)}',
            'download_url': f'/download/{os.path.basename(output_path)}',
            'output_filename': os.path.basename(output_path),
            'input_file': os.path.basename(input_path),  # Return input file for reprocessing
            'original_filename': filename
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/reprocess', methods=['POST'])
def reprocess_file():
    """Reprocess an already uploaded file with new parameters"""
    try:
        # Get the stored input file name
        input_filename = request.form.get('input_file')
        if not input_filename:
            return jsonify({'error': 'No input file specified'}), 400

        input_path = os.path.join(app.config['UPLOAD_FOLDER'], input_filename)

        # Check if file still exists
        if not os.path.exists(input_path):
            return jsonify({'error': 'Original file no longer available. Please re-upload.'}), 404

        # Get new parameters from form
        params = {
            'gamma_red': float(request.form.get('gamma_red', 0.7)),
            'gamma_green': float(request.form.get('gamma_green', 0.8)),
            'gamma_blue': float(request.form.get('gamma_blue', 0.75)),
            'green_multiplier': float(request.form.get('green_multiplier', 0.93)),
            'blue_multiplier': float(request.form.get('blue_multiplier', 1.08)),
            'dark_threshold': float(request.form.get('dark_threshold', 0.15)),
            'dark_multiplier': float(request.form.get('dark_multiplier', 0.3)),
            'mid_threshold': float(request.form.get('mid_threshold', 0.4)),
            'mid_boost': float(request.form.get('mid_boost', 1.5)),
            'bright_multiplier': float(request.form.get('bright_multiplier', 1.1)),
            'saturation_boost': float(request.form.get('saturation_boost', 1.0))
        }

        use_siril = request.form.get('use_siril', 'false') == 'true'

        # Generate new timestamp for output files
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')

        # Extract original filename from input_path
        original_filename = '_'.join(input_filename.split('_')[2:])  # Remove 'input_timestamp_' prefix

        # Process image with new parameters
        if use_siril:
            # Run siril first, then post-process
            basic_path = os.path.join(app.config['UPLOAD_FOLDER'], f'basic_{timestamp}_{original_filename}')
            if run_siril_stretch(input_path, basic_path):
                output_path = os.path.join(app.config['UPLOAD_FOLDER'], f'output_{timestamp}_{original_filename}')
                stretch_image_with_params(basic_path, output_path, params)
                os.remove(basic_path)
            else:
                # Fallback to direct processing if siril fails
                output_path = os.path.join(app.config['UPLOAD_FOLDER'], f'output_{timestamp}_{original_filename}')
                stretch_image_with_params(input_path, output_path, params)
        else:
            # Direct post-processing without siril
            output_path = os.path.join(app.config['UPLOAD_FOLDER'], f'output_{timestamp}_{original_filename}')
            stretch_image_with_params(input_path, output_path, params)

        # Convert to PNG for preview
        preview_path = os.path.join(app.config['UPLOAD_FOLDER'], f'preview_{timestamp}.png')
        img = Image.open(output_path)
        # Resize for preview (max 1200px width)
        max_width = 1200
        if img.width > max_width:
            ratio = max_width / img.width
            new_size = (max_width, int(img.height * ratio))
            img = img.resize(new_size, Image.Resampling.LANCZOS)
        img.save(preview_path, 'PNG')

        return jsonify({
            'success': True,
            'preview_url': f'/preview/{os.path.basename(preview_path)}',
            'download_url': f'/download/{os.path.basename(output_path)}',
            'output_filename': os.path.basename(output_path),
            'input_file': input_filename,  # Keep same input file for further reprocessing
            'original_filename': original_filename
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/preview/<filename>')
def preview_file(filename):
    file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
    if os.path.exists(file_path):
        return send_file(file_path, mimetype='image/png')
    return 'File not found', 404

@app.route('/download/<filename>')
def download_file(filename):
    file_path = os.path.join(app.config['UPLOAD_FOLDER'], filename)
    if os.path.exists(file_path):
        return send_file(file_path, as_attachment=True, download_name=filename)
    return 'File not found', 404

@app.route('/cleanup', methods=['POST'])
def cleanup_file():
    """Clean up stored files when user wants to upload a new image"""
    try:
        input_filename = request.json.get('input_file')
        if input_filename:
            input_path = os.path.join(app.config['UPLOAD_FOLDER'], input_filename)
            if os.path.exists(input_path):
                os.remove(input_path)
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
