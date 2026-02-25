# Clean Reinstall Script
# Completely removes and reinstalls the Auto Stretch service
# Run as Administrator

#Requires -RunAsAdministrator

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Auto Stretch - Clean Reinstall" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will completely remove and reinstall the service." -ForegroundColor Yellow
Write-Host ""

$InstallDir = "C:\Program Files\AutoStretch"
$ServiceName = "AutoStretch"

# Check if installation exists
if (-not (Test-Path $InstallDir)) {
    Write-Host "ERROR: Auto Stretch not found at: $InstallDir" -ForegroundColor Red
    Write-Host "Please run the installer first." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Step 1: Stopping service..." -ForegroundColor Cyan
Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

Write-Host "Step 2: Killing any running processes..." -ForegroundColor Cyan
$pythonPath = "$InstallDir\python\python.exe"
if (Test-Path $pythonPath) {
    $processes = Get-Process python -ErrorAction SilentlyContinue | Where-Object {
        $_.Path -like "$InstallDir\*"
    }
    if ($processes) {
        Write-Host "  Stopping $($processes.Count) process(es)..." -ForegroundColor Yellow
        $processes | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
    } else {
        Write-Host "  No running processes found" -ForegroundColor Gray
    }
}

Write-Host "Step 3: Removing service completely..." -ForegroundColor Cyan
if (Test-Path "$InstallDir\nssm.exe") {
    & "$InstallDir\nssm.exe" remove $ServiceName confirm 2>&1 | Out-Null
    Start-Sleep -Seconds 3
}

# Double-check with sc.exe
$serviceCheck = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($serviceCheck) {
    Write-Host "  Using sc.exe to force remove..." -ForegroundColor Yellow
    sc.exe delete $ServiceName 2>&1 | Out-Null
    Start-Sleep -Seconds 3
}

# Final check
$finalCheck = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($finalCheck) {
    Write-Host ""
    Write-Host "ERROR: Could not remove service!" -ForegroundColor Red
    Write-Host "Please reboot and run this script again." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "  [OK] Service removed" -ForegroundColor Green

Write-Host "Step 4: Clearing old logs..." -ForegroundColor Cyan
if (Test-Path "$InstallDir\logs") {
    Remove-Item "$InstallDir\logs\*" -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] Logs cleared" -ForegroundColor Green
}

Write-Host "Step 5: Setting permissions..." -ForegroundColor Cyan
icacls "$InstallDir" /grant "NT AUTHORITY\SYSTEM:(OI)(CI)F" /T /Q 2>&1 | Out-Null
icacls "$InstallDir" /grant "NETWORK SERVICE:(OI)(CI)F" /T /Q 2>&1 | Out-Null
Write-Host "  [OK] Permissions set" -ForegroundColor Green

Write-Host "Step 6: Reinstalling service..." -ForegroundColor Cyan

# Get port from config
$port = 5000
$configPath = "$InstallDir\config.env"
if (Test-Path $configPath) {
    $content = Get-Content $configPath
    foreach ($line in $content) {
        if ($line -match "APP_PORT=(\d+)") {
            $port = $matches[1]
            break
        }
    }
}

$pythonExe = "$InstallDir\python\python.exe"
$appScript = "$InstallDir\app.py"
$nssmPath = "$InstallDir\nssm.exe"

# Verify files exist
if (-not (Test-Path $pythonExe)) {
    Write-Host ""
    Write-Host "ERROR: Python not found at: $pythonExe" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

if (-not (Test-Path $appScript)) {
    Write-Host ""
    Write-Host "ERROR: app.py not found at: $appScript" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Install service
Write-Host "  Installing service with Python executable..." -ForegroundColor Gray
& "$nssmPath" install $ServiceName $pythonExe

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Failed to install service!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Configure service with proper quoting
Write-Host "  Configuring service..." -ForegroundColor Gray
& "$nssmPath" set $ServiceName AppParameters "`"$appScript`""
& "$nssmPath" set $ServiceName DisplayName "Auto Stretch - Astronomy Image Processor"
& "$nssmPath" set $ServiceName Description "Flask-based web application for processing astronomical TIFF images"
& "$nssmPath" set $ServiceName AppDirectory $InstallDir
& "$nssmPath" set $ServiceName AppEnvironmentExtra "APP_PORT=$port" "PYTHONUNBUFFERED=1"
& "$nssmPath" set $ServiceName Start SERVICE_AUTO_START
& "$nssmPath" set $ServiceName AppStdout "$InstallDir\logs\service-output.log"
& "$nssmPath" set $ServiceName AppStderr "$InstallDir\logs\service-error.log"
& "$nssmPath" set $ServiceName AppRotateFiles 1
& "$nssmPath" set $ServiceName AppRotateBytes 1048576
& "$nssmPath" set $ServiceName AppExit Default Restart
& "$nssmPath" set $ServiceName AppRestartDelay 5000

Write-Host "  [OK] Service configured" -ForegroundColor Green

Write-Host "Step 7: Starting service..." -ForegroundColor Cyan
Start-Service -Name $ServiceName -ErrorAction Stop
Start-Sleep -Seconds 5

# Check status
$service = Get-Service -Name $ServiceName

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Clean Reinstall Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Service Status: $($service.Status)" -ForegroundColor $(if ($service.Status -eq "Running") { "Green" } else { "Red" })
Write-Host "Port: $port" -ForegroundColor Cyan
Write-Host ""

if ($service.Status -eq "Running") {
    Write-Host "SUCCESS! Service is running!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Web Interface: http://localhost:$port" -ForegroundColor Cyan
    Write-Host ""

    $response = Read-Host "Open in browser? (Y/N)"
    if ($response -eq "Y" -or $response -eq "y") {
        Start-Process "http://localhost:$port"
    }
} else {
    Write-Host "WARNING: Service is not running!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Check error log:" -ForegroundColor Yellow
    Write-Host "  $InstallDir\logs\service-error.log" -ForegroundColor Gray
    Write-Host ""

    if (Test-Path "$InstallDir\logs\service-error.log") {
        Write-Host "Last 20 lines of error log:" -ForegroundColor Yellow
        Get-Content "$InstallDir\logs\service-error.log" -Tail 20 | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
    }
}

Write-Host ""
Read-Host "Press Enter to exit"
