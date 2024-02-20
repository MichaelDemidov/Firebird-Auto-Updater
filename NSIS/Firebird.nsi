;General
  ;Name and file

  !include "MUI.nsh"

  RequestExecutionLevel admin
  Name "Firebird install/update"
  OutFile "Firebird_setup.exe"
  AutoCloseWindow true

  !define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\win-install.ico"
  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_LANGUAGE "English"

Section "!Firebird update" SecMain
  ; install it for all users
  SetShellVarContext all

  ; pack the update files
  SetOutPath "$TEMP\Firebird"
  File /r /x *.md "Firebird\*.*"

  ; start Firebird install/update
  ExecWait '"$OUTDIR\fbupdate.exe"'

  ;  remove the updater
  SetOutPath "$TEMP"
  RMDir /r "$TEMP\Firebird"
SectionEnd