@echo off
setlocal enabledelayedexpansion

:: Paths to backend and frontend scripts
set BACKEND_SCRIPT=start.bat
set BACKEND_PATH=backend
set FRONTEND_SCRIPT=start.bat
set FRONTEND_PATH=frontend

:: Supported environments and aliases
set SUPPORTED_ENVIRONMENTS=dev prod setup-dev setup-prod
set ALIASES=sdev:setup-dev dev;prod-env:setup-prod prod

:: Resolve alias
:resolve_alias
for %%A in (%ALIASES%) do (
    for /f "tokens=1,2 delims=:" %%B in ("%%A") do (
        if /I "%%B"=="%1" (
            set RESOLVED_ALIAS=%%C
            goto :eof
        )
    )
)
set RESOLVED_ALIAS=
goto :eof

:: Cleanup function
:cleanup
echo Cleaning up processes...
if defined BACKEND_PID taskkill /PID !BACKEND_PID! /F >nul 2>&1
if defined FRONTEND_PID taskkill /PID !FRONTEND_PID! /F >nul 2>&1
exit /b

:: Start function
:start_environment
echo Starting backend with argument: %1
pushd %BACKEND_PATH% || exit /b 1
call %BACKEND_SCRIPT% %1
set BACKEND_PID=!ERRORLEVEL!
popd

echo Starting frontend with argument: %1
pushd %FRONTEND_PATH% || exit /b 1
call %FRONTEND_SCRIPT% %1
set FRONTEND_PID=!ERRORLEVEL!
popd

echo Processes started for argument '%1': backend (PID !BACKEND_PID!), frontend (PID !FRONTEND_PID!)
goto :eof

:: Main script logic
if "%~1"=="" (
    echo No arguments supplied
    exit /b 1
)

:: Trap signals (Ctrl+C)
for %%A in (INT TERM) do (
    call :cleanup
)

set RESOLVED_ARGS=
for %%A in (%*) do (
    call :resolve_alias %%A
    if defined RESOLVED_ALIAS (
        set RESOLVED_ARGS=!RESOLVED_ARGS! !RESOLVED_ALIAS!
    ) else (
        set RESOLVED_ARGS=!RESOLVED_ARGS! %%A
    )
)

:: Start environments
for %%A in (!RESOLVED_ARGS!) do (
    echo Checking environment %%A...
    echo %SUPPORTED_ENVIRONMENTS% | findstr /I "%%A" >nul
    if errorlevel 1 (
        echo Environment '%%A' is not supported
        exit /b 1
    )
    call :start_environment %%A
)

goto :eof
