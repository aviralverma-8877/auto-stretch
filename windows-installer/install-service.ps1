# Install Auto Stretch as Windows Service
# Usage: powershell -ExecutionPolicy Bypass -File install-service.ps1 <InstallDir> <Port>

param(
    [string]$InstallDir = "$PSScriptRoot",
    [string]$Port = "5000"
)

$ServiceName = "AutoStretch"
$ServiceDisplayName = "Auto Stretch - Astronomy Image Processor"
$ServiceDescription = "Flask-based web application for processing astronomical TIFF images with advanced stretching algorithms."

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installing Auto Stretch Windows Service" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    exit 1
}

# Check if service already exists
$existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($existingService) {
    Write-Host "Service already exists. Stopping..." -ForegroundColor Yellow
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    Write-Host "Removing existing service..." -ForegroundColor Yellow
    & "$InstallDir\nssm.exe" remove $ServiceName confirm
    Start-Sleep -Seconds 2
}

# Install service using NSSM
Write-Host "Installing service..." -ForegroundColor Green
$pythonExe = "$InstallDir\venv\Scripts\python.exe"
$appScript = "$InstallDir\app.py"

# Set environment variable for port
$env:APP_PORT = $Port

# Install service
& "$InstallDir\nssm.exe" install $ServiceName $pythonExe $appScript

# Configure service
Write-Host "Configuring service..." -ForegroundColor Green
& "$InstallDir\nssm.exe" set $ServiceName DisplayName $ServiceDisplayName
& "$InstallDir\nssm.exe" set $ServiceName Description $ServiceDescription
& "$InstallDir\nssm.exe" set $ServiceName AppDirectory $InstallDir
& "$InstallDir\nssm.exe" set $ServiceName AppEnvironmentExtra "APP_PORT=$Port" "PYTHONUNBUFFERED=1"
& "$InstallDir\nssm.exe" set $ServiceName Start SERVICE_AUTO_START
& "$InstallDir\nssm.exe" set $ServiceName AppStdout "$InstallDir\logs\service-output.log"
& "$InstallDir\nssm.exe" set $ServiceName AppStderr "$InstallDir\logs\service-error.log"
& "$InstallDir\nssm.exe" set $ServiceName AppRotateFiles 1
& "$InstallDir\nssm.exe" set $ServiceName AppRotateBytes 1048576  # 1MB

# Create logs directory
$logsDir = "$InstallDir\logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir | Out-Null
}

# Set service to restart on failure
& "$InstallDir\nssm.exe" set $ServiceName AppExit Default Restart
& "$InstallDir\nssm.exe" set $ServiceName AppRestartDelay 5000  # 5 seconds

Write-Host ""
Write-Host "Service installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Service Name: $ServiceName" -ForegroundColor Cyan
Write-Host "Display Name: $ServiceDisplayName" -ForegroundColor Cyan
Write-Host "Port: $Port" -ForegroundColor Cyan
Write-Host "Web Interface: http://localhost:$Port" -ForegroundColor Cyan
Write-Host ""
Write-Host "The service has been configured to start automatically." -ForegroundColor Yellow
Write-Host "Use 'start-service.ps1' to start it now." -ForegroundColor Yellow
Write-Host ""
