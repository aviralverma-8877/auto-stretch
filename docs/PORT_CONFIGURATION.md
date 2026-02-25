# Port Configuration

Auto Stretch allows you to configure the port on which the web interface runs.

## During Installation

When you install the Debian package, you'll be prompted to enter a port number:

```
======================================
Auto Stretch Port Configuration
======================================
Enter port number for the web interface (default: 5000):
```

**Options:**
- **Press Enter** - Uses default port 5000
- **Enter a number** (1-65535) - Uses your custom port

**Examples:**
```bash
# Use default port 5000
Enter port number for the web interface (default: 5000): [Press Enter]

# Use custom port 8080
Enter port number for the web interface (default: 5000): 8080

# Use custom port 3000
Enter port number for the web interface (default: 5000): 3000
```

## After Installation

The port configuration is saved in:
```
/opt/auto-stretch/config.env
```

### View Current Port

```bash
cat /opt/auto-stretch/config.env
```

Output:
```
APP_PORT=5000
```

### Change Port After Installation

**Method 1: Edit config file**
```bash
# Edit the configuration
sudo nano /opt/auto-stretch/config.env

# Change APP_PORT value
APP_PORT=8080

# Restart the service
sudo systemctl restart auto-stretch
```

**Method 2: Recreate config file**
```bash
# Create new config
echo "APP_PORT=8080" | sudo tee /opt/auto-stretch/config.env

# Restart the service
sudo systemctl restart auto-stretch
```

### Verify Port is Working

```bash
# Check service status
sudo systemctl status auto-stretch

# Check which port is listening
sudo netstat -tlnp | grep python

# Or use ss
sudo ss -tlnp | grep python

# Check logs
sudo journalctl -u auto-stretch -n 20
```

You should see:
```
Starting Auto Stretch on port 8080...
```

## Port Requirements

- **Valid Range**: 1-65535
- **Privileged Ports** (1-1024): Require root/sudo
- **Recommended**: Use ports > 1024 (e.g., 5000, 8080, 3000)
- **Check Conflicts**: Make sure no other service is using the port

### Check if Port is Available

Before changing to a new port, check if it's already in use:

```bash
# Check if port 8080 is in use
sudo netstat -tlnp | grep :8080

# Or with ss
sudo ss -tlnp | grep :8080

# Or with lsof
sudo lsof -i :8080
```

If nothing is returned, the port is available.

## Common Ports

| Port | Common Use |
|------|------------|
| 5000 | Flask default (Auto Stretch default) |
| 8080 | Alternative HTTP |
| 3000 | Node.js applications |
| 8000 | Django/Python apps |
| 9000 | Alternative web services |

## Firewall Configuration

If you're accessing from another machine, make sure the firewall allows the port:

### UFW (Ubuntu/Debian)
```bash
# Allow port 5000
sudo ufw allow 5000/tcp

# Allow custom port
sudo ufw allow 8080/tcp

# Check status
sudo ufw status
```

### firewalld (RHEL/CentOS)
```bash
# Allow port 5000
sudo firewall-cmd --permanent --add-port=5000/tcp
sudo firewall-cmd --reload

# Check
sudo firewall-cmd --list-ports
```

### iptables
```bash
# Allow port 5000
sudo iptables -A INPUT -p tcp --dport 5000 -j ACCEPT
```

## Accessing the Application

After configuration, access the application at:

```
http://localhost:[PORT]
http://[SERVER_IP]:[PORT]
```

**Examples:**
- Default: http://localhost:5000
- Custom 8080: http://localhost:8080
- Remote access: http://192.168.1.100:5000

## Troubleshooting

### Service won't start after changing port

**Check if port is in use:**
```bash
sudo netstat -tlnp | grep :[PORT]
```

**Check service logs:**
```bash
sudo journalctl -u auto-stretch -n 50
```

**Common errors:**
- "Address already in use" - Another service is using that port
- "Permission denied" - Using privileged port (< 1024) without proper permissions

### Can't access from browser

1. **Check service is running:**
   ```bash
   sudo systemctl status auto-stretch
   ```

2. **Check firewall:**
   ```bash
   sudo ufw status
   ```

3. **Check if port is listening:**
   ```bash
   sudo netstat -tlnp | grep python
   ```

4. **Check browser URL:**
   - Make sure you're using the correct port
   - Use `http://` not `https://`

## Security Notes

- **Internal Use**: If only using locally, bind to localhost (already configured)
- **External Access**: Be aware that the application will be accessible from other machines
- **Firewall**: Use firewall rules to restrict access if needed
- **Reverse Proxy**: For production, consider using nginx/apache as reverse proxy with HTTPS

## Example Configurations

### Development (Local Only)
```
APP_PORT=5000
```
Access: http://localhost:5000

### Small Office
```
APP_PORT=8080
```
Access: http://server-ip:8080

### Production with Reverse Proxy
```
APP_PORT=5000
```
Nginx listens on 80/443 and forwards to localhost:5000
