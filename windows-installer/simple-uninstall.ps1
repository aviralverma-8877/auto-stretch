# Simple Auto Stretch Uninstaller for Windows
# Usage: Run as Administrator

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Auto Stretch - Uninstaller" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get installation directory from registry
try {
    $InstallDir = (Get-ItemProperty -Path "HKLM:\Software\Auto Stretch" -Name "InstallPath").InstallPath
    Write-Host "Found installation at: $InstallDir" -ForegroundColor Yellow
}
catch {
    Write-Host "Installation not found in registry." -ForegroundColor Yellow
    $InstallDir = Read-Host "Enter installation directory (e.g., C:\Program Files\AutoStretch)"

    if (-not (Test-Path $InstallDir)) {
        Write-Host "ERROR: Directory not found!" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Host ""
$response = Read-Host "Are you sure you want to uninstall Auto Stretch? (Y/N)"
if ($response -ne "Y" -and $response -ne "y") {
    Write-Host "Uninstallation canceled." -ForegroundColor Yellow
    exit 0
}

# Stop and remove service
Write-Host ""
Write-Host "Stopping service..." -ForegroundColor Yellow
Stop-Service -Name "AutoStretch" -Force -ErrorAction SilentlyContinue

Write-Host "Removing service..." -ForegroundColor Yellow
if (Test-Path "$InstallDir\nssm.exe") {
    & "$InstallDir\nssm.exe" remove AutoStretch confirm
}
else {
    sc.exe delete AutoStretch
}

Start-Sleep -Seconds 2

# Remove shortcuts
Write-Host "Removing shortcuts..." -ForegroundColor Yellow
$startMenuPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Auto Stretch"
if (Test-Path $startMenuPath) {
    Remove-Item -Path $startMenuPath -Recurse -Force
}

$desktopShortcut = "$env:PUBLIC\Desktop\Auto Stretch.lnk"
if (Test-Path $desktopShortcut) {
    Remove-Item -Path $desktopShortcut -Force
}

# Remove registry keys
Write-Host "Removing registry keys..." -ForegroundColor Yellow
Remove-Item -Path "HKLM:\Software\Auto Stretch" -Recurse -Force -ErrorAction SilentlyContinue

# Remove installation directory
Write-Host "Removing files..." -ForegroundColor Yellow
try {
    Remove-Item -Path $InstallDir -Recurse -Force
    Write-Host "Files removed successfully." -ForegroundColor Green
}
catch {
    Write-Host "WARNING: Some files could not be removed." -ForegroundColor Yellow
    Write-Host "You may need to delete manually: $InstallDir" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Uninstallation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Read-Host "Press Enter to exit"
