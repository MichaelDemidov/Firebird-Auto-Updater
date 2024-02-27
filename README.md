Firebird Auto Updater
=====================

What Is It?
-----------

A simple NSIS script for updating a client or server installation of the Firebird DBMS under Windows.

I had a task: to update Firebird on several hundred client computers and a dozen developer computers. When installing Firebird, certain installation options must be selected.

To do this, I had to develop a separate solution because for some reason the Firebird developers do not provide any official way to update the DBMS version (at least, I don’t know about it). It is inconvenient for non-advanced users (well, and advanced ones too) to manually uninstall a previous Firebird client, download the Firebird installer, launch it, and manually set the necessary installer settings.

The user would have to download and run a single exe file that unpacks the official Firebird installer into a temporary system folder, checks for a previous version, uninstalls it, launches the installer, waits for it to complete, and deletes the installer from the temporary folder. I use the Nullsoft Scriptable Installation System (NSIS) for this because it's a tool I'm familiar with.

Along the way, I managed to make it so that Firebird could not only be updated, but also installed if it was not installed previously.

> [!NOTE]
> 1. The script requires the official Firebird setup executable file (e.g. from the official site). After compilation, the setup file will be packaged into the resulting file.
> 2. The setup requires system administrator rights when launched, because this is necessary to install and uninstall the DBMS. At the time of launch, it asks the user to confirm running as administrator (and the user may need to enter an administrator password).

How To Run It As A User?
------------------------

To start the installation or update a user need only the compiled `Firebird_update_X_X_X.exe` file.

There are a couple of command line parameters to use with the executable.

> [!TIP]
> Use `Win + R` to open the `Run` dialog, type `cmd`, and press `Ctrl + Shift + Enter` to launch command line as an administrator. If you are using any panel file manager (like FAR Manager or Total Commander) then you can type the below commands in command line.

1. `Firebird_update_X_X_X.exe` without parameters checks the already installed version of Firebird and, if this version is lower than the one specified in the script, removes it and installs a new one. Only the client part is installed, without server components.
2. `Firebird_update_X_X_X.exe /server` performs the same task, but installs the server components.
3. `Firebird_update_X_X_X.exe /force` skips the version checking to force Firebird to be installed.

It is of course possible to combine `/server` and `/force` parameters in any order.

Algorithm
---------

At the beginning of the script some constants are defined. I'll explain them later.

1. The script searches for an installed Firebird on the computer. To do this, it looks in the system registry for a link to the folder in which the Firebird DBMS is installed (e.g. `C:\Program Files\Firebird\Firebird_3_0`). If the folder is not found, then Firebird is most likely not installed—the program skips steps 2–4 and goes to step 5.
2. If a user specified `/force` command line parameter then skip the steps 3 and 4, go to step 5.
3. If the script contains the `CHECK_GDS32` constant (see below) then it checks for the presence of the file `gds32.dll` in the `Windows\System` folder. If the file is not found, go to step 5.
4. The script contains the version of Firebird to install in format 'N.N.', 'N.N.N', and so on. When the installation runs, it tries to extract the Firebird version from `fbclient.dll` library in the Firebird folder. If it fails to get the installed version then install the Firebird (go to step 6). If the version in the configuration file is greater than the installed version then the program needs to remove the installed version and install a new one (go to step 5). Finally, if the version in the configuration file is less than or equal to the installed version, this means there is no need to do anything else (exit the program).
5. The program launches the Firebird uninstaller located in the previously found (step 1) folder and waits for it to complete.
6. The program launches the Firebird installer and waits for it to complete.

> [!IMPORTANT]
> Sometimes, after installing a new version of Firebird, you need to restart your computer (as far as I understand, this is usually on those computers where the DBMS server is upgraded). This message is issued by the installer itself, and not by the program; if you ignore it, Firebird will not start.

Requirements
------------

The script requires NSIS compiler 3.08 or later. It uses the `WordFunc` and `FileFunc` extensions that are included in the default NSIS installation.

The Constants
-------------

```nsis
; --- localization ---

; display name to show
!define inst_name "Firebird"

; interface language, e.g. for installation progress bar and for the message
; about computer restart (name of the locale file, located here:
; ${NSISDIR}\Contrib\Language files\*.nsh)
!define language "English"

; --- Firebird configuration ---

; new version to install
!define FB_VERSION "3.0.11"

; is it necessary to check for the presence of gds32.dll in the System folder?
!define CHECK_GDS32 "yes"

; installer exe name (relative path to the installer)
!define INSTALLER "Firebird-3.0.11.33703_0_Win32.exe"

; uninstaller exe name
!define UNINSTALLER "unins000.exe"

; Firebird client installer options:
; * LANG = language
; * DIR = installation directory. $1 is a predefined constant that is replaced
;   by the actual absolute path. If there was no installation previously, then
;   this parameter is completely ignored. If omitted then use default
;   Program Files folder. $1 is the parent directory of the previous Firebird
;   installation (e.g. C:\Program Files\Firebird)
; * GROUP = folder name for the Windows Start menu
; * TYPE = installation type
; * COMPONENTS = components to install
; * TASKS = additional tasks, here: create the gds32.dll and copy it to the
;   Windows\System directory
; * SILENT = the installer runs in “silent” mode and does not require user
;   intervention (do not write anything after the equal sign)
!define CLIENT_INST_OPTIONS '/LANG=ru /DIR="$1\Firebird_3_0" /GROUP="Firebird \
3.0 (Win32)" /TYPE=clientinstall /COMPONENTS=clientcomponent \
/TASKS=copyfbclienttosystask,copyfbclientasgds32task /SILENT'

; client installer options server installation parameters (the meaning of the
; options is the same as for the client, see above)
!define SERVER_INST_OPTIONS '/LANG=ru /DIR="$1\Firebird_3_0" /GROUP="Firebird \
3.0 (Win32)" /TYPE=serverinstall /COMPONENTS=servercomponent,devadmincomponent,\
clientcomponent /TASKS=usesuperservertask,useservicetask,autostarttask,\
copyfbclienttosystask,copyfbclientasgds32task,enablelegacyclientauth /SILENT'

; uninstaller options: the uninstaller runs in “silent” mode and does not
; require user intervention
!define UNINST_OPTIONS "/SILENT"
```

How To Obtain The Values Of The ..._INST_OPTIONS Constants
----------------------------------------------------------

Of course, it’s impossible to come up with the line `TASKS=copyfbclienttosystask,copyfbclientasgds32task` and other things mentioned above on your own. To obtain a list of valid setup program settings, do the following:

1. Manually uninstall the Firebird DBMS if it is installed.
2. Run the installation program with the command line switch `/SAVEINF=filename`, for example:

    `Firebird-3.0.11.33703_0_Win32.exe /SAVEINF=fb_client.inf`.

3. In the installation program interface, select all the necessary options, install Firebird client as usual.
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
5. The list of keys and their values from it can be used to set the constant CLIENT_INST_OPTIONS value. However, some changes need to be made to this list:
    * enclose the values of the `Dir` and `Group` parameters in double quotes,
    * add a slash to the beginning of each line and replace the equal sign with a space,
    * convert the key names to upper case. I don’t know for sure whether this should be done, but just in case I do it,
    * instead of the `TYPE` key, this file contains `SetupType`, rename it to `TYPE`,
    * change the line `/DIR "..."` to `/DIR "$1\Firebird_..."`, the name of the folder (`Firebird_...`) depends on the major version of Firebird,
    * the `NoIcons` item, in my opinion, does nothing useful, its removal does not affect the operation of the installation program (though, if you write 1 instead of 0 there, then it should disable the creation of the Firebird item in the Start menu),
    * be sure to add the line `/SILENT` to the end of the list (nothing after the equal sign).

    After all these edits it looks like this:
    ```
    /LANG en
    /DIR "$1\Firebird_3_0"
    /GROUP "Firebird 3.0 (Win32) "
    /TYPE clientinstall
    /COMPONENTS clientcomponent
    /TASKS copyfbclienttosystask,copyfbclientasgds32task
    /SILENT
    ```

    Now combine this into one line separated by spaces and assign to the CLIENT_INST_OPTIONS constant.

6. Follow steps 1 through 5 to install the server and set the value of the SERVER_INST_OPTIONS constant.

How To Compile The Script
-------------------------

Put the official Firebird setup file in the same folder as the script, set the constant values, specifically `FB_VERSION` and `INSTALLER`, and compile the script using NSIS compiler.

Source Code
-----------

The source code initially was written in Free Pascal then translated to NSIS because some antiviruses (for example, Microsoft Defender) assumed that the compiled exe file is a Trojan software. And also because NSIS is still better suited for creating installers, of course.

Author
------
Copyright (c) 2024, Michael Demidov

Visit my GitHub page to check for updates, report issues, etc.: https://github.com/MichaelDemidov

Drop me an e-mail at: michael.v.demidov@gmail.com
