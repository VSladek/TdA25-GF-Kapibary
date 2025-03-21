@echo off

set "BACKEND_SCRIPT=start.bat"
set "BACKEND_PATH=backend"
set "FRONTEND_SCRIPT=start.bat"
set "FRONTEND_PATH=frontend"
set "NGINX_CONF=nginx.conf"

set "SUPPORTED_ENVIRONMENTS=dev prod setup-dev setup-prod"

rem Default ports
if "%FRONTEND_PORT%"=="" set FRONTEND_PORT=3000
if "%BACKEND_PORT%"=="" set BACKEND_PORT=2568
if "%HTTP_PORT%"=="" set HTTP_PORT=80
if "%HTTPS_PORT%"=="" set HTTPS_PORT=443

set "ALIASES=sdev:setup-dev;dev;prod-env:setup-prod;prod"

:main
if "%1"=="" (
    echo No arguments supplied.
    exit /B 1
)

for %%p in (%*) do (
    set "ALIAS="
    for %%a in (%ALIASES%) do (
        for /F "tokens=1,2 delims=:" %%x in ("%%a") do if "%%x"=="%%p" set "ALIAS=%%y"
    )

    if not "%ALIAS%"=="" (
        echo Resolved alias "%%p" to "%%ALIAS%".
        call :start %%ALIAS%
    ) else (
        call :check_env %%p || exit /B 1
        call :start %%p
    )
)

:cleanup
echo Cleaning up processes...
if not "%BACKEND_PID%"=="" taskkill /PID %BACKEND_PID% /F 2>NUL && echo Backend process terminated.
if not "%FRONTEND_PID%"=="" taskkill /PID %FRONTEND_PID% /F 2>NUL && echo Frontend process terminated.

rem Stop NGINX
nginx -s stop 2>NUL && echo NGINX stopped successfully. || (
    echo Failed to stop NGINX. Attempting forceful termination...
    taskkill /IM nginx.exe /F 2>NUL && echo NGINX forcefully stopped. || echo NGINX was not running.
)
exit /B

:start_nginx
echo Starting NGINX...
if exist "%NGINX_CONF%" (
    set "TEMP_CONF=%TEMP%\nginx_temp.conf"
    rem Replace variables in the NGINX configuration (requires a tool like envsubst or manual replacement)
    echo Substituting variables in %NGINX_CONF%...
    rem Replace logic (requires a script or tool to substitute placeholders in the file)

    nginx -c "%TEMP_CONF%"
    if %ERRORLEVEL%==0 (
        echo NGINX started with configuration: %TEMP_CONF%
    ) else (
        echo Failed to start NGINX.
        exit /B 1
    )
) else (
    echo Error: NGINX configuration template not found at %NGINX_CONF%.
    exit /B 1
)
exit /B

:start
echo Starting services...
call :start_nginx

rem Start Backend
if exist "%BACKEND_PATH%\%BACKEND_SCRIPT%" (
    pushd "%BACKEND_PATH%"
    start /B cmd /C "%BACKEND_SCRIPT% %1" && set /A BACKEND_PID=%ERRORLEVEL%
    popd
    echo Backend started with PID: %BACKEND_PID%
) else (
    echo Backend script not found or not executable: %BACKEND_PATH%\%BACKEND_SCRIPT%
    exit /B 1
)

rem Start Frontend
if exist "%FRONTEND_PATH%\%FRONTEND_SCRIPT%" (
    pushd "%FRONTEND_PATH%"
    start /B cmd /C "%FRONTEND_SCRIPT% %1" && set /A FRONTEND_PID=%ERRORLEVEL%
    popd
    echo Frontend started with PID: %FRONTEND_PID%
) else (
    echo Frontend script not found or not executable: %FRONTEND_PATH%\%FRONTEND_SCRIPT%
    exit /B 1
)

exit /B

:check_env
for %%e in (%SUPPORTED_ENVIRONMENTS%) do (
    if "%%e"=="%1" exit /B 0
)
echo Environment "%1" is not supported.
exit /B 1
