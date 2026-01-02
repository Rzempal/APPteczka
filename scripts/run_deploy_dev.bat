@echo off
REM Skrypt uruchamiający deploy_apk.ps1 dla kanału INTERNAL (DEV)
REM Kliknij 2x ten plik, aby zbudować i wysłać wersję deweloperską

echo Uruchamianie deploymentu APK (Internal/DEV)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0deploy_apk.ps1' -Channel internal -SkipUpload:$false"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Wystąpił błąd podczas uruchamiania skryptu PowerShell.
    pause
)
