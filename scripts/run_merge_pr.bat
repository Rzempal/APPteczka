@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0merge_pr.ps1" %*
pause
