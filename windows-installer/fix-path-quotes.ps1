# Quick fix for path quoting issue
#Requires -RunAsAdministrator

$InstallDir = "C:\Program Files\AutoStretch"

Write-Host "Fixing path quoting issue..." -ForegroundColor Cyan

# Stop service
Stop-Service -Name AutoStretch -Force -ErrorAction SilentlyContinue

# Fix the AppParameters with proper quoting
& "$InstallDir\nssm.exe" set AutoStretch AppParameters "`"$InstallDir\app.py`""

# Start service
Start-Service -Name AutoStretch

Start-Sleep -Seconds 3

# Check status
$service = Get-Service -Name AutoStretch

if ($service.Status -eq "Running") {
    Write-Host "SUCCESS! Service is now running!" -ForegroundColor Green

    $port = (Get-ItemProperty -Path "HKLM:\Software\Auto Stretch" -Name "Port" -ErrorAction SilentlyContinue).Port
    if (-not $port) { $port = 5000 }

    Write-Host "Web Interface: http://localhost:$port" -ForegroundColor Cyan

    Start-Process "http://localhost:$port"
} else {
    Write-Host "Service Status: $($service.Status)" -ForegroundColor Yellow
    Write-Host "Check logs: $InstallDir\logs\service-error.log" -ForegroundColor Yellow
}

Read-Host "Press Enter to exit"
