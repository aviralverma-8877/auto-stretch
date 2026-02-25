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
if ($service.Status -eq "Running") {
    Write-Host "Stopping service..." -ForegroundColor Yellow
    Stop-Service -Name $ServiceName -Force
    Start-Sleep -Seconds 2
}

# Remove service using NSSM
Write-Host "Removing service..." -ForegroundColor Yellow
if (Test-Path "$InstallDir\nssm.exe") {
    & "$InstallDir\nssm.exe" remove $ServiceName confirm
} else {
    # Fallback to sc.exe if NSSM not found
    sc.exe delete $ServiceName
}

Start-Sleep -Seconds 2

Write-Host ""
Write-Host "Service uninstalled successfully!" -ForegroundColor Green
Write-Host ""
