#!/bin/bash
# Lints modified microservices in the monorepo.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."
LOGGER="$SCRIPT_DIR/logger.sh"
DETECT_CHANGES="$SCRIPT_DIR/detect_changes.sh"

chmod +x "$LOGGER"
chmod +x "$DETECT_CHANGES"

# Services to lint are passed as arguments. If none, auto-detect them.
SERVICES="$*"
if [ -z "$SERVICES" ]; then
  SERVICES=$("$DETECT_CHANGES" "HEAD~1")
fi

if [ -z "$SERVICES" ]; then
  "$LOGGER" "INFO" "Lint Stage: No changed services to lint."
  exit 0
fi

for SERVICE in $SERVICES; do
  "$LOGGER" "INFO" "Running linting for $SERVICE..."
  
  case "$SERVICE" in
    "user-service")
      cd "$ROOT_DIR/user-service"
      if [ ! -d "node_modules" ]; then
        "$LOGGER" "INFO" "node_modules not found. Installing dev dependencies..."
        npm ci
      fi
      "$LOGGER" "INFO" "Running ESLint..."
      npm run lint
      ;;
      
    "transaction-service")
      cd "$ROOT_DIR/transaction-service"
      if ! command -v flake8 >/dev/null 2>&1; then
        "$LOGGER" "WARN" "flake8 not found globally. Running via python module check..."
        python3 -m flake8 . || {
          "$LOGGER" "INFO" "Installing flake8 in user space..."
          pip3 install --user flake8
          python3 -m flake8 .
        }
      else
        flake8 .
      fi
      ;;
      
    "notification-service")
      cd "$ROOT_DIR/notification-service"
      "$LOGGER" "INFO" "Running go fmt check..."
      go fmt ./...
      "$LOGGER" "INFO" "Running go vet..."
      go vet ./...
      ;;
      
    *)
      "$LOGGER" "ERROR" "Unknown service: $SERVICE"
      exit 1
      ;;
  esac
done

"$LOGGER" "SUCCESS" "Lint stage finished successfully."
