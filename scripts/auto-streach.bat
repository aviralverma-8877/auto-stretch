@echo off
setlocal enabledelayedexpansion

REM Ask for input file path
set /p INPUT_FILE="Enter the path to the TIF file: "

REM Check if file exists
if not exist "%INPUT_FILE%" (
    echo Error: File "%INPUT_FILE%" not found!
    pause
    exit /b 1
)

REM Extract file info
for %%F in ("%INPUT_FILE%") do (
    set "FILE_DIR=%%~dpF"
    set "FILE_NAME=%%~nF"
    set "FILE_EXT=%%~xF"
)

REM Set output filenames
set "OUTPUT_FILE=%FILE_NAME%-result.tif"
set "OUTPUT_PNG=%FILE_NAME%-result.png"
set "BASIC_FILE=%FILE_NAME%-basic.tif"

echo Processing %FILE_NAME%%FILE_EXT%...

REM Change to the file's directory
cd /d "%FILE_DIR%"

REM Create siril script for basic stretching
echo requires 1.2.0> stretch.ssf
echo load %FILE_NAME%>> stretch.ssf
echo bg>> stretch.ssf
echo autostretch>> stretch.ssf
echo savetif %FILE_NAME%-basic -astro>> stretch.ssf

REM Run siril-cli
siril-cli -d . -s stretch.ssf

REM Apply Python post-processing
python "%~dp0post_process.py" "%BASIC_FILE%" "%OUTPUT_FILE%"

REM Convert TIF to PNG
echo Converting to PNG...
python -c "from PIL import Image; img = Image.open('%OUTPUT_FILE%'); img.save('%OUTPUT_PNG%')"

echo.
echo Done! Outputs saved:
echo   - %OUTPUT_FILE%
echo   - %OUTPUT_PNG%
pause
