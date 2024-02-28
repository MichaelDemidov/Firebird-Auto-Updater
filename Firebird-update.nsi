;*************************************************************************;
;                                                                         ;
;                          Firebird Auto Updater                          ;
;                                                                         ;
;    A simple application for updating a client or server installation    ;
;    of the Firebird DBMS under Windows.                                  ;
;                                                                         ;
;    Usage: exename [/force] [/server]                                    ;
;      - exename is a name of the installer                               ;
;      - /force parameter makes the installer to remove the previous      ;
;        version of Firebird (if exists) and install the new one          ;
;        in its place (if the parameter is not specified, the             ;
;        installer first checks that the new version is newer than the    ;
;        previously installed one)                                        ;
;      - /server parameter makes the installer to install the server      ;
;        version of the DBMS (if it is not specified, only the client     ;
;        is installed)                                                    ;
;                                                                         ;
;    Requirements: NSIS 3.08+ with the following extensions:              ;
;    WordFunc, FileFunc                                                   ;
;                                                                         ;
;    Copyright (c) 2024, Michael Demidov                                  ;
;                                                                         ;
;    Visit my GitHub page to check for updates, report issues, etc.:      ;
;    https://github.com/MichaelDemidov                                    ;
;                                                                         ;
;    Drop me an e-mail at: michael.v.demidov@gmail.com                    ;
;                                                                         ;
;*************************************************************************;
; ===== feel free to change these values to whatever you need =====

; --- localization ---
; display name to show
!define INST_NAME "Firebird"
; interface language
!define LANGUAGE "English"
; admin rights warning
!define ADMIN_WARNING "Administrator rights required!"

; --- Firebird configuration ---
; new version to install
!define FB_VERSION "3.0.11"
; is it necessary to check for the presence of gds32.dll in the System folder?
!define CHECK_GDS32 "yes"
; installer exe name
!define INSTALLER "Firebird-3.0.11.33703_0_Win32.exe"
; uninstaller exe name
!define UNINSTALLER "unins000.exe"
; installer options: language (for installation progress bar), “silent” mode, components, etc.; $1 is the parent directory of the previous Firebird installation (e.g. C:\Program Files\Firebird)
!define CLIENT_INST_OPTIONS '/LANG=ru /DIR="$1\Firebird_3_0" /GROUP="Firebird 3.0 (Win32)" /TYPE=clientinstall /COMPONENTS=clientcomponent /TASKS=copyfbclienttosystask,copyfbclientasgds32task /SILENT'
!define SERVER_INST_OPTIONS '/LANG=ru /DIR="$1\Firebird_3_0" /GROUP="Firebird 3.0 (Win32)" /TYPE=serverinstall /COMPONENTS=servercomponent,devadmincomponent,clientcomponent /TASKS=usesuperservertask,useservicetask,autostarttask,copyfbclienttosystask,copyfbclientasgds32task,enablelegacyclientauth /SILENT'

; uninstaller options: the uninstaller runs in “silent” mode and does not require user intervention
!define UNINST_OPTIONS "/SILENT"

; =================================================================

; --- installer settings ---
RequestExecutionLevel admin
Name "${INST_NAME}"
!searchreplace NAME_VER '${FB_VERSION}' '.' '_'
OutFile "Firebird_update_${NAME_VER}.exe"
AutoCloseWindow true
SetCompressor lzma

; modern user interface
!include "MUI.nsh"
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\win-install.ico"
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_LANGUAGE "${LANGUAGE}"

!include "WordFunc.nsh"
!include "FileFunc.nsh"

Function .onInit
  UserInfo::GetAccountType
  pop $R0
  StrCmp $R0 "admin" +4
  MessageBox MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "${ADMIN_WARNING}"
  SetErrorLevel 740 ; ERROR_ELEVATION_REQUIRED
  Quit
FunctionEnd

Section "!Firebird" SecMain
  ; install it for all users
  SetShellVarContext all

; --- check the previously installed version and uninstall if needed ---
  ; $0 = full path of the previous Firebird installation WITH a trailing backslash (e.g. C:\Program Files\Firebird\Firebird_3_0\), obtained from the system registry
  ; $1 = the parent directory of $0 WITHOUT trailing backslash (e.g. C:\Program Files\Firebird)
  ; $2 = version of the previous Firebird installation (extracted from the ${DLL} library)
  ; $3 = version comparison result: 1 when the new version of Firebird is greater than the previosly installed one, 0 or 2 if not

  ; default installation path
  StrCpy $1 "$PROGRAMFILES\Firebird"

  ; load the path from the system registry
  ReadRegStr $0 HKLM "SOFTWARE\Firebird Project\Firebird Server\Instances" "DefaultInstance"

  ; previous installation not found, so just install it
  StrCmp "$0" "" install

  ; cut off the last part of the directory path (C:\Program Files\Firebird\Firebird_3_0\ --> C:\Program Files\Firebird)
  ${WordFind} "$0" "\" "-2{*" $1

  ; if "/force" option is specified, skip version check
  ${GetOptions} "$CMDLINE" "/force" $R0
  IfErrors +2 uninstall
  ClearErrors

  ; check for presence of gds32.dll, if needed
  StrCmp CHECK_GDS32 "yes" 0 +2
  IfFileExists "$SYSDIR\gds32.dll" 0 uninstall

  ; get the DLL version
  GetDllVersion /ProductVersion "$0fbclient.dll" $R0 $R1
  IfErrors uninstall
  IntOp $R2 $R0 / 0x00010000
  IntOp $R3 $R0 & 0x0000FFFF
  IntOp $R4 $R1 / 0x00010000
  IntOp $R5 $R1 & 0x0000FFFF
  StrCpy $2 "$R2.$R3.$R4.$R5"

  ; compare the versions
  ${VersionCompare} "${FB_VERSION}" "$2" "$3"
  StrCmp "$3" "1" 0 bye

  uninstall:

  ClearErrors
  ExecWait '"$0${UNINSTALLER}" ${UNINST_OPTIONS}'

  install:

  ClearErrors
  ; Firebird setup file
  SetOutPath "$TEMP"
  File /r "${INSTALLER}"

  ; update Firebird
  StrCpy $R0 '${CLIENT_INST_OPTIONS}'
  ${GetOptions} "$CMDLINE" "/server" $R1
  IfErrors +2
  StrCpy $R0 '${SERVER_INST_OPTIONS}'
  ClearErrors
  ExecWait '"$OUTDIR\${INSTALLER}" $R0'

  ;  remove the updater
  SetOutPath "$TEMP"
  Delete "$OUTDIR\${INSTALLER}"

  bye:

SectionEnd