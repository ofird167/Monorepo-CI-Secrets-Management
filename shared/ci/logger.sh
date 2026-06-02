#!/bin/bash
# Local logging helper that writes events to log/logs.txt and displays them on stdout.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../../log"
LOG_FILE="$LOG_DIR/logs.txt"

# Ensure the log folder exists
mkdir -p "$LOG_DIR"

# Parse arguments
LEVEL=${1:-"INFO"}
shift
MESSAGE="$*"

# Ensure the level is capitalized
LEVEL=$(echo "$LEVEL" | tr '[:lower:]' '[:upper:]')

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Append to logs.txt
cat << EOF >> "$LOG_FILE"
[$TIMESTAMP] [$LEVEL] $MESSAGE
EOF

# Print to stdout for CI logs
echo "[$TIMESTAMP] [$LEVEL] $MESSAGE"
