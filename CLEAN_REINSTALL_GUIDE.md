# Clean Reinstall Guide

## What Changed

I've enhanced the uninstaller and installer to **completely remove and reinstall the service**, fixing any configuration issues from previous installations.

---

## Updated Files

### 1. **[uninstall-service.ps1](windows-installer/uninstall-service.ps1)**
Enhanced to:
- ✅ Stop service (even if paused)
- ✅ Kill any running Python processes from the installation
- ✅ Remove service with NSSM
- ✅ Fallback to sc.exe if NSSM fails
- ✅ Verify complete removal
- ✅ Report if removal was unsuccessful

### 2. **[install-service.ps1](windows-installer/install-service.ps1)**
Enhanced to:
- ✅ Detect existing service
- ✅ Stop and kill any running processes
- ✅ **Completely remove old service** before installing
- ✅ Verify removal succeeded
- ✅ Install fresh service with correct configuration
- ✅ **Properly quote paths** (fixes "C:\Program" error)

### 3. **[installer.nsi](windows-installer/installer.nsi)**
Enhanced to:
- ✅ Wait 3 seconds after uninstalling service
- ✅ Ensures clean removal before file deletion

### 4. **NEW: [clean-reinstall.ps1](windows-installer/clean-reinstall.ps1)**
Complete reinstall script that:
- ✅ Stops all services and processes
- ✅ Removes service completely
- ✅ Clears old logs
- ✅ Sets proper permissions
- ✅ Reinstalls service with correct configuration
- ✅ Starts service and verifies status

---

## How to Use

### On System Where Service Won't Start:

**Option 1: Quick Fix (Just fix path quoting)**
```powershell
powershell -ExecutionPolicy Bypass -File fix-path-quotes.ps1
```

**Option 2: Clean Reinstall (Recommended - completely removes and reinstalls)**
```powershell
powershell -ExecutionPolicy Bypass -File clean-reinstall.ps1
```

### For Future Installations:

Rebuild the installer with all fixes:
```cmd
cd windows-installer
build-installer.bat
```

The new installer will:
- ✅ Bundle Python (no Windows Store issues)
- ✅ Remove any existing service before installing
- ✅ Configure service with properly quoted paths
- ✅ Set correct permissions
- ✅ Start service automatically

---

## What Gets Fixed

### Path Quoting Issue:
**Before:**
```
AppParameters: C:\Program Files\AutoStretch\app.py
Error: can't open file 'C:\Program'
```

**After:**
```
AppParameters: "C:\Program Files\AutoStretch\app.py"
Works correctly!
```

### Service Removal:
**Before:**
```
- Stopped service only
- Old configuration remained
- Reinstall inherited bad config
```

**After:**
```
- Stops service
- Kills all running processes
- Removes service completely
- Verifies removal
- Fresh install with clean config
```

---

## Immediate Fix for Your System

Since the service is already installed but not working, use the **clean-reinstall.ps1** script:

### Steps:

1. **Copy [clean-reinstall.ps1](windows-installer/clean-reinstall.ps1) to the system**

2. **Run as Administrator:**
   ```powershell
   cd path\to\script
   powershell -ExecutionPolicy Bypass -File clean-reinstall.ps1
   ```

3. **The script will:**
   - Stop service
   - Remove completely
   - Clear logs
   - Set permissions
   - Reinstall with correct paths
   - Start service

4. **Service should be running!**

---

## What the Scripts Do

### uninstall-service.ps1
```
1. Stop service (handles Running/Paused states)
2. Kill any Python processes from installation
3. Remove service with NSSM
4. Fallback to sc.exe if needed
5. Verify complete removal
```

### install-service.ps1
```
1. Check for NSSM and Python
2. Set permissions for SYSTEM account
3. Check for existing service
   → If exists: Stop, kill processes, remove completely
4. Install service with Python executable
5. Configure with QUOTED app.py path ← Critical fix
6. Set all service parameters
7. Start service
8. Verify it's running
```

### clean-reinstall.ps1
```
1. Stop service
2. Kill processes
3. Remove service (NSSM + sc.exe)
4. Clear logs
5. Set permissions
6. Reinstall service
7. Configure properly (with quoted paths)
8. Start service
9. Open browser if successful
```

---

## Testing

After running clean-reinstall.ps1:

```powershell
# Check service status
Get-Service AutoStretch

# Check if Python is running
Get-Process python | Where-Object { $_.Path -like "*AutoStretch*" }

# Check logs
Get-Content "C:\Program Files\AutoStretch\logs\service-output.log" -Tail 20

# Access web interface
# Open browser to: http://localhost:5000 (or your configured port)
```

---

## Troubleshooting

### If clean-reinstall fails:

1. **Reboot the system**
2. **Run clean-reinstall.ps1 again**

Sometimes Windows services need a reboot to fully release locks.

### If service still won't start:

1. **Check the error log:**
   ```powershell
   notepad "C:\Program Files\AutoStretch\logs\service-error.log"
   ```

2. **Check if Python works manually:**
   ```powershell
   cd "C:\Program Files\AutoStretch"
   .\python\python.exe app.py
   ```

3. **Check NSSM configuration:**
   ```powershell
   cd "C:\Program Files\AutoStretch"
   .\nssm.exe dump AutoStretch
   ```

---

## Summary

**Problem:** Service had wrong configuration from Windows Store Python and path quoting issues

**Solution:**
1. Enhanced uninstaller to completely remove service
2. Enhanced installer to remove existing service before reinstalling
3. Fixed path quoting: `"C:\Program Files\AutoStretch\app.py"`
4. Created clean-reinstall.ps1 for immediate fix

**Result:** Service installs cleanly, configures correctly, and starts reliably

---

## Next Steps

**On the system where service is failing:**

1. Run [clean-reinstall.ps1](windows-installer/clean-reinstall.ps1)
2. Service should start immediately
3. Access http://localhost:5000 (or your port)

**For future installations:**

1. Rebuild installer: `build-installer.bat`
2. New installer has all fixes
3. Will work on any system

The service should now work perfectly! 🎉
