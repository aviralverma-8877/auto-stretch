# Build Fixes

## Issue 1: Permission Error

### Problem
```
dpkg-deb: error: control directory has bad permissions 777 (must be >=0755 and <=0775)
```

## Root Cause
The `debian/DEBIAN` directory and its contents had incorrect permissions. Debian packages require strict permission settings:
- DEBIAN directory: must be exactly 0755
- control file: must be 0644
- maintainer scripts (postinst, prerm, postrm): must be 0755

## Solution Applied

Updated `scripts/build-deb.sh` to set proper permissions before building the package:

```bash
# DEBIAN directory and control files (strict permissions required by dpkg)
chmod 0755 "$BUILD_DIR/DEBIAN"
chmod 0644 "$BUILD_DIR/DEBIAN/control"
chmod 0755 "$BUILD_DIR/DEBIAN/postinst"
chmod 0755 "$BUILD_DIR/DEBIAN/prerm"
chmod 0755 "$BUILD_DIR/DEBIAN/postrm"

# Application directories
find "$BUILD_DIR/opt" -type d -exec chmod 0755 {} \;
find "$BUILD_DIR/opt" -type f -exec chmod 0644 {} \;
chmod 0755 "$APP_DIR/app_start.py"

# Systemd service files
find "$BUILD_DIR/etc" -type d -exec chmod 0755 {} \;
find "$BUILD_DIR/etc" -type f -exec chmod 0644 {} \;
```

## Testing the Fix

### On Linux/Mac with Docker:
```bash
chmod +x scripts/build-with-docker.sh
./scripts/build-with-docker.sh
```

### On Windows with Docker Desktop:
```cmd
scripts\build-with-docker.bat
```

### Direct build on Debian:
```bash
chmod +x scripts/build-deb.sh
./scripts/build-deb.sh
```

## Expected Output

After the fix, you should see:
```
Setting permissions...
Building package...
dpkg-deb: building package 'auto-stretch' in 'auto-stretch_1.0.0_all.deb'.

==========================================
Build Complete!
==========================================

Package created: auto-stretch_1.0.0_all.deb
```

## File Locations

| File | Location | Purpose |
|------|----------|---------|
| Build script | `scripts/build-deb.sh` | Main build script (fixed) |
| Docker build | `scripts/build-with-docker.sh` | Docker wrapper (Unix) |
| Windows Docker | `scripts/build-with-docker.bat` | Docker wrapper (Windows) |

## Verification

After building, verify the package:
```bash
dpkg-deb --info auto-stretch_1.0.0_all.deb
dpkg-deb --contents auto-stretch_1.0.0_all.deb
```

Both commands should complete without errors.

## Additional Notes

- The fix ensures all files and directories in the package have correct permissions
- This follows Debian packaging best practices
- The permissions are set recursively for all application files
- Executable files (app_start.py, maintainer scripts) get 0755
- Regular files (Python modules, configs) get 0644
- All directories get 0755

---

## Issue 2: Duplicate Installed-Size Field

### Problem
```
dpkg-deb: error: parsing file '/DATA/Downloads/auto-streach/debian/DEBIAN/control' near line 23 package 'auto-stretch':
 duplicate value for 'Installed-Size' field
```

### Root Cause
The build script appends `Installed-Size` to the control file each time it runs. If you run the build multiple times without cleaning, the field gets duplicated.

### Solution Applied

Updated `scripts/build-deb.sh` to remove any existing `Installed-Size` field before adding the new one:

```bash
# Calculate installed size (in KB)
INSTALLED_SIZE=$(du -sk "$BUILD_DIR" | cut -f1)

# Remove any existing Installed-Size field and add the new one
sed -i '/^Installed-Size:/d' "$BUILD_DIR/DEBIAN/control"
echo "Installed-Size: $INSTALLED_SIZE" >> "$BUILD_DIR/DEBIAN/control"
```

### Manual Fix (if needed)

If you still have duplicates in your control file, clean it manually:

```bash
# Remove all Installed-Size lines from control file
sed -i '/^Installed-Size:/d' debian/DEBIAN/control

# Or edit the file and manually remove duplicate lines
nano debian/DEBIAN/control
```

Then run the build script again.

### Prevention

The updated build script now automatically handles this, so you can run the build multiple times without issues.

---

## Status: ✅ ALL ISSUES FIXED
