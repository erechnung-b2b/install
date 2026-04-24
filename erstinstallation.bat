@echo off
chcp 65001 >nul 2>&1
title E-Rechnungssystem v2.0 - Komplettinstallation
color 0F

echo.
echo  ╔════════════════════════════════════════════════════════╗
echo  ║  E-Rechnungssystem v2.0 - EBRK UG                    ║
echo  ║  Komplettinstallation fuer Windows                    ║
echo  ║  XRechnung / ZUGFeRD / EN 16931                       ║
echo  ╚════════════════════════════════════════════════════════╝
echo.

cd /d "%~dp0"
set "INSTALL_DIR=%cd%"

:: ══════════════════════════════════════════════════════════════
:: 1. PYTHON PRUEFEN + INSTALLIEREN
:: ══════════════════════════════════════════════════════════════
echo  [1/6] Python pruefen...

:: Erst schauen ob Python bereits da ist
set "PYTHON_OK=0"
where python >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    for /f "tokens=2 delims= " %%v in ('python --version 2^>^&1') do set PYVER_FULL=%%v
    for /f "tokens=1,2 delims=." %%a in ("%PYVER_FULL%") do (
        if %%a GEQ 3 if %%b GEQ 10 set "PYTHON_OK=1"
    )
)

if "%PYTHON_OK%"=="1" (
    echo  ✓ Python %PYVER_FULL% gefunden
    goto :python_done
)

echo.
echo  Python 3.10+ nicht gefunden oder zu alt.
echo  Installiere Python automatisch...
echo.

:: Methode 1: winget (Windows 10 2004+ / Windows 11)
where winget >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo  Verwende winget...
    winget install Python.Python.3.12 --accept-package-agreements --accept-source-agreements -h
    if %ERRORLEVEL% EQU 0 (
        echo  ✓ Python 3.12 per winget installiert
        echo.
        echo  ══════════════════════════════════════════════
        echo   WICHTIG: Bitte dieses Fenster SCHLIESSEN
        echo   und erstinstallation.bat ERNEUT starten!
        echo   (Python muss den PATH neu laden)
        echo  ══════════════════════════════════════════════
        echo.
        pause
        exit /b 0
    )
    echo  winget Installation fehlgeschlagen, versuche Download...
)

:: Methode 2: Direkter Download mit PowerShell
echo  Lade Python 3.12 herunter...
set "PY_URL=https://www.python.org/ftp/python/3.12.7/python-3.12.7-amd64.exe"
set "PY_INSTALLER=%TEMP%\python-3.12.7-amd64.exe"

powershell -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%PY_URL%' -OutFile '%PY_INSTALLER%' -UseBasicParsing } catch { exit 1 }" 2>nul

if not exist "%PY_INSTALLER%" (
    echo.
    echo  ✗ Download fehlgeschlagen.
    echo.
    echo  Bitte Python manuell installieren:
    echo  https://www.python.org/downloads/
    echo.
    echo  WICHTIG: "Add Python to PATH" ankreuzen!
    echo.
    start https://www.python.org/downloads/
    pause
    exit /b 1
)

echo  Download OK (%PY_INSTALLER%)
echo  Starte Installation (bitte warten)...
echo.

:: Silent install mit PATH
"%PY_INSTALLER%" /quiet InstallAllUsers=0 PrependPath=1 Include_pip=1 Include_launcher=1

if %ERRORLEVEL% EQU 0 (
    echo  ✓ Python 3.12 installiert
    echo.
    echo  ══════════════════════════════════════════════
    echo   WICHTIG: Bitte dieses Fenster SCHLIESSEN
    echo   und erstinstallation.bat ERNEUT starten!
    echo   (PATH muss neu geladen werden)
    echo  ══════════════════════════════════════════════
    echo.
    del "%PY_INSTALLER%" >nul 2>&1
    pause
    exit /b 0
) else (
    echo.
    echo  ✗ Automatische Installation fehlgeschlagen.
    echo  Starte manuellen Installer...
    echo.
    echo  WICHTIG: "Add Python to PATH" ankreuzen!
    echo.
    "%PY_INSTALLER%"
    echo.
    echo  Nach der Installation: Fenster schliessen,
    echo  erstinstallation.bat erneut starten.
    pause
    exit /b 1
)

:python_done

:: ══════════════════════════════════════════════════════════════
:: 2. JAVA PRUEFEN + INSTALLIEREN (optional)
:: ══════════════════════════════════════════════════════════════
echo  [2/6] Java pruefen (fuer XRechnung-Validator)...

where java >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    for /f "tokens=*" %%v in ('java -version 2^>^&1 ^| findstr /i "version"') do set JVER=%%v
    echo  ✓ Java gefunden: %JVER%
    goto :java_done
)

echo  Java nicht gefunden.
echo.
echo  Java wird fuer den offiziellen KoSIT XRechnung-Validator
echo  benoetigt. Ohne Java wird der eingebaute Basis-Validator
echo  verwendet (funktioniert, aber weniger Pruefregeln).
echo.
set /p "INSTALL_JAVA=  Java jetzt installieren? (j/n): "
if /i "%INSTALL_JAVA%" NEQ "j" (
    echo  Uebersprungen. Basis-Validator wird verwendet.
    goto :java_done
)

:: Java per winget
where winget >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo  Installiere Java (Eclipse Temurin 21)...
    winget install EclipseAdoptium.Temurin.21.JRE --accept-package-agreements --accept-source-agreements -h
    if %ERRORLEVEL% EQU 0 (
        echo  ✓ Java installiert
        goto :java_done
    )
)

:: Fallback: Download
echo  Lade Java (Temurin JRE 21) herunter...
set "JAVA_URL=https://api.adoptium.net/v3/installer/latest/21/ga/windows/x64/jre/hotspot/normal/eclipse"
set "JAVA_INSTALLER=%TEMP%\temurin-jre-21.msi"

powershell -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%JAVA_URL%' -OutFile '%JAVA_INSTALLER%' -UseBasicParsing } catch { exit 1 }" 2>nul

if exist "%JAVA_INSTALLER%" (
    echo  Installiere Java...
    msiexec /i "%JAVA_INSTALLER%" /quiet ADDLOCAL=FeatureMain,FeatureEnvironment,FeatureJarFileRunWith
    if %ERRORLEVEL% EQU 0 (
        echo  ✓ Java installiert
        del "%JAVA_INSTALLER%" >nul 2>&1
    ) else (
        echo  ⚠ Java Installation fehlgeschlagen.
        echo  Manuell: https://adoptium.net/de/temurin/releases/
    )
) else (
    echo  ⚠ Java Download fehlgeschlagen.
    echo  Manuell: https://adoptium.net/de/temurin/releases/
)

:java_done
echo.

:: ══════════════════════════════════════════════════════════════
:: 3. VIRTUAL ENVIRONMENT
:: ══════════════════════════════════════════════════════════════
echo  [3/6] Virtual Environment einrichten...

if not exist ".venv" (
    python -m venv .venv
    if %ERRORLEVEL% NEQ 0 (
        echo  ✗ venv konnte nicht erstellt werden.
        echo  Pruefen Sie ob Python korrekt installiert ist.
        pause
        exit /b 1
    )
    echo  ✓ .venv erstellt
) else (
    echo  ✓ .venv existiert bereits
)

call .venv\Scripts\activate.bat

:: ══════════════════════════════════════════════════════════════
:: 4. PYTHON-PAKETE
:: ══════════════════════════════════════════════════════════════
echo  [4/6] Python-Pakete installieren...

pip install --upgrade pip -q 2>nul
pip install -r requirements.txt -q 2>nul

:: Prüfen ob alles da ist
python -c "import flask,lxml,qrcode,cryptography,pdfplumber,reportlab,pikepdf; print('  ✓ Alle 7 Kernpakete installiert')" 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo  ⚠ Einige Pakete fehlen. Versuche erneut...
    pip install flask lxml qrcode cryptography pdfplumber reportlab pikepdf -q
    python -c "import flask; print('  ✓ Pakete nachinstalliert')" 2>nul
    if %ERRORLEVEL% NEQ 0 (
        echo  ✗ Paket-Installation fehlgeschlagen.
        echo  Manuell: .venv\Scripts\activate.bat
        echo           pip install -r requirements.txt
        pause
        exit /b 1
    )
)

:: ══════════════════════════════════════════════════════════════
:: 5. DATENVERZEICHNISSE
:: ══════════════════════════════════════════════════════════════
echo  [5/6] Datenverzeichnisse anlegen...

for %%d in (archiv export sent_mails test_mails logo documents attachments) do (
    if not exist "data\%%d" mkdir "data\%%d"
)
echo  ✓ data\ Struktur angelegt

:: ══════════════════════════════════════════════════════════════
:: 6. KOSIT-VALIDATOR PRUEFEN
:: ══════════════════════════════════════════════════════════════
echo  [6/6] KoSIT XRechnung-Validator pruefen...

if exist "tools\kosit\validator.jar" (
    if exist "tools\kosit\scenarios.xml" (
        echo  ✓ KoSIT-Validator vorhanden
    ) else (
        echo  ⚠ scenarios.xml fehlt in tools\kosit\
    )
) else (
    echo  ⚠ KoSIT-Validator nicht vorhanden
    where java >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo  Java ist da — Validator kann spaeter nachgeladen werden
    ) else (
        echo  Basis-Validator wird verwendet (reicht fuer den Betrieb)
    )
)

:: ══════════════════════════════════════════════════════════════
:: FERTIG
:: ══════════════════════════════════════════════════════════════
echo OK > .deps_installed

echo.
echo  ╔════════════════════════════════════════════════════════╗
echo  ║                                                        ║
echo  ║   ✓ Installation abgeschlossen!                        ║
echo  ║                                                        ║
echo  ╠════════════════════════════════════════════════════════╣
echo  ║                                                        ║
echo  ║   Starten:  Doppelklick auf starten.bat                ║
echo  ║                                                        ║
echo  ║   Browser oeffnet sich automatisch:                    ║
echo  ║   http://localhost:5000                                 ║
echo  ║                                                        ║
echo  ║   28-Tage-Testmodus startet beim ersten Aufruf.        ║
echo  ║   Danach: Lizenzschluessel unter Einstellungen.        ║
echo  ║                                                        ║
echo  ╚════════════════════════════════════════════════════════╝
echo.

:: Zusammenfassung
echo  Installierte Komponenten:
python --version 2>&1
where java >nul 2>&1 && (java -version 2>&1 | findstr /i "version") || echo  Java: nicht installiert (optional)
echo  Pakete: flask, lxml, qrcode, cryptography, pdfplumber, reportlab, pikepdf
echo  Verzeichnis: %INSTALL_DIR%
echo.

pause
