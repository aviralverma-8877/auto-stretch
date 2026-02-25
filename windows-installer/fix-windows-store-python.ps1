# Fix for Windows Store Python Issue
# This script recreates the virtual environment using system-wide Python
# Run as Administrator

#Requires -RunAsAdministrator

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fix Windows Store Python Issue" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$InstallDir = "C:\Program Files\AutoStretch"

# Check if installation exists
if (-not (Test-Path $InstallDir)) {
    Write-Host "ERROR: Auto Stretch not found at: $InstallDir" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "The issue: Windows Store Python cannot be used for Windows services" -ForegroundColor Yellow
Write-Host "because services run as SYSTEM and cannot access user AppData folders." -ForegroundColor Yellow
Write-Host ""

# Check current Python
Write-Host "Checking current Python installation..." -ForegroundColor Cyan
$pythonCmd = Get-Command python -ErrorAction SilentlyContinue

if ($pythonCmd) {
    $pythonPath = $pythonCmd.Source
    Write-Host "Found Python at: $pythonPath" -ForegroundColor Gray

    # Check if it's Windows Store Python
    if ($pythonPath -like "*WindowsApps*") {
        Write-Host ""
        Write-Host "ERROR: You are still using Windows Store Python!" -ForegroundColor Red
        Write-Host ""
        Write-Host "To fix this:" -ForegroundColor Yellow
        Write-Host "1. Download Python from: https://www.python.org/downloads/" -ForegroundColor Yellow
        Write-Host "2. Run the installer" -ForegroundColor Yellow
        Write-Host "3. Check 'Add Python to PATH'" -ForegroundColor Yellow
        Write-Host "4. After installation, close this window and open a NEW PowerShell window" -ForegroundColor Yellow
        Write-Host "5. Run this script again" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Press Enter to exit"
        exit 1
    }

    Write-Host "[OK] Using system-wide Python (not Windows Store)" -ForegroundColor Green
} else {
    Write-Host "ERROR: Python not found in PATH!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install Python from: https://www.python.org/downloads/" -ForegroundColor Yellow
    Write-Host "Make sure to check 'Add Python to PATH' during installation" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "This will:" -ForegroundColor Cyan
Write-Host "1. Stop the service" -ForegroundColor Gray
Write-Host "2. Delete the old virtual environment" -ForegroundColor Gray
Write-Host "3. Create a new venv with system Python" -ForegroundColor Gray
Write-Host "4. Reinstall all dependencies" -ForegroundColor Gray
Write-Host "5. Restart the service" -ForegroundColor Gray
Write-Host ""

$response = Read-Host "Continue? (Y/N)"
if ($response -ne "Y" -and $response -ne "y") {
    Write-Host "Cancelled" -ForegroundColor Yellow
    exit 0
}

Write-Host ""

# Stop service
Write-Host "Stopping service..." -ForegroundColor Yellow
Stop-Service -Name "AutoStretch" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Remove old venv
Write-Host "Removing old virtual environment..." -ForegroundColor Yellow
if (Test-Path "$InstallDir\venv") {
    Remove-Item -Path "$InstallDir\venv" -Recurse -Force
}

# Create new venv with --copies flag (makes it self-contained)
Write-Host "Creating new virtual environment with system Python..." -ForegroundColor Green
& python -m venv "$InstallDir\venv" --copies

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to create virtual environment!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[OK] Virtual environment created" -ForegroundColor Green

# Upgrade pip
Write-Host "Upgrading pip..." -ForegroundColor Green
& "$InstallDir\venv\Scripts\pip.exe" install --upgrade pip wheel

# Install dependencies
Write-Host "Installing dependencies..." -ForegroundColor Green
& "$InstallDir\venv\Scripts\pip.exe" install -r "$InstallDir\requirements.txt"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to install dependencies!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[OK] Dependencies installed" -ForegroundColor Green
Write-Host ""

# Verify the new Python path
Write-Host "Verifying new Python executable..." -ForegroundColor Cyan
$newPythonPath = & "$InstallDir\venv\Scripts\python.exe" -c "import sys; print(sys.executable)" 2>&1

if ($newPythonPath -like "*WindowsApps*") {
    Write-Host "WARNING: Virtual environment still references Windows Store Python!" -ForegroundColor Red
    Write-Host "Path: $newPythonPath" -ForegroundColor Gray
} else {
    Write-Host "[OK] Virtual environment is using system Python" -ForegroundColor Green
    Write-Host "Path: $newPythonPath" -ForegroundColor Gray
}

Write-Host ""

# Start service
Write-Host "Starting service..." -ForegroundColor Yellow
Start-Service -Name "AutoStretch" -ErrorAction Stop

Start-Sleep -Seconds 5

# Check status
$service = Get-Service -Name "AutoStretch"
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Service Status: $($service.Status)" -ForegroundColor $(if ($service.Status -eq "Running") { "Green" } else { "Red" })
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($service.Status -eq "Running") {
    Write-Host "SUCCESS! Service is now running!" -ForegroundColor Green
    Write-Host ""

    # Get port
    $port = (Get-ItemProperty -Path "HKLM:\Software\Auto Stretch" -Name "Port" -ErrorAction SilentlyContinue).Port
    if (-not $port) {
        $port = 5000
    }

    Write-Host "Web Interface: http://localhost:$port" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Open in browser? (Y/N)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -eq "Y" -or $response -eq "y") {
        Start-Process "http://localhost:$port"
    }
} else {
    Write-Host "ERROR: Service failed to start!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check error log:" -ForegroundColor Yellow
    Write-Host "  $InstallDir\logs\service-error.log" -ForegroundColor Gray
    Write-Host ""

    if (Test-Path "$InstallDir\logs\service-error.log") {
        Write-Host "Last 10 lines of error log:" -ForegroundColor Yellow
        Get-Content "$InstallDir\logs\service-error.log" -Tail 10 | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
    }
}

Write-Host ""
Read-Host "Press Enter to exit"
