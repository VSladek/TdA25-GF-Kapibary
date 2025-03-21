#!/bin/sh

if [ "$1" = "dev" ]; then
  echo "Starting backend in development mode"
  source .venv/bin/activate

  python3 manage.py runserver 127.0.0.1:$BACKEND_PORT
elif [ "$1" = "prod" ]; then
  echo "Starting backend in production mode"

  uvicorn backend.asgi:application --host 0.0.0.0 --port $BACKEND_PORT --workers $BACKEND_WORKERS
elif [ "$1" = "setup-prod" ]; then
  echo "Setting up backend for production"

  python3 -m venv /opt/venv
  source .venv/bin/activate
  #source /opt/venv/bin/activate
  python3 -m pip install --upgrade pip
  pip install -r requirements.txt

  export DJANGO_DEBUG=False
  python3 manage.py check --deploy

  touch db.sqlite3
  python3 manage.py makemigrations
  python3 manage.py migrate
elif [ "$1" = "setup-dev" ]; then
  echo "Setting up backend for development"

  python3 -m venv .venv
  source .venv/bin/activate

  # install requirements
  pip install -r requirements.txt

  # create db
  rm db.sqlite3
  touch db.sqlite3
  python3 manage.py makemigrations
  python3 manage.py migrate
else
  echo "Unknown backend environment: $1"
  exit 1
fi

