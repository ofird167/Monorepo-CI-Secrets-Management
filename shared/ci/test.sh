#!/bin/bash
# Runs tests for modified microservices in the monorepo.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."
LOGGER="$SCRIPT_DIR/logger.sh"
DETECT_CHANGES="$SCRIPT_DIR/detect_changes.sh"

chmod +x "$LOGGER"
chmod +x "$DETECT_CHANGES"

# Services to test are passed as arguments. If none, auto-detect them.
SERVICES="$*"
if [ -z "$SERVICES" ]; then
  SERVICES=$("$DETECT_CHANGES" "HEAD~1")
fi

if [ -z "$SERVICES" ]; then
  "$LOGGER" "INFO" "Test Stage: No changed services to test."
  exit 0
fi

for SERVICE in $SERVICES; do
  "$LOGGER" "INFO" "Running tests for $SERVICE..."
  
  case "$SERVICE" in
    "user-service")
      cd "$ROOT_DIR/user-service"
      if [ ! -d "node_modules" ]; then
        "$LOGGER" "INFO" "node_modules not found. Installing dependencies..."
        npm ci
      fi
      "$LOGGER" "INFO" "Running Jest tests..."
      npm run test
      ;;
      
    "transaction-service")
      cd "$ROOT_DIR/transaction-service"
      if ! command -v pytest >/dev/null 2>&1; then
        "$LOGGER" "WARN" "pytest not found globally. Running via python module check..."
        python3 -m pytest -v --junitxml=report.xml || {
          "$LOGGER" "INFO" "Installing pytest in user space..."
          pip3 install --user pytest
          python3 -m pytest -v --junitxml=report.xml
        }
      else
        pytest -v --junitxml=report.xml
      fi
      ;;
      
    "notification-service")
      cd "$ROOT_DIR/notification-service"
      "$LOGGER" "INFO" "Running Go unit tests with coverage..."
      go test -v -coverprofile=coverage.out ./...
      ;;
      
    *)
      "$LOGGER" "ERROR" "Unknown service: $SERVICE"
      exit 1
      ;;
  esac
done

"$LOGGER" "SUCCESS" "Test stage finished successfully."
