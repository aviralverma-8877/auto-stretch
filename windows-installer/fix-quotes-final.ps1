# Final Fix for NSSM Path Quoting
# This uses the correct NSSM syntax for quoted paths
#Requires -RunAsAdministrator

$InstallDir = "C:\Program Files\AutoStretch"

Write-Host "Fixing NSSM path quoting..." -ForegroundColor Cyan

# Stop service
Stop-Service -Name AutoStretch -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

# The trick: NSSM needs the path passed with escaped quotes
# We need to pass it as: nssm set ServiceName AppParameters "\"C:\Program Files\AutoStretch\app.py\""
$appPath = "$InstallDir\app.py"

# Use Start-Process to properly escape for NSSM
$nssmArgs = @(
    "set",
    "AutoStretch",
    "AppParameters",
    "`"$appPath`""
)

Write-Host "Running: nssm.exe set AutoStretch AppParameters `"$appPath`"" -ForegroundColor Gray

& "$InstallDir\nssm.exe" @nssmArgs

# Verify what was set
Write-Host ""
Write-Host "Verifying configuration..." -ForegroundColor Yellow
$result = & "$InstallDir\nssm.exe" get AutoStretch AppParameters
Write-Host "AppParameters is now: $result" -ForegroundColor Cyan

# Start service
Write-Host ""
Write-Host "Starting service..." -ForegroundColor Yellow
Start-Service -Name AutoStretch
Start-Sleep -Seconds 5

$service = Get-Service -Name AutoStretch
Write-Host ""
Write-Host "Service Status: $($service.Status)" -ForegroundColor $(if ($service.Status -eq "Running") { "Green" } else { "Red" })

if ($service.Status -eq "Running") {
    Write-Host ""
    Write-Host "SUCCESS!" -ForegroundColor Green
    Write-Host "Opening browser..." -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    Start-Process "http://localhost:5000"
} else {
    Write-Host ""
    Write-Host "Service failed to start. Check logs:" -ForegroundColor Red
    Write-Host "  $InstallDir\logs\service-error.log" -ForegroundColor Gray
}

Read-Host "Press Enter to exit"
