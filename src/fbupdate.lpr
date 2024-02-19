program fbupdate;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp,
  { you can add units after this }
  {$if defined(MSWINDOWS)}
  Windows, jwawinbase, Registry, fileinfo, winpeimagereader,
  {$endif}
  LazUTF8, fileutilsex, ConstsEx, IniFiles;

type

  { Tfbupdate }

  Tfbupdate = class(TCustomApplication)
  private
    // previous Firebird instance path
    FOldPath: string;

    // config file name
    FConfig: TIniFile;

    // output messages
    procedure WriteFirebirdNotInstalled;
    procedure WriteDLLFound(AFound: Boolean; APath: string = '');
    procedure WriteDLLVerInfo(APath, AVersion: string);
    procedure WriteNewVersion(AVersion: string; NeedUninstall: Boolean);
    procedure WriteUninstPath(APath, AOptions: string; AFileFound: Boolean);
    procedure WriteInstPath(APath, AOptions: string; AFileFound: Boolean);
    procedure WriteUninstError(AExeName: string);
    procedure WriteGlobalResult(Success: Boolean);

    // get the full path to the gds32.dll or fbclient.dll file. Also check for
    // their existence and return an empty string if they don't exist.
    function GetFBDLLFullPath: string;

    // uninstall previous version if needed; return False if no further
    // installation needed (new version already installed)
    function UninstallFirebird: Boolean;

    // install new version of the Firebird
    procedure InstallFirebird;
  protected
    // main action queue
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ Get the Windows\SysXXX (System32 or SysWOW64) directory path }
function GetShellSystemDir(const Win32Compat: Boolean = False): string;
begin
  Result := '';

  if Win32Compat then
  begin
    SetLength(Result, Windows.MAX_PATH);
    SetLength(Result, GetSystemWow64Directory(PChar(Result), Windows.MAX_PATH));
  end;

  // not 'else'!
  if not Win32Compat or not DirectoryExists(Result) then
  begin
    SetLength(Result, Windows.MAX_PATH);
    SetLength(Result, GetSystemDirectory(PChar(Result), Windows.MAX_PATH));
  end;

  if Result <> '' then
    Result := IncludeTrailingPathDelimiter(Result);
end;

{ Extract DLL version info.

  Adapted from: https://forum.lazarus.freepascal.org/index.php?topic=57626.0}
function GetDLLVersion(const dll_fnm: String; out ProductName, ProductVersion:
  string): Boolean;
var
  FileVerInfo: TFileVersionInfo;
begin
  FileVerInfo := nil;
  Result := False;
  ProductName := '';
  ProductVersion := '';
  FileVerInfo := TFileVersionInfo.Create(nil);
  try
    FileVerInfo.FileName := dll_fnm;
    FileVerInfo.ReadFileInfo;
    if FileVerInfo.VersionStrings.Values['InternalName'] <> '' then
    begin
      ProductName := FileVerInfo.VersionStrings.Values['ProductName'];
      ProductVersion := FileVerInfo.VersionStrings.Values['ProductVersion'];
      Result := True;
    end;
  finally
    FileVerInfo.Free;
  end;
end;

{ Compare two versions and return 1 (V1 > V2), 0 (V1 = V2), or -1 (V1 < V2).
  Version string usually has a format 'x.x', 'x.x.x', and so on.
  Compare numbers from left to right: '1.5' < '2', '1.5.7' < '1.6', etc.
  If the next part of the version string is not a number, -1 is returned:
  '1.2.3' < 'alpha', but '1.alpha' < '2.0'}
function CompareVersions(V1, V2: string): Integer;
var
  S1, S2: TStringArray;
  M, I1, I2, L, E: Integer;
begin
  if (V1 = '') or (V2 = '') then
  begin
    Result := 1;
    Exit;
  end;

  Result := 0;

  S1 := V1.Split('.');
  S2 := V2.Split('.');
  M := High(S1);
  if M < High(S2) then
    M := High(S2);

  for L := 0 to M do
  begin
    if L > High(S1) then
      Result := -1
    else if L > High(S2) then
      Result := 1
    else
    begin
      Val(S1[L], I1, E);
      if E > 0 then
        Result := 1
      else
      begin
        Val(S2[L], I2, E);
        if E > 0 then
          Result := 1
        else
          Result := I1 - I2;
      end;
    end;

    if Result <> 0 then
      Break;
  end;
end;


{ load an option list from ini/cfg file and add them into command line in the
  form:
  1) if value = '%%' then do not add it (see below)
  2) if value = '' then just /NAME
  3) if value <> '' then /NAME=value or /NAME="value" (if the value contains
     spaces or commas)

  ASubstitutions is a list of the replacements for option values. Each line of
  the list has the format RNAME=rvalue, and if value contains %RNAME% then it
  will replaced with rvalue, e.g.: if ini section contains path=%path%, and
  the ASubstitutions contains path=real_path then %path% is replaced with
  real_path. If ASubstitutions contains rvalue='%%' then the NAME will not be
  presented in the output }
function LoadInstallerOptions(AIniFile: TIniFile; ASection: string;
  ASubstitutions: TStrings = nil): string;
var
  S: string;
  TS: TStringList;
  I, J: Integer;
begin
  Result := '';
  TS := TStringList.Create;
  AIniFile.ReadSectionRaw(ASection, TS);
  for I := 0 to TS.Count - 1 do
  begin
    S := Trim(TS.ValueFromIndex[I]);

    if Assigned(ASubstitutions) then
      for J := 0 to ASubstitutions.Count - 1 do
        S := S.Replace('%' + ASubstitutions.Names[J] + '%',
          ASubstitutions.ValueFromIndex[J], [rfReplaceAll]);

    if S <> '%%' then
    begin
      S := S.Replace('%%', '', [rfReplaceAll]);

      Result := Result + ' ' + '/' + TS.Names[I];

      if S <> '' then
        if S.Contains(' ') or S.Contains(',') then
          Result := Result + '=' + S.QuotedString('"')
        else
          Result := Result + '=' + S;
    end;
  end;
  FreeAndNil(TS);
  if Result <> '' then
    Delete(Result, 1, 1);
end;

{ Tfbupdate }

constructor Tfbupdate.Create(TheOwner: TComponent);
const
  RegPathWin32 = '\SOFTWARE\Firebird Project\Firebird Server\Instances\';
  RegPathWin64 = '\SOFTWARE\WOW6432Node\Firebird Project\Firebird Server\Instances\';
  RegKey = 'DefaultInstance';
var
  S, IniPath: string;
begin
  inherited Create(TheOwner);
  StopOnException := True;
  FOldPath := '';

  // get the config file name
  if ParamCount > 0 then
  begin
    IniPath := ParamStr(1);
    S := ExtractFilePath(IniPath);
    if (S = '') or not DirectoryExists(S) then
      IniPath := ExtractFilePath(ExeName) + IniPath;
  end
  else
    IniPath := ChangeFileExt(ExeName, '.cfg');

  // load the config file
  try
    FConfig := TIniFile.Create(IniPath, [ifoStripComments, ifoStripInvalid,
      ifoStripQuotes]);
  except
    on E: Exception do
    begin
      ShowException(E);
      WriteGlobalResult(False);
      Terminate;
    end;
  end;

  // load the Firebird installation path from registry
  with TRegistry.Create do
  try
    RootKey := HKEY_LOCAL_MACHINE;
    if OpenKeyReadOnly(RegPathWin32) or OpenKeyReadOnly(RegPathWin64)
    then
    try
      try
        FOldPath := ReadString(RegKey);
      except
        FOldPath := ''
      end;
    finally
      CloseKey;
    end;
  finally
    Free;
  end;
end;

destructor Tfbupdate.Destroy;
begin
  FConfig.Free;
  inherited Destroy;
end;

procedure Tfbupdate.DoRun;
var
  ErrorMsg: string;
begin
  // quick check parameters
  ErrorMsg := CheckOptions('h', ['help']);
  if ErrorMsg <> '' then
  begin
    ShowException(Exception.Create(ErrorMsg));
    WriteGlobalResult(False);
    Terminate;
    Exit;
  end;

  // parse parameters
  if HasOption('h', 'help') then
  begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  if UninstallFirebird then
    InstallFirebird;

  // stop program loop
  Terminate;
end;

{$I writes.inc}

function Tfbupdate.GetFBDLLFullPath: string;
var
  DLLName: string;
begin
  Result := '';

  // default dll name (if no dll specified) is fbclient.dll
  DLLName := FConfig.ReadString('firebird', 'dll', SFBClientName);

  if DLLName = SGDS32Name then
    Result := GetShellSystemDir(True)
  else
    Result := FOldPath;

  if Result <> '' then
  begin
    // check for the dll existence
    Result := Result + DLLName + '.dll';
    if not FileExists(Result) then
      Result := '';
  end;
end;

function Tfbupdate.UninstallFirebird: Boolean;
var
  DLLPath, GDSName, GDSVersion, NewVersion, FBPath, Opts: string;
  NeedUninstall: Boolean;
begin
  NeedUninstall := False;
  Result := True;
  FBPath := '';

  // search for either [SysXXX]\gds32.dll or [Firebird folder]\fbclient.dll
  DLLPath := GetFBDLLFullPath;
  if DLLPath = '' then
  begin
    // the DLL not found
    WriteDLLFound(False);
    NeedUninstall := True;
  end
  else if FOldPath = '' then
  begin
    // the DLL found but the Firebird itself is not installed
    WriteDLLFound(True, DLLPath);
    WriteFirebirdNotInstalled;
    NeedUninstall := True;
  end
  else
  begin
    // extract the DLL version and compare it with the new one (from .cfg file)
    WriteDLLFound(True, DLLPath);
    if GetDLLVersion(DLLPath, GDSName, GDSVersion) then
    begin
      WriteDLLVerInfo(DLLPath, GDSName + ' ' + GDSVersion);
      NewVersion := FConfig.ReadString('firebird', 'version', '');
      NeedUninstall := CompareVersions(NewVersion, GDSVersion) > 0;
      if not NeedUninstall then
        Result := False;
      WriteNewVersion(NewVersion, NeedUninstall);
    end
    else
    begin
      WriteDLLVerInfo(DLLPath, '');
      NeedUninstall := True;
    end;
  end;

  if NeedUninstall then
  begin
    // uninstall exe
    if FOldPath <> '' then
      FBPath := IncludeTrailingPathDelimiter(FOldPath) +
        FConfig.ReadString('firebird', 'uninstaller', '');

    if (FOldPath <> '') and FileExists(FBPath) then
    begin
      // run uninstall
      Opts := LoadInstallerOptions(FConfig, 'uninstaller');

      WriteUninstPath(FBPath, Opts, True);

      if RunAndWait(FBPath, Opts) then
        ForceDeleteDirectory(FOldPath)
      else
        WriteUninstError(FBPath);
    end
    else
      WriteUninstPath(FBPath, '', False);
  end;
end;

procedure Tfbupdate.InstallFirebird;
var
  OptSubst: TStringList;
  FBPath, Opts: string;
begin
  FBPath := '';

  OptSubst := TStringList.Create;
  try
    if FOldPath = '' then
      OptSubst.Values['FbDir'] := '%%'
    else
      OptSubst.Values['FbDir'] :=
        ExtractFilePath(ExcludeTrailingPathDelimiter(FOldPath));
    Opts := LoadInstallerOptions(FConfig, 'installer', OptSubst);

    FBPath := ExpandFileName(FConfig.ReadString('firebird', 'installer', ''));

    if not FileExists(FBPath) then
      FBPath := ExtractFilePath(ExeName) + FConfig.ReadString('firebird',
        'installer', '');
  finally
    FreeAndNil(OptSubst);
  end;

  if (FBPath <> '') and FileExists(FBPath) then
  begin
    WriteInstPath(FBPath, Opts, True);

    if RunAndWait(FBPath, Opts) then
      WriteGlobalResult(True)
    else
      WriteGlobalResult(False);
  end
  else
  begin
    WriteInstPath(FBPath, Opts, False);
    WriteGlobalResult(False);
  end;
end;

var
  Application: Tfbupdate;

{$R *.res}

begin
  Application := Tfbupdate.Create(nil);
  Application.Title:='Firebird Update';
  Application.Run;
  Application.Free;
end.

