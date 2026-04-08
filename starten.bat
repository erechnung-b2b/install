@echo off
title E-Rechnungssystem
echo.
echo  ========================================================
echo   E-Rechnungssystem
echo   XRechnung / ZUGFeRD / EN 16931
echo  ========================================================
echo.

python --version >nul 2>&1
if errorlevel 1 (
    echo  Python nicht gefunden!
    echo  Bitte Python 3.10+ installieren: https://www.python.org/downloads/
    echo  WICHTIG: "Add Python to PATH" anhaken!
    echo.
    pause
    exit /b 1
)

if not exist ".deps_installed" (
    echo  Erstmalige Einrichtung...
    pip install -r requirements.txt --quiet
    echo OK > .deps_installed
    echo  Abhaengigkeiten installiert.
    echo.
)

echo  Starte Server...
echo  Der Browser oeffnet sich gleich automatisch.
echo  Zum Beenden: Strg+C oder dieses Fenster schliessen.
echo.
python run.py %1
pause
