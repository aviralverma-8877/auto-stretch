# Auto Stretch - Windows Installer

Windows installer package that installs Auto Stretch as a Windows service with automatic startup.

## Prerequisites

### For End Users (Installing the Application)

1. **Windows 10/11** (64-bit)
2. **Python 3.9 or later** - Download from [python.org](https://www.python.org/downloads/)
   - ⚠️ **Important**: During Python installation, check "Add Python to PATH"
3. **Administrator privileges** - Required for service installation

### For Developers (Building the Installer)

1. **NSIS (Nullsoft Scriptable Install System)**
   - Download from: [nsis.sourceforge.io](https://nsis.sourceforge.io/Download)
   - Install and add to PATH
2. **Python 3.9+** with required packages

## Quick Installation (End Users)

### Step 1: Download
Download the installer: `AutoStretch-Setup-1.0.0.exe`

### Step 2: Run Installer
1. Right-click the installer → **Run as Administrator**
2. Follow the installation wizard
3. Choose installation directory (default: `C:\Program Files\AutoStretch`)
4. **Enter port number** (default: 5000)
   - Recommended ports: 5000, 8080, 3000
5. Click Install

### Step 3: Installation Process
The installer will:
- ✅ Check for Python 3.9+
- ✅ Copy application files
- ✅ Create Python virtual environment
- ✅ Install dependencies (Flask, Pillow, numpy, etc.)
- ✅ Download and configure NSSM (service manager)
- ✅ Install Windows service
- ✅ Create Start Menu shortcuts
- ✅ Create Desktop shortcut

### Step 4: Access Application
After installation:
- Service starts automatically
- Open browser: `http://localhost:5000` (or your chosen port)
- Desktop shortcut available
- Start Menu → Auto Stretch

## Post-Installation

### Starting the Service

**Option 1: Automatic (Default)**
- Service starts automatically on Windows startup
- No manual intervention needed

**Option 2: Manual Start**
- Start Menu → Auto Stretch → **Start Service**
- Or run PowerShell as Admin:
  ```powershell
  Start-Service AutoStretch
  ```

### Stopping the Service

**Option 1: Start Menu**
- Start Menu → Auto Stretch → **Stop Service**

**Option 2: PowerShell**
```powershell
Stop-Service AutoStretch
```

**Option 3: Services Manager**
- Press `Win + R` → type `services.msc` → Enter
- Find "Auto Stretch" → Right-click → Stop

### Checking Service Status

**PowerShell:**
```powershell
Get-Service AutoStretch
```

**Services Manager:**
- Press `Win + R` → type `services.msc` → Enter
- Find "Auto Stretch"

### Changing Port After Installation

1. Stop the service
2. Edit config file:
   ```
   C:\Program Files\AutoStretch\config.env
   ```
3. Change `APP_PORT=5000` to desired port
4. Save file
5. Start the service

Or update registry:
```powershell
Set-ItemProperty -Path "HKLM:\Software\Auto Stretch" -Name "Port" -Value 8080
```

## Logs

Service logs are located at:
```
C:\Program Files\AutoStretch\logs\
  - service-output.log  (Application output)
  - service-error.log   (Error messages)
```

**View logs:**
```powershell
Get-Content "C:\Program Files\AutoStretch\logs\service-output.log" -Tail 50
```

## Uninstallation

### Option 1: Start Menu
- Start Menu → Auto Stretch → **Uninstall**

### Option 2: Settings
- Settings → Apps → Apps & features
- Find "Auto Stretch" → Uninstall

### Option 3: Uninstaller
- Navigate to installation directory
- Run `Uninstall.exe`

**Uninstallation will:**
- ✅ Stop the service
- ✅ Remove the service
- ✅ Delete application files
- ✅ Remove Start Menu shortcuts
- ✅ Remove Desktop shortcut
- ✅ Clean up registry entries

## Building the Installer (Developers)

### Step 1: Install NSIS
1. Download NSIS from [nsis.sourceforge.io](https://nsis.sourceforge.io/Download)
2. Install with default options
3. Add NSIS to PATH (or note installation directory)

### Step 2: Prepare Files
Ensure project structure:
```
auto-streach/
├── src/
│   ├── app.py
│   ├── post_process.py
│   ├── templates/
│   └── static/
├── requirements.txt
├── README.md
└── windows-installer/
    ├── installer.nsi
    ├── install-service.ps1
    ├── start-service.ps1
    ├── stop-service.ps1
    ├── uninstall-service.ps1
    └── build-installer.bat
```

### Step 3: Build
```cmd
cd windows-installer
build-installer.bat
```

Or manually:
```cmd
makensis installer.nsi
```

### Step 4: Output
Installer will be created:
```
windows-installer/AutoStretch-Setup-1.0.0.exe
```

## Technical Details

### Service Configuration

**Service Name:** AutoStretch
**Display Name:** Auto Stretch - Astronomy Image Processor
**Startup Type:** Automatic
**Service Manager:** NSSM (Non-Sucking Service Manager)

### Installation Directory
Default: `C:\Program Files\AutoStretch\`

Contents:
```
AutoStretch/
├── venv/                 # Python virtual environment
├── templates/            # HTML templates
├── static/              # CSS, images
├── logs/                # Service logs
├── app.py               # Main application
├── post_process.py      # Image processing
├── config.env           # Port configuration
├── requirements.txt     # Python dependencies
├── nssm.exe            # Service manager
├── *.ps1               # Service scripts
└── Uninstall.exe       # Uninstaller
```

### Registry Keys

**Installation Info:**
```
HKLM\Software\Auto Stretch\
  - InstallPath (String): Installation directory
  - Version (String): Application version
  - Port (String): Web interface port
```

**Uninstaller Info:**
```
HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\Auto Stretch\
  - DisplayName
  - DisplayVersion
  - Publisher
  - UninstallString
```

### Python Dependencies

Installed in virtual environment:
- Flask 3.0.0
- Werkzeug 3.0.1
- Pillow 10.2.0
- numpy 1.26.3
- tifffile
- imagecodecs (optional)

### Firewall Configuration

If accessing from other computers on network:

1. Open Windows Defender Firewall
2. Advanced Settings → Inbound Rules → New Rule
3. Port → TCP → Specific port: 5000 (or your port)
4. Allow the connection
5. Apply to all profiles
6. Name: "Auto Stretch Web Interface"

Or PowerShell:
```powershell
New-NetFirewallRule -DisplayName "Auto Stretch" -Direction Inbound -Protocol TCP -LocalPort 5000 -Action Allow
```

## Troubleshooting

### Service Won't Start

**Check Python installation:**
```powershell
python --version
```
Should show Python 3.9 or later.

**Check service status:**
```powershell
Get-Service AutoStretch | Format-List *
```

**Check logs:**
```powershell
Get-Content "C:\Program Files\AutoStretch\logs\service-error.log" -Tail 20
```

**Common fixes:**
1. Ensure Python is in PATH
2. Reinstall Python with "Add to PATH" checked
3. Run: `python -m pip install --upgrade pip`
4. Reinstall application

### Port Already in Use

**Find what's using the port:**
```powershell
Get-NetTCPConnection -LocalPort 5000 | Select-Object -Property LocalAddress,LocalPort,State,OwningProcess
```

**Kill process or change port:**
1. Stop the service
2. Edit `C:\Program Files\AutoStretch\config.env`
3. Change to different port
4. Start the service

### Permission Errors

**Run as Administrator:**
- Right-click → Run as Administrator

**Check NSSM status:**
```powershell
& "C:\Program Files\AutoStretch\nssm.exe" status AutoStretch
```

### Python Not Found During Installation

1. Install Python from [python.org](https://www.python.org/downloads/)
2. During installation, check:
   - ✅ **Add Python to PATH**
   - ✅ Install for all users
3. Restart computer
4. Verify: `python --version`
5. Run installer again

### Dependencies Installation Fails

**Manual installation:**
```powershell
cd "C:\Program Files\AutoStretch"
.\venv\Scripts\activate
pip install -r requirements.txt
```

## Security Considerations

### Service Account
- Service runs as Local System account
- Has full system privileges
- Consider creating dedicated service account for production

### Network Access
- By default, binds to all interfaces (0.0.0.0)
- Accessible from network if firewall allows
- Use reverse proxy (IIS, nginx) for HTTPS in production

### Updates
- Stop service before updating
- Replace files manually or reinstall
- Preserve config.env if needed

## Advanced Configuration

### Custom Service Configuration

Edit service using NSSM GUI:
```cmd
nssm edit AutoStretch
```

Available settings:
- Application path
- Arguments
- Working directory
- Environment variables
- Log rotation
- Process priority
- Restart behavior

### Environment Variables

Edit `config.env`:
```
APP_PORT=5000
PYTHONUNBUFFERED=1
CUSTOM_VAR=value
```

### Running Multiple Instances

1. Copy installation directory
2. Use different port
3. Install as different service name:
   ```powershell
   nssm install AutoStretch2 ...
   ```

## Support

### Get Help
- Check logs: `C:\Program Files\AutoStretch\logs\`
- Service status: `Get-Service AutoStretch`
- GitHub Issues: [github.com/example/auto-stretch](https://github.com/example/auto-stretch)

### System Requirements
- Windows 10/11 (64-bit)
- Python 3.9+
- 2 GB RAM minimum
- 500 MB disk space

### Tested On
- ✅ Windows 10 (21H2, 22H2)
- ✅ Windows 11 (21H2, 22H2, 23H2)
- ✅ Windows Server 2019
- ✅ Windows Server 2022

## Changelog

### Version 1.0.0
- Initial Windows installer release
- NSIS-based installation
- Windows service integration using NSSM
- Automatic startup configuration
- Port configuration during installation
- Start Menu and Desktop shortcuts
- Comprehensive logging
- Clean uninstallation

## License

See main README.md for license information.

## Credits

- **NSSM** - [nssm.cc](https://nssm.cc/) - Public Domain
- **NSIS** - [nsis.sourceforge.io](https://nsis.sourceforge.io/) - zlib/libpng license
