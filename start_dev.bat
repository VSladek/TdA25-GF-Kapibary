@echo off

:: Set PORT environment variables
set HTTP_PORT=3000
set HTTPS_PORT=3001
set BACKEND_PORT=2568
set FRONTEND_PORT=3002

:: Run start.bat with the dev argument
call start.bat dev
