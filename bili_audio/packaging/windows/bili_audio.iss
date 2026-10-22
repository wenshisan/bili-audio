#ifndef MyAppVersion
  #define MyAppVersion "0.1.0"
#endif

[Setup]
AppId={{8C4E2A17-6B5D-4F0A-9E3C-1D7A5B8C0E42}
AppName=bili-audio
AppVersion={#MyAppVersion}
AppPublisher=bili-audio
DefaultDirName={localappdata}\BiliAudio
DisableProgramGroupPage=yes
OutputDir=..\..\dist
OutputBaseFilename=bili_audio-windows-x64-setup
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
WizardStyle=modern
UninstallDisplayIcon={app}\bili_audio.exe

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加任务:"; Flags: unchecked

[Icons]
Name: "{autoprograms}\bili-audio"; Filename: "{app}\bili_audio.exe"
Name: "{userdesktop}\bili-audio"; Filename: "{app}\bili_audio.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\bili_audio.exe"; Description: "启动 bili-audio"; Flags: nowait postinstall skipifsilent
