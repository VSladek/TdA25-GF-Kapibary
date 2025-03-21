#!/bin/sh

if [ "$1" = "dev" ]; then
  echo "Starting frontend in development mode on port $FRONTEND_PORT"

  npm run dev -- --port $FRONTEND_PORT
elif [ "$1" = "prod" ]; then
  echo "Starting frontend in production mode on port $FRONTEND_PORT"

  npm start -- --port $FRONTEND_PORT
elif [ "$1" = "setup-prod" ]; then
  echo "Setting up frontend for production"

  npm install -f
  npm run build
elif [ "$1" = "setup-dev" ]; then
  echo "Setting up frontend for development"

  npm install -f
else
  echo "Unknown frontend environment: $1"
  exit 1
fi
