@echo off
REM Simple batch file fix for NSSM quoting
REM Run as Administrator

echo Fixing NSSM AppParameters...
cd "C:\Program Files\AutoStretch"

REM Stop service
echo Stopping service...
nssm.exe stop AutoStretch
timeout /t 3 /nobreak >nul

REM Set with proper quoting - batch file style
echo Setting AppParameters with quotes...
nssm.exe set AutoStretch AppParameters ^"C:\Program Files\AutoStretch\app.py^"

REM Verify
echo.
echo Verifying configuration...
nssm.exe get AutoStretch AppParameters

REM Start service
echo.
echo Starting service...
nssm.exe start AutoStretch
timeout /t 5 /nobreak >nul

REM Check status
echo.
sc query AutoStretch

echo.
echo If service is RUNNING, open: http://localhost:5000
echo.
pause
