# Simple Python Download Script
$ErrorActionPreference = "Continue"

Write-Host "Downloading Python..." -ForegroundColor Cyan

$url = "https://www.python.org/ftp/python/3.12.8/python-3.12.8-embed-amd64.zip"
$zip = "python.zip"

# Download
Write-Host "Downloading from: $url"
Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing

# Extract
Write-Host "Extracting..."
Expand-Archive -Path $zip -DestinationPath "python-embed" -Force

# Enable pip
$pthFile = Get-ChildItem "python-embed\python*._pth" | Select-Object -First 1
$content = Get-Content $pthFile.FullName
$content = $content -replace '^#import site', 'import site'
Set-Content $pthFile.FullName $content

# Download get-pip
Write-Host "Downloading pip..."
Invoke-WebRequest -Uri "https://bootstrap.pypa.io/get-pip.py" -OutFile "python-embed\get-pip.py" -UseBasicParsing

# Cleanup
Remove-Item $zip -Force

Write-Host "Done! Python is in: python-embed\" -ForegroundColor Green
dir python-embed
