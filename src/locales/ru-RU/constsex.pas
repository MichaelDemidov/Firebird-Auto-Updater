unit ConstsEx;

{$mode ObjFPC}{$H+}

interface

resourcestring
  // do not localize
  SGDS32Name = 'gds32';
  SFBClientName = 'fbclient';

  // Firebird DLL error messages
  SNoGDS32 = 'Не найдена клиентская динамическая библиотека Firebird: ' +
    'gds32.dll или fbclient.dll. Переустанавливаем';
  SGDS32Found = 'Клиентская динамическая библиотека обнаружена: %s';
  SGDS32InfoSuccess = 'Сведения о библиотеке %s: %s';
  SGDS32InfoError = 'Загрузка сведений о библиотеке %s невозможна. ' +
    'Переустанавливаем';
  SFirebirdNotInstalled = 'Firebird не был установлен, нужно его установить';

  // need update?
  SNewVersionUpdate = 'Новая версия: %s, нужно обновление';
  SNewVersionNoUpdate = 'Новая версия: %s, обновление не требуется';

  // install messages
  SInstall = 'Найден файл установки: %s. Параметры командной строки:' +
    LineEnding + '%s';
  SInstallNoFileSpecified = 'Ошибка: не указано имя файла установки, ' +
    'продолжение работы невозможно';
  SInstallNotFound = 'Ошибка: файл установки не найден: %s';
  SInstallError = 'Ошибка запуска файла установки: %s';

  // uninstall messages
  SUninstall = 'Найден файл для удаления предыдущей версии: %s. Параметры ' +
    'командной строки:' + LineEnding + '%s';
  SUninstallNoFileSpecified = 'Ошибка: не укзаано имя файла для удаления ' +
    'предыдущей версии, могут быть проблемы при переустановке';
  SUninstallNotFound = 'Ошибка: файл для удаления предыдущей версии не ' +
    'найден: %s';
  SUninstallError = 'Ошибка запуска файла для удаления предыдущей версии: %s';

  // Help screen
  SHelpMessage = 'Запуск программы:' + LineEnding + LineEnding +
    '%0:s -h или %0:s --help' + LineEnding +
    '  - для отображения экрана помощи (этого экрана)' + LineEnding +
    '%0:s [file_name.cfg]' + LineEnding +
    '  - для запуска процесса обновления. Если имя файла с настройками ' +
    '(file_name.cfg в примере) не задано, будет использовано имя приложения ' +
    'с расширением "cfg" (т.е. %1:s)';

  // global result messages
  SSuccess = 'Установка завершена успешно. Для работы Firebird может ' +
    'понадобиться перезагрузка компьютера';
  SError = 'Неустранимые ошибки при обновлении. Проверьте, пожалуйста, ' +
    'предыдущие сообщения';

implementation

end.

