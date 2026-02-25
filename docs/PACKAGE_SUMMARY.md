# Auto Stretch - Debian Package Summary

## Package Information

- **Name**: auto-stretch
- **Version**: 1.0.0
- **Architecture**: all (platform-independent)
- **Target**: Debian Trixie (testing/13)
- **Section**: science
- **Dependencies**:
  - python3 (>= 3.9)
  - python3-pip
  - siril (installed automatically)

## Installation

```bash
sudo dpkg -i auto-stretch_1.0.0_all.deb
```

Access at: **http://localhost:5000**

## Package Contents

### Application Files
```
/opt/auto-stretch/
├── app.py                  # Main Flask application
├── app_start.py            # Production startup wrapper
├── post_process.py         # Image processing engine
├── requirements.txt        # Python dependencies
├── README.md              # Application documentation
├── templates/
│   └── index.html         # Web interface
└── static/
    ├── favicon.svg        # Animated galaxy favicon
    ├── favicon.png        # PNG fallback
    ├── favicon.ico        # ICO fallback
    └── css/
        └── style.css      # Astronomy theme styles
```

### System Integration
```
/etc/systemd/system/
└── auto-stretch.service   # Systemd service definition
```

### Created at Installation
- System user: `auto-stretch` (no login)
- System group: `auto-stretch`
- Service: Auto-starts on boot
- Log location: journalctl -u auto-stretch

## Features

✅ **Automatic Siril Installation** - Dependency handled by apt
✅ **Systemd Service** - Runs in background, auto-starts
✅ **Dedicated User** - Secure, isolated execution
✅ **Web Interface** - Accessible on port 5000
✅ **Astronomy Theme** - Starry background, galaxy favicon
✅ **TIFF Processing** - Advanced stretching algorithms
✅ **Configurable** - 11+ adjustable parameters
✅ **Service Logs** - Full journald integration

## Build Process

### Files for Building
```
auto-streach/
├── build-deb.sh            # Main build script (Linux)
├── build-with-docker.sh    # Docker build (any OS)
├── build-with-docker.bat   # Docker build (Windows)
├── debian/
│   ├── DEBIAN/
│   │   ├── control         # Package metadata
│   │   ├── postinst        # Post-install script
│   │   ├── prerm           # Pre-removal script
│   │   └── postrm          # Post-removal script
│   └── etc/
│       └── systemd/system/
│           └── auto-stretch.service
```

### Build Commands

**On Debian:**
```bash
./build-deb.sh
```

**With Docker (any OS):**
```bash
# Linux/Mac
./build-with-docker.sh

# Windows
build-with-docker.bat
```

## Documentation

| File | Description |
|------|-------------|
| **README.md** | Application usage guide |
| **DEBIAN_PACKAGE.md** | Detailed packaging documentation |
| **INSTALL_DEBIAN.md** | Quick installation guide |
| **PACKAGE_SUMMARY.md** | This file - quick reference |

## Service Management

| Command | Description |
|---------|-------------|
| `sudo systemctl status auto-stretch` | Check status |
| `sudo systemctl start auto-stretch` | Start service |
| `sudo systemctl stop auto-stretch` | Stop service |
| `sudo systemctl restart auto-stretch` | Restart service |
| `sudo journalctl -u auto-stretch -f` | View logs |

## Quick Troubleshooting

| Issue | Solution |
|-------|----------|
| Service won't start | `sudo journalctl -u auto-stretch -n 50` |
| Port in use | `sudo lsof -i :5000` |
| Permission errors | `sudo chown -R auto-stretch:auto-stretch /opt/auto-stretch` |
| Dependency issues | `sudo pip3 install -r /opt/auto-stretch/requirements.txt` |

## Removal

```bash
# Keep config
sudo apt-get remove auto-stretch

# Remove everything
sudo apt-get purge auto-stretch
```

## Package Size

- **Compressed (.deb)**: ~50-100 KB
- **Installed**: ~5-10 MB (without Python packages)
- **With dependencies**: ~200 MB (includes Siril)

## Python Dependencies

Automatically installed via pip:
- Flask==3.0.0
- Werkzeug==3.0.1
- Pillow==10.2.0
- numpy==1.26.3
- tifffile>=2024.8.0
- imagecodecs>=2024.6.0

## Security

- Runs as unprivileged user `auto-stretch`
- No shell access (`/usr/sbin/nologin`)
- Systemd hardening enabled
- Protected system directories
- Only `/tmp` writable

## Network Access

Default: http://localhost:5000

To enable network access:
```bash
sudo ufw allow 5000/tcp
```

## Compatibility

- **Tested on**: Debian Trixie (13)
- **Should work on**: Ubuntu 24.04+, Debian Testing/Unstable
- **May work on**: Other Debian-based distributions

## Support

For issues:
1. Check logs: `sudo journalctl -u auto-stretch`
2. Review documentation in README.md
3. Verify dependencies: `dpkg -l | grep -E "(python3|siril)"`

## Building From Source

If you prefer not to use the package:

```bash
# Install dependencies manually
sudo apt-get install python3 python3-pip siril
pip3 install -r requirements.txt

# Run directly
python3 app.py
```

## License

[Specify your license here]

## Version History

- **1.0.0** (2026-02-25)
  - Initial Debian package release
  - Systemd service integration
  - Automatic Siril dependency
  - Astronomy-themed UI
