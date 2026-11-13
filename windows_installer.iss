[Setup]
AppName=SalesHub
AppVersion=1.0.0
DefaultDirName={autopf}\SalesHub
DefaultGroupName=SalesHub
OutputDir=Output
OutputBaseFilename=SalesHub-Setup
Compression=lzma2
SolidCompression=yes
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\SalesHub"; Filename: "{app}\crm.exe"
Name: "{autodesktop}\SalesHub"; Filename: "{app}\crm.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked

[Run]
Filename: "{app}\crm.exe"; Description: "Launch SalesHub"; Flags: nowait postinstall skipifsilent
