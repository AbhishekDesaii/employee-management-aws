#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------
# setup.sh
# Local development environment setup using Docker.
# -------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "========================================"
echo "  Employee Management — Setup"
echo "========================================"

# --------------------------------------------------
# 1. Check prerequisites
# --------------------------------------------------
check_cmd() {
  if ! command -v "$1" &>/dev/null; then
    echo "[ERROR] '$1' is not installed. Please install it first."
    exit 1
  fi
}

check_cmd docker
check_cmd docker-compose || check_cmd docker

# Docker Compose is available as a plugin or standalone
DOCKER_COMPOSE="docker compose"
if ! docker compose version &>/dev/null; then
  if command -v docker-compose &>/dev/null; then
    DOCKER_COMPOSE="docker-compose"
  else
    echo "[ERROR] Neither 'docker compose' plugin nor 'docker-compose' CLI was found."
    exit 1
  fi
fi

echo "[OK] Docker and Docker Compose are available."

# --------------------------------------------------
# 2. Create .env files from examples if missing
# --------------------------------------------------
for env_dir in . backend frontend; do
  env_file="$env_dir/.env"
  env_example="$env_dir/.env.example"
  if [ -f "$env_example" ] && [ ! -f "$env_file" ]; then
    cp "$env_example" "$env_file"
    echo "[INFO] Created $env_file from template."
  fi
done

# --------------------------------------------------
# 3. Build and start containers
# --------------------------------------------------
echo ""
echo "[STEP] Building images..."
$DOCKER_COMPOSE build

echo ""
echo "[STEP] Starting services in detached mode..."
$DOCKER_COMPOSE up -d

# --------------------------------------------------
# 4. Show status
# --------------------------------------------------
echo ""
echo "[STEP] Container status:"
$DOCKER_COMPOSE ps

echo ""
echo "========================================"
echo "  Setup complete!"
echo "  Access the app at http://localhost"
echo "========================================"
