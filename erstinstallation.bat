@echo off
chcp 65001 >nul 2>&1
setlocal EnableExtensions EnableDelayedExpansion
title E-Rechnungssystem - Installation
cd /d "%~dp0"
set "BASIS=%CD%"

echo.
echo  ════════════════════════════════════════════════════════
echo   E-Rechnungssystem - Installation
echo   Alles wird im Programmordner eingerichtet.
echo   Keine Administratorrechte, kein vorhandenes Python noetig.
echo  ════════════════════════════════════════════════════════
echo.

:: Versionen und Pruefsummen
for /f "usebackq eol=# tokens=1,* delims==" %%a in ("installer\laufzeit.txt") do set "%%a=%%b"
if not defined PY_WIN_X64 (
    echo  X installer\laufzeit.txt fehlt - bitte das Programm erneut herunterladen.
    goto :abbruch
)
where tar >nul 2>&1 || (
    echo  X Windows 10 Version 1803 oder neuer wird benoetigt ^(tar fehlt^).
    goto :abbruch
)
if not exist laufzeit mkdir laufzeit
set "TMPDIR=%TEMP%\erechnung-setup-%RANDOM%"
mkdir "%TMPDIR%" >nul 2>&1

:: ── 1. Python ─────────────────────────────────────────────────
echo  [1/5] Python %PY_VERSION% einrichten...
set "PY=%BASIS%\laufzeit\python\python.exe"
if exist "%PY%" (
    "%PY%" -c "import sys; sys.exit(0 if sys.version_info[:2]==(3,12) else 1)" >nul 2>&1 && (
        echo        OK bereits vorhanden
        goto :venv
    )
)
echo        Lade Python ^(ca. 45 MB^)...
call :laden "%PY_BASE%/%PY_WIN_X64%" "%TMPDIR%\python.tar.gz" "%PY_WIN_X64_SHA%" || (
    echo  X Python konnte nicht geladen werden. Internetverbindung pruefen.
    goto :abbruch
)
if exist laufzeit\python rmdir /s /q laufzeit\python
tar -xzf "%TMPDIR%\python.tar.gz" -C laufzeit || goto :abbruch
if not exist "%PY%" (
    echo  X Python-Archiv unvollstaendig.
    goto :abbruch
)
for /f "delims=" %%v in ('"%PY%" --version') do echo        OK %%v

:venv
:: ── 2. Programmumgebung + Pakete ─────────────────────────────
echo.
echo  [2/5] Programmumgebung und Pakete ^(1-3 Minuten^)...
if exist ".venv\Scripts\python.exe" (
    ".venv\Scripts\python.exe" -c "import sys; sys.exit(0 if sys.version_info[:2]==(3,12) else 1)" >nul 2>&1 || rmdir /s /q .venv
)
if not exist ".venv\Scripts\python.exe" (
    "%PY%" -m venv .venv || goto :abbruch
)
".venv\Scripts\python.exe" -m pip install --upgrade pip --quiet --disable-pip-version-check
".venv\Scripts\python.exe" -m pip install --only-binary=:all: -r requirements.txt -c installer\constraints.txt --quiet --disable-pip-version-check || (
    echo  X Paketinstallation fehlgeschlagen ^(siehe Meldungen oben^).
    goto :abbruch
)
".venv\Scripts\python.exe" -c "import flask, lxml, qrcode, cryptography, pdfplumber, reportlab, pikepdf, waitress" || (
    echo  X Pakete unvollstaendig.
    goto :abbruch
)
echo        OK alle Pakete installiert

:: ── 3. Java fuer KoSIT ───────────────────────────────────────
echo.
echo  [3/5] Java fuer den KoSIT-Validator ^(optional^)...
set "JAVA=%BASIS%\laufzeit\java\bin\java.exe"
if "%~1"=="--ohne-java" (
    echo        uebersprungen
    set "JAVA="
    goto :kosit
)
if not exist "%JAVA%" (
    echo        Lade Java-Laufzeit ^(ca. 45 MB^)...
    call :laden "%JRE_BASE%/%JRE_WIN_X64%" "%TMPDIR%\jre.zip" "%JRE_WIN_X64_SHA%" && (
        if exist laufzeit\java rmdir /s /q laufzeit\java
        powershell -NoProfile -Command "Expand-Archive -LiteralPath '%TMPDIR%\jre.zip' -DestinationPath '%TMPDIR%\jre' -Force"
        for /d %%d in ("%TMPDIR%\jre\*") do move "%%d" "%BASIS%\laufzeit\java" >nul
    )
)
if exist "%JAVA%" (
    echo        OK Java bereit
) else (
    echo        Hinweis: Java nicht verfuegbar - der eingebaute Pruefer wird genutzt
    set "JAVA="
)

:kosit
:: ── 4. KoSIT-Validator ───────────────────────────────────────
echo.
echo  [4/5] KoSIT-Validator ^(offizielle XRechnung-Pruefung^)...
if not defined JAVA (
    echo        ohne Java uebersprungen
    goto :abschluss
)
if exist "tools\kosit\validator.jar" if exist "tools\kosit\scenarios.xml" (
    echo        OK bereits vorhanden
    goto :abschluss
)
".venv\Scripts\python.exe" installer\kosit_laden.py >nul 2>&1
if exist "tools\kosit\scenarios.xml" (
    echo        OK KoSIT-Validator einsatzbereit
) else (
    if exist "tools\kosit\validator.jar" del /q "tools\kosit\validator.jar"
    echo        Hinweis: KoSIT konnte nicht geladen werden - spaeter erneut ausfuehren
)

:abschluss
:: ── 5. Abschluss ─────────────────────────────────────────────
echo.
echo  [5/5] Abschluss...
for %%d in (data\archiv data\export data\sent_mails data\test_mails data\logo data\documents) do if not exist %%d mkdir %%d
".venv\Scripts\python.exe" -c "import cii_generator, pdfa3, zugferd_writer, xrechnung_generator" || (
    echo  X Selbsttest fehlgeschlagen.
    goto :abbruch
)
echo OK Python %PY_VERSION% > .deps_installed
rmdir /s /q "%TMPDIR%" >nul 2>&1

echo.
echo  ════════════════════════════════════════════════════════
echo   OK Installation abgeschlossen
echo  ════════════════════════════════════════════════════════
echo.
echo   Starten: Doppelklick auf starten.bat
echo   Der Browser oeffnet sich auf http://localhost:5000
echo   28 Tage Testzeitraum - danach Lizenzcode unter Einstellungen.
echo.
if /i not "%~1"=="--still" pause
exit /b 0

:abbruch
rmdir /s /q "%TMPDIR%" >nul 2>&1
echo.
echo  Die Installation wurde nicht abgeschlossen.
if /i not "%~1"=="--still" pause
exit /b 1

:: ── Download mit SHA-256-Pruefung (3 Versuche) ──────────────
:laden
set "L_URL=%~1"
set "L_ZIEL=%~2"
set "L_SHA=%~3"
for /l %%n in (1,1,3) do (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol='Tls12';" ^
      "try { Invoke-WebRequest -Uri $env:L_URL -OutFile $env:L_ZIEL -UseBasicParsing } catch { exit 2 };" ^
      "if ((Get-FileHash -Algorithm SHA256 $env:L_ZIEL).Hash.ToLower() -ne $env:L_SHA.ToLower()) { Remove-Item $env:L_ZIEL; exit 3 }"
    if !ERRORLEVEL! EQU 0 exit /b 0
    echo        Download/Pruefsumme fehlgeschlagen ^(Versuch %%n^) - erneut...
)
exit /b 1
