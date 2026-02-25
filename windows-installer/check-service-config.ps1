# Check Service Configuration
# Diagnostic script to see exactly what NSSM has configured

$InstallDir = "C:\Program Files\AutoStretch"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Auto Stretch - Service Configuration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path "$InstallDir\nssm.exe")) {
    Write-Host "ERROR: NSSM not found!" -ForegroundColor Red
    exit 1
}

Write-Host "Current NSSM Configuration:" -ForegroundColor Yellow
Write-Host ""

$items = @(
    "Application",
    "AppParameters",
    "AppDirectory",
    "AppEnvironmentExtra",
    "Start",
    "AppStdout",
    "AppStderr"
)

foreach ($item in $items) {
    $value = & "$InstallDir\nssm.exe" get AutoStretch $item 2>&1
    Write-Host "${item}:" -ForegroundColor Cyan
    Write-Host "  $value" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Service Status:" -ForegroundColor Yellow
Write-Host ""

$service = Get-Service -Name AutoStretch -ErrorAction SilentlyContinue
if ($service) {
    Write-Host "  Status: $($service.Status)" -ForegroundColor $(if ($service.Status -eq "Running") { "Green" } else { "Red" })
} else {
    Write-Host "  Service not found!" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Error Log (last 20 lines):" -ForegroundColor Yellow
Write-Host ""

$errorLog = "$InstallDir\logs\service-error.log"
if (Test-Path $errorLog) {
    Get-Content $errorLog -Tail 20 | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }
} else {
    Write-Host "  No error log found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Output Log (last 20 lines):" -ForegroundColor Yellow
Write-Host ""

$outputLog = "$InstallDir\logs\service-output.log"
if (Test-Path $outputLog) {
    Get-Content $outputLog -Tail 20 | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }
} else {
    Write-Host "  No output log found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Python manually:" -ForegroundColor Yellow
Write-Host ""

$pythonExe = "$InstallDir\python\python.exe"
$appScript = "$InstallDir\app.py"

Write-Host "Command: $pythonExe `"$appScript`"" -ForegroundColor Gray
Write-Host ""

try {
    $env:APP_PORT = "5000"
    $output = & $pythonExe $appScript 2>&1
    Write-Host "Python output:" -ForegroundColor Green
    $output | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }
} catch {
    Write-Host "Error running Python:" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Gray
}

Write-Host ""
Read-Host "Press Enter to exit"
