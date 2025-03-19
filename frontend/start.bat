@echo off

:: Default frontend port
if "%FRONTEND_PORT%"=="" (
    set FRONTEND_PORT=80
)

if "%1"=="dev" (
    echo Starting frontend in development mode on port %FRONTEND_PORT%
    npm run dev -- --port %FRONTEND_PORT%
) else if "%1"=="prod" (
    echo Starting frontend in production mode on port %FRONTEND_PORT%
    npm start -- --port %FRONTEND_PORT%
) else if "%1"=="setup-prod" (
    echo Setting up frontend for production
    npm install
    npm run build
) else if "%1"=="setup-dev" (
    echo Setting up frontend for development
    npm install
) else (
    echo Unknown frontend environment: %1
    exit /b 1
)
