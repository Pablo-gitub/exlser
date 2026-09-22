; Inno Setup script for the Exlser Windows desktop build.
;
; Compiled by the desktop release workflow, which supplies the three defines
; below from pubspec.yaml and the Flutter build output. It is not meant to be
; opened and compiled by hand without them.

#ifndef AppVersion
  #error AppVersion must be supplied by the release build
#endif

#ifndef AppNumericVersion
  #error AppNumericVersion must be supplied by the release build
#endif

#ifndef SourceDir
  #error SourceDir must point to the Flutter windows release bundle
#endif

#define AppName "Exlser"
#define AppPublisher "Paolo Pietrelli"
#define AppUrl "https://github.com/Pablo-gitub/exlser"
#define AppExecutable "exlser.exe"

[Setup]
; Unique to Exlser. Never reuse another product's AppId: Windows keys the
; install directory, the upgrade path and the uninstall entry off this value,
; so a shared id makes two unrelated apps overwrite each other.
AppId={{064D553D-1732-4D84-A7C5-1C1032639E64}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppUrl}
AppSupportURL={#AppUrl}/issues
AppUpdatesURL={#AppUrl}/releases
DefaultDirName={localappdata}\Programs\Exlser
DefaultGroupName=Exlser
DisableProgramGroupPage=yes
; Installing per-user keeps the whole flow free of UAC, which matters for a
; build that is not signed with a code-signing certificate.
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputBaseFilename=exlser-windows-x64-setup
SetupIconFile=..\..\flutter_app\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExecutable}
VersionInfoVersion={#AppNumericVersion}
VersionInfoProductVersion={#AppNumericVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no
UsePreviousAppDir=yes

[Languages]
; The app ships nine locales; these are the ones Inno Setup provides an
; official translation for. Chinese has no bundled .isl, so the installer
; falls back to English there while the app itself stays localized.
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; The Flutter release bundle is a flat directory: the executable, its DLLs
; (including the sqlite3.dll that sqlite3_flutter_libs contributes) and a data
; folder that must stay next to the binary.
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Exlser"; Filename: "{app}\{#AppExecutable}"
Name: "{autodesktop}\Exlser"; Filename: "{app}\{#AppExecutable}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExecutable}"; Description: "{cm:LaunchProgram,Exlser}"; Flags: nowait postinstall skipifsilent
