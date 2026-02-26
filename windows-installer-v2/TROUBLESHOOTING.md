# Troubleshooting Installation Issues

## Installation Error: "A program run as part of the setup did not finish as expected"

This error means one of the PowerShell custom actions failed during installation.

### Step 1: Run Pre-Installation Diagnostics

```powershell
# Run as Administrator
cd windows-installer-v2
.\test-before-install.ps1
```

This will check:
- Administrator privileges
- PowerShell execution policy
- Port availability
- Existing installations
- Disk space

### Step 2: Install with Detailed Logging

```powershell
# Double-click this file or run:
.\install-with-log.bat
```

This creates `install.log` with detailed error information.

### Step 3: Find the Failing Step

Open `install.log` and search for these patterns:

1. **Search for "CustomAction SetupPython"** - Python environment setup
2. **Search for "CustomAction InstallService"** - Windows service installation
3. **Search for "CustomAction FinalizeInstall"** - Shortcuts and registry
4. **Search for "return value 3"** - Indicates which action failed

### Common Issues and Solutions

#### Issue 1: Python Setup Fails

**Symptoms:** Installation fails after "Configuring Python environment"

**Solution:**
```powershell
# Manually test Python setup
cd C:\AutoStretch
.\setup-python.ps1 -InstallDir "C:\AutoStretch"

# Check for errors in output
```

#### Issue 2: Service Installation Fails

**Symptoms:** Installation fails at "Installing Windows service"

**Possible causes:**
- Existing AutoStretch service
- pywin32 installation failed
- Permissions issue

**Solution:**
```powershell
# Check for existing service
Get-Service AutoStretch

# If exists, remove it
sc.exe delete AutoStretch

# Retry installation
```

#### Issue 3: Port Already in Use

**Symptoms:** Service installs but doesn't start

**Solution:**
```powershell
# Check what's using port 5000
netstat -ano | findstr :5000

# Install with different port
msiexec /i AutoStretch-Setup-2.0.0.msi PORT=8080
```

#### Issue 4: PowerShell ExecutionPolicy

**Symptoms:** Scripts won't run

**Solution:**
The installer already uses `-ExecutionPolicy Bypass`, but you can also set it system-wide:

```powershell
# As Administrator
Set-ExecutionPolicy RemoteSigned
```

### Manual Installation Steps

If the MSI continues to fail, you can install manually:

```powershell
# 1. Create directory
New-Item -ItemType Directory -Path "C:\AutoStretch" -Force

# 2. Copy Python embeddable
Copy-Item ".\build\python-embed\*" "C:\AutoStretch\python\" -Recurse

# 3. Copy application files
Copy-Item "..\src\*" "C:\AutoStretch\app\" -Recurse -Exclude "*.pyc","__pycache__"

# 4. Copy scripts
Copy-Item ".\scripts\*" "C:\AutoStretch\" -Force

# 5. Create config
Copy-Item ".\config\config.json.template" "C:\AutoStretch\app\config.json"

# 6. Run setup scripts
cd C:\AutoStretch
.\setup-python.ps1 -InstallDir "C:\AutoStretch"
.\install-service.ps1 -InstallDir "C:\AutoStretch" -Port 5000
.\finalize.ps1 -InstallDir "C:\AutoStretch" -Port 5000
```

### Checking Installation Logs

After installation (success or failure), check these locations:

```powershell
# MSI installation log (if you used install-with-log.bat)
notepad install.log

# Python setup output (search for errors)
# In install.log, search for: "CustomAction SetupPython"

# Service installation output
# In install.log, search for: "CustomAction InstallService"

# Service logs (after service is created)
Get-Content "C:\AutoStretch\logs\service.log" -Tail 50
```

### Uninstalling and Retrying

If installation partially completed:

```powershell
# 1. Uninstall via MSI (if possible)
msiexec /x AutoStretch-Setup-2.0.0.msi

# 2. Manual cleanup if needed
Stop-Service AutoStretch -ErrorAction SilentlyContinue
sc.exe delete AutoStretch
Remove-Item "C:\AutoStretch" -Recurse -Force
Remove-Item "HKLM:\SOFTWARE\AutoStretch" -Recurse -Force -ErrorAction SilentlyContinue

# 3. Retry installation
.\install-with-log.bat
```

### Getting Help

When reporting issues, please include:

1. **Output from test-before-install.ps1**
2. **Relevant sections from install.log** (search for "return value 3")
3. **Windows version**: Run `winver`
4. **PowerShell version**: Run `$PSVersionTable.PSVersion`
5. **Contents of C:\AutoStretch\logs\service.log** (if it exists)

### Testing the Service Manually

If installation completes but service doesn't work:

```powershell
# Check service status
Get-Service AutoStretch

# Try starting service manually
Start-Service AutoStretch

# View service logs
Get-Content "C:\AutoStretch\logs\service.log" -Wait

# Test service wrapper directly
cd C:\AutoStretch\app
C:\AutoStretch\python\python.exe service_wrapper.py

# Test Flask app directly (without service)
cd C:\AutoStretch\app
C:\AutoStretch\python\python.exe app.py
```

### Known Issues

1. **Windows Defender/Antivirus**
   - May block Python execution
   - Add C:\AutoStretch to exclusions

2. **Corporate Group Policies**
   - May prevent service installation
   - Contact IT administrator

3. **Insufficient Permissions**
   - Must install as Administrator
   - Service runs as Local System account

### Still Having Issues?

Please run and share the output of:

```powershell
# Diagnostic information
.\test-before-install.ps1 > diagnostic.txt

# Include this file when reporting issues
```
