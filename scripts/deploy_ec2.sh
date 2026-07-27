#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------
# deploy_ec2.sh
# Deploy the Employee Management app on a
# fresh EC2 instance (Amazon Linux 2023 / Ubuntu).
# -------------------------------------------

REPO_URL="${REPO_URL:-https://github.com/example/employee-management.git}"
BRANCH="${BRANCH:-main}"
APP_DIR="${APP_DIR:-/home/ubuntu/employee-management}"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# --------------------------------------------------
# 1. Update system packages
# --------------------------------------------------
log_info "Updating system packages..."
if command -v apt-get &>/dev/null; then
  sudo apt-get update -y
  sudo apt-get upgrade -y
elif command -v yum &>/dev/null; then
  sudo yum update -y
else
  log_error "Unsupported package manager."
  exit 1
fi

# --------------------------------------------------
# 2. Install Docker (if not present)
# --------------------------------------------------
if ! command -v docker &>/dev/null; then
  log_info "Installing Docker..."
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"
  log_info "Docker installed. You may need to log out and back in for group changes."
else
  log_info "Docker already installed."
fi

# --------------------------------------------------
# 3. Install Docker Compose (if not present)
# --------------------------------------------------
if ! command -v docker-compose &>/dev/null && ! docker compose version &>/dev/null; then
  log_info "Installing Docker Compose..."
  sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
fi
log_info "Docker Compose ready."

# --------------------------------------------------
# 4. Clone or pull latest code
# --------------------------------------------------
if [ -d "$APP_DIR" ]; then
  log_info "Pulling latest code in $APP_DIR..."
  cd "$APP_DIR"
  git pull origin "$BRANCH"
else
  log_info "Cloning repository into $APP_DIR..."
  git clone --branch "$BRANCH" "$REPO_URL" "$APP_DIR"
  cd "$APP_DIR"
fi

# --------------------------------------------------
# 5. Create .env from example if needed
# --------------------------------------------------
for env_dir in . backend frontend; do
  env_file="$env_dir/.env"
  env_example="$env_dir/.env.example"
  if [ -f "$env_example" ] && [ ! -f "$env_file" ]; then
    cp "$env_example" "$env_file"
    log_info "Created $env_file from template."
  fi
done

# --------------------------------------------------
# 6. Build and start services
# --------------------------------------------------
log_info "Building and starting Docker services..."
sudo docker compose up --build -d

# --------------------------------------------------
# 7. Show status
# --------------------------------------------------
echo ""
log_info "Container status:"
sudo docker compose ps

echo ""
log_info "Deployment to EC2 complete!"
echo "  App should be accessible at http://$(curl -s http://checkip.amazonaws.com || echo 'localhost')"
