# setup-python.ps1
# MSI Custom Action: Configure Python environment
#
# This script:
# 1. Enables site-packages in python._pth for pip support
# 2. Installs pip using get-pip.py
# 3. Installs Python dependencies from requirements.txt
#
# Called by MSI during installation

param(
    [string]$InstallDir = "C:\AutoStretch"
)

$ErrorActionPreference = "Stop"

Write-Host "="*60
Write-Host "Auto Stretch - Python Environment Setup"
Write-Host "="*60
Write-Host ""

$pythonDir = Join-Path $InstallDir "python"
$pythonExe = Join-Path $pythonDir "python.exe"
$appDir = Join-Path $InstallDir "app"
$requirementsFile = Join-Path $appDir "requirements.txt"

# Validate paths
Write-Host "Validating installation directories..." -ForegroundColor Cyan
if (-not (Test-Path $pythonDir)) {
    Write-Error "Python directory not found: $pythonDir"
    exit 1
}

if (-not (Test-Path $pythonExe)) {
    Write-Error "Python executable not found: $pythonExe"
    exit 1
}

if (-not (Test-Path $requirementsFile)) {
    Write-Error "Requirements file not found: $requirementsFile"
    exit 1
}

Write-Host "  Python directory: $pythonDir" -ForegroundColor Green
Write-Host "  Python executable: $pythonExe" -ForegroundColor Green
Write-Host "  Requirements file: $requirementsFile" -ForegroundColor Green
Write-Host ""

# Step 1: Enable site-packages in python._pth
Write-Host "Step 1: Enabling site-packages for pip support..." -ForegroundColor Cyan

$pthFiles = Get-ChildItem -Path $pythonDir -Filter "python*._pth"
if ($pthFiles.Count -eq 0) {
    Write-Error "No python._pth file found in $pythonDir"
    exit 1
}

$pthFile = $pthFiles[0].FullName
Write-Host "  Found: $($pthFiles[0].Name)" -ForegroundColor Gray

# Read and modify ._pth file
$pthContent = Get-Content $pthFile
$modified = $false

$newContent = $pthContent | ForEach-Object {
    if ($_ -match "^#\s*import site") {
        $modified = $true
        "import site"  # Uncomment the line
    } elseif ($_ -match "^import site") {
        $modified = $true
        $_  # Already uncommented
    } else {
        $_
    }
}

# If "import site" wasn't found at all, add it
if (-not $modified) {
    $newContent += "import site"
}

# Write back to file
$newContent | Set-Content $pthFile -Encoding ASCII
Write-Host "  Site-packages enabled!" -ForegroundColor Green
Write-Host ""

# Step 2: Install pip
Write-Host "Step 2: Installing pip..." -ForegroundColor Cyan

$getPipPath = Join-Path $pythonDir "get-pip.py"

if (-not (Test-Path $getPipPath)) {
    Write-Host "  Downloading get-pip.py..." -ForegroundColor Yellow
    try {
        $getPipUrl = "https://bootstrap.pypa.io/get-pip.py"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $getPipUrl -OutFile $getPipPath
        Write-Host "  Downloaded get-pip.py" -ForegroundColor Green
    } catch {
        Write-Error "Failed to download get-pip.py: $_"
        exit 1
    }
}

# Install pip
try {
    Write-Host "  Running get-pip.py..." -ForegroundColor Gray
    & $pythonExe $getPipPath --no-warn-script-location 2>&1 | ForEach-Object {
        Write-Host "    $_" -ForegroundColor DarkGray
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Error "get-pip.py failed with exit code $LASTEXITCODE"
        exit 1
    }

    Write-Host "  Pip installed successfully!" -ForegroundColor Green
} catch {
    Write-Error "Failed to install pip: $_"
    exit 1
}

Write-Host ""

# Step 3: Upgrade pip and install wheel
Write-Host "Step 3: Upgrading pip and installing wheel..." -ForegroundColor Cyan

try {
    & $pythonExe -m pip install --upgrade pip wheel 2>&1 | ForEach-Object {
        Write-Host "  $_" -ForegroundColor DarkGray
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Pip upgrade failed (non-fatal, continuing...)"
    } else {
        Write-Host "  Pip and wheel upgraded!" -ForegroundColor Green
    }
} catch {
    Write-Warning "Failed to upgrade pip: $_ (non-fatal, continuing...)"
}

Write-Host ""

# Step 4: Install dependencies
Write-Host "Step 4: Installing Python dependencies..." -ForegroundColor Cyan
Write-Host "  This may take several minutes..." -ForegroundColor Yellow
Write-Host ""

try {
    # Install dependencies with progress output
    $startTime = Get-Date

    & $pythonExe -m pip install -r $requirementsFile --no-warn-script-location 2>&1 | ForEach-Object {
        $line = $_.ToString()
        if ($line -match "Successfully installed" -or $line -match "Requirement already satisfied") {
            Write-Host "  $line" -ForegroundColor Green
        } elseif ($line -match "ERROR" -or $line -match "FAILED") {
            Write-Host "  $line" -ForegroundColor Red
        } elseif ($line -match "Collecting|Downloading|Installing") {
            Write-Host "  $line" -ForegroundColor Gray
        }
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install dependencies (exit code: $LASTEXITCODE)"
        exit 1
    }

    $elapsed = ((Get-Date) - $startTime).TotalSeconds
    Write-Host ""
    Write-Host "  Dependencies installed successfully!" -ForegroundColor Green
    Write-Host "  Time elapsed: $([math]::Round($elapsed, 1)) seconds" -ForegroundColor Gray

} catch {
    Write-Error "Failed to install dependencies: $_"
    exit 1
}

Write-Host ""

# Step 5: Verify installation
Write-Host "Step 5: Verifying installation..." -ForegroundColor Cyan

$packagesToVerify = @("Flask", "Werkzeug", "Pillow", "numpy", "tifffile", "pywin32")

foreach ($package in $packagesToVerify) {
    $result = & $pythonExe -m pip show $package 2>&1
    if ($LASTEXITCODE -eq 0) {
        $version = ($result | Select-String "Version:").ToString().Split(":")[1].Trim()
        Write-Host "  $package : $version" -ForegroundColor Green
    } else {
        if ($package -eq "pywin32") {
            Write-Host "  $package : not installed (Windows only)" -ForegroundColor Yellow
        } else {
            Write-Warning "  $package : not found!"
        }
    }
}

Write-Host ""
Write-Host "="*60
Write-Host "Python Environment Setup Complete!" -ForegroundColor Green
Write-Host "="*60

exit 0
