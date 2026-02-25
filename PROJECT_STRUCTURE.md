# Project Structure

This document describes the organization of the Auto Stretch project.

```
auto-streach/
├── src/                        # Source code
│   ├── app.py                  # Main Flask application
│   ├── post_process.py         # Image processing engine
│   ├── templates/              # HTML templates
│   │   └── index.html          # Main web interface
│   └── static/                 # Static assets
│       ├── css/
│       │   └── style.css       # Astronomy theme styles
│       ├── favicon.svg         # Animated galaxy favicon
│       ├── favicon.png         # PNG fallback
│       └── favicon.ico         # ICO fallback
│
├── scripts/                    # Build and utility scripts
│   ├── build-deb.sh            # Build Debian package (Linux)
│   ├── build-with-docker.sh    # Build with Docker (Unix)
│   ├── build-with-docker.bat   # Build with Docker (Windows)
│   ├── auto-streach.bat        # Original batch processing script
│   └── generate_favicon.py     # Favicon generation utility
│
├── debian/                     # Debian packaging files
│   ├── DEBIAN/
│   │   ├── control             # Package metadata
│   │   ├── postinst            # Post-installation script
│   │   ├── prerm               # Pre-removal script
│   │   └── postrm              # Post-removal script
│   └── etc/
│       └── systemd/system/
│           └── auto-stretch.service  # Systemd service file
│
├── docs/                       # Documentation
│   ├── DEBIAN_PACKAGE.md       # Debian packaging guide
│   ├── INSTALL_DEBIAN.md       # Installation instructions
│   ├── PACKAGE_SUMMARY.md      # Package summary
│   ├── BUILD_ON_WINDOWS.md     # Windows build guide
│   └── PORT_CONFIGURATION.md   # Port configuration guide
│
├── tests/                      # Test files
│   ├── test_upload.py          # Upload testing script
│   └── debug_stretch.py        # Debug utilities
│
├── samples/                    # Sample files
│   └── orion.tif               # Sample astronomical image
│
├── README.md                   # Main project documentation
├── requirements.txt            # Python dependencies
└── .gitignore                  # Git ignore rules
```

## Directory Purposes

### src/
Contains all application source code. This is the main codebase that gets deployed.

### scripts/
Build scripts, utilities, and helper tools. Not deployed with the application.

### debian/
Debian package configuration and control files for creating .deb packages.

### docs/
All documentation files except the main README.md.

### tests/
Test scripts and debugging utilities for development.

### samples/
Sample files for testing and demonstration purposes.

## Running the Application

### Development Mode
```bash
cd src
python app.py
```

Access at: http://localhost:5000

### Building Debian Package
```bash
# On Linux/Mac
./scripts/build-with-docker.sh

# On Windows
scripts\build-with-docker.bat
```

## Key Files

| File | Purpose |
|------|---------|
| `src/app.py` | Main Flask web application |
| `src/post_process.py` | Image stretching algorithms |
| `requirements.txt` | Python package dependencies |
| `README.md` | Main project documentation |
| `scripts/build-deb.sh` | Package build script |

## Notes

- The `src/` directory contains the deployable application
- Flask automatically finds `templates/` and `static/` relative to `app.py`
- Build scripts reference files in `src/` directory
- Temporary files are created in system temp directory, not in project

## Post-Installation Files

After installing the Debian package, these additional files are created:

- `/opt/auto-stretch/config.env` - Port configuration (e.g., APP_PORT=5000)
- `/opt/auto-stretch/venv/` - Python virtual environment with dependencies
- `/opt/auto-stretch/app_start.py` - Systemd service wrapper script

## Port Configuration

During package installation, you'll be prompted to choose a port:
- Default: 5000
- Can be changed by editing `/opt/auto-stretch/config.env`
- See [docs/PORT_CONFIGURATION.md](docs/PORT_CONFIGURATION.md) for details
