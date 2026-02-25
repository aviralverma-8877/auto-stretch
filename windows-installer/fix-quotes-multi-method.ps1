# Try Multiple Methods to Fix NSSM Quoting
#Requires -RunAsAdministrator

$InstallDir = "C:\Program Files\AutoStretch"
$appPath = "$InstallDir\app.py"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Trying Multiple Methods to Fix Quoting" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Stop service
Write-Host "Stopping service..." -ForegroundColor Yellow
Stop-Service -Name AutoStretch -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3

Write-Host ""
Write-Host "Method 1: Using PowerShell array..." -ForegroundColor Cyan
try {
    & "$InstallDir\nssm.exe" set AutoStretch AppParameters "`"$appPath`""
    $result1 = & "$InstallDir\nssm.exe" get AutoStretch AppParameters
    Write-Host "  Result: $result1" -ForegroundColor Gray
} catch {
    Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Method 2: Using cmd /c..." -ForegroundColor Cyan
try {
    cmd /c "`"$InstallDir\nssm.exe`" set AutoStretch AppParameters `"`"$appPath`"`""
    $result2 = & "$InstallDir\nssm.exe" get AutoStretch AppParameters
    Write-Host "  Result: $result2" -ForegroundColor Gray
} catch {
    Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Method 3: Using Start-Process..." -ForegroundColor Cyan
try {
    Start-Process -FilePath "$InstallDir\nssm.exe" -ArgumentList "set", "AutoStretch", "AppParameters", "`"$appPath`"" -Wait -NoNewWindow
    $result3 = & "$InstallDir\nssm.exe" get AutoStretch AppParameters
    Write-Host "  Result: $result3" -ForegroundColor Gray
} catch {
    Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Method 4: Using escaped backslash..." -ForegroundColor Cyan
try {
    & "$InstallDir\nssm.exe" set AutoStretch AppParameters "\`"$appPath\`""
    $result4 = & "$InstallDir\nssm.exe" get AutoStretch AppParameters
    Write-Host "  Result: $result4" -ForegroundColor Gray
} catch {
    Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Current Configuration:" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
$finalResult = & "$InstallDir\nssm.exe" get AutoStretch AppParameters
Write-Host $finalResult -ForegroundColor White

Write-Host ""
Write-Host "Starting service to test..." -ForegroundColor Yellow
Start-Service -Name AutoStretch -ErrorAction SilentlyContinue
Start-Sleep -Seconds 5

$service = Get-Service -Name AutoStretch
Write-Host "Service Status: $($service.Status)" -ForegroundColor $(if ($service.Status -eq "Running") { "Green" } else { "Red" })

if ($service.Status -ne "Running") {
    Write-Host ""
    Write-Host "Checking error log..." -ForegroundColor Yellow
    $errorLog = "$InstallDir\logs\service-error.log"
    if (Test-Path $errorLog) {
        Get-Content $errorLog -Tail 5 | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Red
        }
    }
}

Write-Host ""
Read-Host "Press Enter to exit"
