#!/bin/bash
# Build Debian package using Docker (works on any system with Docker)

set -e

PACKAGE_NAME="auto-stretch"
VERSION="1.0.0"

echo "=========================================="
echo "Building $PACKAGE_NAME Debian Package"
echo "Using Docker (Debian Trixie)"
echo "=========================================="
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH"
    echo "Please install Docker Desktop: https://www.docker.com/products/docker-desktop"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo "Error: Docker daemon is not running"
    echo "Please start Docker Desktop"
    exit 1
fi

echo "Creating Docker build environment..."

# Create a temporary Dockerfile
cat > Dockerfile.build << 'DOCKERFILE'
FROM debian:trixie-slim

RUN apt-get update && \
    apt-get install -y dpkg-dev debhelper && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build

CMD ["./build-deb.sh"]
DOCKERFILE

# Build the Docker image
echo "Building Docker image..."
docker build -f Dockerfile.build -t auto-stretch-builder:latest .

# Run the build in Docker
echo ""
echo "Building package in Docker container..."
docker run --rm -v "$(pwd)":/build auto-stretch-builder:latest

# Clean up
rm Dockerfile.build

# Check if package was created
if [ -f "${PACKAGE_NAME}_${VERSION}_all.deb" ]; then
    echo ""
    echo "=========================================="
    echo "Build Complete!"
    echo "=========================================="
    echo ""
    echo "Package: ${PACKAGE_NAME}_${VERSION}_all.deb"
    echo "Size: $(du -h "${PACKAGE_NAME}_${VERSION}_all.deb" | cut -f1)"
    echo ""
    echo "To install on Debian Trixie:"
    echo "  1. Copy the .deb file to your Debian system"
    echo "  2. Run: sudo dpkg -i ${PACKAGE_NAME}_${VERSION}_all.deb"
    echo "  3. Access at: http://localhost:5000"
    echo ""
else
    echo ""
    echo "Error: Package file was not created"
    exit 1
fi
