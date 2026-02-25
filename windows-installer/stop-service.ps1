# Stop Auto Stretch Service
# Usage: powershell -ExecutionPolicy Bypass -File stop-service.ps1

$ServiceName = "AutoStretch"

Write-Host "Stopping Auto Stretch service..." -ForegroundColor Cyan

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
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if service is running
if ($service.Status -ne "Running") {
    Write-Host "Service is not running." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 0
}

# Stop service
try {
    Stop-Service -Name $ServiceName -Force
    Write-Host "Service stopped successfully!" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to stop service!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Read-Host "Press Enter to exit"
