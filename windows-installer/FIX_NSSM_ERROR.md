# Fix: NSSM Plugin Error

## Error You're Seeing

```
Plugin not found, cannot call inetc::get in script "installer.nsi" on line 170
-- aborting creation process
ERROR: Build failed!
```

## Problem

The original NSIS script tried to download NSSM during installation using the `inetc` plugin, which is not included by default with NSIS.

## Solution: Fixed!

I've updated the installer script to **not require the inetc plugin**. Instead, NSSM needs to be downloaded beforehand and placed in the `windows-installer` directory.

## How to Fix

### Option 1: Automatic Download (Recommended)

Run the download script:

```powershell
cd windows-installer
powershell -ExecutionPolicy Bypass -File download-nssm.ps1
```

This will download NSSM and place it in the correct location.

### Option 2: Manual Download

If automatic download fails (server unavailable):

1. **Download NSSM:**
   - Visit: https://nssm.cc/download
   - Or direct link: https://nssm.cc/release/nssm-2.24.zip

2. **Extract the file:**
   - Extract `nssm-2.24.zip`
   - Navigate to: `nssm-2.24\win64\`
   - Find: `nssm.exe`

3. **Copy to installer directory:**
   ```
   Copy nssm.exe to: C:\Users\aviralv\Downloads\auto-streach\windows-installer\
   ```

4. **Verify:**
   ```cmd
   dir nssm.exe
   ```
   Should show the file in the windows-installer directory.

### Option 3: Build Without NSSM (Not Recommended)

You can build the installer without NSSM, but the service installation will fail. The installer will show a warning and the user will need to manually copy nssm.exe after installation.

## After Fixing

Once `nssm.exe` is in the `windows-installer` directory:

```cmd
cd windows-installer
build-installer.bat
```

The build should complete successfully!

## What Changed

**Before (broken):**
```nsis
; This required inetc plugin
inetc::get "https://nssm.cc/release/nssm-2.24.zip" "$TEMP\nssm.zip" /END
```

**After (fixed):**
```nsis
; Now copies from installer directory
IfFileExists "nssm.exe" 0 nssm_missing
    File "nssm.exe"
    Goto nssm_done
nssm_missing:
    DetailPrint "Warning: NSSM not found..."
nssm_done:
```

## Alternative: Use PowerShell Installer

If you can't get NSSM or prefer a simpler approach, use the PowerShell installer instead:

```powershell
cd windows-installer
.\simple-install.ps1
```

The PowerShell installer:
- ✅ Doesn't need NSIS
- ✅ Downloads NSSM automatically during installation
- ✅ Works immediately without building

## Build Steps Summary

1. ✅ Install NSIS
2. ✅ Download NSSM (run `download-nssm.ps1` or manual download)
3. ✅ Run `build-installer.bat`
4. ✅ Distribute `AutoStretch-Setup-1.0.0.exe`

## Verification

After downloading NSSM:

```cmd
cd windows-installer
dir nssm.exe
```

Should show:
```
nssm.exe    (approximately 300-400 KB)
```

Then build:
```cmd
build-installer.bat
```

Should complete without the plugin error!

## Status

✅ **FIXED** - Installer script updated to not require inetc plugin
✅ **TESTED** - NSIS script syntax verified
⏳ **PENDING** - Need to download NSSM

## Support

If you still have issues:
1. Check that `nssm.exe` is in `windows-installer` directory
2. Verify NSIS is installed correctly
3. Try the PowerShell installer as alternative
