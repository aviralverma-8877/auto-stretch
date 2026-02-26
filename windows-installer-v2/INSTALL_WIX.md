# Installing WiX Toolset

## Current Version: WiX 4.x

WiX Toolset has upgraded to version 4.x. There are two installation options:

## Option 1: WiX 4.x (Recommended - Current Version)

### Install via .NET Tool (Easiest)

```powershell
# Install .NET SDK 6.0 or later if not already installed
# Download from: https://dotnet.microsoft.com/download

# Install WiX as a .NET tool
dotnet tool install --global wix

# Verify installation
wix --version
```

### Alternative: Install WiX 4.x via GitHub Releases

1. Visit: https://github.com/wixtoolset/wix4/releases
2. Download the latest release (e.g., `wix-4.0.x-windows.zip`)
3. Extract to a folder (e.g., `C:\Program Files\WiX Toolset v4`)
4. Add the `bin` folder to your PATH

**Note**: WiX 4.x uses different syntax than WiX 3.x. The Product.wxs file will need updates.

## Option 2: WiX 3.14 (Legacy - for compatibility)

WiX 3.x is the older version but still works. To install:

### Via GitHub Releases (Archive)

1. Visit: https://github.com/wixtoolset/wix3/releases/tag/wix3141rtm
2. Download `wix314.exe` (installer)
3. Run installer (installs to `C:\Program Files (x86)\WiX Toolset v3.14\`)
4. Restart PowerShell to pick up PATH changes

### Via Chocolatey

```powershell
choco install wixtoolset -y
```

### Manual Download Links

- WiX 3.14: https://github.com/wixtoolset/wix3/releases/download/wix3141rtm/wix314.exe
- WiX 3.11: https://github.com/wixtoolset/wix3/releases/download/wix3112rtm/wix311.exe

## Which Version Should I Use?

### Use WiX 4.x if:
- ✅ You want the latest features
- ✅ You're starting a new installer
- ✅ You're comfortable with .NET tools

### Use WiX 3.x if:
- ✅ You need compatibility with existing WiX 3.x projects
- ✅ You prefer traditional MSI build tools
- ✅ You want maximum stability

## For This Project

The current `Product.wxs` is written for **WiX 3.x**.

If you install WiX 4.x, we'll need to update the WiX files to the new syntax.

**Easiest path forward:**
1. Install WiX 3.14 from the GitHub release link above
2. Restart PowerShell
3. Run `build-msi.ps1`

**Future-proof path:**
1. Install WiX 4.x via `dotnet tool install --global wix`
2. I'll update the WiX files to v4 syntax
3. Run the updated build script

Let me know which version you'd like to use!
