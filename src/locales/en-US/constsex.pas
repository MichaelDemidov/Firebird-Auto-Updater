unit ConstsEx;

{$mode ObjFPC}{$H+}

interface

resourcestring
  // do not localize
  SGDS32Name = 'gds32';
  SFBClientName = 'fbclient';

  // Firebird DLL error messages
  SNoGDS32 = 'The Firebird client DLL gds32.dll or fbclient.dll not found. ' +
    'Will be reinstalled';
  SGDS32Found = 'The Firebird client DLL found: %s';
  SGDS32InfoSuccess = 'The Firebird client DLL (%s) info: %s';
  SGDS32InfoError = 'Unable to load information about DLL %s. ' +
    'Will be reinstalled';
  SFirebirdNotInstalled = 'Firebird is not installed, will be installed';

  // need update?
  SNewVersionUpdate = 'Newer version found: %s, will be updated';
  SNewVersionNoUpdate = 'New version is: %s, no update required';

  // install messages
  SInstall = 'Installer found: %s. Command line options:' + LineEnding + '%s';
  SInstallNoFileSpecified = 'Error: installer name not specified, cannot ' +
    'continue';
  SInstallNotFound = 'Error: Installer not found: %s';
  SInstallError = 'Error starting installer: %s';

  // uninstall messages
  SUninstall = 'Uninstaller found: %s. Command line options:' +
    LineEnding + '%s';
  SUninstallNoFileSpecified = 'Error: uninstaller name not specified, there '  +
    'may be troubles during installation';
  SUninstallNotFound = 'Error: uninstaller not found: %s';
  SUninstallError = 'Error starting uninstaller: %s';

  // Help screen
  SHelpMessage = 'How to use:' + LineEnding + LineEnding +
    '%0:s -h or %0:s --help' + LineEnding +
    '  - to read the help screen (this one)' + LineEnding +
    '%0:s [file_name.cfg]' + LineEnding +
    '  - to start the update process. If no config file name is specified, ' +
    'the exe name with the extension "cfg" will be used (that is %1:s)';

  // global result messages
  SSuccess = 'Installation completed successfully. You may need to restart ' +
    'your computer for Firebird to work.';
  SError = 'Fatal errors during update. Please check the messages above';

implementation

end.

