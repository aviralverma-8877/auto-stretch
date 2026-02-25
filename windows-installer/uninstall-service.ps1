# Uninstall Auto Stretch Service
# Usage: powershell -ExecutionPolicy Bypass -File uninstall-service.ps1

param(
    [string]$InstallDir = "$PSScriptRoot"
)

$ServiceName = "AutoStretch"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Uninstalling Auto Stretch Windows Service" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    exit 1
}

# Check if service exists
$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $service) {
    Write-Host "Service not found. Nothing to uninstall." -ForegroundColor Yellow
    exit 0
}

# Stop service if running
if ($service.Status -eq "Running" -or $service.Status -eq "Paused") {
    Write-Host "Stopping service..." -ForegroundColor Yellow
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
}

# Kill any remaining Python processes from this installation
Write-Host "Checking for running processes..." -ForegroundColor Yellow
$pythonPath = "$InstallDir\python\python.exe"
if (Test-Path $pythonPath) {
    $processes = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
        $_.Path -like "$InstallDir\*"
    }
    if ($processes) {
        Write-Host "Stopping $($processes.Count) Python process(es)..." -ForegroundColor Yellow
        $processes | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    }
}

# Remove service using NSSM
Write-Host "Removing service..." -ForegroundColor Yellow
if (Test-Path "$InstallDir\nssm.exe") {
    & "$InstallDir\nssm.exe" remove $ServiceName confirm 2>&1 | Out-Null
    Start-Sleep -Seconds 2

    # Verify removal
    $serviceCheck = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($serviceCheck) {
        Write-Host "NSSM removal failed, trying sc.exe..." -ForegroundColor Yellow
        sc.exe delete $ServiceName 2>&1 | Out-Null
        Start-Sleep -Seconds 2
    }
} else {
    # Fallback to sc.exe if NSSM not found
    Write-Host "NSSM not found, using sc.exe..." -ForegroundColor Yellow
    sc.exe delete $ServiceName 2>&1 | Out-Null
    Start-Sleep -Seconds 2
}

# Final verification
$finalCheck = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($finalCheck) {
    Write-Host ""
    Write-Host "WARNING: Service may not have been completely removed!" -ForegroundColor Red
    Write-Host "Try rebooting and running this script again." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "Service removed successfully!" -ForegroundColor Green
}

Write-Host ""
