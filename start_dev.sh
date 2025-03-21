#!/bin/bash

# Set PORT environment variable
export HTTP_PORT=3000
export HTTPS_PORT=3001
export BACKEND_PORT=2568
export FRONTEND_PORT=3002

./start.sh dev
