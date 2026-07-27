#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------
# deploy_ecs.sh
# Build, tag, and push Docker images to Amazon
# ECR, then force-update an ECS service.
# -------------------------------------------

# --------------- Configuration ---------------
AWS_REGION="${AWS_REGION:-us-east-1}"
ECR_REPOSITORY="${ECR_REPOSITORY:-employee-management}"
ECS_CLUSTER="${ECS_CLUSTER:-employee-management-cluster}"
ECS_SERVICE="${ECS_SERVICE:-employee-management-service}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
BACKEND_IMAGE="$ECR_REPOSITORY/backend:$IMAGE_TAG"
FRONTEND_IMAGE="$ECR_REPOSITORY/frontend:$IMAGE_TAG"
NGINX_IMAGE="$ECR_REPOSITORY/nginx:$IMAGE_TAG"

# --------------- Helpers ---------------
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# --------------- Pre-flight checks ---------------
check_cmd() {
  if ! command -v "$1" &>/dev/null; then
    log_error "'$1' is required but not found. Install it first."
    exit 1
  fi
}

check_cmd docker
check_cmd aws

# --------------- 1. Authenticate with ECR ---------------
log_info "Authenticating Docker with Amazon ECR..."
aws ecr get-login-password --region "$AWS_REGION" \
  | docker login --username AWS --password-stdin "$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com"

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# --------------- 2. Build and tag images ---------------
log_info "Building images with docker-compose..."
docker compose build

log_info "Tagging images for ECR..."
docker tag employee-management-backend:latest  "$ECR_REGISTRY/$BACKEND_IMAGE"
docker tag employee-management-frontend:latest "$ECR_REGISTRY/$FRONTEND_IMAGE"
docker tag employee-management-nginx:latest    "$ECR_REGISTRY/$NGINX_IMAGE"

# --------------- 3. Push images to ECR ---------------
log_info "Pushing images to Amazon ECR..."
docker push "$ECR_REGISTRY/$BACKEND_IMAGE"
docker push "$ECR_REGISTRY/$FRONTEND_IMAGE"
docker push "$ECR_REGISTRY/$NGINX_IMAGE"

# --------------- 4. Update ECS service ---------------
log_info "Updating ECS service '$ECS_SERVICE' on cluster '$ECS_CLUSTER'..."
aws ecs update-service \
  --cluster "$ECS_CLUSTER" \
  --service "$ECS_SERVICE" \
  --force-new-deployment \
  --region "$AWS_REGION" \
  --no-cli-pager

log_info "Deployment triggered. Monitor progress in the AWS Console."
log_info "  https://$AWS_REGION.console.aws.amazon.com/ecs/home?region=$AWS_REGION#/clusters/$ECS_CLUSTER/services/$ECS_SERVICE"
