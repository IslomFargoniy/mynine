; Inno Setup 6 script for the Mynine desktop exam client.
;
; Build (CI does this, see .github/workflows/windows-build.yml):
;   flutter build windows --release
;   ISCC.exe /DMyAppVersion=1.2.0 installer\mynine.iss
; Output: build\installer\mynine-setup-<version>.exe
;
; The app's self-updater runs this installer with
;   /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
; and the [Run] entry below relaunches the app after a silent install.

#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\build\windows\x64\runner\Release"
#endif

#define MyAppName "Mynine Exam"
#define MyAppPublisher "Mynine"
#define MyAppURL "https://mynine.uz"
#define MyAppExeName "mynine_desktop.exe"
; Must match the mutex created in windows/runner/main.cpp.
#define MyAppMutex "MynineDesktopSingleInstance"

[Setup]
AppId={{6C2F1B7E-4F1A-4B8C-9C55-2E8D0B7A9E31}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
DisableDirPage=auto
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
OutputDir=..\build\installer
OutputBaseFilename=mynine-setup-{#MyAppVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
SetupLogging=yes
; The updater exits the app right after starting setup; Restart Manager closes
; it if it is still running.
CloseApplications=force
RestartApplications=no
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
VersionInfoVersion={#MyAppVersion}
VersionInfoProductName={#MyAppName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"
Name: "autostart"; Description: "Start {#MyAppName} automatically when Windows starts"; GroupDescription: "Exam PC:"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{commonstartup}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: autostart

[Run]
; No "skipifsilent": the self-updater installs silently and needs the relaunch.
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall

[Code]
// Wait (max 15 s) for the running app to exit before files are replaced.
function InitializeSetup(): Boolean;
var
  I: Integer;
begin
  I := 0;
  while CheckForMutexes('{#MyAppMutex}') and (I < 30) do
  begin
    Sleep(500);
    I := I + 1;
  end;
  Result := True;
end;
