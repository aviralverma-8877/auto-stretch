# Building Auto Stretch Debian Package on Windows

Quick guide for building the Debian package on Windows using Docker Desktop.

## Prerequisites

### 1. Install Docker Desktop

Download and install Docker Desktop for Windows:
- https://www.docker.com/products/docker-desktop

After installation:
1. Start Docker Desktop
2. Wait for the Docker icon in system tray to show "Docker Desktop is running"

### 2. Verify Docker Installation

Open PowerShell or Command Prompt:

```cmd
docker --version
```

Should show something like: `Docker version 24.0.x, build xxxxx`

```cmd
docker info
```

Should show Docker system information without errors.

## Building the Package

### Step 1: Open Command Prompt

Navigate to the auto-streach directory:

```cmd
cd C:\Users\aviralv\Downloads\auto-streach
```

### Step 2: Run the Build Script

Simply double-click `build-with-docker.bat` or run:

```cmd
build-with-docker.bat
```

### Step 3: Wait for Build

The script will:
1. ✅ Check Docker availability
2. ✅ Download Debian Trixie image (~50 MB, one-time)
3. ✅ Create build environment
4. ✅ Build the .deb package

This takes about 2-5 minutes on first run (image download),
then ~30 seconds on subsequent runs.

### Step 4: Package Created!

You'll see:

```
==========================================
Build Complete!
==========================================

Package: auto-stretch_1.0.0_all.deb
Size: XXXXX bytes

To install on Debian Trixie:
  1. Copy the .deb file to your Debian system
  2. Run: sudo dpkg -i auto-stretch_1.0.0_all.deb
  3. Access at: http://localhost:5000
```

The `.deb` file will be in the same directory.

## Transferring to Debian

### Option A: Using SCP (if you have SSH access)

```powershell
scp auto-stretch_1.0.0_all.deb user@debian-server:/tmp/
```

Then on the Debian server:
```bash
cd /tmp
sudo dpkg -i auto-stretch_1.0.0_all.deb
```

### Option B: Using USB Drive

1. Copy `auto-stretch_1.0.0_all.deb` to USB drive
2. Plug into Debian machine
3. Install:
   ```bash
   sudo dpkg -i /media/usb/auto-stretch_1.0.0_all.deb
   ```

### Option C: Using Shared Folder (WSL2)

If you have WSL2 with Debian:

```powershell
# In Windows PowerShell
wsl -d Debian

# Now in Debian
cd /mnt/c/Users/aviralv/Downloads/auto-streach
sudo dpkg -i auto-stretch_1.0.0_all.deb
```

Then access at http://localhost:5000 from Windows!

## Troubleshooting

### Docker not found

**Error**: `'docker' is not recognized as an internal or external command`

**Solution**:
1. Make sure Docker Desktop is installed
2. Restart your computer
3. Verify Docker Desktop is running (check system tray)

### Docker daemon not running

**Error**: `error during connect: ... Docker daemon is not running`

**Solution**:
1. Start Docker Desktop from Start Menu
2. Wait for "Docker Desktop is running" in system tray
3. Try again

### Permission denied

**Error**: `permission denied while trying to connect to the Docker daemon`

**Solution**:
- Run Command Prompt as Administrator
- Or add your user to docker-users group (requires logout)

### WSL2 not configured

**Error**: `WSL 2 installation is incomplete`

**Solution**:
1. Open PowerShell as Administrator
2. Run: `wsl --install`
3. Restart computer
4. Start Docker Desktop

### Permission errors during build

**Error**: `dpkg-deb: error: control directory has bad permissions 777 (must be >=0755 and <=0775)`

**Solution**:
This is fixed in the build script. The script now sets proper permissions:
- DEBIAN directory: 0755
- control file: 0644
- maintainer scripts: 0755

If you still see this error, ensure you're using the latest build-deb.sh script.

### Build fails

**Error**: Various build errors

**Solutions**:
1. Check disk space (need ~500 MB)
2. Update Docker Desktop to latest version
3. Try: `docker system prune` to clean up
4. Restart Docker Desktop
5. Ensure build scripts have execute permissions: `chmod +x scripts/*.sh`

## Testing Locally with WSL2

You can test the package on Windows using WSL2:

### Install WSL2 Debian

```powershell
# In PowerShell (as Administrator)
wsl --install -d Debian
```

Restart computer, then:

```powershell
# Start Debian
wsl -d Debian

# Update system
sudo apt-get update
sudo apt-get upgrade

# Install the package
cd /mnt/c/Users/aviralv/Downloads/auto-streach
sudo dpkg -i auto-stretch_1.0.0_all.deb

# Access from Windows browser
# http://localhost:5000
```

## Alternative: Build Without Docker

If Docker doesn't work, you can:

### 1. Use GitHub Actions (Free)

Create a repository, push the code, and use GitHub Actions to build.

### 2. Use Online Debian VM

- https://www.osboxes.org/debian/ (Download Debian VM)
- Run in VirtualBox
- Share folder with Windows
- Build inside VM

### 3. Use Debian Cloud Instance

- DigitalOcean, Linode, or AWS
- Free tier available
- Build and download

## Next Steps

Once you have the `.deb` file:

1. Transfer to Debian Trixie system
2. Install: `sudo dpkg -i auto-stretch_1.0.0_all.deb`
3. Access web interface: http://localhost:5000
4. Upload TIFF images and process!

## Quick Reference

| File | Purpose |
|------|---------|
| `build-with-docker.bat` | Windows build script |
| `build-with-docker.sh` | Linux/Mac build script |
| `build-deb.sh` | Direct build on Debian |
| `auto-stretch_1.0.0_all.deb` | Final package file |

## Need Help?

See also:
- **INSTALL_DEBIAN.md** - Installation guide
- **DEBIAN_PACKAGE.md** - Detailed package documentation
- **PACKAGE_SUMMARY.md** - Quick reference

## Tips

💡 **Speed up builds**: Docker caches the Debian image after first download. Subsequent builds are much faster!

💡 **Disk space**: Clean up Docker images with `docker system prune -a` when done.

💡 **Local testing**: Use WSL2 Debian to test the package without a separate Debian machine.

💡 **Updates**: To rebuild after changes, just run `build-with-docker.bat` again.
