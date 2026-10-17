@echo off
setlocal
cd /d "%~dp0"

rem Start the dashboard server only if it isn't already listening on 8787
netstat -ano | findstr ":8787" | findstr "LISTENING" >nul
if errorlevel 1 (
    start "Web Task Server" /min node server.js
    timeout /t 2 /nobreak >nul
)

start "" "http://127.0.0.1:8787/"
