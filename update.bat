@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion
title E-Rechnungssystem - Update

echo.
echo  ========================================================
echo   E-Rechnungssystem - Update
echo  ========================================================
echo.

REM Arbeitsverzeichnis = Speicherort dieser Datei
cd /d "%~dp0"
set INSTALL_DIR=%CD%

REM Pruefen ob dies ein gueltiger Installationsordner ist
if not exist "webapp.py" (
    echo  [FEHLER] Diese Datei muss im Installationsordner liegen.
    echo           Datei nicht gefunden: webapp.py
    echo           Aktueller Pfad: %INSTALL_DIR%
    echo.
    pause
    exit /b 1
)

echo  Installationsordner: %INSTALL_DIR%
echo.

REM Zeitstempel fuer Backup
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set LDT=%%I
set TIMESTAMP=%LDT:~0,4%-%LDT:~4,2%%LDT:~6,2%-%LDT:~8,2%%LDT:~10,2%
set BACKUP_DIR=%INSTALL_DIR%\backup\backup-%TIMESTAMP%

echo  [1/5] Sichere Ihre Daten...
if exist "data" (
    mkdir "%BACKUP_DIR%" 2>nul
    xcopy /E /I /Q /Y "data" "%BACKUP_DIR%\data" >nul
    echo        Sicherung erstellt: %BACKUP_DIR%
) else (
    echo        Keine Daten zu sichern (Erstinstallation).
)
if exist "lizenz_data" (
    xcopy /E /I /Q /Y "lizenz_data" "%BACKUP_DIR%\lizenz_data" >nul
)
echo.

echo  [2/5] Lade aktuelle Version von GitHub...
set UPDATE_ZIP=%TEMP%\erechnung-update.zip
set UPDATE_DIR=%TEMP%\erechnung-update-extract

if exist "%UPDATE_ZIP%" del /q "%UPDATE_ZIP%"
if exist "%UPDATE_DIR%" rmdir /s /q "%UPDATE_DIR%"

powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'https://github.com/erechnung-b2b/install/archive/refs/heads/main.zip' -OutFile '%UPDATE_ZIP%' -UseBasicParsing } catch { exit 1 }"
if errorlevel 1 (
    echo        [FEHLER] Download fehlgeschlagen. Internetverbindung pruefen.
    pause
    exit /b 1
)
echo        Download abgeschlossen.
echo.

echo  [3/5] Entpacke Update...
powershell -NoProfile -Command "Expand-Archive -Path '%UPDATE_ZIP%' -DestinationPath '%UPDATE_DIR%' -Force"
if errorlevel 1 (
    echo        [FEHLER] Entpacken fehlgeschlagen.
    pause
    exit /b 1
)

REM Quellordner finden (install-main\erechnung-komplett\erechnung ODER install-main\erechnung)
set SRC=%UPDATE_DIR%\install-main\erechnung-komplett\erechnung
if not exist "%SRC%\webapp.py" set SRC=%UPDATE_DIR%\install-main\erechnung
if not exist "%SRC%\webapp.py" (
    echo        [FEHLER] Quelldateien im Download nicht gefunden.
    pause
    exit /b 1
)
echo        Entpackt.
echo.

echo  [4/5] Kopiere neue Programmdateien...
for %%F in ("%SRC%\*.py") do copy /Y "%%F" "%INSTALL_DIR%\" >nul
for %%F in ("%SRC%\*.bat") do (
    if /i not "%%~nxF"=="update.bat" copy /Y "%%F" "%INSTALL_DIR%\" >nul
)
if exist "%SRC%\requirements.txt" copy /Y "%SRC%\requirements.txt" "%INSTALL_DIR%\" >nul
if exist "%SRC%\erechnung.spec" copy /Y "%SRC%\erechnung.spec" "%INSTALL_DIR%\" >nul

if exist "%SRC%\static" (
    xcopy /E /I /Q /Y "%SRC%\static" "%INSTALL_DIR%\static" >nul
)
if exist "%SRC%\docs" (
    xcopy /E /I /Q /Y "%SRC%\docs" "%INSTALL_DIR%\docs" >nul
)
echo        Alle Dateien aktualisiert.
echo.

echo  [5/5] Raeume auf...
del /q "%UPDATE_ZIP%" 2>nul
rmdir /s /q "%UPDATE_DIR%" 2>nul
echo        Fertig.
echo.

echo  ========================================================
echo   Update erfolgreich abgeschlossen!
echo  ========================================================
echo.
echo   Ihre Daten wurden gesichert unter:
echo   %BACKUP_DIR%
echo.
echo   Zum Starten doppelklicken Sie auf: starten.bat
echo.
pause
