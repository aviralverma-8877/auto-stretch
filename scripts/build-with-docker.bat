@echo off
REM Build Debian package using Docker (works on Windows with Docker Desktop)

set PACKAGE_NAME=auto-stretch
set VERSION=1.0.0

echo ==========================================
echo Building %PACKAGE_NAME% Debian Package
echo Using Docker (Debian Trixie)
echo ==========================================
echo.

REM Check if Docker is available
docker --version >nul 2>&1
if errorlevel 1 (
    echo Error: Docker is not installed or not in PATH
    echo Please install Docker Desktop: https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

REM Check if Docker daemon is running
docker info >nul 2>&1
if errorlevel 1 (
    echo Error: Docker daemon is not running
    echo Please start Docker Desktop
    pause
    exit /b 1
)

echo Creating Docker build environment...

REM Create a temporary Dockerfile
(
echo FROM debian:trixie-slim
echo.
echo RUN apt-get update ^&^& \
echo     apt-get install -y dpkg-dev debhelper ^&^& \
echo     rm -rf /var/lib/apt/lists/*
echo.
echo WORKDIR /build
echo.
echo CMD ["./build-deb.sh"]
) > Dockerfile.build

REM Build the Docker image
echo Building Docker image...
docker build -f Dockerfile.build -t auto-stretch-builder:latest .
if errorlevel 1 (
    echo Error building Docker image
    del Dockerfile.build
    pause
    exit /b 1
)

REM Run the build in Docker
echo.
echo Building package in Docker container...
docker run --rm -v "%cd%":/build auto-stretch-builder:latest
if errorlevel 1 (
    echo Error building package
    del Dockerfile.build
    pause
    exit /b 1
)

REM Clean up
del Dockerfile.build

REM Check if package was created
if exist "%PACKAGE_NAME%_%VERSION%_all.deb" (
    echo.
    echo ==========================================
    echo Build Complete!
    echo ==========================================
    echo.
    echo Package: %PACKAGE_NAME%_%VERSION%_all.deb
    for %%A in ("%PACKAGE_NAME%_%VERSION%_all.deb") do echo Size: %%~zA bytes
    echo.
    echo To install on Debian Trixie:
    echo   1. Copy the .deb file to your Debian system
    echo   2. Run: sudo dpkg -i %PACKAGE_NAME%_%VERSION%_all.deb
    echo   3. Access at: http://localhost:5000
    echo.
) else (
    echo.
    echo Error: Package file was not created
    pause
    exit /b 1
)

pause
