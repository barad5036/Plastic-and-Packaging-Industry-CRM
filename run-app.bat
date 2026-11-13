@echo off
title SalesHub CRM Application Launcher
echo ========================================================
echo               SalesHub CRM Web Application
echo ========================================================
echo.
echo Launching local server on http://localhost:8080 ...
echo.
start http://localhost:8080
cd /d "%~dp0build\web"
python -m http.server 8080
