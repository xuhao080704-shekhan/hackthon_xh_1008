@echo off
chcp 65001 >nul
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0app\scripts\configure-ai.ps1" -ConfigRoot "%~dp0."
if errorlevel 1 pause
