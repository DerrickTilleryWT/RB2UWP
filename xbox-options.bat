@echo off
rem Picks extra settings for the game on the Xbox (graphics tests) and
rem restarts it with them. No rebuild needed. deploy-xbox.bat keeps using
rem the last choice; pick 0 to go back to normal.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy-xbox.ps1" -Options
echo.
pause
