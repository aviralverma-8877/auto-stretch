# finalize.ps1
# MSI Custom Action: Finalize installation
#
# This script:
# 1. Creates Start Menu shortcuts
# 2. Creates Desktop shortcut
# 3. Writes registry entries
#
# Called by MSI at the end of installation

param(
    [string]$InstallDir = "C:\AutoStretch",
    [int]$Port = 5000
)

$ErrorActionPreference = "Stop"

Write-Host "="*60
Write-Host "Auto Stretch - Installation Finalization"
Write-Host "="*60
Write-Host ""

$appUrl = "http://localhost:$Port"

# Step 1: Create Start Menu shortcuts
Write-Host "Creating Start Menu shortcuts..." -ForegroundColor Cyan

try {
    $startMenuPath = Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs\Auto Stretch"

    # Create Start Menu folder
    if (-not (Test-Path $startMenuPath)) {
        New-Item -ItemType Directory -Path $startMenuPath -Force | Out-Null
    }

    $shell = New-Object -ComObject WScript.Shell

    # Application shortcut
    $shortcut = $shell.CreateShortcut((Join-Path $startMenuPath "Auto Stretch.lnk"))
    $shortcut.TargetPath = $appUrl
    $shortcut.Description = "Open Auto Stretch Web Interface"
    $shortcut.Save()

    Write-Host "  Created: Auto Stretch.lnk" -ForegroundColor Green

    # Uninstall shortcut (points to Add/Remove Programs)
    $uninstallPath = "ms-settings:appsfeatures"
    $shortcut = $shell.CreateShortcut((Join-Path $startMenuPath "Uninstall Auto Stretch.lnk"))
    $shortcut.TargetPath = $uninstallPath
    $shortcut.Description = "Uninstall Auto Stretch"
    $shortcut.Save()

    Write-Host "  Created: Uninstall Auto Stretch.lnk" -ForegroundColor Green

} catch {
    Write-Warning "Failed to create Start Menu shortcuts: $_"
}

Write-Host ""

# Step 2: Create Desktop shortcut
Write-Host "Creating Desktop shortcut..." -ForegroundColor Cyan

try {
    $desktopPath = [Environment]::GetFolderPath("CommonDesktopDirectory")
    $shell = New-Object -ComObject WScript.Shell

    $shortcut = $shell.CreateShortcut((Join-Path $desktopPath "Auto Stretch.lnk"))
    $shortcut.TargetPath = $appUrl
    $shortcut.Description = "Open Auto Stretch Web Interface"
    $shortcut.Save()

    Write-Host "  Created: Desktop\Auto Stretch.lnk" -ForegroundColor Green

} catch {
    Write-Warning "Failed to create Desktop shortcut: $_"
}

Write-Host ""

# Step 3: Write registry entries
Write-Host "Writing registry entries..." -ForegroundColor Cyan

try {
    $regPath = "HKLM:\SOFTWARE\AutoStretch"

    # Create registry key
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }

    # Write values
    Set-ItemProperty -Path $regPath -Name "InstallPath" -Value $InstallDir -Type String
    Set-ItemProperty -Path $regPath -Name "Version" -Value "2.0.0" -Type String
    Set-ItemProperty -Path $regPath -Name "Port" -Value $Port -Type DWord

    Write-Host "  Registry key: HKLM\SOFTWARE\AutoStretch" -ForegroundColor Green
    Write-Host "    InstallPath = $InstallDir" -ForegroundColor Gray
    Write-Host "    Version = 2.0.0" -ForegroundColor Gray
    Write-Host "    Port = $Port" -ForegroundColor Gray

} catch {
    Write-Warning "Failed to write registry entries: $_"
}

Write-Host ""
Write-Host "="*60
Write-Host "Installation Finalization Complete!" -ForegroundColor Green
Write-Host "="*60
Write-Host ""
Write-Host "Auto Stretch is now installed and running!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Access the web interface at: $appUrl" -ForegroundColor Yellow
Write-Host ""

exit 0
