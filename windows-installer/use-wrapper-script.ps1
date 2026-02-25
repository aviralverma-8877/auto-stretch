# Configure NSSM to Use Wrapper Script
# This bypasses all quoting issues!
#Requires -RunAsAdministrator

$InstallDir = "C:\Program Files\AutoStretch"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Using Wrapper Script Solution" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This completely bypasses the path quoting issue by using" -ForegroundColor Yellow
Write-Host "a wrapper batch file that NSSM calls." -ForegroundColor Yellow
Write-Host ""

# Stop service
Write-Host "Stopping service..." -ForegroundColor Yellow
Stop-Service -Name AutoStretch -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

# Create wrapper script
$wrapperPath = "$InstallDir\start-app.bat"
Write-Host "Creating wrapper script at: $wrapperPath" -ForegroundColor Cyan

$wrapperContent = @"
@echo off
REM Wrapper script to start Auto Stretch with properly quoted paths
cd /d "$InstallDir"
"$InstallDir\python\python.exe" "$InstallDir\app.py"
"@

Set-Content -Path $wrapperPath -Value $wrapperContent -Force
Write-Host "[OK] Wrapper script created" -ForegroundColor Green

# Reconfigure NSSM to use wrapper script
Write-Host ""
Write-Host "Reconfiguring NSSM to use wrapper script..." -ForegroundColor Cyan

# Set Application to the wrapper batch file (cmd.exe will run it)
& "$InstallDir\nssm.exe" set AutoStretch Application "$wrapperPath"

# Clear AppParameters (not needed with wrapper)
& "$InstallDir\nssm.exe" set AutoStretch AppParameters ""

Write-Host "[OK] NSSM reconfigured" -ForegroundColor Green

# Verify configuration
Write-Host ""
Write-Host "Current configuration:" -ForegroundColor Yellow
$app = & "$InstallDir\nssm.exe" get AutoStretch Application
$params = & "$InstallDir\nssm.exe" get AutoStretch AppParameters

Write-Host "  Application: $app" -ForegroundColor Gray
Write-Host "  AppParameters: $params" -ForegroundColor Gray

# Start service
Write-Host ""
Write-Host "Starting service..." -ForegroundColor Yellow
Start-Service -Name AutoStretch
Start-Sleep -Seconds 5

# Check status
$service = Get-Service -Name AutoStretch
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Service Status: $($service.Status)" -ForegroundColor $(if ($service.Status -eq "Running") { "Green" } else { "Red" })
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if ($service.Status -eq "Running") {
    Write-Host "SUCCESS! The wrapper script solution worked!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Web Interface: http://localhost:5000" -ForegroundColor Cyan
    Write-Host ""

    $response = Read-Host "Open in browser? (Y/N)"
    if ($response -eq "Y" -or $response -eq "y") {
        Start-Process "http://localhost:5000"
    }
} else {
    Write-Host "Service still failed to start." -ForegroundColor Red
    Write-Host ""
    Write-Host "Checking error log..." -ForegroundColor Yellow
    $errorLog = "$InstallDir\logs\service-error.log"
    if (Test-Path $errorLog) {
        Write-Host ""
        Get-Content $errorLog -Tail 10 | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
    }
}

Write-Host ""
Read-Host "Press Enter to exit"
