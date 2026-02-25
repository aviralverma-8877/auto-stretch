# Simple Auto Stretch Installer for Windows
# No NSIS required - Pure PowerShell installation
# Usage: Run as Administrator

#Requires -RunAsAdministrator

param(
    [string]$InstallDir = "$env:ProgramFiles\AutoStretch",
    [int]$Port = 5000
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Auto Stretch - Simple Windows Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Python
Write-Host "Checking Python installation..." -ForegroundColor Yellow
try {
    $pythonVersion = & python --version 2>&1
    Write-Host "Found: $pythonVersion" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Python not found!" -ForegroundColor Red
    Write-Host "Please install Python 3.9+ from https://www.python.org/" -ForegroundColor Red
    exit 1
}

# Ask for port
Write-Host ""
$portInput = Read-Host "Enter port number for web interface (default: 5000)"
if ($portInput -match '^\d+$' -and [int]$portInput -gt 0 -and [int]$portInput -le 65535) {
    $Port = [int]$portInput
}
Write-Host "Using port: $Port" -ForegroundColor Green

# Ask for installation directory
Write-Host ""
$dirInput = Read-Host "Installation directory (default: $InstallDir)"
if ($dirInput) {
    $InstallDir = $dirInput
}
Write-Host "Installing to: $InstallDir" -ForegroundColor Green

# Create installation directory
Write-Host ""
Write-Host "Creating installation directory..." -ForegroundColor Yellow
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# Get source directory
$SourceDir = Split-Path -Parent $PSScriptRoot
$SrcPath = Join-Path $SourceDir "src"

if (-not (Test-Path $SrcPath)) {
    Write-Host "ERROR: Source files not found at $SrcPath" -ForegroundColor Red
    exit 1
}

# Copy files
Write-Host "Copying application files..." -ForegroundColor Yellow
Copy-Item -Path "$SrcPath\*" -Destination $InstallDir -Recurse -Force
Copy-Item -Path "$SourceDir\requirements.txt" -Destination $InstallDir -Force
Copy-Item -Path "$SourceDir\README.md" -Destination $InstallDir -Force -ErrorAction SilentlyContinue

# Copy service scripts
$InstallerPath = Join-Path $SourceDir "windows-installer"
Copy-Item -Path "$InstallerPath\install-service.ps1" -Destination $InstallDir -Force
Copy-Item -Path "$InstallerPath\start-service.ps1" -Destination $InstallDir -Force
Copy-Item -Path "$InstallerPath\stop-service.ps1" -Destination $InstallDir -Force
Copy-Item -Path "$InstallerPath\uninstall-service.ps1" -Destination $InstallDir -Force

# Create config file
Write-Host "Creating configuration..." -ForegroundColor Yellow
"APP_PORT=$Port" | Out-File -FilePath "$InstallDir\config.env" -Encoding UTF8

# Create Python virtual environment
Write-Host "Creating Python virtual environment..." -ForegroundColor Yellow
& python -m venv "$InstallDir\venv"

if (-not (Test-Path "$InstallDir\venv\Scripts\python.exe")) {
    Write-Host "ERROR: Failed to create virtual environment" -ForegroundColor Red
    exit 1
}

# Install dependencies
Write-Host "Installing Python dependencies..." -ForegroundColor Yellow
Write-Host "(This may take a few minutes)" -ForegroundColor Gray
& "$InstallDir\venv\Scripts\pip.exe" install --upgrade pip wheel --quiet
& "$InstallDir\venv\Scripts\pip.exe" install -r "$InstallDir\requirements.txt" --quiet

# Download NSSM
Write-Host "Downloading NSSM (service manager)..." -ForegroundColor Yellow
$nssmUrl = "https://nssm.cc/release/nssm-2.24.zip"
$nssmZip = "$env:TEMP\nssm.zip"
$nssmExtract = "$env:TEMP\nssm"

try {
    Invoke-WebRequest -Uri $nssmUrl -OutFile $nssmZip -UseBasicParsing
    Expand-Archive -Path $nssmZip -DestinationPath $nssmExtract -Force
    Copy-Item -Path "$nssmExtract\nssm-2.24\win64\nssm.exe" -Destination "$InstallDir\nssm.exe" -Force
    Remove-Item $nssmZip -Force
    Remove-Item $nssmExtract -Recurse -Force
}
catch {
    Write-Host "WARNING: Could not download NSSM. Service installation may fail." -ForegroundColor Yellow
}

# Create logs directory
New-Item -ItemType Directory -Path "$InstallDir\logs" -Force | Out-Null

# Install service
Write-Host "Installing Windows service..." -ForegroundColor Yellow
& "$InstallDir\install-service.ps1" -InstallDir $InstallDir -Port $Port

# Create shortcuts
Write-Host "Creating shortcuts..." -ForegroundColor Yellow

# Start Menu
$startMenuPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Auto Stretch"
New-Item -ItemType Directory -Path $startMenuPath -Force | Out-Null

$WScriptShell = New-Object -ComObject WScript.Shell

# Web Interface shortcut
$shortcut = $WScriptShell.CreateShortcut("$startMenuPath\Auto Stretch.lnk")
$shortcut.TargetPath = "http://localhost:$Port"
$shortcut.Save()

# Start Service shortcut
$shortcut = $WScriptShell.CreateShortcut("$startMenuPath\Start Service.lnk")
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$InstallDir\start-service.ps1`""
$shortcut.WorkingDirectory = $InstallDir
$shortcut.Save()

# Stop Service shortcut
$shortcut = $WScriptShell.CreateShortcut("$startMenuPath\Stop Service.lnk")
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$InstallDir\stop-service.ps1`""
$shortcut.WorkingDirectory = $InstallDir
$shortcut.Save()

# Desktop shortcut
$shortcut = $WScriptShell.CreateShortcut("$env:PUBLIC\Desktop\Auto Stretch.lnk")
$shortcut.TargetPath = "http://localhost:$Port"
$shortcut.Save()

# Write registry keys
Write-Host "Writing registry keys..." -ForegroundColor Yellow
New-Item -Path "HKLM:\Software\Auto Stretch" -Force | Out-Null
Set-ItemProperty -Path "HKLM:\Software\Auto Stretch" -Name "InstallPath" -Value $InstallDir
Set-ItemProperty -Path "HKLM:\Software\Auto Stretch" -Name "Version" -Value "1.0.0"
Set-ItemProperty -Path "HKLM:\Software\Auto Stretch" -Name "Port" -Value $Port

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Installation Directory: $InstallDir" -ForegroundColor Cyan
Write-Host "Web Interface: http://localhost:$Port" -ForegroundColor Cyan
Write-Host ""
Write-Host "The service has been installed and configured." -ForegroundColor Yellow
Write-Host ""

# Ask to start service
$response = Read-Host "Start the service now? (Y/N)"
if ($response -eq "Y" -or $response -eq "y") {
    Start-Service -Name "AutoStretch"
    Start-Sleep -Seconds 3
    Write-Host ""
    Write-Host "Service started!" -ForegroundColor Green
    Write-Host ""

    $response = Read-Host "Open web browser? (Y/N)"
    if ($response -eq "Y" -or $response -eq "y") {
        Start-Process "http://localhost:$Port"
    }
}

Write-Host ""
Write-Host "Shortcuts created:" -ForegroundColor Cyan
Write-Host "  - Start Menu: Auto Stretch" -ForegroundColor Gray
Write-Host "  - Desktop: Auto Stretch" -ForegroundColor Gray
Write-Host ""
Write-Host "Useful commands:" -ForegroundColor Cyan
Write-Host "  - Start:  Start-Service AutoStretch" -ForegroundColor Gray
Write-Host "  - Stop:   Stop-Service AutoStretch" -ForegroundColor Gray
Write-Host "  - Status: Get-Service AutoStretch" -ForegroundColor Gray
Write-Host ""

Read-Host "Press Enter to exit"
