# Download Python Embeddable Package for bundling with installer
# This downloads the portable Python distribution from python.org

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Downloading Python Embeddable Package" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Python version to download
$pythonVersion = "3.12.8"
$pythonUrl = "https://www.python.org/ftp/python/$pythonVersion/python-$pythonVersion-embed-amd64.zip"
$pythonZip = "python-embed.zip"
$pythonDir = "python-embed"

# Check if already downloaded
if (Test-Path $pythonDir) {
    Write-Host "Python embeddable package already exists at: $pythonDir" -ForegroundColor Yellow
    $response = Read-Host "Re-download? (Y/N)"
    if ($response -ne "Y" -and $response -ne "y") {
        Write-Host "Using existing Python package" -ForegroundColor Green
        exit 0
    }
    Remove-Item -Path $pythonDir -Recurse -Force
}

if (Test-Path $pythonZip) {
    Remove-Item -Path $pythonZip -Force
}

Write-Host "Downloading Python $pythonVersion embeddable package..." -ForegroundColor Cyan
Write-Host "URL: $pythonUrl" -ForegroundColor Gray
Write-Host ""

try {
    # Download with progress
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($pythonUrl, $pythonZip)

    Write-Host "[OK] Downloaded successfully" -ForegroundColor Green

    # Get file size
    $fileSize = (Get-Item $pythonZip).Length / 1MB
    Write-Host "Size: $($fileSize.ToString('0.00')) MB" -ForegroundColor Gray
    Write-Host ""

    # Extract
    Write-Host "Extracting Python package..." -ForegroundColor Cyan
    Expand-Archive -Path $pythonZip -DestinationPath $pythonDir -Force

    Write-Host "[OK] Extracted to: $pythonDir" -ForegroundColor Green
    Write-Host ""

    # Modify python312._pth to enable pip
    Write-Host "Configuring Python for pip support..." -ForegroundColor Cyan
    $pthFile = Get-ChildItem -Path $pythonDir -Filter "python*._pth" | Select-Object -First 1

    if ($pthFile) {
        $pthContent = Get-Content $pthFile.FullName
        # Uncomment the import site line
        $pthContent = $pthContent -replace '^#import site', 'import site'
        Set-Content -Path $pthFile.FullName -Value $pthContent
        Write-Host "[OK] Enabled site packages" -ForegroundColor Green
    }

    # Download get-pip.py
    Write-Host "Downloading pip installer..." -ForegroundColor Cyan
    $getPipUrl = "https://bootstrap.pypa.io/get-pip.py"
    $getPipPath = "$pythonDir\get-pip.py"

    Invoke-WebRequest -Uri $getPipUrl -OutFile $getPipPath -UseBasicParsing
    Write-Host "[OK] Downloaded get-pip.py" -ForegroundColor Green
    Write-Host ""

    # Clean up zip
    Remove-Item -Path $pythonZip -Force

    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Python Package Ready!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Location: $pythonDir" -ForegroundColor Cyan
    Write-Host "Version: $pythonVersion" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This Python package will be bundled with the installer." -ForegroundColor Gray
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "ERROR: Failed to download Python!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please download manually:" -ForegroundColor Yellow
    Write-Host "1. Visit: $pythonUrl" -ForegroundColor Gray
    Write-Host "2. Save as: $pythonZip" -ForegroundColor Gray
    Write-Host "3. Extract to: $pythonDir" -ForegroundColor Gray
    Write-Host ""
    exit 1
}
