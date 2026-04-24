@echo off
chcp 65001 >nul 2>&1
title E-Rechnungssystem v2.0 - EBRK UG
color 0F

cd /d "%~dp0"

:: ── Erstinstallation? ──
if not exist ".deps_installed" (
    echo.
    echo  Erstmalige Einrichtung erkannt...
    echo.
    if exist "erstinstallation.bat" (
        call erstinstallation.bat
        if %ERRORLEVEL% NEQ 0 exit /b 1
    ) else (
        echo  ✗ erstinstallation.bat nicht gefunden!
        pause
        exit /b 1
    )
)

:: ── Python prüfen ──
where python >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  ✗ Python nicht gefunden!
    echo  Bitte erstinstallation.bat erneut ausfuehren.
    echo.
    del .deps_installed >nul 2>&1
    pause
    exit /b 1
)

:: ── venv prüfen + aktivieren ──
if not exist ".venv\Scripts\activate.bat" (
    echo  .venv beschaedigt — erstelle neu...
    python -m venv .venv
)
call .venv\Scripts\activate.bat

:: ── Flask prüfen ──
python -c "import flask" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo  Pakete fehlen — installiere nach...
    pip install -r requirements.txt -q 2>nul
)

:: ── Starten ──
echo.
echo  ╔════════════════════════════════════════════════════════╗
echo  ║  E-Rechnungssystem v2.0 - EBRK UG                    ║
echo  ║  XRechnung / ZUGFeRD / EN 16931                       ║
echo  ╚════════════════════════════════════════════════════════╝
echo.
echo  Server startet auf http://localhost:5000
echo  Browser oeffnet sich automatisch.
echo  Zum Beenden: Strg+C oder Fenster schliessen.
echo  ────────────────────────────────────────────────────────
echo.

python run.py %1
