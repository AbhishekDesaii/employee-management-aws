#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# build-and-push.sh
# Builds the Flask backend + Express frontend images and pushes them to ECR.
# Run AFTER `terraform apply` has created the repositories.
# -----------------------------------------------------------------------------

AWS_REGION="${AWS_REGION:-us-east-1}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
NAME_PREFIX="${NAME_PREFIX:-employee}"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGISTRY="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

BACKEND_REPO="$NAME_PREFIX-backend"
FRONTEND_REPO="$NAME_PREFIX-frontend"

log() { echo -e "\033[0;32m[INFO]\033[0m $*"; }

log "Logging into ECR..."
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$REGISTRY"

log "Building backend image..."
docker build -t "$BACKEND_REPO:$IMAGE_TAG" ./backend

log "Building frontend image..."
docker build -t "$FRONTEND_REPO:$IMAGE_TAG" ./frontend

log "Tagging and pushing backend..."
docker tag "$BACKEND_REPO:$IMAGE_TAG" "$REGISTRY/$BACKEND_REPO:$IMAGE_TAG"
docker push "$REGISTRY/$BACKEND_REPO:$IMAGE_TAG"

log "Tagging and pushing frontend..."
docker tag "$FRONTEND_REPO:$IMAGE_TAG" "$REGISTRY/$FRONTEND_REPO:$IMAGE_TAG"
docker push "$REGISTRY/$FRONTEND_REPO:$IMAGE_TAG"

log "Done. Images pushed to:"
echo "  $REGISTRY/$BACKEND_REPO:$IMAGE_TAG"
echo "  $REGISTRY/$FRONTEND_REPO:$IMAGE_TAG"
