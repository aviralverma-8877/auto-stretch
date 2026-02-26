# install-service.ps1
# MSI Custom Action: Install Windows Service
#
# This script:
# 1. Runs pywin32 post-install configuration
# 2. Installs the Auto Stretch Windows service using the native Python service wrapper
# 3. Configures service to auto-start
# 4. Sets service recovery options
# 5. Starts the service
#
# Called by MSI during installation (must run with elevated privileges)

param(
    [string]$InstallDir = "C:\AutoStretch",
    [int]$Port = 5000
)

$ErrorActionPreference = "Stop"

Write-Host "="*60
Write-Host "Auto Stretch - Windows Service Installation"
Write-Host "="*60
Write-Host ""

# Validate administrator privileges
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator"
    exit 1
}

$pythonExe = Join-Path $InstallDir "python\python.exe"
$appDir = Join-Path $InstallDir "app"
$serviceScript = Join-Path $appDir "service_wrapper.py"
$configFile = Join-Path $appDir "config.json"
$logsDir = Join-Path $InstallDir "logs"
$serviceName = "AutoStretch"

# Validate paths
Write-Host "Validating installation..." -ForegroundColor Cyan
if (-not (Test-Path $pythonExe)) {
    Write-Error "Python executable not found: $pythonExe"
    exit 1
}

if (-not (Test-Path $serviceScript)) {
    Write-Error "Service wrapper not found: $serviceScript"
    exit 1
}

Write-Host "  Python: $pythonExe" -ForegroundColor Green
Write-Host "  Service script: $serviceScript" -ForegroundColor Green
Write-Host "  Port: $Port" -ForegroundColor Green
Write-Host ""

# Create logs directory
if (-not (Test-Path $logsDir)) {
    Write-Host "Creating logs directory..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
    Write-Host "  Created: $logsDir" -ForegroundColor Green
    Write-Host ""
}

# Step 1: Run pywin32 post-install script
Write-Host "Step 1: Configuring pywin32..." -ForegroundColor Cyan

try {
    # Find the pywin32_postinstall.py script
    $scriptsDir = Join-Path $InstallDir "python\Scripts"
    $postInstallScript = Join-Path $scriptsDir "pywin32_postinstall.py"

    if (Test-Path $postInstallScript) {
        Write-Host "  Running pywin32_postinstall.py..." -ForegroundColor Gray
        & $pythonExe $postInstallScript -install -silent 2>&1 | ForEach-Object {
            Write-Host "    $_" -ForegroundColor DarkGray
        }

        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
            Write-Host "  pywin32 configured successfully!" -ForegroundColor Green
        } else {
            Write-Warning "pywin32_postinstall.py returned exit code $LASTEXITCODE (continuing...)"
        }
    } else {
        Write-Warning "pywin32_postinstall.py not found at $postInstallScript (skipping...)"
    }
} catch {
    Write-Warning "Failed to run pywin32_postinstall.py: $_ (continuing...)"
}

Write-Host ""

# Step 2: Create/update configuration file
Write-Host "Step 2: Creating configuration file..." -ForegroundColor Cyan

$config = @{
    version = "2.0.0"
    port = $Port
    debug = $false
    max_upload_mb = 500
    log_level = "INFO"
    temp_dir = $null
    paths = @{
        base = $InstallDir
        app = $appDir
        python = (Join-Path $InstallDir "python")
        logs = $logsDir
    }
}

try {
    $config | ConvertTo-Json -Depth 10 | Set-Content $configFile -Encoding UTF8
    Write-Host "  Configuration saved: $configFile" -ForegroundColor Green
    Write-Host "  Port configured: $Port" -ForegroundColor Green
} catch {
    Write-Error "Failed to create configuration file: $_"
    exit 1
}

Write-Host ""

# Step 3: Remove existing service if present
Write-Host "Step 3: Checking for existing service..." -ForegroundColor Cyan

$existingService = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($existingService) {
    Write-Host "  Existing service found. Removing..." -ForegroundColor Yellow

    # Stop service if running
    if ($existingService.Status -eq "Running") {
        Write-Host "  Stopping service..." -ForegroundColor Gray
        Stop-Service -Name $serviceName -Force
        Start-Sleep -Seconds 2
    }

    # Remove service
    try {
        & $pythonExe $serviceScript remove 2>&1 | Out-Null
        Start-Sleep -Seconds 1
        Write-Host "  Existing service removed" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to remove existing service: $_"
        # Try sc.exe as fallback
        & sc.exe delete $serviceName 2>&1 | Out-Null
        Start-Sleep -Seconds 1
    }
} else {
    Write-Host "  No existing service found" -ForegroundColor Gray
}

Write-Host ""

# Step 4: Install new service
Write-Host "Step 4: Installing Windows service..." -ForegroundColor Cyan

try {
    # Install service
    Write-Host "  Registering service..." -ForegroundColor Gray
    & $pythonExe $serviceScript install 2>&1 | ForEach-Object {
        $line = $_.ToString()
        if ($line -match "installed|created|success") {
            Write-Host "    $line" -ForegroundColor Green
        } elseif ($line -match "error|failed") {
            Write-Host "    $line" -ForegroundColor Red
        } else {
            Write-Host "    $line" -ForegroundColor DarkGray
        }
    }

    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
        Write-Error "Service installation failed with exit code $LASTEXITCODE"
        exit 1
    }

    Write-Host "  Service installed successfully!" -ForegroundColor Green
} catch {
    Write-Error "Failed to install service: $_"
    exit 1
}

Write-Host ""

# Step 5: Configure service to auto-start
Write-Host "Step 5: Configuring service startup..." -ForegroundColor Cyan

try {
    & $pythonExe $serviceScript update --startup auto 2>&1 | Out-Null

    # Alternative: use sc.exe to set auto-start
    & sc.exe config $serviceName start= auto 2>&1 | Out-Null

    Write-Host "  Service set to automatic startup" -ForegroundColor Green
} catch {
    Write-Warning "Failed to set service startup type: $_"
}

Write-Host ""

# Step 6: Set file permissions for Local System account
Write-Host "Step 6: Setting file permissions..." -ForegroundColor Cyan

try {
    # Grant full control to SYSTEM account
    icacls $InstallDir /grant "NT AUTHORITY\SYSTEM:(OI)(CI)F" /T /Q 2>&1 | Out-Null

    Write-Host "  Permissions set for SYSTEM account" -ForegroundColor Green
} catch {
    Write-Warning "Failed to set permissions: $_"
}

Write-Host ""

# Step 7: Configure service recovery options
Write-Host "Step 7: Configuring service recovery..." -ForegroundColor Cyan

try {
    # Set service to restart on failure (after 5s, 10s, 30s)
    & sc.exe failure $serviceName reset= 86400 actions= restart/5000/restart/10000/restart/30000 2>&1 | Out-Null

    Write-Host "  Service recovery configured (auto-restart on failure)" -ForegroundColor Green
} catch {
    Write-Warning "Failed to configure service recovery: $_"
}

Write-Host ""

# Step 8: Start the service
Write-Host "Step 8: Starting service..." -ForegroundColor Cyan

try {
    & $pythonExe $serviceScript start 2>&1 | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }

    # Wait for service to start
    Start-Sleep -Seconds 3

    # Verify service is running
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

    if ($service -and $service.Status -eq "Running") {
        Write-Host "  Service started successfully!" -ForegroundColor Green
        Write-Host "  Status: $($service.Status)" -ForegroundColor Green
        Write-Host "  Web interface: http://localhost:$Port" -ForegroundColor Cyan
    } else {
        Write-Warning "Service installed but not running. Status: $($service.Status)"
        Write-Warning "Check logs at: $logsDir\service.log"
        Write-Host ""
        Write-Host "You can start the service manually with:" -ForegroundColor Yellow
        Write-Host "  Start-Service -Name $serviceName" -ForegroundColor Yellow
    }
} catch {
    Write-Warning "Failed to start service: $_"
    Write-Warning "Check logs at: $logsDir\service.log"
}

Write-Host ""
Write-Host "="*60
Write-Host "Service Installation Complete!" -ForegroundColor Green
Write-Host "="*60
Write-Host ""
Write-Host "Service Name: $serviceName" -ForegroundColor Cyan
Write-Host "Web Interface: http://localhost:$Port" -ForegroundColor Cyan
Write-Host "Logs: $logsDir\service.log" -ForegroundColor Cyan
Write-Host ""

exit 0
