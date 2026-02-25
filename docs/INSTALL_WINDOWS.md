# Auto Stretch - Windows Installation Guide

Complete guide for installing Auto Stretch on Windows as a Windows service.

## Two Installation Methods

### Method 1: NSIS Installer (Recommended for End Users)
- ✅ Professional installer with GUI
- ✅ Creates uninstaller
- ✅ Automatic dependency installation
- ✅ Requires building with NSIS

### Method 2: PowerShell Script (Quick & Simple)
- ✅ No build tools required
- ✅ Direct installation
- ✅ Good for developers and testing
- ✅ Requires manual PowerShell execution

---

## Method 1: NSIS Installer

### For End Users

#### Prerequisites
1. **Windows 10/11** (64-bit)
2. **Python 3.9+** from [python.org](https://www.python.org/downloads/)
   - ⚠️ **Check "Add Python to PATH" during installation!**

#### Installation Steps

1. **Download Installer**
   ```
   AutoStretch-Setup-1.0.0.exe
   ```

2. **Run Installer**
   - Right-click → **Run as Administrator**
   - Follow installation wizard

3. **Configure Port**
   - Enter port number (default: 5000)
   - Click Next

4. **Install**
   - Click Install
   - Wait for completion

5. **Access Application**
   - Desktop shortcut created
   - Or browse to: `http://localhost:5000`

#### What Gets Installed
- Application files in `C:\Program Files\AutoStretch`
- Windows service (automatic startup)
- Start Menu shortcuts
- Desktop shortcut
- Uninstaller

### For Developers (Building Installer)

#### Prerequisites
1. **NSIS** - Download from [nsis.sourceforge.io](https://nsis.sourceforge.io/Download)
2. Add NSIS to PATH

#### Build Steps

1. **Navigate to installer directory**
   ```cmd
   cd windows-installer
   ```

2. **Run build script**
   ```cmd
   build-installer.bat
   ```

   Or manually:
   ```cmd
   makensis installer.nsi
   ```

3. **Output**
   ```
   windows-installer/AutoStretch-Setup-1.0.0.exe
   ```

#### Distribution
Distribute the `.exe` file to users. No additional files needed.

---

## Method 2: PowerShell Script

### Simple Installation (No NSIS Required)

#### Prerequisites
1. **Windows 10/11** (64-bit)
2. **Python 3.9+** with PATH configured
3. **Administrator privileges**

#### Installation Steps

1. **Open PowerShell as Administrator**
   - Right-click Start → Windows PowerShell (Admin)

2. **Navigate to project**
   ```powershell
   cd "C:\Users\...\auto-streach\windows-installer"
   ```

3. **Run installer**
   ```powershell
   .\simple-install.ps1
   ```

4. **Follow prompts**
   - Enter port (default: 5000)
   - Enter installation directory (default: C:\Program Files\AutoStretch)
   - Wait for installation
   - Choose to start service

5. **Access Application**
   ```
   http://localhost:5000
   ```

#### Custom Installation
```powershell
.\simple-install.ps1 -InstallDir "D:\MyApps\AutoStretch" -Port 8080
```

### Uninstallation

#### Using Uninstaller Script
```powershell
.\simple-uninstall.ps1
```

---

## Post-Installation

### Service Management

#### Start Service
**Option 1: Start Menu**
```
Start Menu → Auto Stretch → Start Service
```

**Option 2: PowerShell**
```powershell
Start-Service AutoStretch
```

**Option 3: Services Manager**
```
Win + R → services.msc → Find "AutoStretch" → Start
```

#### Stop Service
```powershell
Stop-Service AutoStretch
```

#### Check Status
```powershell
Get-Service AutoStretch
```

### Change Port After Installation

1. **Stop service**
   ```powershell
   Stop-Service AutoStretch
   ```

2. **Edit config file**
   ```
   C:\Program Files\AutoStretch\config.env
   ```
   Change:
   ```
   APP_PORT=8080
   ```

3. **Start service**
   ```powershell
   Start-Service AutoStretch
   ```

### View Logs

**PowerShell:**
```powershell
Get-Content "C:\Program Files\AutoStretch\logs\service-output.log" -Tail 50
```

**Log Files:**
```
C:\Program Files\AutoStretch\logs\
  - service-output.log  (Application output)
  - service-error.log   (Error messages)
```

---

## Service Details

### Service Configuration
- **Name:** AutoStretch
- **Display Name:** Auto Stretch - Astronomy Image Processor
- **Startup Type:** Automatic
- **Account:** Local System
- **Manager:** NSSM (Non-Sucking Service Manager)

### Installation Directory
```
C:\Program Files\AutoStretch\
├── venv\                 # Python virtual environment
├── templates\            # HTML templates
├── static\              # CSS, JavaScript, images
├── logs\                # Service logs
├── app.py               # Main application
├── post_process.py      # Image processing
├── config.env           # Configuration (port)
├── requirements.txt     # Dependencies
└── nssm.exe            # Service manager
```

---

## Firewall Configuration

### Allow Remote Access

If accessing from other computers:

**PowerShell (as Admin):**
```powershell
New-NetFirewallRule -DisplayName "Auto Stretch" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 5000 `
    -Action Allow
```

**Or Windows Firewall GUI:**
1. Windows Defender Firewall → Advanced Settings
2. Inbound Rules → New Rule
3. Port → TCP → 5000
4. Allow connection → Apply to all profiles

---

## Troubleshooting

### Python Not Found

**Symptoms:**
- Installer fails with "Python not found"

**Solution:**
1. Install Python from [python.org](https://www.python.org/downloads/)
2. **Check "Add Python to PATH"**
3. Restart computer
4. Verify: `python --version`
5. Run installer again

### Service Won't Start

**Check logs:**
```powershell
Get-Content "C:\Program Files\AutoStretch\logs\service-error.log" -Tail 20
```

**Check service status:**
```powershell
Get-Service AutoStretch | Format-List *
```

**Manual start attempt:**
```powershell
cd "C:\Program Files\AutoStretch"
.\venv\Scripts\python.exe app.py
```

### Port Already in Use

**Find process using port:**
```powershell
Get-NetTCPConnection -LocalPort 5000 | Select-Object -Property OwningProcess
```

**Change to different port:**
1. Edit `config.env`
2. Restart service

### Permission Errors

**Run as Administrator:**
- All installation and service commands must run as Administrator

**Check NSSM:**
```powershell
& "C:\Program Files\AutoStretch\nssm.exe" status AutoStretch
```

### Dependencies Installation Fails

**Manual installation:**
```powershell
cd "C:\Program Files\AutoStretch"
.\venv\Scripts\activate
pip install -r requirements.txt
```

---

## Comparison: NSIS vs PowerShell

| Feature | NSIS Installer | PowerShell Script |
|---------|---------------|-------------------|
| **GUI** | ✅ Yes | ❌ No (command-line) |
| **Build Required** | ✅ Yes (NSIS) | ❌ No |
| **Uninstaller** | ✅ Automatic | ⚠️ Manual script |
| **Add/Remove Programs** | ✅ Yes | ❌ No |
| **Port Config** | ✅ GUI dialog | ⚠️ Prompt |
| **Best For** | End users | Developers, testing |
| **File Size** | ~10-15 MB | Source only |
| **Distribution** | Single .exe | Multiple files |

---

## Advanced Configuration

### Custom Service Configuration

**Edit with NSSM GUI:**
```cmd
nssm edit AutoStretch
```

**Available settings:**
- Application path
- Arguments
- Working directory
- Environment variables
- Log rotation
- Restart behavior

### Environment Variables

Add to `config.env`:
```
APP_PORT=5000
PYTHONUNBUFFERED=1
DEBUG=False
CUSTOM_VAR=value
```

### Multiple Instances

Run multiple instances on different ports:

1. Copy installation directory
2. Change port in config.env
3. Install as different service:
   ```powershell
   nssm install AutoStretch2 ...
   ```

---

## System Requirements

### Minimum
- Windows 10 (64-bit)
- Python 3.9+
- 2 GB RAM
- 500 MB disk space

### Recommended
- Windows 11 (64-bit)
- Python 3.11+
- 4 GB RAM
- 1 GB disk space
- SSD for better performance

### Tested On
- ✅ Windows 10 (21H2, 22H2)
- ✅ Windows 11 (21H2, 22H2, 23H2)
- ✅ Windows Server 2019
- ✅ Windows Server 2022

---

## Security Considerations

### Service Account
- Default: Local System (full privileges)
- Production: Create dedicated service account

### Network Access
- Binds to 0.0.0.0 (all interfaces)
- Accessible from network if firewall allows
- Use reverse proxy (IIS) for HTTPS in production

### Firewall
- Blocked by default
- Manually configure for remote access
- Restrict to specific IP ranges if needed

---

## Uninstallation

### NSIS Installer Users

**Option 1: Start Menu**
```
Start Menu → Auto Stretch → Uninstall
```

**Option 2: Settings**
```
Settings → Apps → Auto Stretch → Uninstall
```

**Option 3: Uninstaller**
```
C:\Program Files\AutoStretch\Uninstall.exe
```

### PowerShell Script Users

**Run uninstaller:**
```powershell
cd windows-installer
.\simple-uninstall.ps1
```

**Or manual removal:**
1. Stop service: `Stop-Service AutoStretch`
2. Remove service: `sc.exe delete AutoStretch`
3. Delete directory: `C:\Program Files\AutoStretch`
4. Remove shortcuts from Start Menu and Desktop

---

## Getting Help

### Check Installation
```powershell
Get-Service AutoStretch
Get-ItemProperty -Path "HKLM:\Software\Auto Stretch"
```

### View Logs
```powershell
Get-Content "C:\Program Files\AutoStretch\logs\service-output.log" -Tail 50
```

### Service Status
```powershell
Get-Service AutoStretch | Format-List *
```

### Test Application
```powershell
cd "C:\Program Files\AutoStretch"
.\venv\Scripts\python.exe app.py
```
Then visit http://localhost:5000

---

## Quick Reference

### Common Commands

| Task | Command |
|------|---------|
| **Start Service** | `Start-Service AutoStretch` |
| **Stop Service** | `Stop-Service AutoStretch` |
| **Restart Service** | `Restart-Service AutoStretch` |
| **Check Status** | `Get-Service AutoStretch` |
| **View Logs** | `Get-Content "C:\...\logs\service-output.log"` |
| **Change Port** | Edit `config.env`, restart service |
| **Uninstall** | Run Uninstall.exe or script |

### File Locations

| Item | Path |
|------|------|
| **Installation** | `C:\Program Files\AutoStretch` |
| **Logs** | `C:\Program Files\AutoStretch\logs` |
| **Config** | `C:\Program Files\AutoStretch\config.env` |
| **Start Menu** | `Start Menu → Auto Stretch` |
| **Desktop** | `Auto Stretch.lnk` |
| **Registry** | `HKLM:\Software\Auto Stretch` |

---

## Support

For issues or questions:
- Check logs first
- Review troubleshooting section
- GitHub Issues: [github.com/example/auto-stretch](https://github.com/example/auto-stretch)

---

## License

See main README.md for license information.
