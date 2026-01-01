@echo off
REM Skrypt uruchamiający deploy_apk.ps1 z obejściem polityki wykonywania skryptów
REM Kliknij 2x ten plik, aby uruchomić deployment

echo Uruchamianie deploymentu APK...
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0deploy_apk.ps1' -SkipUpload:$false"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Wystąpił błąd podczas uruchamiania skryptu PowerShell.
    pause
)
REM Skrypt PS1 ma własny "Exit-WithPause", więc tu nie musimy pauzować, chyba że PS w ogóle nie ruszył
