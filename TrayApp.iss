#define AppName "TrayApp"
#define AppVersion "1.0.0"

[Setup]
AppId={{8F3C2A47-5B1E-4D9A-9C6E-2B7A1F0D4E55}
AppName={#AppName}
AppVersion={#AppVersion}
DefaultDirName={autopf}\{#AppName}
DisableProgramGroupPage=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=installer-out
OutputBaseFilename=TrayApp-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayName={#AppName}

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "package\TrayApp.exe";        DestDir: "{app}"; Flags: ignoreversion
Source: "package\TrayService.exe";    DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\TrayApp.exe"

[Code]
const
  SvcName = 'TrayAppService';
  SvcSddl = 'D:(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;LCRP;;;IU)';

function RunHidden(const Exe, Params: String): Integer;
var
  rc: Integer;
begin
  if not Exec(Exe, Params, '', SW_HIDE, ewWaitUntilTerminated, rc) then
    rc := -1;
  Result := rc;
end;

procedure RemoveOldService();
begin
  RunHidden(ExpandConstant('{sys}\taskkill.exe'), '/F /IM TrayService.exe');
  RunHidden(ExpandConstant('{sys}\taskkill.exe'), '/F /IM TrayApp.exe');
  RunHidden(ExpandConstant('{sys}\sc.exe'), 'delete ' + SvcName);
  Sleep(1500);
end;

procedure InstallService();
var
  sc: String;
begin
  sc := ExpandConstant('{sys}\sc.exe');

  if RunHidden(sc, 'create ' + SvcName + ' binPath= "' +
       ExpandConstant('{app}\TrayService.exe') +
       '" start= auto DisplayName= "TrayApp Service"') <> 0 then
  begin
    MsgBox('Failed to create the TrayAppService service.', mbError, MB_OK);
    Exit;
  end;

  RunHidden(sc, 'description ' + SvcName + ' "TrayApp per-session GUI service"');
  RunHidden(sc, 'sdset ' + SvcName + ' "' + SvcSddl + '"');

  if RunHidden(sc, 'start ' + SvcName) <> 0 then
    MsgBox('The service was installed but could not be started. Start it by launching TrayApp.', mbInformation, MB_OK);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
    RemoveOldService()
  else if CurStep = ssPostInstall then
    InstallService();
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
    RemoveOldService();
end;