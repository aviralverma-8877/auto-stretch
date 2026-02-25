# Validate PowerShell Scripts
$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Validating Windows Installer Scripts" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$scripts = @(
    "simple-install.ps1",
    "simple-uninstall.ps1",
    "install-service.ps1",
    "start-service.ps1",
    "stop-service.ps1",
    "uninstall-service.ps1"
)

$allValid = $true

foreach ($script in $scripts) {
    Write-Host "Checking $script..." -NoNewline

    if (-not (Test-Path $script)) {
        Write-Host " [NOT FOUND]" -ForegroundColor Red
        $allValid = $false
        continue
    }

    try {
        # Parse the script to check for syntax errors
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $script -Raw), [ref]$null)
        Write-Host " [OK]" -ForegroundColor Green
    }
    catch {
        Write-Host " [SYNTAX ERROR]" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        $allValid = $false
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

if ($allValid) {
    Write-Host "All scripts validated successfully!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "Some scripts have errors!" -ForegroundColor Red
    exit 1
}
