@echo off
chcp 65001 >nul 2>&1
title E-Rechnungssystem
cd /d "%~dp0"

:: Erstinstallation fehlt oder unvollstaendig -> automatisch nachholen
if not exist ".deps_installed" goto :einrichten
if not exist ".venv\Scripts\python.exe" goto :einrichten
".venv\Scripts\python.exe" -c "import flask, pikepdf" >nul 2>&1 || goto :einrichten
goto :start

:einrichten
echo.
echo  Erstmalige Einrichtung - das dauert einige Minuten...
echo.
call erstinstallation.bat --still
if errorlevel 1 (
    pause
    exit /b 1
)

:start
:: Java aus dem Programmordner fuer den KoSIT-Validator
if exist "laufzeit\java\bin\java.exe" (
    set "JAVA_HOME=%CD%\laufzeit\java"
    set "PATH=%CD%\laufzeit\java\bin;%PATH%"
)
echo.
echo  ════════════════════════════════════════════════════════
echo   E-Rechnungssystem  -  XRechnung / ZUGFeRD / EN 16931
echo  ════════════════════════════════════════════════════════
echo   Der Browser oeffnet sich automatisch.
echo   Zum Beenden: Strg+C oder dieses Fenster schliessen.
echo.
".venv\Scripts\python.exe" run.py %*
pause
