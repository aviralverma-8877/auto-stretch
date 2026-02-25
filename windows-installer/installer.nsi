; Auto Stretch - Windows Installer Script
; Uses NSIS (Nullsoft Scriptable Install System)
; Build with: makensis installer.nsi

;--------------------------------
; Configuration

!define APP_NAME "Auto Stretch"
!define APP_VERSION "1.0.0"
!define APP_PUBLISHER "Auto Stretch Team"
!define APP_URL "https://github.com/example/auto-stretch"
!define INSTALL_DIR "$PROGRAMFILES64\AutoStretch"
!define SERVICE_NAME "AutoStretch"

;--------------------------------
; Includes

!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "x64.nsh"

;--------------------------------
; General Settings

Name "${APP_NAME}"
OutFile "AutoStretch-Setup-${APP_VERSION}.exe"
InstallDir "${INSTALL_DIR}"
InstallDirRegKey HKLM "Software\${APP_NAME}" "InstallPath"
RequestExecutionLevel admin

;--------------------------------
; Interface Settings

!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install-blue.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall-blue.ico"
!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "Open Auto Stretch in Browser"
!define MUI_FINISHPAGE_RUN_FUNCTION "OpenBrowser"

;--------------------------------
; Pages

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\README.md"
!insertmacro MUI_PAGE_DIRECTORY

; Custom page for port configuration
Page custom PortConfigPage PortConfigLeave

!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

;--------------------------------
; Languages

!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Variables

Var PortNumber
Var PythonPath
Var Dialog
Var PortInput

;--------------------------------
; Functions

Function .onInit
  ; Check if 64-bit Windows
  ${If} ${RunningX64}
    ; OK
  ${Else}
    MessageBox MB_OK|MB_ICONSTOP "This application requires 64-bit Windows."
    Abort
  ${EndIf}

  ; Set default port (Python is bundled, no need to check)
  StrCpy $PortNumber "5000"
FunctionEnd

Function PortConfigPage
  !insertmacro MUI_HEADER_TEXT "Port Configuration" "Choose the port for the web interface"

  nsDialogs::Create 1018
  Pop $Dialog

  ${If} $Dialog == error
    Abort
  ${EndIf}

  ${NSD_CreateLabel} 0 0 100% 20u "Enter the port number for the Auto Stretch web interface:"
  Pop $0

  ${NSD_CreateLabel} 0 30u 100% 10u "Default port: 5000"
  Pop $0

  ${NSD_CreateText} 0 45u 80u 12u "$PortNumber"
  Pop $PortInput

  ${NSD_CreateLabel} 0 65u 100% 30u "The web interface will be accessible at:$\nhttp://localhost:<port>$\n$\nRecommended ports: 5000, 8080, 3000"
  Pop $0

  nsDialogs::Show
FunctionEnd

Function PortConfigLeave
  ${NSD_GetText} $PortInput $PortNumber

  ; Validate port number
  ${If} $PortNumber == ""
    StrCpy $PortNumber "5000"
  ${EndIf}

  ; Check if port is numeric and in valid range
  ; (Simple validation - could be enhanced)
  IntOp $0 $PortNumber + 0
  ${If} $0 < 1
    MessageBox MB_OK|MB_ICONEXCLAMATION "Invalid port number. Using default port 5000."
    StrCpy $PortNumber "5000"
  ${EndIf}
  ${If} $0 > 65535
    MessageBox MB_OK|MB_ICONEXCLAMATION "Invalid port number. Using default port 5000."
    StrCpy $PortNumber "5000"
  ${EndIf}
FunctionEnd

;--------------------------------
; Installation Section

Section "Install"
  SetOutPath "$INSTDIR"

  ; Copy application files
  File /r "..\src\*.*"
  File "..\requirements.txt"
  File "..\README.md"

  ; Copy service management scripts
  File "install-service.ps1"
  File "uninstall-service.ps1"
  File "start-service.ps1"
  File "stop-service.ps1"

  ; Copy NSSM (Non-Sucking Service Manager)
  DetailPrint "Installing NSSM service manager..."
  IfFileExists "$EXEDIR\nssm.exe" 0 +3
    CopyFiles "$EXEDIR\nssm.exe" "$INSTDIR\nssm.exe"
    Goto nssm_done
  IfFileExists "nssm.exe" 0 nssm_missing
    File "nssm.exe"
    Goto nssm_done
  nssm_missing:
    DetailPrint "Warning: NSSM not found. Service installation may fail."
    DetailPrint "Please download NSSM from https://nssm.cc/release/nssm-2.24.zip"
    DetailPrint "Extract nssm.exe to $INSTDIR manually after installation."
  nssm_done:

  ; Copy bundled Python
  DetailPrint "Installing bundled Python..."
  SetOutPath "$INSTDIR\python"
  IfFileExists "python-embed\python.exe" 0 python_missing
    File /r "python-embed\*.*"
    Goto python_done
  python_missing:
    MessageBox MB_OK|MB_ICONSTOP "Bundled Python not found!$\n$\nThe installer was not built correctly.$\nPlease run: download-python.ps1 before building the installer."
    Abort
  python_done:

  SetOutPath "$INSTDIR"

  ; Create config file with port
  FileOpen $0 "$INSTDIR\config.env" w
  FileWrite $0 "APP_PORT=$PortNumber$\r$\n"
  FileClose $0

  ; Install pip in bundled Python
  DetailPrint "Installing pip..."
  nsExec::ExecToLog '"$INSTDIR\python\python.exe" "$INSTDIR\python\get-pip.py" --no-warn-script-location'

  ; Install dependencies
  DetailPrint "Installing Python dependencies..."
  nsExec::ExecToLog '"$INSTDIR\python\python.exe" -m pip install --upgrade pip wheel --no-warn-script-location'
  nsExec::ExecToLog '"$INSTDIR\python\python.exe" -m pip install -r "$INSTDIR\requirements.txt" --no-warn-script-location'

  ; Grant permissions to SYSTEM account (required for service)
  DetailPrint "Setting file permissions for service..."
  nsExec::ExecToLog 'icacls "$INSTDIR" /grant "NT AUTHORITY\SYSTEM:(OI)(CI)F" /T /Q'

  ; Install and configure service
  DetailPrint "Installing Windows service..."
  nsExec::ExecToLog 'powershell -ExecutionPolicy Bypass -File "$INSTDIR\install-service.ps1" "$INSTDIR" "$PortNumber"'
  Pop $0
  ${If} $0 != 0
    DetailPrint "WARNING: Service installation returned error code $0"
    DetailPrint "Check logs at: $INSTDIR\logs\service-error.log"
  ${EndIf}

  ; Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  ; Write registry keys
  WriteRegStr HKLM "Software\${APP_NAME}" "InstallPath" "$INSTDIR"
  WriteRegStr HKLM "Software\${APP_NAME}" "Version" "${APP_VERSION}"
  WriteRegStr HKLM "Software\${APP_NAME}" "Port" "$PortNumber"

  ; Add to Add/Remove Programs
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayName" "${APP_NAME}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayVersion" "${APP_VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "Publisher" "${APP_PUBLISHER}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "URLInfoAbout" "${APP_URL}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "NoRepair" 1

  ; Create Start Menu shortcuts
  CreateDirectory "$SMPROGRAMS\${APP_NAME}"
  CreateShortCut "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" "http://localhost:$PortNumber"
  CreateShortCut "$SMPROGRAMS\${APP_NAME}\Start Service.lnk" "powershell" '-ExecutionPolicy Bypass -File "$INSTDIR\start-service.ps1"'
  CreateShortCut "$SMPROGRAMS\${APP_NAME}\Stop Service.lnk" "powershell" '-ExecutionPolicy Bypass -File "$INSTDIR\stop-service.ps1"'
  CreateShortCut "$SMPROGRAMS\${APP_NAME}\Uninstall.lnk" "$INSTDIR\Uninstall.exe"

  ; Create Desktop shortcut
  CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "http://localhost:$PortNumber"

  MessageBox MB_OK "Installation complete!$\n$\nAuto Stretch is now running as a Windows service.$\n$\nAccess the web interface at:$\nhttp://localhost:$PortNumber$\n$\nNote: The service may take a few seconds to fully start."
SectionEnd

;--------------------------------
; Open Browser Function

Function OpenBrowser
  ; Wait for service to fully start
  DetailPrint "Waiting for service to start..."
  Sleep 5000

  ; Open browser
  Exec '"http://localhost:$PortNumber"'
FunctionEnd

;--------------------------------
; Uninstallation Section

Section "Uninstall"
  ; Stop and remove service
  DetailPrint "Stopping and removing service..."
  nsExec::ExecToLog 'powershell -ExecutionPolicy Bypass -File "$INSTDIR\uninstall-service.ps1"'

  ; Remove files
  RMDir /r "$INSTDIR\python"
  RMDir /r "$INSTDIR\logs"
  RMDir /r "$INSTDIR\templates"
  RMDir /r "$INSTDIR\static"
  RMDir /r "$INSTDIR\__pycache__"
  Delete "$INSTDIR\*.py"
  Delete "$INSTDIR\*.ps1"
  Delete "$INSTDIR\*.txt"
  Delete "$INSTDIR\*.md"
  Delete "$INSTDIR\*.env"
  Delete "$INSTDIR\*.exe"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"

  ; Remove shortcuts
  RMDir /r "$SMPROGRAMS\${APP_NAME}"
  Delete "$DESKTOP\${APP_NAME}.lnk"

  ; Remove registry keys
  DeleteRegKey HKLM "Software\${APP_NAME}"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"

  MessageBox MB_OK "Auto Stretch has been uninstalled."
SectionEnd
