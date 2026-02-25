@echo off
REM Wrapper script to start Auto Stretch with properly quoted paths
REM NSSM calls this script, which then calls Python

cd /d "C:\Program Files\AutoStretch"
"C:\Program Files\AutoStretch\python\python.exe" "C:\Program Files\AutoStretch\app.py"
