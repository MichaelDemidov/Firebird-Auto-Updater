procedure Tfbupdate.WriteHelp;
begin
  writeln(Format(SHelpMessage, [ExeName, ChangeFileExt(ExeName, '.cfg')]));
end;

procedure Tfbupdate.WriteDLLFound(AFound: Boolean; APath: string = '');
begin
  if AFound then
    writeln(Format(SGDS32Found, [APath]))
  else
    writeln(SNoGDS32);
end;

procedure Tfbupdate.WriteNewVersion(AVersion: string; NeedUninstall: Boolean);
begin
  if NeedUninstall then
    writeln(Format(SNewVersionUpdate, [AVersion]))
  else
    writeln(Format(SNewVersionNoUpdate, [AVersion]));
end;

procedure Tfbupdate.WriteDLLVerInfo(APath, AVersion: string);
begin
  if AVersion = '' then // no info
    writeln(Format(SGDS32InfoError, [APath]))
  else
    writeln(Format(SGDS32InfoSuccess, [APath, AVersion]));
end;

procedure Tfbupdate.WriteUninstPath(APath, AOptions: string; AFileFound:
  Boolean);
begin
  if APath = '' then
    writeln(SUninstallNoFileSpecified)
  else if AFileFound then
    writeln(Format(SUninstall, [APath, AOptions]))
  else
    writeln(Format(SUninstallNotFound, [APath]));
end;

procedure Tfbupdate.WriteUninstError(AExeName: string);
begin
  writeln(Format(SUninstallError, [AExeName]));
end;

procedure Tfbupdate.WriteInstPath(APath, AOptions: string; AFileFound:
  Boolean);
begin
  if APath = '' then
    writeln(SInstallNoFileSpecified)
  else if AFileFound then
    writeln(Format(SInstall, [APath, AOptions]))
  else
    writeln(Format(SInstallNotFound, [APath]));
end;

procedure Tfbupdate.WriteGlobalResult(Success: Boolean);
begin
  if Success then
    writeln(SSuccess)
  else
    writeln(SError)
end;

procedure Tfbupdate.WriteFirebirdNotInstalled;
begin
  writeln(SFirebirdNotInstalled);
end;
