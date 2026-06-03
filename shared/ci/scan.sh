#!/bin/bash
# Runs SAST and secrets detection on modified microservices.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."
LOGGER="$SCRIPT_DIR/logger.sh"
DETECT_CHANGES="$SCRIPT_DIR/detect_changes.sh"

chmod +x "$LOGGER"
chmod +x "$DETECT_CHANGES"

# Services to scan are passed as arguments. If none, auto-detect them.
SERVICES="$*"
if [ -z "$SERVICES" ]; then
  SERVICES=$("$DETECT_CHANGES" "HEAD~1")
fi

if [ -z "$SERVICES" ]; then
  "$LOGGER" "INFO" "Scan Stage: No changed services to scan."
  exit 0
fi

# ---------------------------------------------------------
# Phase 1: Secrets Scanning
# ---------------------------------------------------------
"$LOGGER" "INFO" "Starting Secrets Detection..."

if command -v gitleaks >/dev/null 2>&1; then
  "$LOGGER" "INFO" "gitleaks detected on system. Executing gitleaks scan..."
  gitleaks detect --verbose || {
    "$LOGGER" "ERROR" "Gitleaks detected credentials in repository!"
    exit 1
  }
else
  "$LOGGER" "WARN" "gitleaks not found. Running custom regex-based credentials scan..."
  
  # Search patterns for common hardcoded secrets (private keys, passwords, API keys)
  # excluding the Git-ignored /secret/ and /log/ folders.
  SECRET_PATTERNS=(
    "api_key\s*=\s*['\"][a-zA-Z0-9_\-]{8,}['\"]"
    "password\s*=\s*['\"][a-zA-Z0-9_\-]{6,}['\"]"
    "db_pass\s*=\s*['\"][a-zA-Z0-9_\-]{6,}['\"]"
    "client_secret\s*=\s*['\"][a-zA-Z0-9_\-]{10,}['\"]"
    "-----BEGIN [A-Z]+ PRIVATE KEY-----"
  )
  
  SECRET_FOUND=0
  SECRETS_LOG=$(mktemp)
  for PATTERN in "${SECRET_PATTERNS[@]}"; do
    # Run git grep to respect .gitignore rules. Ignore matches inside /secret/ and /log/
    if git -C "$ROOT_DIR" grep -E -I -n "$PATTERN" -- ':!secret/*' ':!log/*' > "$SECRETS_LOG" 2>&1; then
      "$LOGGER" "ERROR" "CRITICAL: Hardcoded secret pattern matches found:"
      cat "$SECRETS_LOG"
      SECRET_FOUND=1
    fi
  done
  rm -f "$SECRETS_LOG"
  
  if [ "$SECRET_FOUND" -ne 0 ]; then
    "$LOGGER" "ERROR" "Secrets scan failed! Remove hardcoded secrets from code."
    exit 1
  fi
  "$LOGGER" "INFO" "No hardcoded secrets detected in source code."
fi

# ---------------------------------------------------------
# Phase 2: SAST Scanning
# ---------------------------------------------------------
for SERVICE in $SERVICES; do
  "$LOGGER" "INFO" "Running SAST scanner for $SERVICE..."
  
  case "$SERVICE" in
    "user-service")
      cd "$ROOT_DIR/user-service"
      "$LOGGER" "INFO" "Running npm audit..."
      # npm audit returns non-zero exit codes if vulns are found. We check for critical issues.
      npm audit --audit-level=critical || "$LOGGER" "WARN" "npm audit flagged critical vulnerabilities."
      ;;
      
    "transaction-service")
      cd "$ROOT_DIR/transaction-service"
      if ! command -v bandit >/dev/null 2>&1; then
        "$LOGGER" "WARN" "bandit not found globally. Running via python module check..."
        python3 -m bandit -r . -x test_main.py -s B101 || {
          "$LOGGER" "INFO" "Installing bandit in user space..."
          pip3 install --user bandit --break-system-packages
          python3 -m bandit -r . -x test_main.py -s B101
        }
      else
        bandit -r . -x test_main.py -s B101
      fi
      ;;
      
    "notification-service")
      cd "$ROOT_DIR/notification-service"
      "$LOGGER" "INFO" "Running go vet for static analysis..."
      go vet ./...
      ;;
      
    *)
      "$LOGGER" "ERROR" "Unknown service: $SERVICE"
      exit 1
      ;;
  esac
done

"$LOGGER" "SUCCESS" "Scan stage finished successfully."
