import requests
import time

def test_upload():
    """Test the Flask app by uploading orion.tif"""

    url = 'http://localhost:5000/upload'

    # Wait for server to be ready
    print("Waiting for server to be ready...")
    time.sleep(2)

    # Prepare the file and parameters
    files = {'file': ('orion.tif', open('orion.tif', 'rb'), 'image/tiff')}

    # Use default parameters
    data = {
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
        'saturation_boost': 1.0,
        'use_siril': 'false'
    }

    print("Uploading orion.tif to Flask server...")
    print("Parameters:", data)

    try:
        response = requests.post(url, files=files, data=data, timeout=120)

        if response.status_code == 200:
            result = response.json()
            print("\n[SUCCESS]")
            print(f"Preview URL: {result.get('preview_url')}")
            print(f"Download URL: {result.get('download_url')}")
            print(f"Output file: {result.get('output_filename')}")
            print("\nYou can now:")
            print("  1. Open http://localhost:5000 in your browser to see the web interface")
            print("  2. View the preview and download the result")
        else:
            print(f"\n[ERROR] Status: {response.status_code}")
            print(response.text)

    except requests.exceptions.ConnectionError:
        print("[ERROR] Could not connect to server. Make sure Flask is running on port 5000")
    except Exception as e:
        print(f"[ERROR] {e}")

if __name__ == "__main__":
    test_upload()
