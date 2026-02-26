# uninstall-service.ps1
# MSI Custom Action: Uninstall Windows Service
#
# This script stops and removes the Auto Stretch Windows service
# Called by MSI during uninstallation

param(
    [string]$InstallDir = "C:\AutoStretch"
)

$ErrorActionPreference = "Continue"  # Continue on errors during uninstall

Write-Host "="*60
Write-Host "Auto Stretch - Service Uninstallation"
Write-Host "="*60
Write-Host ""

$pythonExe = Join-Path $InstallDir "python\python.exe"
$appDir = Join-Path $InstallDir "app"
$serviceScript = Join-Path $appDir "service_wrapper.py"
$serviceName = "AutoStretch"

# Check if service exists
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if (-not $service) {
    Write-Host "Service not found. Nothing to uninstall." -ForegroundColor Gray
    exit 0
}

Write-Host "Service found: $($service.DisplayName)" -ForegroundColor Cyan
Write-Host "Status: $($service.Status)" -ForegroundColor Cyan
Write-Host ""

# Step 1: Stop service
if ($service.Status -eq "Running" -or $service.Status -eq "Paused") {
    Write-Host "Stopping service..." -ForegroundColor Yellow
    try {
        Stop-Service -Name $serviceName -Force -ErrorAction Stop
        Start-Sleep -Seconds 2
        Write-Host "  Service stopped" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to stop service: $_"
    }
}

Write-Host ""

# Step 2: Remove service
Write-Host "Removing service..." -ForegroundColor Cyan

$removed = $false

# Try Python service wrapper first
if (Test-Path $pythonExe) {
    if (Test-Path $serviceScript) {
        try {
            Write-Host "  Using service_wrapper.py..." -ForegroundColor Gray
            & $pythonExe $serviceScript remove 2>&1 | Out-Null
            Start-Sleep -Seconds 1
            $removed = $true
            Write-Host "  Service removed via Python wrapper" -ForegroundColor Green
        } catch {
            Write-Host "  Python wrapper removal failed: $_" -ForegroundColor Yellow
        }
    }
}

# Fallback to sc.exe if Python method failed
if (-not $removed) {
    try {
        Write-Host "  Using sc.exe..." -ForegroundColor Gray
        & sc.exe delete $serviceName 2>&1 | Out-Null
        Start-Sleep -Seconds 1
        $removed = $true
        Write-Host "  Service removed via sc.exe" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to remove service via sc.exe: $_"
    }
}

Write-Host ""

# Step 3: Verify removal
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($service) {
    Write-Warning "Service still exists after removal attempt"
    Write-Warning "You may need to manually remove it with: sc.exe delete $serviceName"
} else {
    Write-Host "Service removed successfully!" -ForegroundColor Green
}

Write-Host ""
Write-Host "="*60
Write-Host "Service Uninstallation Complete"
Write-Host "="*60

exit 0
