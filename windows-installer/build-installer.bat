@echo off
REM Build Windows Installer for Auto Stretch
REM Requires NSIS (Nullsoft Scriptable Install System)

echo ==========================================
echo Building Auto Stretch Windows Installer
echo ==========================================
echo.

REM Check if NSIS is installed
where makensis >nul 2>&1
if errorlevel 1 (
    echo ERROR: NSIS not found!
    echo.
    echo Please install NSIS from: https://nsis.sourceforge.io/Download
    echo.
    echo After installation, add NSIS to PATH or run this script from NSIS directory.
    pause
    exit /b 1
)

REM Check if source files exist
if not exist "..\src\app.py" (
    echo ERROR: Source files not found!
    echo Please ensure you're running this from the windows-installer directory.
    pause
    exit /b 1
)

REM Check if NSSM exists
if not exist "nssm.exe" goto check_nssm_missing
goto nssm_present

:check_nssm_missing
echo.
echo WARNING: nssm.exe not found!
echo.
echo NSSM is required for Windows service management.
echo.
echo Option 1: Download automatically
echo   powershell -ExecutionPolicy Bypass -File download-nssm.ps1
echo.
echo Option 2: Download manually
echo   1. Visit: https://nssm.cc/download
echo   2. Download: nssm-2.24.zip
echo   3. Extract: nssm-2.24\win64\nssm.exe
echo   4. Copy to: %cd%
echo.
choice /C YN /M "Try to download NSSM automatically now"
if errorlevel 2 goto nssm_present

echo.
echo Downloading NSSM...
powershell -ExecutionPolicy Bypass -File download-nssm.ps1
if errorlevel 1 (
    echo.
    echo Automatic download failed. Please download manually.
    echo You can still build the installer, but you'll need to add nssm.exe manually after installation.
    echo.
    pause
)

:nssm_present

REM Build installer
echo Building installer...
makensis installer.nsi

if errorlevel 1 (
    echo.
    echo ERROR: Build failed!
    pause
    exit /b 1
)

echo.
echo ==========================================
echo Build Complete!
echo ==========================================
echo.

REM Find the generated installer
for %%f in (AutoStretch-Setup-*.exe) do (
    echo Installer created: %%f
    echo Size: %%~zf bytes
    echo.
)

echo To install:
echo   1. Run the installer as Administrator
echo   2. Follow the installation wizard
echo   3. Choose a port for the web interface
echo   4. The service will be installed and started automatically
echo.

pause
