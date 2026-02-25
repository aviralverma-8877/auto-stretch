# Windows Installer for Auto Stretch

This directory contains files for creating a Windows installer package that installs Auto Stretch as a Windows service.

## Quick Start

### For End Users

**Download and run:**
```
AutoStretch-Setup-1.0.0.exe
```

No additional steps needed!

### For Developers

**Option 1: Build NSIS Installer**
```cmd
build-installer.bat
```

**Option 2: Use PowerShell Script**
```powershell
.\simple-install.ps1
```

## Files in This Directory

### Installer Scripts
- **`installer.nsi`** - NSIS installer script (professional GUI installer)
- **`build-installer.bat`** - Build script for NSIS installer

### Simple PowerShell Installation
- **`simple-install.ps1`** - Direct PowerShell installation (no NSIS needed)
- **`simple-uninstall.ps1`** - PowerShell uninstaller

### Service Management
- **`install-service.ps1`** - Install Windows service
- **`start-service.ps1`** - Start the service
- **`stop-service.ps1`** - Stop the service
- **`uninstall-service.ps1`** - Uninstall the service

### Documentation
- **`README_WINDOWS.md`** - Comprehensive Windows installation guide
- **`README.md`** - This file

## Installation Methods

### Method 1: NSIS Installer (Recommended)

**Benefits:**
- ✅ Professional GUI installer
- ✅ Single .exe file
- ✅ Automatic uninstaller
- ✅ Add/Remove Programs integration
- ✅ Best for distribution to end users

**Requirements:**
- NSIS installed (for building)
- Python 3.9+ on user's machine

**Build:**
```cmd
build-installer.bat
```

**Distribute:**
```
AutoStretch-Setup-1.0.0.exe
```

### Method 2: PowerShell Script

**Benefits:**
- ✅ No build tools required
- ✅ Quick and simple
- ✅ Good for developers
- ✅ Customizable

**Requirements:**
- PowerShell 5.0+
- Python 3.9+
- Administrator privileges

**Install:**
```powershell
.\simple-install.ps1
```

**Uninstall:**
```powershell
.\simple-uninstall.ps1
```

## Building the NSIS Installer

### Prerequisites

1. **Install NSIS**
   - Download from: [nsis.sourceforge.io/Download](https://nsis.sourceforge.io/Download)
   - Install with default options
   - Add to PATH or note installation directory

2. **Prepare source files**
   - Ensure `../src/` contains all application files
   - Ensure `../requirements.txt` exists
   - Ensure `../README.md` exists

### Build Process

1. **Open Command Prompt in this directory**
   ```cmd
   cd windows-installer
   ```

2. **Run build script**
   ```cmd
   build-installer.bat
   ```

3. **Output**
   ```
   AutoStretch-Setup-1.0.0.exe
   ```

### What the Installer Does

1. Checks for Python 3.9+
2. Asks user for port number
3. Copies application files
4. Creates Python virtual environment
5. Installs dependencies
6. Downloads NSSM (service manager)
7. Installs and configures Windows service
8. Creates Start Menu shortcuts
9. Creates Desktop shortcut
10. Writes registry entries
11. Creates uninstaller

## Using PowerShell Installation

### Installation

```powershell
# Basic installation (interactive)
.\simple-install.ps1

# Custom installation
.\simple-install.ps1 -InstallDir "D:\AutoStretch" -Port 8080
```

**Interactive prompts:**
1. Port number (default: 5000)
2. Installation directory (default: C:\Program Files\AutoStretch)
3. Start service now? (Y/N)
4. Open web browser? (Y/N)

### Uninstallation

```powershell
.\simple-uninstall.ps1
```

## Service Management Scripts

These scripts are included in both installation methods.

### Install Service
```powershell
.\install-service.ps1 -InstallDir "C:\Path" -Port 5000
```

### Start Service
```powershell
.\start-service.ps1
```

### Stop Service
```powershell
.\stop-service.ps1
```

### Uninstall Service
```powershell
.\uninstall-service.ps1
```

## Installer Features

### NSIS Installer Features

- ✅ Professional installation wizard
- ✅ License agreement display
- ✅ Custom port configuration page
- ✅ Progress indicators
- ✅ Automatic dependency installation
- ✅ Service configuration
- ✅ Shortcut creation
- ✅ Registry management
- ✅ Complete uninstaller
- ✅ Add/Remove Programs entry

### PowerShell Script Features

- ✅ Command-line installation
- ✅ Customizable parameters
- ✅ Interactive prompts
- ✅ Detailed progress messages
- ✅ Error handling
- ✅ Service configuration
- ✅ Shortcut creation
- ✅ Registry management
- ✅ Uninstaller script

## Technical Details

### Service Configuration

**Service Name:** AutoStretch
**Display Name:** Auto Stretch - Astronomy Image Processor
**Startup Type:** Automatic
**Account:** Local System
**Manager:** NSSM (Non-Sucking Service Manager)

### Installation Structure

```
C:\Program Files\AutoStretch\
├── venv\                   # Python virtual environment
│   ├── Scripts\
│   │   ├── python.exe
│   │   ├── pip.exe
│   │   └── activate.bat
│   └── Lib\
├── templates\              # Flask templates
│   └── index.html
├── static\                # Static assets
│   ├── css\
│   └── favicon.*
├── logs\                  # Service logs
│   ├── service-output.log
│   └── service-error.log
├── app.py                 # Main application
├── post_process.py        # Image processing
├── requirements.txt       # Dependencies
├── config.env            # Configuration
├── nssm.exe              # Service manager
├── *.ps1                 # Service scripts
└── Uninstall.exe         # Uninstaller (NSIS only)
```

### Registry Keys

```
HKLM\Software\Auto Stretch\
  - InstallPath (String)
  - Version (String)
  - Port (String)

HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\Auto Stretch\
  - DisplayName
  - DisplayVersion
  - Publisher
  - UninstallString
```

## Distribution

### For End Users

Distribute only:
```
AutoStretch-Setup-1.0.0.exe
```

User requirements:
- Windows 10/11 (64-bit)
- Python 3.9+
- Administrator privileges

### For Developers

Share entire `windows-installer` directory plus source files for PowerShell installation method.

## Testing

### Test NSIS Installer

1. Build installer
2. Run on clean Windows machine
3. Follow installation wizard
4. Verify service starts
5. Access http://localhost:5000
6. Test functionality
7. Run uninstaller
8. Verify clean removal

### Test PowerShell Installation

1. Open PowerShell as Admin
2. Run `.\simple-install.ps1`
3. Verify installation
4. Test service
5. Access web interface
6. Run `.\simple-uninstall.ps1`
7. Verify clean removal

## Troubleshooting

### Build Errors

**NSIS not found:**
- Install NSIS
- Add to PATH
- Or run from NSIS directory

**Source files not found:**
- Check file paths in `installer.nsi`
- Ensure running from correct directory

### Installation Errors

**Python not found:**
- Install Python 3.9+
- Check "Add to PATH" during installation
- Restart computer

**Permission denied:**
- Run as Administrator
- Check UAC settings

**Service won't start:**
- Check logs in installation directory
- Verify Python virtual environment created
- Manually test: `venv\Scripts\python.exe app.py`

## Customization

### Change Application Name

In `installer.nsi`:
```nsis
!define APP_NAME "Your App Name"
!define SERVICE_NAME "YourServiceName"
```

### Change Default Port

In `installer.nsi`:
```nsis
StrCpy $PortNumber "8080"
```

In `simple-install.ps1`:
```powershell
param([int]$Port = 8080)
```

### Add Dependencies

In `requirements.txt`:
```
package-name==version
```

## Support

For issues:
1. Check logs in installation directory
2. Review README_WINDOWS.md
3. See ../docs/INSTALL_WINDOWS.md
4. GitHub Issues

## License

See main README.md for license information.

## Credits

- **NSSM** - https://nssm.cc/ (Public Domain)
- **NSIS** - https://nsis.sourceforge.io/ (zlib/libpng license)
