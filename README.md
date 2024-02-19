Firebird-update
===============

What Is It?
-----------

A simple application for updating a client or server installation of the Firebird DBMS under Windows.

I had a task: to update Firebird on several hundred client computers and a dozen developer computers. When installing Firebird, certain installation options must be selected.

To do this, I had to develop a separate program because for some reason the Firebird developers do not provide any official way to update the DBMS version (at least, I don’t know about it). A user can only remove the DBMS and reinstall it, adding all the necessary settings. Along the way, I managed to make it so that Firebird could not only be updated, but also installed if it was not installed before.

> [!CAUTION]
> 1. The application is *a console application,* that is, it does not have a user interface, and all messages and errors are written to the console.
> 2. The program requires system administrator rights when launched, because this is necessary to install and uninstall the DBMS.

How To Run It?
--------------

To start the installation or update you need: the `fbupdate.exe` file, one or more files with settings (by default they have the `cfg` extension), and a Firebird installation file of the appropriate version (located in the `update` folder).

To start the program type in a command line: `fbupdate file_name_with_settings`. For example, `fbupdate fbupdate_server.cfg`.

> [!NOTE]
>If you are using the Windows Explorer then you just need to drag the `fbupdate_server.cfg` file onto the `fbupdate.exe` icon, and if you are using any panel file manager (like FAR Manager or Total Commander) then you can type the above command in command line.

If the name of the settings file is omitted (you just run the exe file), then the program tries to connect the `fbupdate.cfg` file. And if the file is not found, there will be an error and nothing will be executed.

How It Works?
-------------

The program:

1. The program searches for an installed Firebird on the computer. To do this, it looks in the system registry for a link to the folder in which the Firebird DBMS is installed. If the folder is not found, then Firebird is most likely not installed—the program skips steps 2 and 3 and goes to step 4.
2. The config file contains the version of Firebird to install. There may be the following options:
    * the configuration file contains a version number in format 'N.N.', 'N.N.N', and so on. The program tries to extract the Firebird version from `fbclient.dll` (in the Firebird folder) or `gds32.dll` (in the `Windows\System` folder). If it fails to get the installed version then install the Firebird (go to step 4). If the version in the configuration file is greater than the installed version then the program needs to remove the installed version and install a new one (go to step 3). Finally, if the version in the configuration file is less than or equal to the installed version, this means there is no need to do anything else (exit the program),
    * the configuration file contains something that is not a number (a string that cannot be converted to a number). In this case, the program goes to step 3.
3. The program launches the Firebird uninstaller located in the previously found (step 1) folder and waits for it to complete.
4. The program launches the Firebird installer and waits for it to complete.

> [!CAUTION]
> Sometimes, after installing a new version of Firebird, you need to restart your computer (as far as I understand, this is usually on those computers where the DBMS server is installed). This message is issued by the installer itself, and not by the program; if you ignore it, Firebird will not start.

> [!NOTE]
>The program tries to install Firebird to the same folder where it was previously installed (see `%FbDir%` constant below).

The Configuration File
----------------------

```ini
; common information

[firebird]
; new version to install
version=3.0.11
; DLL name to check: fbclient or gds32
dll=gds32
; relative path to the installer
installer=update\Firebird-3.0.11.33703_0_Win32.exe
; unistaller exe name
uninstaller=unins000.exe

; uninstaller options

[uninstaller]
; the uninstaller runs in “silent” mode and does not require user intervention (do not write anything after the equal sign)
SILENT=

; installer options

[installer]
; interface language (e.g. for the message about computer restart)
LANG=en
; installation directory. %FbDir% is a predefined constant that is replaced by the actual absolute path. If there was no installation previously, then this parameter is completely ignored. If omitted then use default Program Files folder
DIR=%FbDir%\Firebird_3_0
; folder name for the Windows Start menu
GROUP=Firebird 3.0 (Win32)
; installation type
TYPE=clientinstall
; components to install
COMPONENTS=clientcomponent
; additional tasks, here: create the gds32.dll and copy it to the Windows\System directory
TASKS=copyfbclienttosystask,copyfbclientasgds32task
; the installer runs in “silent” mode and does not require user intervention (do not write anything after the equal sign)
SILENT=
```

How To Create The Configuration File
------------------------------------

Of course, it’s impossible to come up with the line `TASKS=copyfbclienttosystask,copyfbclientasgds32task` and other things mentioned above on your own. To prepare a settings file and obtain a list of valid setup program settings, do the following:

1. Manually uninstall the Firebird DBMS if it is installed.
2. Run the installation program with the command line switch `/SAVEINF=filename`, for example:

    `Firebird-3.0.11.33703_0_Win32.exe /SAVEINF=fb_client.inf`.

3. In the installation program interface, select all the necessary options, install Firebird as usual.
4. A text file with a list of keys that we need will appear in the folder with the installation file (in the example above, this is `fb_client.inf`). Its contents look something like this:
    ```ini
    [Setup]
    Lang=en
    Dir=C:\Program Files (x86)\Firebird\Firebird_3_0
    Group=Firebird 3.0 (Win32)
    NoIcons=0
    SetupType=clientinstall
    Components=clientcomponent
    Tasks=copyfbclienttosystask,copyfbclientasgds32task
    ```
5. The `[Setup]` section name itself is not needed, and the list of keys and their values from it can be copied to the `[installer]` section of the our config file. However, some changes need to be made to this list:
    * firstly, the key names are not converted to upper case. I don’t know for sure whether this should be done, but just in case I do it,
    * instead of the `TYPE` key, this file contains `SetupType`, I rename it to `TYPE`,
    * I also add the line `DIR=%FbDir%\Firebird_...`, the name of the folder (`Firebird_...`) depends on the major version of Firebird (see above),
    * the `NoIcons` item, in my opinion, does nothing useful, its removal does not affect the operation of the installation program (though, if you write 1 instead of 0 there, then it should disable the creation of the Firebird item in the Start menu),
    * be sure to add the line `SILENT=` to the end of the list (nothing after the equal sign).

    After all these edits it looks like this:
    ```ini
    `[installer]`
    LANG=en
    DIR=%FbDir%\Firebird_3_0
    GROUP=Firebird 3.0 (Win32) 
    TYPE=clientinstall
    COMPONENTS=clientcomponent
    TASKS=copyfbclienttosystask,copyfbclientasgds32task
    ```

NSIS
----

There is a difficulty: it is inconvenient for non-advanced users to download a set consisting of the program, Firebird installer, and configuration files, and then to run the program with the corresponding config file. So I made a separate "meta-installer" for this. The user downloads and runs a single exe, which unpacks all the necessary files into a system temporary folder, launches the program, waits for it to complete, and deletes the files from the temporary folder. I use the Nullsoft Scriptable Installation System (NSIS) for this because it's a tool I'm familiar with. Of course, you can come up with something else.

To use it, please copy the executable file `fbupdate.exe` and the desired configuration file in the `Firebird` folder. Then rename the config file to `fbupdate.cfg`. Also copy the Firebird setup file in the `Firebird\update` folder.

Then compile then `Firebird.nsi` script using NSIS compiler.

Source Code
-----------

The source code is written in Free Pascal (IDE Lazarus 3). I think it can be easily transferred to Delphi. I have also included the compiled exe file so there is no need to recompile it.

The `src\Locale` folder contains translations of program messages into different languages. You need to change the search path (`-Fu` option) in the project settings. Now there are English (`en-US`, default) and Russian (`ru-RU`) locales.

Author
------
Copyright (c) 2024, Michael Demidov

Visit my GitHub page to check for updates, report issues, etc.: https://github.com/MichaelDemidov

Drop me an e-mail at: michael.v.demidov@gmail.com
