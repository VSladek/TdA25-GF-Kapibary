#!/bin/sh

BACKEND_SCRIPT="start.sh"
BACKEND_PATH="./backend"
FRONTEND_SCRIPT="start.sh"
FRONTEND_PATH="./frontend"

SUPPORTED_ENVIRONMENTS="dev prod setup-dev setup-prod"

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
  fi
  if [ -n "$FRONTEND_PID" ]; then
    kill "$FRONTEND_PID" 2>/dev/null || echo "Failed to kill frontend process"
  fi
}

start() {
  for arg in "$@"; do
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
    wait "$BACKEND_PID" "$FRONTEND_PID"
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

