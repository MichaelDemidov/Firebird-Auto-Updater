unit fileutilsex;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

{ silently delete the directory/folder; accepts fully qualified name of
  the directory being deleted }
procedure ForceDeleteDirectory(DirName: string);

function RunAndWait(AExePath: string; AParams: string = ''): Boolean;

implementation

uses
  ShellAPI, Process;

{ from: https://stackoverflow.com/questions/213392/what-is-the-win32-api-function-to-use-to-delete-a-folder }
procedure ForceDeleteDirectory(DirName: string);
var
  Sh: TSHFILEOPSTRUCT;
begin
  DirName := IncludeTrailingPathDelimiter(DirName);

  with Sh do
  begin
    Wnd := 0;
    wFunc := FO_DELETE;
    pFrom := PChar(DirName);
    pTo := nil;
    fFlags := FOF_NOCONFIRMATION or FOF_NOERRORUI or FOF_SILENT;
    fAnyOperationsAborted := False;
    hNameMappings := nil;
    lpszProgressTitle := nil;
  end;
  SHFileOperation(Sh);
end;

function RunAndWait(AExePath: string; AParams: string = ''): Boolean;
var
  Proc: TProcess;
begin
  Result := False;
  Proc := TProcess.Create(nil);
  try
    Proc.Options := [poWaitOnExit];
    if AParams <> '' then
    begin
      if AExePath.Contains(' ') and not AExePath.Contains('"') then
        AExePath := '"' + AExePath + '"';
      Proc.CommandLine := AExePath + ' ' + AParams
    end
    else
      Proc.Executable := AExePath;
    Proc.Execute;
    FreeAndNil(Proc);
  except
    Result := False;
    FreeAndNil(Proc);
  end;

  Result := True;
end;

end.

