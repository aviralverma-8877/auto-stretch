# Quick Fix for Service Permissions Issue
# Run this on the system where the service won't start
# Usage: Run as Administrator

#Requires -RunAsAdministrator

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Auto Stretch - Permission Fix" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$InstallDir = "C:\Program Files\AutoStretch"

# Check if installation exists
if (-not (Test-Path $InstallDir)) {
    Write-Host "ERROR: Auto Stretch not found at: $InstallDir" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Found installation at: $InstallDir" -ForegroundColor Green
Write-Host ""

# Stop service if running
Write-Host "Stopping service..." -ForegroundColor Yellow
Stop-Service -Name "AutoStretch" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Grant full permissions to SYSTEM account
Write-Host "Granting full permissions to SYSTEM account..." -ForegroundColor Yellow
$result = icacls "$InstallDir" /grant "NT AUTHORITY\SYSTEM:(OI)(CI)F" /T /Q 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "Permissions granted successfully!" -ForegroundColor Green
} else {
    Write-Host "Some files failed, but continuing..." -ForegroundColor Yellow
}

Write-Host ""

# Remove and reinstall service
Write-Host "Removing existing service..." -ForegroundColor Yellow
& "$InstallDir\nssm.exe" remove AutoStretch confirm 2>&1 | Out-Null
Start-Sleep -Seconds 2

# Get port from config
$port = 5000
$configPath = "$InstallDir\config.env"
if (Test-Path $configPath) {
    $content = Get-Content $configPath
    foreach ($line in $content) {
        if ($line -match "APP_PORT=(\d+)") {
            $port = $matches[1]
            break
        }
    }
}

Write-Host "Reinstalling service with port $port..." -ForegroundColor Yellow

$pythonExe = "$InstallDir\venv\Scripts\python.exe"
$appScript = "$InstallDir\app.py"

# Install service with ONLY the Python executable (CRITICAL FIX)
Write-Host "Installing service with Python executable..." -ForegroundColor Gray
& "$InstallDir\nssm.exe" install AutoStretch $pythonExe

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to install service!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Configure service
Write-Host "Setting application parameters..." -ForegroundColor Gray

# CRITICAL: Set app.py as AppParameters (not as part of install command)
& "$InstallDir\nssm.exe" set AutoStretch AppParameters $appScript

& "$InstallDir\nssm.exe" set AutoStretch DisplayName "Auto Stretch - Astronomy Image Processor"
& "$InstallDir\nssm.exe" set AutoStretch Description "Flask-based web application for processing astronomical TIFF images"
& "$InstallDir\nssm.exe" set AutoStretch AppDirectory $InstallDir
& "$InstallDir\nssm.exe" set AutoStretch AppEnvironmentExtra "APP_PORT=$port" "PYTHONUNBUFFERED=1"
& "$InstallDir\nssm.exe" set AutoStretch Start SERVICE_AUTO_START
& "$InstallDir\nssm.exe" set AutoStretch AppStdout "$InstallDir\logs\service-output.log"
& "$InstallDir\nssm.exe" set AutoStretch AppStderr "$InstallDir\logs\service-error.log"
& "$InstallDir\nssm.exe" set AutoStretch AppRotateFiles 1
& "$InstallDir\nssm.exe" set AutoStretch AppRotateBytes 1048576
& "$InstallDir\nssm.exe" set AutoStretch AppExit Default Restart
& "$InstallDir\nssm.exe" set AutoStretch AppRestartDelay 5000

Write-Host "Service configured successfully!" -ForegroundColor Green
Write-Host ""

# Start service
Write-Host "Starting service..." -ForegroundColor Yellow
Start-Service -Name AutoStretch -ErrorAction Stop

Start-Sleep -Seconds 3

# Check status
$service = Get-Service -Name AutoStretch
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Service Status: $($service.Status)" -ForegroundColor $(if ($service.Status -eq "Running") { "Green" } else { "Red" })
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($service.Status -eq "Running") {
    Write-Host "SUCCESS! Service is now running." -ForegroundColor Green
    Write-Host ""
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
