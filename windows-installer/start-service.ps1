# Start Auto Stretch Service
# Usage: powershell -ExecutionPolicy Bypass -File start-service.ps1

$ServiceName = "AutoStretch"

Write-Host "Starting Auto Stretch service..." -ForegroundColor Cyan

# Check if running as Administrator
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if service exists
$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $service) {
    Write-Host "ERROR: Service '$ServiceName' not found!" -ForegroundColor Red
    Write-Host "Please run the installer first." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Start service
try {
    Start-Service -Name $ServiceName
    Write-Host "Service started successfully!" -ForegroundColor Green

    # Wait a moment for service to fully start
    Start-Sleep -Seconds 3

    # Get port from registry
    $port = (Get-ItemProperty -Path "HKLM:\Software\Auto Stretch" -Name "Port" -ErrorAction SilentlyContinue).Port
    if (-not $port) {
        $port = "5000"
    }

    Write-Host ""
    Write-Host "Auto Stretch is now running!" -ForegroundColor Green
    Write-Host "Access the web interface at: http://localhost:$port" -ForegroundColor Cyan
    Write-Host ""

    # Ask if user wants to open browser
    $response = Read-Host "Open web browser? (Y/N)"
    if ($response -eq "Y" -or $response -eq "y") {
        Start-Process "http://localhost:$port"
    }
}
catch {
    Write-Host "ERROR: Failed to start service!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Read-Host "Press Enter to exit"
