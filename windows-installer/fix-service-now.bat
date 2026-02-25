@echo off
REM Quick Fix for Service Path Issue
REM Run as Administrator

echo ==========================================
echo Fixing Auto Stretch Service Path
echo ==========================================
echo.

cd "C:\Program Files\AutoStretch"

echo Stopping service...
nssm.exe stop AutoStretch
timeout /t 3 /nobreak >nul

echo Fixing path configuration...
nssm.exe set AutoStretch AppParameters """C:\Program Files\AutoStretch\app.py"""

echo Starting service...
nssm.exe start AutoStretch
timeout /t 5 /nobreak >nul

echo.
echo ==========================================
echo Checking service status...
echo ==========================================
sc query AutoStretch
echo.

echo.
echo Service should now be running!
echo Open: http://localhost:5000
echo.

pause
