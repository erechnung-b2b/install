@echo off
title E-Rechnungssystem - GitHub Upload
echo.
echo  ========================================================
echo   E-Rechnungssystem - Upload zu GitHub
echo  ========================================================
echo.
echo   Ziel: https://github.com/erechnung-b2b/install
echo.

git --version >nul 2>&1
if errorlevel 1 (
    echo  Git nicht gefunden!
    echo  Bitte installieren: https://git-scm.com/download/win
    echo  Danach dieses Script erneut starten.
    pause
    exit /b 1
)

echo  Git gefunden:
git --version
echo.

if exist ".git" (
    echo  Repository existiert bereits. Aktualisiere...
    git add -A
    git commit -m "Aktualisierung %date% %time:~0,5%"
    git push
    echo.
    echo  Fertig!
    pause
    exit /b 0
)

echo  Initialisiere Git-Repository...
echo.
echo  HINWEIS: Du brauchst einen Personal Access Token von GitHub.
echo  Falls du noch keinen hast:
echo    1. https://github.com/settings/tokens/new
echo    2. Name: erechnung-push
echo    3. Haken bei: repo
echo    4. Generate token - Token kopieren
echo.

set /p GHTOKEN=GitHub Token eingeben: 

git init
git add -A
git commit -m "E-Rechnungssystem v1.0 mit RSA-Lizenzierung"
git branch -M main
git remote add origin https://erechnung-b2b:%GHTOKEN%@github.com/erechnung-b2b/install.git

echo.
echo  Lade hoch zu GitHub...
git push -u origin main

if errorlevel 1 (
    echo.
    echo  Push fehlgeschlagen. Moegliche Ursachen:
    echo    - Token falsch oder abgelaufen
    echo    - Repository existiert noch nicht auf GitHub
    echo    - Keine Internetverbindung
    echo.
    echo  Repository anlegen: https://github.com/new
    echo    Name: install
    echo    Owner: erechnung-b2b
    echo    Private Repository!
    echo.
    pause
    exit /b 1
)

echo.
echo  ========================================================
echo   Upload erfolgreich!
echo  ========================================================
echo.
echo   Repository: https://github.com/erechnung-b2b/install
echo.
pause
