@echo off
chcp 65001 >nul
cd /d "%~dp0"
"%~dp0runtime\node.exe" "%~dp0launch-demo.mjs"
if errorlevel 1 pause
