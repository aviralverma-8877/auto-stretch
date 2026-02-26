@echo off
echo Installing Auto Stretch with detailed logging...
echo.
echo This will create install.log in the current directory.
echo Please wait for installation to complete or fail...
echo.

msiexec /i "%~dp0output\AutoStretch-Setup-2.0.0.msi" /l*v "%~dp0install.log"

echo.
echo Installation complete (or failed).
echo.
echo Check install.log for details.
echo Press any key to open the log file...
pause >nul

notepad "%~dp0install.log"
