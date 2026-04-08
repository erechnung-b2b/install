@echo off
title E-Rechnungssystem - Build
echo.
echo  ========================================================
echo   E-Rechnungssystem - Windows Build
echo  ========================================================
echo.

REM Pruefe Python
python --version >nul 2>&1
if errorlevel 1 (
    echo  FEHLER: Python nicht gefunden!
    echo  Bitte Python 3.10+ installieren: https://www.python.org/downloads/
    echo  WICHTIG: "Add Python to PATH" anhaken!
    pause
    exit /b 1
)

echo  [1/4] Python gefunden:
python --version
echo.

REM Abhaengigkeiten installieren
echo  [2/4] Installiere Abhaengigkeiten...
pip install -r requirements.txt pyinstaller --quiet
if errorlevel 1 (
    echo  FEHLER bei der Installation der Abhaengigkeiten
    pause
    exit /b 1
)
echo         OK
echo.

REM Teste ob die Anwendung startet
echo  [3/4] Pruefe Anwendung...
python -c "from webapp import app; print('         OK: Alle Module geladen')"
if errorlevel 1 (
    echo  FEHLER beim Laden der Module
    pause
    exit /b 1
)
echo.

REM PyInstaller Build
echo  [4/4] Erstelle Standalone-Anwendung...
echo         Das kann 1-3 Minuten dauern...
echo.
pyinstaller erechnung.spec --noconfirm --clean
if errorlevel 1 (
    echo.
    echo  FEHLER: Build fehlgeschlagen!
    echo  Moegliche Ursachen:
    echo    - Antivirus blockiert PyInstaller
    echo    - Schreibrechte fehlen
    pause
    exit /b 1
)

REM Datenverzeichnisse erstellen
mkdir "dist\erechnung\data\archiv" 2>nul
mkdir "dist\erechnung\data\export" 2>nul
mkdir "dist\erechnung\data\logo" 2>nul

echo.
echo  ========================================================
echo   Build erfolgreich!
echo  ========================================================
echo.
echo   Anwendung liegt in: dist\erechnung\
echo   Starten mit:        dist\erechnung\E-Rechnungssystem.exe
echo.
echo   Diesen Ordner koennen Sie auf beliebige Windows-PCs
echo   kopieren - Python ist NICHT mehr noetig.
echo.
pause
