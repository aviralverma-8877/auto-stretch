#!/bin/bash
set -e

PACKAGE_NAME="auto-stretch"
VERSION="1.0.0"
ARCH="all"
BUILD_DIR="$(pwd)/debian"
APP_DIR="$BUILD_DIR/opt/auto-stretch"

echo "========================================"
echo "Building Auto Stretch Debian Package"
echo "========================================"
echo ""

# Clean previous build if exists
if [ -d "$BUILD_DIR" ]; then
    echo "Cleaning previous build..."
    rm -rf "$BUILD_DIR/opt"
    mkdir -p "$BUILD_DIR/opt/auto-stretch"
fi

# Create application directory structure
echo "Creating directory structure..."
mkdir -p "$APP_DIR"
mkdir -p "$APP_DIR/templates"
mkdir -p "$APP_DIR/static/css"

# Copy application files
echo "Copying application files..."
cp src/app.py "$APP_DIR/"
cp src/post_process.py "$APP_DIR/"
cp requirements.txt "$APP_DIR/"
cp README.md "$APP_DIR/"

# Copy templates
cp src/templates/index.html "$APP_DIR/templates/"

# Copy static files
cp -r src/static/* "$APP_DIR/static/"

# Create a production-ready version of app.py
echo "Creating production configuration..."
cat > "$APP_DIR/app_start.py" << 'APPSTART'
#!/usr/bin/env python3
import sys
import os

# Ensure the application directory is in the path
sys.path.insert(0, '/opt/auto-stretch')

# Import and run the application
from app import app

if __name__ == '__main__':
    # Run on all interfaces for systemd service
    app.run(host='0.0.0.0', port=5000, debug=False)
APPSTART

# Update the systemd service to use the wrapper script
sed -i 's|ExecStart=/usr/bin/python3 /opt/auto-stretch/app.py|ExecStart=/usr/bin/python3 /opt/auto-stretch/app_start.py|' \
    "$BUILD_DIR/etc/systemd/system/auto-stretch.service"

# Set proper permissions
echo "Setting permissions..."
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
chmod 0644 "$APP_DIR/app.py"
chmod 0644 "$APP_DIR/post_process.py"

# Systemd service files
find "$BUILD_DIR/etc" -type d -exec chmod 0755 {} \;
find "$BUILD_DIR/etc" -type f -exec chmod 0644 {} \;

# Calculate installed size (in KB)
INSTALLED_SIZE=$(du -sk "$BUILD_DIR" | cut -f1)

# Remove any existing Installed-Size field and add the new one
sed -i '/^Installed-Size:/d' "$BUILD_DIR/DEBIAN/control"
echo "Installed-Size: $INSTALLED_SIZE" >> "$BUILD_DIR/DEBIAN/control"

# Build the package
echo ""
echo "Building package..."
PACKAGE_FILE="${PACKAGE_NAME}_${VERSION}_${ARCH}.deb"

dpkg-deb --build "$BUILD_DIR" "$PACKAGE_FILE"

# Check the package
echo ""
echo "Verifying package..."
dpkg-deb --info "$PACKAGE_FILE"

echo ""
echo "========================================"
echo "Build Complete!"
echo "========================================"
echo ""
echo "Package created: $PACKAGE_FILE"
echo "Package size: $(du -h "$PACKAGE_FILE" | cut -f1)"
echo ""
echo "To install:"
echo "  sudo dpkg -i $PACKAGE_FILE"
echo "  sudo apt-get install -f  # If there are dependency issues"
echo ""
echo "To remove:"
echo "  sudo apt-get remove $PACKAGE_NAME      # Keep config files"
echo "  sudo apt-get purge $PACKAGE_NAME       # Remove everything"
echo ""
