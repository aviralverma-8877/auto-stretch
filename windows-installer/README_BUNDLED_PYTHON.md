# Building Installer with Bundled Python

This guide explains how to build the Auto Stretch installer with bundled Python, creating a **fully self-contained installer** that requires NO Python installation on the target system.

## Benefits

✅ **No Python Required** - Users don't need to install Python
✅ **No Windows Store Issues** - Eliminates Windows Store Python compatibility problems
✅ **Fully Self-Contained** - Everything needed is included in the installer
✅ **No PATH Conflicts** - Doesn't interfere with other Python installations
✅ **Always Works** - Same Python version on all systems
✅ **Service-Ready** - Python is accessible to Windows services (SYSTEM account)

## Prerequisites

1. **NSIS** (Nullsoft Scriptable Install System)
   - Download from: https://nsis.sourceforge.io/Download
   - Add to PATH or note installation directory

2. **PowerShell** - Already included in Windows

3. **Internet Connection** - To download Python embeddable package and NSSM

## Building the Installer

### Automatic Method (Recommended)

Simply run the build script - it will download everything automatically:

```cmd
cd windows-installer
build-installer.bat
```

The script will:
1. Check for bundled Python, prompt to download if missing
2. Check for NSSM, prompt to download if missing
3. Build the installer with NSIS

### Manual Method

If automatic download fails, you can prepare manually:

**Step 1: Download Python Embeddable Package**

Run the PowerShell script:
```powershell
cd windows-installer
powershell -ExecutionPolicy Bypass -File download-python.ps1
```

Or manually:
1. Visit: https://www.python.org/downloads/
2. Download: `python-3.12.8-embed-amd64.zip` (or latest 3.12.x)
3. Extract to: `windows-installer/python-embed/`
4. Download get-pip.py: https://bootstrap.pypa.io/get-pip.py
5. Place in: `windows-installer/python-embed/get-pip.py`
6. Edit `python312._pth` and uncomment `import site`

**Step 2: Download NSSM**

Run the PowerShell script:
```powershell
cd windows-installer
powershell -ExecutionPolicy Bypass -File download-nssm.ps1
```

Or manually:
1. Visit: https://nssm.cc/download
2. Download: `nssm-2.24.zip`
3. Extract `nssm-2.24/win64/nssm.exe`
4. Copy to: `windows-installer/nssm.exe`

**Step 3: Build**

```cmd
cd windows-installer
makensis installer.nsi
```

## Directory Structure

After downloading, your structure should look like:

```
windows-installer/
├── python-embed/          # Bundled Python
│   ├── python.exe
│   ├── python312.dll
│   ├── python312._pth
│   ├── get-pip.py
│   └── ... (other Python files)
├── nssm.exe              # NSSM service manager
├── installer.nsi         # NSIS installer script
├── download-python.ps1   # Python download script
├── download-nssm.ps1     # NSSM download script
└── build-installer.bat   # Build script
```

## How It Works

### Installation Process

1. **Installer copies bundled Python** to `C:\Program Files\AutoStretch\python\`
2. **Installs pip** in bundled Python
3. **Installs dependencies** (Flask, Pillow, numpy, etc.) using bundled Python's pip
4. **Creates Windows service** using bundled Python executable
5. **Service runs** using bundled Python (no system Python needed)

### Service Configuration

The service is configured to use:
- **Application**: `C:\Program Files\AutoStretch\python\python.exe`
- **Parameters**: `C:\Program Files\AutoStretch\app.py`
- **Working Directory**: `C:\Program Files\AutoStretch`

This means the service:
- ✅ Uses the bundled Python (always accessible to SYSTEM account)
- ✅ Has all dependencies installed in bundled Python
- ✅ Works independently of any system Python installation

## Python Version

The installer currently bundles **Python 3.12.8** (embeddable package).

### Updating Python Version

To use a different version, edit `download-python.ps1`:

```powershell
$pythonVersion = "3.12.8"  # Change this
```

Make sure to use:
- Python 3.9 or later (required for dependencies)
- 64-bit embeddable package (`-embed-amd64.zip`)
- Compatible with all packages in requirements.txt

## Troubleshooting

### "Bundled Python not found" error during build

**Solution**: Run `download-python.ps1` or manually download Python embeddable package

### Service fails to start after installation

**Check**:
1. Is Python directory present? `C:\Program Files\AutoStretch\python\`
2. Does python.exe exist? `C:\Program Files\AutoStretch\python\python.exe`
3. Check service logs: `C:\Program Files\AutoStretch\logs\service-error.log`

### Dependencies fail to install during installation

**Possible causes**:
- No internet connection (pip needs to download packages)
- Firewall blocking pip
- Incompatible package version in requirements.txt

**Solution**: Check installation logs in NSIS installer output

## Advantages Over System Python

| Aspect | Bundled Python | System Python |
|--------|---------------|---------------|
| Installation | Automatic | User must install |
| Windows Store Issues | ✅ None | ❌ Causes service failures |
| PATH Conflicts | ✅ None | ❌ Can conflict |
| Version Control | ✅ Guaranteed same version | ❌ User's version varies |
| Service Access | ✅ Always accessible | ❌ May not be accessible |
| Updates | ✅ Controlled by installer | ❌ User may update/break |

## File Size

The installer with bundled Python is approximately:
- **Python embeddable**: ~10 MB
- **Dependencies (Flask, Pillow, numpy, etc.)**: ~50 MB
- **Application files**: ~1 MB
- **NSSM**: ~0.5 MB

**Total installer size**: ~60-70 MB (compressed)

## Testing

To test the bundled installer:

1. Build the installer
2. Test on a **clean Windows system** (VM recommended)
3. Do NOT install Python on test system
4. Run installer as Administrator
5. Verify service starts automatically
6. Access web interface at configured port

This confirms the installer is truly self-contained.

## Related Files

- `installer.nsi` - Main NSIS installer script
- `download-python.ps1` - Downloads Python embeddable package
- `download-nssm.ps1` - Downloads NSSM service manager
- `build-installer.bat` - Automated build script
- `install-service.ps1` - Service installation script (uses bundled Python)

## Questions?

- For Python embeddable packages: https://www.python.org/downloads/windows/
- For NSIS installer documentation: https://nsis.sourceforge.io/Docs/
- For NSSM service manager: https://nssm.cc/
