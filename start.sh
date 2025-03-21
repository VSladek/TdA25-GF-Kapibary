#!/bin/sh

BACKEND_SCRIPT="start.sh"
BACKEND_PATH="./backend"
FRONTEND_SCRIPT="start.sh"
FRONTEND_PATH="./frontend"
NGINX_CONF="./nginx.conf"

SUPPORTED_ENVIRONMENTS="dev prod setup-dev setup-prod"

# Default frontend port
if [ -z "$FRONTEND_PORT" ]; then
  export FRONTEND_PORT=3000
fi

if [ -z $BACKEND_PORT ]; then
  export BACKEND_PORT=2568
fi

if [ -z $HTTP_PORT ]; then
  export HTTP_PORT=80
fi

if [ -z $HTTPS_PORT ]; then
  export HTTPS_PORT=443
fi


# Aliases: commands separated by ;
ALIASES="sdev:setup-dev dev;prod-env:setup-prod prod"

get_alias() {
  echo "$ALIASES" | tr ';' '\n' | while IFS=':' read -r alias target; do
    if [ "$alias" = "$1" ]; then
      echo "$target"
      return 0
    fi
  done
}

cleanup() {
  echo "Cleaning up processes..."
  if [ -n "$BACKEND_PID" ]; then
    kill "$BACKEND_PID" 2>/dev/null || echo "Failed to kill backend process"
    pkill python3
  fi
  if [ -n "$FRONTEND_PID" ]; then
    kill "$FRONTEND_PID" 2>/dev/null || echo "Failed to kill frontend process"
  fi
   if nginx -c "$NGINX_CONF" -s stop 2>/dev/null; then
    echo "NGINX stopped successfully."
  else
    echo "Failed to stop NGINX. Attempting to terminate forcefully..."
    pkill -f nginx && echo "NGINX forcefully stopped." || echo "NGINX was not running."
  fi
}

start_nginx() {
  echo "Starting NGINX..."

  mkdir -p /tmp/nginx/{client-body,fastcgi,proxy,scgi,uwsgi}
  mkdir -p /tmp/nginx/logs
  chown -R nginx:nginx /tmp/nginx
  chmod -R 750 /tmp/nginx

  # Define SSL placeholders
  SSL_LISTEN=""
  SSL_CONFIG=""

  # Check if SSL certificate and key exist
  if [ -f "/etc/ssl/certs/certificate.crt" ] && [ -f "/etc/ssl/private/certificate.key" ]; then
    echo "SSL certificates found, enabling SSL..."
    SSL_LISTEN="listen ${HTTPS_PORT} ssl;"
    SSL_CONFIG="
    ssl_certificate /etc/ssl/certs/certificate.crt;
    ssl_certificate_key /etc/ssl/private/certificate.key;
    "
  else
    echo "No SSL certificates found, starting without SSL..."
  fi

  # Check if the NGINX_CONF variable is set and points to a valid template file
  if [ -z "$NGINX_CONF" ]; then
    echo "Error: NGINX_CONF environment variable is not set."
    exit 1
  fi

  if [ -f "$NGINX_CONF" ]; then
    # Create a temporary directory for the generated config
    TEMP_CONF=$(mktemp /tmp/nginx.conf.XXXXXX)

    # Substitute environment variables into the temporary configuration file
    echo "Substituting environment variables in $NGINX_CONF..."
    envsubst '${BACKEND_PORT} ${FRONTEND_PORT} ${HTTP_PORT} ${SSL_LISTEN} ${SSL_CONFIG}' < "$NGINX_CONF" > "$TEMP_CONF"

    # Start NGINX with the generated configuration
    nginx -c "$TEMP_CONF"
    echo "NGINX started with configuration: $TEMP_CONF"
  else
    echo "Error: NGINX configuration template not found at $NGINX_CONF"
    exit 1
  fi
}

start() {
  for arg in "$@"; do
    echo "Starting NGINX server..."
    start_nginx

    echo "Starting backend with argument: $arg"
    if [ -x "$BACKEND_PATH/$BACKEND_SCRIPT" ]; then
      cd "$BACKEND_PATH" || exit 1
      ./"$BACKEND_SCRIPT" "$arg" &
      BACKEND_PID=$!
      echo "Backend started with PID: $BACKEND_PID"
      cd - > /dev/null || exit 1 # Return to the previous directory
    else
      echo "Backend script not found or not executable: $BACKEND_PATH/$BACKEND_SCRIPT"
      exit 1
    fi

    echo "Starting frontend with argument: $arg"
    if [ -x "$FRONTEND_PATH/$FRONTEND_SCRIPT" ]; then
      cd "$FRONTEND_PATH" || exit 1
      ./"$FRONTEND_SCRIPT" "$arg" &
      FRONTEND_PID=$!
      echo "Frontend started with PID: $FRONTEND_PID"
      cd - > /dev/null || exit 1 # Return to the previous directory
    else
      echo "Frontend script not found or not executable: $FRONTEND_PATH/$FRONTEND_SCRIPT"
      exit 1
    fi

    # Wait for both processes to finish before continuing to the next argument
    echo "Processes started for argument '$arg': backend (PID $BACKEND_PID), frontend (PID $FRONTEND_PID)"
    wait "$BACKEND_PID" 
    wait "$FRONTEND_PID"
  done
}

check_env() {
  echo "$SUPPORTED_ENVIRONMENTS" | grep -qw "$1"
}

# Trap signals for cleanup
trap cleanup INT TERM

# Main script logic
if [ $# -eq 0 ]; then
  echo "No arguments supplied"
  exit 1
fi

for param in "$@"; do
  case "$param" in
    -h|--help)
      echo "Usage: start.sh [environment|alias]"
      echo "Supported environments: $SUPPORTED_ENVIRONMENTS"
      echo "Aliases: $ALIASES"
      echo "Runs backend: $BACKEND_SCRIPT in $BACKEND_PATH and frontend: $FRONTEND_SCRIPT in $FRONTEND_PATH"
      exit 0
      ;;
    *)
      alias=$(get_alias "$param")
      if [ -n "$alias" ]; then
        echo "Resolved alias '$param' to '$alias'"
        # Expand the alias into multiple arguments
        set -- $alias
      fi

      for env in "$@"; do
        if ! check_env "$env"; then
          echo "Environment '$env' is not supported"
          exit 1
        fi
      done

      start "$@"
      break
      ;;
  esac
done
