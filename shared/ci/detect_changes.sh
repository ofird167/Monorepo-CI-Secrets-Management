#!/bin/bash
# Detects changed service folders relative to a Git reference (defaulting to HEAD~1).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."
LOGGER="$SCRIPT_DIR/logger.sh"

chmod +x "$LOGGER"

# Base reference default
BASE_REF=${1:-"HEAD~1"}

# Case 1: Not a git repo
if ! git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  "$LOGGER" "WARN" "Not in a Git worktree. Defaulting to all services."
  echo "user-service transaction-service notification-service"
  exit 0
fi

# Case 2: No commits in repo
if ! git -C "$ROOT_DIR" rev-parse --quiet --verify HEAD >/dev/null 2>&1; then
  "$LOGGER" "WARN" "No commits found in repository. Defaulting to all services."
  echo "user-service transaction-service notification-service"
  exit 0
fi

# Case 3: Verify the BASE_REF exists. If not, try HEAD~1, or default to all services.
if ! git -C "$ROOT_DIR" rev-parse --quiet --verify "$BASE_REF" >/dev/null 2>&1; then
  if git -C "$ROOT_DIR" rev-parse --quiet --verify HEAD~1 >/dev/null 2>&1; then
    BASE_REF="HEAD~1"
  else
    "$LOGGER" "INFO" "Single commit repository. Defaulting to all services."
    echo "user-service transaction-service notification-service"
    exit 0
  fi
fi

"$LOGGER" "INFO" "Analyzing changes since reference: $BASE_REF"

# List files modified
CHANGED_FILES=$(git -C "$ROOT_DIR" diff --name-only "$BASE_REF" HEAD)

SERVICES=()
if echo "$CHANGED_FILES" | grep -q "^user-service/"; then
  SERVICES+=("user-service")
fi
if echo "$CHANGED_FILES" | grep -q "^transaction-service/"; then
  SERVICES+=("transaction-service")
fi
if echo "$CHANGED_FILES" | grep -q "^notification-service/"; then
  SERVICES+=("notification-service")
fi

# If modifications are found in shared configurations or CI scripts, run all services.
if echo "$CHANGED_FILES" | grep -qv -e "^user-service/" -e "^transaction-service/" -e "^notification-service/" -e "^log/" -e "^secret/" -e "^.gitignore"; then
  "$LOGGER" "INFO" "Root level or CI shared changes detected. Building all services."
  echo "user-service transaction-service notification-service"
  exit 0
fi

if [ ${#SERVICES[@]} -eq 0 ]; then
  "$LOGGER" "INFO" "No microservice changes detected."
  echo ""
else
  "$LOGGER" "INFO" "Detected changed services: ${SERVICES[*]}"
  echo "${SERVICES[*]}"
fi
