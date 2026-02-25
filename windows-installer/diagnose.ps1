# Diagnostic Script for Service Issues
# Run as Administrator

#Requires -RunAsAdministrator

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Auto Stretch - Diagnostic Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$InstallDir = "C:\Program Files\AutoStretch"

# Check 1: Does installation directory exist?
Write-Host "[1] Checking installation directory..." -ForegroundColor Yellow
if (Test-Path $InstallDir) {
    Write-Host "    [OK] Directory exists: $InstallDir" -ForegroundColor Green
} else {
    Write-Host "    [FAIL] Directory not found: $InstallDir" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check 2: Does Python executable exist?
Write-Host "[2] Checking Python executable..." -ForegroundColor Yellow
$pythonExe = "$InstallDir\venv\Scripts\python.exe"
if (Test-Path $pythonExe) {
    Write-Host "    [OK] Python found: $pythonExe" -ForegroundColor Green

    # Try to get file info
    $fileInfo = Get-Item $pythonExe
    Write-Host "    Size: $($fileInfo.Length) bytes" -ForegroundColor Gray
} else {
    Write-Host "    [FAIL] Python not found: $pythonExe" -ForegroundColor Red
    Write-Host "    Virtual environment was not created properly" -ForegroundColor Yellow
}

# Check 3: Does app.py exist?
Write-Host "[3] Checking app.py..." -ForegroundColor Yellow
$appScript = "$InstallDir\app.py"
if (Test-Path $appScript) {
    Write-Host "    [OK] App script found: $appScript" -ForegroundColor Green
} else {
    Write-Host "    [FAIL] App script not found: $appScript" -ForegroundColor Red
}

# Check 4: Check permissions
Write-Host "[4] Checking file permissions..." -ForegroundColor Yellow
try {
    $acl = Get-Acl $InstallDir
    $systemAccess = $acl.Access | Where-Object { $_.IdentityReference -match "SYSTEM" }

    if ($systemAccess) {
        Write-Host "    [OK] SYSTEM has access:" -ForegroundColor Green
        foreach ($access in $systemAccess) {
            Write-Host "        $($access.FileSystemRights) - $($access.AccessControlType)" -ForegroundColor Gray
        }
    } else {
        Write-Host "    [FAIL] SYSTEM account has no permissions!" -ForegroundColor Red
    }
} catch {
    Write-Host "    [WARN] Could not check permissions: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Check 5: Try to run Python as current user
Write-Host "[5] Testing Python execution (as current user)..." -ForegroundColor Yellow
if (Test-Path $pythonExe) {
    try {
        $output = & $pythonExe --version 2>&1
        Write-Host "    [OK] Python runs: $output" -ForegroundColor Green
    } catch {
        Write-Host "    [FAIL] Cannot run Python: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "    [SKIP] Python not found" -ForegroundColor Gray
}

# Check 6: Check NSSM service configuration
Write-Host "[6] Checking NSSM service configuration..." -ForegroundColor Yellow
if (Test-Path "$InstallDir\nssm.exe") {
    $app = & "$InstallDir\nssm.exe" get AutoStretch Application 2>&1
    $params = & "$InstallDir\nssm.exe" get AutoStretch AppParameters 2>&1
    $dir = & "$InstallDir\nssm.exe" get AutoStretch AppDirectory 2>&1

    Write-Host "    Application: $app" -ForegroundColor Gray
    Write-Host "    AppParameters: $params" -ForegroundColor Gray
    Write-Host "    AppDirectory: $dir" -ForegroundColor Gray
} else {
    Write-Host "    [WARN] NSSM not found" -ForegroundColor Yellow
}

# Check 7: Test running Python as SYSTEM account
Write-Host "[7] Testing Python execution as SYSTEM account..." -ForegroundColor Yellow
Write-Host "    This will use PsExec to run as SYSTEM" -ForegroundColor Gray

# Check if PsExec is available
$psexecPath = "C:\Windows\System32\psexec.exe"
if (-not (Test-Path $psexecPath)) {
    Write-Host "    [SKIP] PsExec not available (download from sysinternals)" -ForegroundColor Yellow
    Write-Host "    Download: https://live.sysinternals.com/psexec.exe" -ForegroundColor Gray
} else {
    Write-Host "    Attempting to run Python as SYSTEM..." -ForegroundColor Gray
    try {
        $result = & $psexecPath -s -accepteula $pythonExe --version 2>&1
        Write-Host "    [OK] Python works as SYSTEM: $result" -ForegroundColor Green
    } catch {
        Write-Host "    [FAIL] Python cannot run as SYSTEM!" -ForegroundColor Red
        Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    This is likely the issue - security software may be blocking it" -ForegroundColor Yellow
    }
}

# Check 8: Security software
Write-Host "[8] Checking for security software..." -ForegroundColor Yellow
$securitySoftware = @(
    "Avecto*",
    "Defendpoint*",
    "McAfee*",
    "Symantec*",
    "Kaspersky*",
    "Sophos*"
)

$found = $false
foreach ($sw in $securitySoftware) {
    $processes = Get-Process -Name $sw -ErrorAction SilentlyContinue
    if ($processes) {
        Write-Host "    [FOUND] Security software: $($processes[0].ProcessName)" -ForegroundColor Yellow
        $found = $true
    }
}

if (-not $found) {
    Write-Host "    [OK] No known security software detected" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Diagnosis Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Recommendations
Write-Host "RECOMMENDATIONS:" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $pythonExe)) {
    Write-Host "1. Virtual environment missing - reinstall or recreate venv:" -ForegroundColor Yellow
    Write-Host "   cd `"$InstallDir`"" -ForegroundColor Gray
    Write-Host "   python -m venv venv" -ForegroundColor Gray
    Write-Host ""
}

if ($found) {
    Write-Host "2. Security software detected - may need to whitelist:" -ForegroundColor Yellow
    Write-Host "   - $pythonExe" -ForegroundColor Gray
    Write-Host "   - $appScript" -ForegroundColor Gray
    Write-Host "   Contact your IT admin to add these to allowed list" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "3. Try alternative: Run as Network Service instead of SYSTEM:" -ForegroundColor Yellow
Write-Host "   Run: fix-permissions-networkservice.ps1" -ForegroundColor Gray
Write-Host ""

Read-Host "Press Enter to exit"
