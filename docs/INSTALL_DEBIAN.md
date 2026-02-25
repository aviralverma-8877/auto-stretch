# Auto Stretch - Debian Installation Guide

Quick guide for installing Auto Stretch on Debian Trixie as a system service.

## Quick Install (Debian Trixie)

If you already have the `.deb` package:

```bash
sudo dpkg -i auto-stretch_1.0.0_all.deb
```

That's it! The application will:
- Install Siril automatically
- Start running on http://localhost:5000
- Auto-start on system boot

## Building the Package

### Option 1: On Debian Trixie

```bash
cd /path/to/auto-streach
chmod +x build-deb.sh
./build-deb.sh
```

### Option 2: Using Docker (Windows/Mac/Linux)

**On Linux/Mac:**
```bash
chmod +x build-with-docker.sh
./build-with-docker.sh
```

**On Windows:**
```cmd
build-with-docker.bat
```

## Post-Installation

### Check Service Status
```bash
sudo systemctl status auto-stretch
```

### Access Web Interface
Open your browser to:
- Local: http://localhost:5000
- Network: http://YOUR_SERVER_IP:5000

### View Logs
```bash
# Follow logs in real-time
sudo journalctl -u auto-stretch -f

# View last 50 lines
sudo journalctl -u auto-stretch -n 50
```

## Service Management

```bash
# Stop service
sudo systemctl stop auto-stretch

# Start service
sudo systemctl start auto-stretch

# Restart service
sudo systemctl restart auto-stretch

# Disable auto-start
sudo systemctl disable auto-stretch

# Enable auto-start
sudo systemctl enable auto-stretch
```

## Uninstallation

```bash
# Remove but keep config
sudo apt-get remove auto-stretch

# Complete removal
sudo apt-get purge auto-stretch
```

## Firewall Setup (Optional)

To access from other computers on your network:

```bash
# UFW
sudo ufw allow 5000/tcp

# firewalld
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --reload

# iptables
sudo iptables -A INPUT -p tcp --dport 5000 -j ACCEPT
sudo iptables-save > /etc/iptables/rules.v4
```

## What Gets Installed

- **Application**: `/opt/auto-stretch/`
- **Service**: `/etc/systemd/system/auto-stretch.service`
- **User**: System user `auto-stretch` (no login)
- **Dependencies**: Python packages, Siril

## Troubleshooting

### Service won't start
```bash
# Check detailed logs
sudo journalctl -u auto-stretch -n 100 --no-pager

# Check if port is in use
sudo lsof -i :5000

# Try running manually
sudo -u auto-stretch python3 /opt/auto-stretch/app.py
```

### Port already in use
```bash
# Find what's using port 5000
sudo lsof -i :5000

# Kill the process (replace PID)
sudo kill -9 PID
```

### Permission errors
```bash
# Fix ownership
sudo chown -R auto-stretch:auto-stretch /opt/auto-stretch
sudo chmod -R 755 /opt/auto-stretch
sudo systemctl restart auto-stretch
```

### Dependency issues
```bash
# Reinstall Python packages
sudo pip3 install -r /opt/auto-stretch/requirements.txt
sudo systemctl restart auto-stretch
```

## Configuration

### Change Port
Edit the service file:
```bash
sudo nano /etc/systemd/system/auto-stretch.service
```

Change the `ExecStart` line to add port parameter:
```ini
ExecStart=/usr/bin/python3 /opt/auto-stretch/app_start.py --port 8080
```

Reload and restart:
```bash
sudo systemctl daemon-reload
sudo systemctl restart auto-stretch
```

### Enable Debug Mode
```bash
# Stop service
sudo systemctl stop auto-stretch

# Run manually with debug
cd /opt/auto-stretch
sudo -u auto-stretch python3 app.py

# Press Ctrl+C to stop
# Start service again
sudo systemctl start auto-stretch
```

## Security Notes

The service runs with minimal privileges:
- Dedicated user with no shell access
- Protected system directories
- No new privileges allowed
- Only temp directory is writable

## Upgrading

1. Stop the current service:
   ```bash
   sudo systemctl stop auto-stretch
   ```

2. Install new version:
   ```bash
   sudo dpkg -i auto-stretch_X.X.X_all.deb
   ```

3. Service will restart automatically

## Need Help?

Check the main README.md for:
- Application usage
- Parameter descriptions
- Image processing tips

For package issues, see DEBIAN_PACKAGE.md
