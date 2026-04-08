@echo off
REM ========================================================
REM  E-Rechnungssystem - Erstinstallation Windows
REM  Installiert ALLE Voraussetzungen automatisch:
REM    - Python 3.12 (via Microsoft Store oder offizieller Installer)
REM    - Java 17 (via winget oder direkter Download)
REM    - Python-Pakete (pip install -r requirements.txt)
REM    - KoSIT-Validator + XRechnung-Konfiguration
REM    - Datenverzeichnisse
REM  Aufruf: einmalig per Doppelklick. Bei Folgestarts: starten.bat
REM ========================================================
setlocal enabledelayedexpansion
title E-Rechnungssystem - Erstinstallation
color 0B

echo.
echo  ========================================================
echo   E-Rechnungssystem - Erstinstallation
echo   Diese Installation richtet ALLES ein, was die Software
echo   zum Laufen braucht. Bitte einmalig ausfuehren.
echo  ========================================================
echo.

cd /d "%~dp0"

REM ── 1. Pruefe Administrator-Rechte (fuer winget) ──
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  HINWEIS: Skript laeuft ohne Admin-Rechte.
    echo  Falls Python oder Java nicht installiert sind, wird das
    echo  Skript die Installation per winget vorschlagen — Windows
    echo  fragt dann ggf. nach Bestaetigung.
    echo.
)

REM ── 2. Python pruefen ────────────────────────────────────
echo  [1/6] Pruefe Python-Installation...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo         Python nicht gefunden — versuche Installation per winget...
    where winget >nul 2>&1
    if !errorlevel! neq 0 (
        echo.
        echo  FEHLER: Python und winget sind nicht verfuegbar.
        echo.
        echo  Bitte Python manuell installieren:
        echo    https://www.python.org/downloads/
        echo  WICHTIG: Bei der Installation "Add Python to PATH" anhaken.
        echo.
        echo  Nach der Installation diese Datei erneut ausfuehren.
        pause
        exit /b 1
    )
    winget install -e --id Python.Python.3.12 --accept-source-agreements --accept-package-agreements
    if !errorlevel! neq 0 (
        echo  FEHLER: Python-Installation per winget fehlgeschlagen.
        echo  Bitte manuell von https://www.python.org/downloads/ installieren.
        pause
        exit /b 1
    )
    echo         Python wurde installiert. Bitte dieses Skript NEU starten,
    echo         damit das System die neuen PATH-Variablen kennt.
    pause
    exit /b 0
)
for /f "tokens=*" %%v in ('python --version') do echo         Gefunden: %%v
echo.

REM ── 3. Java pruefen ──────────────────────────────────────
echo  [2/6] Pruefe Java-Installation (fuer KoSIT-Validator)...
java -version >nul 2>&1
if %errorlevel% neq 0 (
    echo         Java nicht gefunden — versuche Installation per winget...
    where winget >nul 2>&1
    if !errorlevel! neq 0 (
        echo.
        echo  WARNUNG: Java konnte nicht automatisch installiert werden.
        echo  Die Software laeuft auch ohne Java, aber der offizielle
        echo  KoSIT-Validator wird nicht verfuegbar sein.
        echo.
        echo  Manuelle Installation: https://adoptium.net/de/temurin/releases/
        echo  ^(Temurin JRE 17 oder neuer^)
        echo.
        echo  Druecken Sie eine Taste, um ohne Java fortzufahren...
        pause >nul
        goto :skip_java
    )
    winget install -e --id EclipseAdoptium.Temurin.17.JRE --accept-source-agreements --accept-package-agreements
    if !errorlevel! neq 0 (
        echo  WARNUNG: Java-Installation fehlgeschlagen — fahre ohne KoSIT fort.
        goto :skip_java
    )
    echo         Java wurde installiert. PATH wird im neuen Fenster aktiv.
)
for /f "tokens=*" %%v in ('java -version 2^>^&1 ^| findstr /i "version"') do echo         Gefunden: %%v
:skip_java
echo.

REM ── 4. Python-Pakete installieren ────────────────────────
echo  [3/6] Installiere Python-Pakete (kann 1-2 Minuten dauern)...
python -m pip install --upgrade pip --quiet
python -m pip install -r requirements.txt --quiet
if %errorlevel% neq 0 (
    echo  FEHLER: Installation der Python-Pakete fehlgeschlagen.
    echo  Versuchen Sie manuell: python -m pip install -r requirements.txt
    pause
    exit /b 1
)
echo         OK
echo.

REM ── 5. KoSIT-Validator herunterladen ─────────────────────
echo  [4/6] Lade KoSIT-Validator herunter (optional)...
java -version >nul 2>&1
if %errorlevel% neq 0 (
    echo         Java fehlt — KoSIT-Validator wird uebersprungen.
    goto :skip_kosit
)
if exist "tools\kosit\scenarios.xml" (
    echo         KoSIT-Validator bereits vorhanden — uebersprungen.
    goto :skip_kosit
)
if not exist "tools\kosit" mkdir "tools\kosit"
echo         Lade Validator-JAR von GitHub...
powershell -NoProfile -Command ^
    "$ErrorActionPreference='Stop'; "^
    "$rel = Invoke-RestMethod 'https://api.github.com/repos/itplr-kosit/validator/releases/latest'; "^
    "$jar = $rel.assets | Where-Object { $_.name -like 'validator-*-standalone.jar' } | Select-Object -First 1; "^
    "if (-not $jar) { throw 'Kein passender JAR im Release gefunden' }; "^
    "Invoke-WebRequest $jar.browser_download_url -OutFile 'tools\kosit\validator.jar' -UseBasicParsing; "^
    "Write-Host '         Validator-JAR heruntergeladen.'"
if %errorlevel% neq 0 (
    echo         WARNUNG: Validator-Download fehlgeschlagen — KoSIT bleibt deaktiviert.
    goto :skip_kosit
)
echo         Lade XRechnung-Konfiguration von GitHub...
powershell -NoProfile -Command ^
    "$ErrorActionPreference='Stop'; "^
    "$rel = Invoke-RestMethod 'https://api.github.com/repos/itplr-kosit/validator-configuration-xrechnung/releases/latest'; "^
    "$zip = $rel.assets | Where-Object { $_.name -like '*.zip' -and $_.name -notlike '*test*' -and $_.name -notlike '*source*' } | Select-Object -First 1; "^
    "if (-not $zip) { throw 'Keine Konfigurations-ZIP gefunden' }; "^
    "Invoke-WebRequest $zip.browser_download_url -OutFile 'tools\kosit\config.zip' -UseBasicParsing; "^
    "Expand-Archive -Path 'tools\kosit\config.zip' -DestinationPath 'tools\kosit' -Force; "^
    "Remove-Item 'tools\kosit\config.zip'; "^
    "Write-Host '         XRechnung-Konfiguration entpackt.'"
if %errorlevel% neq 0 (
    echo         WARNUNG: Konfigurations-Download fehlgeschlagen — KoSIT bleibt deaktiviert.
    goto :skip_kosit
)
if not exist "tools\kosit\scenarios.xml" (
    echo         WARNUNG: scenarios.xml nicht gefunden nach Entpackung.
    echo         KoSIT bleibt deaktiviert. Pruefe tools\kosit\ manuell.
    goto :skip_kosit
)
echo         OK — KoSIT-Validator einsatzbereit.
:skip_kosit
echo.

REM ── 6. Datenverzeichnisse anlegen ────────────────────────
echo  [5/6] Lege Datenverzeichnisse an...
if not exist "data" mkdir "data"
if not exist "data\archiv" mkdir "data\archiv"
if not exist "data\export" mkdir "data\export"
if not exist "data\sent_mails" mkdir "data\sent_mails"
if not exist "data\logo" mkdir "data\logo"
echo         OK
echo.

REM ── 7. Funktionstest ─────────────────────────────────────
echo  [6/6] Pruefe, ob die Anwendung startbereit ist...
python -c "from webapp import app" 2>nul
if %errorlevel% neq 0 (
    echo  FEHLER: Anwendung kann nicht geladen werden.
    echo  Bitte requirements.txt pruefen oder Support kontaktieren.
    pause
    exit /b 1
)
echo         OK
echo.

REM ── Fertig ───────────────────────────────────────────────
echo  ========================================================
echo   Installation erfolgreich abgeschlossen!
echo  ========================================================
echo.
echo   Software starten mit: starten.bat (oder Doppelklick darauf)
echo.
echo   Beim ersten Start:
echo     1. Browser oeffnet sich automatisch auf http://localhost:5000
echo     2. 28 Tage kostenlose Testphase startet
echo     3. Lizenz spaeter unter "Einstellungen" eingeben
echo.
pause
exit /b 0
