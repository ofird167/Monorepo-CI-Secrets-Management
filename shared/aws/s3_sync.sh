#!/bin/bash
# Synchronizes the /secret/ directory with AWS S3.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/../.."
LOGGER="$SCRIPT_DIR/../ci/logger.sh"
BUCKET_NAME="${AWS_S3_BUCKET:-your-s3-bucket}"
SECRET_DIR="$ROOT_DIR/secret"

chmod +x "$LOGGER"

mkdir -p "$SECRET_DIR"

usage() {
  echo "Usage: $0 {upload|download|clean}"
  echo "  upload   : Sync local secrets to AWS S3 bucket: $BUCKET_NAME"
  echo "  download : Sync remote secrets from AWS S3 to local /secret"
  echo "  clean    : Empty all files inside AWS S3 bucket: $BUCKET_NAME"
  exit 1
}

ACTION="$1"

if [ -z "$ACTION" ]; then
  usage
fi

case "$ACTION" in
  "upload")
    "$LOGGER" "INFO" "Uploading local secrets from $SECRET_DIR to s3://$BUCKET_NAME/secrets/ ..."
    aws s3 sync "$SECRET_DIR/" "s3://$BUCKET_NAME/secrets/" --exclude "*.git*"
    "$LOGGER" "SUCCESS" "Upload to S3 completed."
    ;;
    
  "download")
    "$LOGGER" "INFO" "Downloading remote secrets from s3://$BUCKET_NAME/secrets/ to $SECRET_DIR ..."
    aws s3 sync "s3://$BUCKET_NAME/secrets/" "$SECRET_DIR/"
    "$LOGGER" "SUCCESS" "Download from S3 completed."
    ;;
    
  "clean")
    "$LOGGER" "WARN" "Emptying S3 bucket: s3://$BUCKET_NAME ..."
    aws s3 rm "s3://$BUCKET_NAME" --recursive
    "$LOGGER" "SUCCESS" "AWS S3 bucket $BUCKET_NAME cleaned successfully."
    ;;
    
  *)
    usage
    ;;
esac
