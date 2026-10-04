@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Create-Review-Shortcuts.ps1"
if errorlevel 1 pause
