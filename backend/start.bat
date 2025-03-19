@echo off
setlocal enabledelayedexpansion

REM Default values for environment variables
if "%BACKEND_PORT%"=="" set BACKEND_PORT=2568
if "%BACKEND_WORKERS%"=="" set BACKEND_WORKERS=2

REM Check the provided environment
if "%1"=="" (
    echo No environment provided.
    exit /b 1
)

if "%1"=="dev" (
    echo Starting backend in development mode
    python manage.py runserver 127.0.0.1:%BACKEND_PORT%
    exit /b 0
) else if "%1"=="prod" (
    echo Starting backend in production mode
    gunicorn backend.wsgi:application --bind 0.0.0.0:%BACKEND_PORT% --workers %BACKEND_WORKERS%
    exit /b 0
) else if "%1"=="setup-prod" (
    echo Setting up backend for production

    python -m venv %~dp0venv
    call %~dp0venv\Scripts\activate

    python -m pip install --upgrade pip
    pip install -r requirements.txt

    set DJANGO_DEBUG=False
    python manage.py check --deploy

    if not exist db.sqlite3 type nul > db.sqlite3
    python manage.py makemigrations
    python manage.py migrate
    exit /b 0
) else if "%1"=="setup-dev" (
    echo Setting up backend for development

    python -m venv .venv
    call .venv\Scripts\activate

    pip install -r requirements.txt

    if exist db.sqlite3 del db.sqlite3
    type nul > db.sqlite3
    python manage.py makemigrations
    python manage.py migrate
    exit /b 0
) else (
    echo Unknown backend environment: %1
    exit /b 1
)
