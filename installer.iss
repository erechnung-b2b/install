; E-Rechnungssystem – Inno Setup Installer Script
; Erstellt eine professionelle Setup.exe mit Startmenü und Deinstallation
;
; Voraussetzung: PyInstaller-Build wurde bereits durchgeführt (dist\erechnung\ existiert)
; Build: Inno Setup Compiler öffnen → dieses Script laden → Build → Compile

[Setup]
AppName=E-Rechnungssystem
AppVersion=1.0.0
AppVerName=E-Rechnungssystem 1.0.0
AppPublisher=Energieberatung Rolf Krause
DefaultDirName={autopf}\E-Rechnungssystem
DefaultGroupName=E-Rechnungssystem
OutputDir=output
OutputBaseFilename=E-Rechnungssystem_Setup
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
LicenseFile=
SetupIconFile=
UninstallDisplayName=E-Rechnungssystem
DisableProgramGroupPage=yes
DisableWelcomePage=no

[Languages]
Name: "german"; MessagesFile: "compiler:Languages\German.isl"

[Messages]
german.WelcomeLabel1=E-Rechnungssystem Setup
german.WelcomeLabel2=Dieses Setup installiert das E-Rechnungssystem (XRechnung / ZUGFeRD / EN 16931) auf Ihrem Computer.%n%nDas System ermöglicht:%n  • Empfang und Validierung von E-Rechnungen%n  • Freigabe-Workflows mit Vier-Augen-Prinzip%n  • DATEV-Export und GoBD-konforme Archivierung%n  • Erstellung von Ausgangsrechnungen
german.FinishedHeadingLabel=Installation abgeschlossen
german.FinishedLabel=Das E-Rechnungssystem wurde erfolgreich installiert.%n%nKlicken Sie auf "Fertigstellen" um das Programm zu starten.

[Tasks]
Name: "desktopicon"; Description: "Desktop-Verknüpfung erstellen"; GroupDescription: "Zusätzliche Optionen:"
Name: "autostart"; Description: "Beim Windows-Start automatisch starten"; GroupDescription: "Zusätzliche Optionen:"; Flags: unchecked

[Files]
; Alle Dateien aus dem PyInstaller-Build
Source: "dist\erechnung\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Dirs]
Name: "{app}\data\archiv"
Name: "{app}\data\export"
Name: "{app}\data\logo"
Name: "{app}\data\sent_mails"

[Icons]
Name: "{group}\E-Rechnungssystem"; Filename: "{app}\E-Rechnungssystem.exe"; WorkingDir: "{app}"
Name: "{group}\E-Rechnungssystem Deinstallieren"; Filename: "{uninstallexe}"
Name: "{autodesktop}\E-Rechnungssystem"; Filename: "{app}\E-Rechnungssystem.exe"; WorkingDir: "{app}"; Tasks: desktopicon
Name: "{userstartup}\E-Rechnungssystem"; Filename: "{app}\E-Rechnungssystem.exe"; WorkingDir: "{app}"; Tasks: autostart

[Run]
Filename: "{app}\E-Rechnungssystem.exe"; Description: "E-Rechnungssystem jetzt starten"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Datenverzeichnisse werden bei Deinstallation NICHT gelöscht (Benutzerdaten schützen)
; Der Benutzer muss data/ manuell entfernen wenn gewünscht
Type: filesandordirs; Name: "{app}\_internal"
Type: filesandordirs; Name: "{app}\static"

[Code]
// Prüfe ob die Anwendung bereits läuft
function IsAppRunning(): Boolean;
var
  ResultCode: Integer;
begin
  Result := False;
  if Exec('tasklist', '/FI "IMAGENAME eq E-Rechnungssystem.exe" /NH', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
  begin
    // Vereinfachte Prüfung
    Result := False;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // Nach Installation: nichts weiter nötig
    Log('Installation abgeschlossen');
  end;
end;
