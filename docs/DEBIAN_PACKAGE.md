# Auto Stretch - Debian Package Build Instructions

This directory contains everything needed to build a Debian package for Auto Stretch that targets Debian Trixie.

## Package Features

- **Automatic Siril Installation**: Siril is automatically installed as a dependency
- **Systemd Service**: Runs as a background service on port 5000
- **Automatic Startup**: Starts automatically on boot
- **Dedicated User**: Runs under a dedicated `auto-stretch` system user for security

## Prerequisites

You need a Debian Trixie (or compatible) system to build the package:

```bash
# Required packages
sudo apt-get update
sudo apt-get install dpkg-dev debhelper
```

## Building the Package

1. **Transfer files to a Debian system**:
   ```bash
   # Copy the entire auto-streach directory to your Debian system
   scp -r auto-streach/ user@debian-host:/tmp/
   ```

2. **Build the package**:
   ```bash
   cd /tmp/auto-streach
   chmod +x build-deb.sh
   ./build-deb.sh
   ```

3. **The build script will create**: `auto-stretch_1.0.0_all.deb`

## Installation

### On Debian Trixie:

```bash
# Install the package
sudo dpkg -i auto-stretch_1.0.0_all.deb

# If dependencies are missing (shouldn't happen with Siril in repos):
sudo apt-get install -f
```

### What Happens During Installation:

1. Installs Python dependencies (Flask, Pillow, numpy, tifffile, imagecodecs)
2. Installs Siril automatically (from Debian repositories)
3. Creates a dedicated `auto-stretch` system user
4. Copies application files to `/opt/auto-stretch/`
5. Installs and enables the systemd service
6. Starts the service automatically

### Access the Application:

After installation, the web interface is available at:
- **http://localhost:5000** (local access)
- **http://YOUR_SERVER_IP:5000** (network access)

## Service Management

```bash
# Check service status
sudo systemctl status auto-stretch

# View logs
sudo journalctl -u auto-stretch -f

# Restart service
sudo systemctl restart auto-stretch

# Stop service
sudo systemctl stop auto-stretch

# Start service
sudo systemctl start auto-stretch

# Disable auto-start on boot
sudo systemctl disable auto-stretch

# Enable auto-start on boot
sudo systemctl enable auto-stretch
```

## Uninstallation

```bash
# Remove package (keep configuration)
sudo apt-get remove auto-stretch

# Complete removal (remove everything including user)
sudo apt-get purge auto-stretch
```

## Package Structure

```
debian/
├── DEBIAN/
│   ├── control          # Package metadata
│   ├── postinst         # Post-installation script
│   ├── prerm            # Pre-removal script
│   └── postrm           # Post-removal script
├── etc/
│   └── systemd/system/
│       └── auto-stretch.service  # Systemd service file
└── opt/
    └── auto-stretch/    # Application files
        ├── app.py
        ├── post_process.py
        ├── requirements.txt
        ├── templates/
        └── static/
```

## Firewall Configuration

If you want to access the web interface from other machines:

```bash
# For UFW firewall
sudo ufw allow 5000/tcp

# For firewalld
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --reload
```

## Troubleshooting

### Service won't start:

```bash
# Check logs
sudo journalctl -u auto-stretch -n 50

# Check if port 5000 is already in use
sudo lsof -i :5000

# Test manually
sudo -u auto-stretch python3 /opt/auto-stretch/app.py
```

### Permission issues:

```bash
# Reset permissions
sudo chown -R auto-stretch:auto-stretch /opt/auto-stretch
sudo chmod -R 755 /opt/auto-stretch
```

### Python dependencies issues:

```bash
# Reinstall dependencies
sudo pip3 install -r /opt/auto-stretch/requirements.txt
sudo systemctl restart auto-stretch
```

## Building on Non-Debian Systems

If you're on a different system (like Windows), you can:

1. **Use Docker**:
   ```bash
   docker run -it --rm -v "$(pwd)":/work debian:trixie bash
   cd /work
   apt-get update && apt-get install -y dpkg-dev debhelper
   ./build-deb.sh
   ```

2. **Use WSL2 with Debian**:
   ```bash
   wsl --install -d Debian
   wsl -d Debian
   # Then follow normal build instructions
   ```

3. **Use a Virtual Machine**: Set up a Debian Trixie VM

## Version Updates

To update the version:

1. Edit `debian/DEBIAN/control` - change Version field
2. Edit `build-deb.sh` - change VERSION variable
3. Rebuild the package

## Security Considerations

The service runs as a dedicated `auto-stretch` user with:
- No login shell (`/usr/sbin/nologin`)
- Limited file system access
- `NoNewPrivileges=true` in systemd
- `ProtectSystem=strict` and `ProtectHome=true`
- Only `/tmp` is writable

## Support

For issues or questions:
- Check logs: `sudo journalctl -u auto-stretch -f`
- Review README.md for application usage
- Check service status: `sudo systemctl status auto-stretch`
