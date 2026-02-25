# Download NSSM for Windows Installer
# Run this before building the NSIS installer

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Downloading NSSM" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Multiple download sources (try in order)
$nssmUrls = @(
    "https://nssm.cc/release/nssm-2.24.zip",
    "https://github.com/kirillkovalenko/nssm/releases/download/2.24/nssm-2.24.zip",
    "https://nssm.cc/ci/nssm-2.24.zip"
)
$nssmZip = "$PSScriptRoot\nssm-2.24.zip"
$nssmExtract = "$PSScriptRoot\nssm-temp"
$nssmExe = "$PSScriptRoot\nssm.exe"

# Check if already downloaded
if (Test-Path $nssmExe) {
    Write-Host "NSSM already downloaded: $nssmExe" -ForegroundColor Green
    Write-Host "File size: $((Get-Item $nssmExe).Length) bytes" -ForegroundColor Gray
    Write-Host ""
    $response = Read-Host "Re-download? (Y/N)"
    if ($response -ne "Y" -and $response -ne "y") {
        Write-Host "Using existing NSSM." -ForegroundColor Yellow
        exit 0
    }
}

# Download NSSM (try multiple sources)
$downloaded = $false
foreach ($nssmUrl in $nssmUrls) {
    Write-Host "Trying: $nssmUrl..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $nssmUrl -OutFile $nssmZip -UseBasicParsing -TimeoutSec 30
        Write-Host "Download complete!" -ForegroundColor Green
        $downloaded = $true
        break
    }
    catch {
        Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Gray
    }
}

if (-not $downloaded) {
    Write-Host ""
    Write-Host "ERROR: Could not download NSSM from any source!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please download manually:" -ForegroundColor Yellow
    Write-Host "  1. Visit: https://nssm.cc/download" -ForegroundColor Gray
    Write-Host "  2. Download: nssm-2.24.zip" -ForegroundColor Gray
    Write-Host "  3. Extract: nssm-2.24\win64\nssm.exe" -ForegroundColor Gray
    Write-Host "  4. Copy to: $PSScriptRoot" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

# Extract NSSM
Write-Host "Extracting NSSM..." -ForegroundColor Yellow
try {
    Expand-Archive -Path $nssmZip -DestinationPath $nssmExtract -Force
    Copy-Item -Path "$nssmExtract\nssm-2.24\win64\nssm.exe" -Destination $nssmExe -Force
    Write-Host "Extraction complete!" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to extract NSSM!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Cleanup
Write-Host "Cleaning up..." -ForegroundColor Yellow
Remove-Item $nssmZip -Force -ErrorAction SilentlyContinue
Remove-Item $nssmExtract -Recurse -Force -ErrorAction SilentlyContinue

# Verify
if (Test-Path $nssmExe) {
    $fileSize = (Get-Item $nssmExe).Length
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "NSSM Downloaded Successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "File: $nssmExe" -ForegroundColor Cyan
    Write-Host "Size: $fileSize bytes" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "You can now build the NSIS installer:" -ForegroundColor Yellow
    Write-Host "  build-installer.bat" -ForegroundColor Gray
    Write-Host ""
}
else {
    Write-Host "ERROR: NSSM not found after extraction!" -ForegroundColor Red
    exit 1
}
