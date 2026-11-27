; نصب‌کنندهٔ ویندوز «Now / الآن» (Inno Setup)
#ifndef AppVersion
  #define AppVersion "0.6.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\build\windows\x64\runner\Release"
#endif
#ifndef IconFile
  #define IconFile "..\windows\runner\resources\app_icon.ico"
#endif

[Setup]
AppId={{8B1F6D1C-5E64-4D7B-9C1A-6E1D0A7C2F11}
AppName=Now
AppVersion={#AppVersion}
AppPublisher=Now
DefaultDirName={autopf}\Now
DefaultGroupName=Now
DisableProgramGroupPage=yes
OutputDir=..\installer_out
OutputBaseFilename=Now-Setup-{#AppVersion}
SetupIconFile={#IconFile}
UninstallDisplayIcon={app}\Now.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"
Name: "startup"; Description: "Start Now with Windows (keeps reminders ringing in the background)"; GroupDescription: "Background:"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Now"; Filename: "{app}\Now.exe"
Name: "{autodesktop}\Now"; Filename: "{app}\Now.exe"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "Now"; ValueData: """{app}\Now.exe"" --background"; Tasks: startup; Flags: uninsdeletevalue

[Run]
Filename: "{app}\Now.exe"; Description: "Launch Now"; Flags: nowait postinstall skipifsilent
