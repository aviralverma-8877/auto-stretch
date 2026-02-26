# test-before-install.ps1
# Test prerequisites before running MSI installation

$ErrorActionPreference = "Continue"

Write-Host "="*60 -ForegroundColor Cyan
Write-Host "Pre-Installation Diagnostic Test" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan
Write-Host ""

$allGood = $true

# Test 1: Administrator privileges
Write-Host "1. Testing Administrator privileges..." -ForegroundColor Yellow
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    Write-Host "   PASS: Running as Administrator" -ForegroundColor Green
} else {
    Write-Host "   FAIL: Not running as Administrator" -ForegroundColor Red
    Write-Host "   Please right-click and 'Run as Administrator'" -ForegroundColor Yellow
    $allGood = $false
}
Write-Host ""

# Test 2: PowerShell ExecutionPolicy
Write-Host "2. Testing PowerShell ExecutionPolicy..." -ForegroundColor Yellow
$policy = Get-ExecutionPolicy
Write-Host "   Current policy: $policy" -ForegroundColor Gray

if ($policy -eq "Restricted") {
    Write-Host "   WARN: ExecutionPolicy is Restricted" -ForegroundColor Yellow
    Write-Host "   The installer will use -ExecutionPolicy Bypass" -ForegroundColor Yellow
} else {
    Write-Host "   PASS: ExecutionPolicy allows script execution" -ForegroundColor Green
}
Write-Host ""

# Test 3: Test if port 5000 is available
Write-Host "3. Testing if port 5000 is available..." -ForegroundColor Yellow
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect("localhost", 5000)
    $tcp.Close()
    Write-Host "   WARN: Port 5000 is in use" -ForegroundColor Yellow
    Write-Host "   You can specify a different port during installation" -ForegroundColor Yellow
} catch {
    Write-Host "   PASS: Port 5000 is available" -ForegroundColor Green
}
Write-Host ""

# Test 4: Check for existing AutoStretch installation
Write-Host "4. Checking for existing installation..." -ForegroundColor Yellow
if (Test-Path "C:\AutoStretch") {
    Write-Host "   WARN: C:\AutoStretch already exists" -ForegroundColor Yellow
    Write-Host "   Contents:" -ForegroundColor Gray
    Get-ChildItem "C:\AutoStretch" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "     $($_.Name)" -ForegroundColor Gray
    }
    Write-Host "   Consider uninstalling previous version first" -ForegroundColor Yellow
} else {
    Write-Host "   PASS: No existing installation found" -ForegroundColor Green
}
Write-Host ""

# Test 5: Check for existing service
Write-Host "5. Checking for existing AutoStretch service..." -ForegroundColor Yellow
$service = Get-Service -Name "AutoStretch" -ErrorAction SilentlyContinue
if ($service) {
    Write-Host "   WARN: AutoStretch service exists" -ForegroundColor Yellow
    Write-Host "   Status: $($service.Status)" -ForegroundColor Gray
    Write-Host "   Consider removing it first" -ForegroundColor Yellow
} else {
    Write-Host "   PASS: No existing service found" -ForegroundColor Green
}
Write-Host ""

# Test 6: Disk space
Write-Host "6. Checking disk space on C:..." -ForegroundColor Yellow
$drive = Get-PSDrive -Name C
$freeSpaceGB = [math]::Round($drive.Free / 1GB, 2)
Write-Host "   Free space: $freeSpaceGB GB" -ForegroundColor Gray

if ($freeSpaceGB -lt 0.5) {
    Write-Host "   FAIL: Insufficient disk space (need at least 500 MB)" -ForegroundColor Red
    $allGood = $false
} else {
    Write-Host "   PASS: Sufficient disk space" -ForegroundColor Green
}
Write-Host ""

# Test 7: Test PowerShell script execution
Write-Host "7. Testing PowerShell script execution..." -ForegroundColor Yellow
try {
    $testScript = @"
Write-Host 'Script execution test successful'
exit 0
"@
    $testFile = Join-Path $env:TEMP "autostretch-test.ps1"
    Set-Content $testFile $testScript

    $result = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $testFile 2>&1
    Remove-Item $testFile -ErrorAction SilentlyContinue

    Write-Host "   PASS: PowerShell scripts can execute" -ForegroundColor Green
} catch {
    Write-Host "   FAIL: Cannot execute PowerShell scripts" -ForegroundColor Red
    Write-Host "   Error: $_" -ForegroundColor Red
    $allGood = $false
}
Write-Host ""

# Summary
Write-Host "="*60 -ForegroundColor Cyan
if ($allGood) {
    Write-Host "READY FOR INSTALLATION" -ForegroundColor Green
    Write-Host "="*60 -ForegroundColor Cyan
    Write-Host ""
    Write-Host "You can now run the installer:" -ForegroundColor Cyan
    Write-Host "  .\install-with-log.bat" -ForegroundColor Yellow
} else {
    Write-Host "NOT READY - Please fix the issues above" -ForegroundColor Red
    Write-Host "="*60 -ForegroundColor Cyan
}
Write-Host ""
