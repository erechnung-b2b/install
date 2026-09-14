@echo off
chcp 65001 >nul 2>&1
setlocal EnableExtensions
title E-Rechnungssystem - Update
cd /d "%~dp0"
set "BASIS=%CD%"
if not exist "webapp.py" (
    echo  X Bitte im Installationsordner ausfuehren.
    pause
    exit /b 1
)
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd-HHmm"') do set "STAND=%%i"
set "TMPDIR=%TEMP%\erechnung-update-%RANDOM%"
mkdir "%TMPDIR%" >nul 2>&1

echo.
echo  [1/4] Sichere Ihre Daten...
if exist data (
    xcopy /E /I /Q /Y data "backup\backup-%STAND%\data" >nul
    echo        OK backup\backup-%STAND%
)

echo  [2/4] Lade aktuelle Version...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ProgressPreference='SilentlyContinue'; [Net.ServicePointManager]::SecurityProtocol='Tls12';" ^
  "try { Invoke-WebRequest 'https://github.com/erechnung-b2b/install/archive/refs/heads/main.zip' -OutFile '%TMPDIR%\update.zip' -UseBasicParsing;" ^
  "Expand-Archive -LiteralPath '%TMPDIR%\update.zip' -DestinationPath '%TMPDIR%\neu' -Force } catch { exit 1 }"
if errorlevel 1 (
    echo  X Download fehlgeschlagen - Internetverbindung pruefen.
    goto :ende_fehler
)
set "SRC="
for /d %%d in ("%TMPDIR%\neu\*") do if exist "%%d\webapp.py" set "SRC=%%d"
if not defined SRC (
    echo  X Download unvollstaendig.
    goto :ende_fehler
)

echo  [3/4] Ersetze Programmdateien...
robocopy "%SRC%" "%BASIS%" /E /NFL /NDL /NJH /NJS /NP /XD data laufzeit .venv backup tools /XF .deps_installed >nul
if errorlevel 8 (
    echo  X Kopieren fehlgeschlagen.
    goto :ende_fehler
)
echo        OK aktualisiert

echo  [4/4] Aktualisiere Pakete...
call erstinstallation.bat --still || goto :ende_fehler
rmdir /s /q "%TMPDIR%" >nul 2>&1
echo.
echo  OK Update abgeschlossen. Ihre Daten liegen zusaetzlich unter backup\backup-%STAND%
echo.
pause
exit /b 0

:ende_fehler
rmdir /s /q "%TMPDIR%" >nul 2>&1
pause
exit /b 1
