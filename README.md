# Auto Stretch - TIFF Image Processor Web App

A Flask-based web application for advanced TIFF image stretching and color enhancement, based on the auto-streach.bat workflow.

## Features

- **TIFF Upload**: Support for .tif and .tiff image files
- **Configurable Parameters**:
  - Gamma correction for each RGB channel
  - Color balance adjustments
  - Tone curve customization (dark/mid/bright regions)
  - Saturation boost controls
- **Optional Siril Pre-processing**: Use siril-cli for initial stretching (if installed)
- **Live Preview**: Preview processed images in the browser
- **Download Results**: Download processed TIFF files

## Installation

1. Install Python dependencies:
```bash
pip install -r requirements.txt
```

2. (Optional) Install siril-cli for Siril pre-processing:
   - Download from: https://siril.org/
   - Make sure `siril-cli` is in your system PATH
   - **Note**: Siril is optional. The app includes built-in auto-stretch that works without Siril

## Usage

1. Start the Flask application:
```bash
python app.py
```

2. Open your browser and navigate to:
```
http://localhost:5000
```

3. Upload a TIFF image and adjust parameters:
   - **Gamma Correction**: Adjust the brightness curve for each color channel
   - **Color Balance**: Fine-tune green and blue channel multipliers
   - **Tone Curve**: Control how dark, mid-tone, and bright areas are processed
   - **Saturation**: Boost color saturation in bright areas
   - **Siril Pre-processing**: Enable to use siril-cli for initial stretching

4. Click "Auto Stretch" to process your image

5. Preview the result and download the processed TIFF file

## Default Parameters

The application uses the same default parameters as the original post_process.py:

- **Gamma Red**: 0.7
- **Gamma Green**: 0.8
- **Gamma Blue**: 0.75
- **Green Multiplier**: 0.93
- **Blue Multiplier**: 1.08
- **Dark Threshold**: 0.15
- **Dark Multiplier**: 0.3
- **Mid Threshold**: 0.4
- **Mid-tone Boost**: 1.5
- **Bright Multiplier**: 1.1
- **Saturation Boost**: 1.0

## File Structure

```
auto-streach/
├── app.py                 # Flask application
├── post_process.py        # Image processing logic
├── requirements.txt       # Python dependencies
├── templates/
│   └── index.html        # Web interface
├── static/
│   └── css/
│       └── style.css     # Styling
└── auto-streach.bat      # Original batch script
```

## API Endpoints

- `GET /` - Main web interface
- `POST /upload` - Upload and process image
- `GET /preview/<filename>` - Preview processed image (PNG)
- `GET /download/<filename>` - Download processed TIFF

## Notes

- Maximum file size: 100MB
- Processed files are temporarily stored in the system temp directory
- Preview images are automatically resized to max 1200px width for faster loading
- The web app works without siril-cli, but enabling it provides additional pre-processing
