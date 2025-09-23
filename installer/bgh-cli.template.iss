[Setup]
AppName=BGH CLI Installer
AppVersion=__RELEASE_TAG__
DefaultDirName={userappdata}\..\ .bgh
DisableDirPage=yes
DefaultGroupName=BGHCLI
OutputDir=.
OutputBaseFilename=bgh-cli-installer
Compression=lzma
SolidCompression=yes
SetupIconFile=icon.ico
AppPublisher=__PUBLISHER_NAME__
AppPublisherURL=__PUBLISHER_URL__
AppContact=__PUBLISHER_EMAIL__ 

[Files]
Source: "installer.ps1"; DestDir: "{tmp}"; Flags: deleteafterinstall
Source: "GitHub.psm1"; DestDir: "{tmp}"; Flags: deleteafterinstall
Source: "icon.ico"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Run]
Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -NoLogo -NoProfile -WindowStyle Hidden -File ""{tmp}\installer.ps1"""; StatusMsg: "CLI wird installiert..."; Flags: runhidden

[Icons]
Name: "{group}\BGH-CLI starten"; Filename: "powershell.exe"; Parameters: "-NoLogo -NoProfile -Command bgh hilfe"