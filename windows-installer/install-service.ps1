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

# Check if NSSM exists
$nssmPath = "$InstallDir\nssm.exe"
if (-not (Test-Path $nssmPath)) {
    Write-Host "ERROR: NSSM not found at: $nssmPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please download NSSM from: https://nssm.cc/release/nssm-2.24.zip" -ForegroundColor Yellow
    Write-Host "Extract nssm.exe from nssm-2.24\win64\ to: $InstallDir" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# Verify Python and app.py exist
$pythonExe = "$InstallDir\python\python.exe"
$appScript = "$InstallDir\app.py"

if (-not (Test-Path $pythonExe)) {
    Write-Host "ERROR: Python not found at: $pythonExe" -ForegroundColor Red
    Write-Host "Bundled Python was not installed correctly." -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $appScript)) {
    Write-Host "ERROR: Application script not found at: $appScript" -ForegroundColor Red
    exit 1
}

# Create logs directory first (before configuring service)
Write-Host "Creating logs directory..." -ForegroundColor Green
$logsDir = "$InstallDir\logs"
if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir | Out-Null
}

# Grant permissions to Local System account (service runs as SYSTEM)
Write-Host "Setting file permissions..." -ForegroundColor Green
try {
    # Grant Full Control to SYSTEM account (needed for logs and temp files)
    $acl = Get-Acl $InstallDir
    $systemSid = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-18")
    $systemAccount = $systemSid.Translate([System.Security.Principal.NTAccount])
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $systemAccount,
        "FullControl",
        "ContainerInherit,ObjectInherit",
        "None",
        "Allow"
    )
    $acl.SetAccessRule($accessRule)
    Set-Acl -Path $InstallDir -AclObject $acl

    Write-Host "Permissions set successfully for SYSTEM account" -ForegroundColor Green
} catch {
    Write-Host "Warning: Could not set permissions via PowerShell: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Trying icacls command..." -ForegroundColor Yellow

    # Fallback to icacls
    $icaclsResult = & icacls "`"$InstallDir`"" /grant "NT AUTHORITY\SYSTEM:(OI)(CI)F" /T /Q 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Permissions set successfully via icacls" -ForegroundColor Green
    } else {
        Write-Host "Failed to set permissions. Service may not start." -ForegroundColor Red
        Write-Host "Manually run: icacls `"$InstallDir`" /grant `"NT AUTHORITY\SYSTEM:(OI)(CI)F`" /T" -ForegroundColor Yellow
    }
}

# Check if service already exists
$existingService = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($existingService) {
    Write-Host "Service already exists. Stopping..." -ForegroundColor Yellow
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    Write-Host "Removing existing service..." -ForegroundColor Yellow
    & "$nssmPath" remove $ServiceName confirm
    Start-Sleep -Seconds 2
}

# Install service using NSSM
Write-Host "Installing service..." -ForegroundColor Green

# Set environment variable for port
$env:APP_PORT = $Port

# Install service - Install with ONLY the Python executable
# NSSM requires: install <servicename> <executable>
# Then set parameters separately with AppParameters
Write-Host "Installing service with Python executable only..." -ForegroundColor Gray
& "$nssmPath" install $ServiceName $pythonExe
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to install service! Exit code: $LASTEXITCODE" -ForegroundColor Red
    Write-Host "Try removing existing service first if it exists" -ForegroundColor Yellow
    exit 1
}

# Configure service
Write-Host "Configuring service..." -ForegroundColor Green

# CRITICAL: Set the app.py script as a parameter (not part of install command)
Write-Host "Setting application parameters (app.py)..." -ForegroundColor Gray
& "$nssmPath" set $ServiceName AppParameters $appScript

# Set other configuration
& "$nssmPath" set $ServiceName DisplayName $ServiceDisplayName
& "$nssmPath" set $ServiceName Description $ServiceDescription
& "$nssmPath" set $ServiceName AppDirectory $InstallDir
& "$nssmPath" set $ServiceName AppEnvironmentExtra "APP_PORT=$Port" "PYTHONUNBUFFERED=1"
& "$nssmPath" set $ServiceName Start SERVICE_AUTO_START
& "$nssmPath" set $ServiceName AppStdout "$logsDir\service-output.log"
& "$nssmPath" set $ServiceName AppStderr "$logsDir\service-error.log"
& "$nssmPath" set $ServiceName AppRotateFiles 1
& "$nssmPath" set $ServiceName AppRotateBytes 1048576  # 1MB

# Set service to restart on failure
& "$nssmPath" set $ServiceName AppExit Default Restart
& "$nssmPath" set $ServiceName AppRestartDelay 5000  # 5 seconds

Write-Host ""
Write-Host "Service installed successfully!" -ForegroundColor Green

# Start the service
Write-Host "Starting service..." -ForegroundColor Green
try {
    Start-Service -Name $ServiceName -ErrorAction Stop
    Start-Sleep -Seconds 3

    # Verify service is running
    $service = Get-Service -Name $ServiceName
    if ($service.Status -eq "Running") {
        Write-Host "Service started successfully!" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Service installed but not running. Status: $($service.Status)" -ForegroundColor Yellow
        Write-Host "Check logs at: $logsDir\service-error.log" -ForegroundColor Yellow
    }
} catch {
    Write-Host "WARNING: Service installed but failed to start!" -ForegroundColor Yellow
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "Check logs at: $logsDir\service-error.log" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Service Name: $ServiceName" -ForegroundColor Cyan
Write-Host "Display Name: $ServiceDisplayName" -ForegroundColor Cyan
Write-Host "Port: $Port" -ForegroundColor Cyan
Write-Host "Web Interface: http://localhost:$Port" -ForegroundColor Cyan
Write-Host "Logs: $logsDir" -ForegroundColor Cyan
Write-Host ""
