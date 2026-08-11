#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# bootstrap.sh
# Creates the S3 bucket + DynamoDB lock table used for remote Terraform state.
# Run once before the first `terraform init`.
# -----------------------------------------------------------------------------

BUCKET="${BUCKET:-employee-management-tfstate}"
REGION="${AWS_REGION:-us-east-1}"
TABLE="terraform-locks"

log() { echo -e "\033[0;32m[INFO]\033[0m $*"; }

# Bucket (us-east-1 has no LocationConstraint)
if aws s3api head-bucket --bucket "$BUCKET" --region "$REGION" 2>/dev/null; then
  log "Bucket $BUCKET already exists."
else
  log "Creating S3 bucket $BUCKET..."
  if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
  else
    aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi
fi

log "Enabling bucket versioning..."
aws s3api put-bucket-versioning --bucket "$BUCKET" --versioning-configuration Status=Enabled

log "Enabling default encryption..."
aws s3api put-bucket-encryption --bucket "$BUCKET" \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

log "Creating DynamoDB lock table $TABLE..."
aws dynamodb create-table \
  --table-name "$TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION" >/dev/null || log "Lock table may already exist."

log "State bootstrap complete. Now run 'terraform init' in each part directory."
