import numpy as np
from PIL import Image
import sys
import tifffile

def stretch_image(input_path, output_path, params=None):
    """
    Apply auto-stretch with configurable parameters

    Args:
        input_path: Path to input TIFF file
        output_path: Path to save output file
        params: Dictionary of processing parameters (optional)
    """
    # Default parameters
    if params is None:
        params = {
            'gamma_red': 0.7,
            'gamma_green': 0.8,
            'gamma_blue': 0.75,
            'green_multiplier': 0.93,
            'blue_multiplier': 1.08,
            'dark_threshold': 0.15,
            'dark_multiplier': 0.3,
            'mid_threshold': 0.4,
            'mid_boost': 1.5,
            'bright_multiplier': 1.1,
            'saturation_boost': 1.0
        }

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
    print(f"Processed image saved to {output_path}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        input_file = sys.argv[1]
        output_file = sys.argv[2] if len(sys.argv) > 2 else "result.tif"
    else:
        input_file = "result.tif"
        output_file = "result.tif"

    stretch_image(input_file, output_file)
