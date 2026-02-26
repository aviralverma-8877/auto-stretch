# Feature: Custom Port Configuration

## Overview

The Debian package now supports custom port configuration during installation. Users can choose their preferred port for the web interface.

## What's New

### 1. Interactive Port Prompt During Installation

When installing the package, users are now prompted:

```
======================================
Auto Stretch Port Configuration
======================================
Enter port number for the web interface (default: 5000):
```

**User Options:**
- **Press Enter** → Uses default port 5000
- **Enter number** → Uses custom port (e.g., 8080, 3000, 9000)

### 2. Port Validation

The installer validates the port input:
- Must be a number between 1 and 65535
- Invalid input defaults to 5000
- Displays confirmation of selected port

### 3. Configuration Storage

Port setting is saved in:
```
/opt/auto-stretch/config.env
```

Example content:
```bash
APP_PORT=8080
```

### 4. Dynamic Port Binding

The application reads the port from environment variable at startup:
- systemd service loads config.env
- app_start.py reads APP_PORT
- Falls back to 5000 if not set

### 5. Post-Installation Information

Installation success message shows:
```
==============================================
Auto Stretch has been installed successfully!
==============================================

Service Status: RUNNING
Access the web interface at: http://localhost:8080

Configuration:
  - Port: 8080
  - Config file: /opt/auto-stretch/config.env

To change the port:
  1. Edit: /opt/auto-stretch/config.env
  2. Restart: sudo systemctl restart auto-stretch
```

## Implementation Details

### Files Modified

#### 1. `debian/DEBIAN/postinst`
```bash
# Ask user for port configuration
read -p "Enter port number for the web interface (default: 5000): " USER_PORT

# Validate and set port
if [ -z "$USER_PORT" ]; then
    APP_PORT=5000
else
    # Validation logic
    APP_PORT=$USER_PORT
fi

# Save configuration
echo "APP_PORT=$APP_PORT" > "$APP_DIR/config.env"
```

#### 2. `debian/etc/systemd/system/auto-stretch.service`
```ini
[Service]
EnvironmentFile=-/opt/auto-stretch/config.env
ExecStart=/opt/auto-stretch/venv/bin/python /opt/auto-stretch/app_start.py
```

The `-` prefix in `EnvironmentFile=-` means "don't fail if file doesn't exist"

#### 3. `scripts/build-deb.sh` - app_start.py generation
```python
if __name__ == '__main__':
    # Get port from environment variable or use default
    port = int(os.environ.get('APP_PORT', 5000))

    print(f"Starting Auto Stretch on port {port}...")

    app.run(host='0.0.0.0', port=port, debug=False)
```

## User Benefits

✅ **Flexibility** - Choose any port between 1-65535
✅ **No conflicts** - Avoid port conflicts with other services
✅ **Easy to change** - Simple config file edit
✅ **Safe defaults** - Falls back to 5000 if not configured
✅ **Clear feedback** - Shows selected port in success message

## Use Cases

### 1. Default Installation (Port 5000)
```bash
$ sudo dpkg -i auto-stretch_1.0.0_all.deb
Enter port number for the web interface (default: 5000): [Enter]
Using default port: 5000

Access at: http://localhost:5000
```

### 2. Custom Port (8080)
```bash
$ sudo dpkg -i auto-stretch_1.0.0_all.deb
Enter port number for the web interface (default: 5000): 8080
Using port: 8080

Access at: http://localhost:8080
```

### 3. Development Environment (3000)
```bash
$ sudo dpkg -i auto-stretch_1.0.0_all.deb
Enter port number for the web interface (default: 5000): 3000
Using port: 3000

Access at: http://localhost:3000
```

### 4. Change Port After Installation
```bash
# Edit config
$ sudo nano /opt/auto-stretch/config.env
# Change: APP_PORT=9000

# Restart
$ sudo systemctl restart auto-stretch

# Verify
$ sudo journalctl -u auto-stretch -n 5
# Output: Starting Auto Stretch on port 9000...
```

## Testing

### Test Default Port
```bash
sudo dpkg -i auto-stretch_1.0.0_all.deb
# Press Enter at prompt
curl http://localhost:5000
```

### Test Custom Port
```bash
sudo dpkg -i auto-stretch_1.0.0_all.deb
# Enter: 8080
curl http://localhost:8080
```

### Test Port Change
```bash
echo "APP_PORT=9000" | sudo tee /opt/auto-stretch/config.env
sudo systemctl restart auto-stretch
curl http://localhost:9000
```

### Test Invalid Port
```bash
sudo dpkg -i auto-stretch_1.0.0_all.deb
# Enter: abc123
# Should default to 5000
curl http://localhost:5000
```

## Documentation

New documentation files:
- [docs/PORT_CONFIGURATION.md](docs/PORT_CONFIGURATION.md) - Comprehensive port guide
- Updated [docs/INSTALL_DEBIAN.md](docs/INSTALL_DEBIAN.md) - Installation guide with port info

## Backward Compatibility

✅ **Fully backward compatible**
- If user presses Enter → uses default 5000 (same as before)
- If config.env doesn't exist → falls back to 5000
- Existing installations not affected

## Security Considerations

- Port validation prevents invalid input
- Privileged ports (1-1024) can be used but require sudo
- Service runs as `auto-stretch` user (not root)
- Firewall configuration still user's responsibility

## Future Enhancements

Possible improvements:
- [ ] Auto-detect available ports
- [ ] Suggest alternative if port is in use
- [ ] Support for multiple instances on different ports
- [ ] Web-based port configuration page
- [ ] HTTPS support with certificate configuration

## Status

✅ **Implemented and Ready**

All changes complete and tested:
- Port prompt during installation
- Configuration file storage
- Dynamic port binding
- Updated documentation
- Success messages show correct port
