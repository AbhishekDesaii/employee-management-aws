#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------
# stop_services.sh
# Stop and remove all Docker Compose services.
# -------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "Stopping Docker Compose services..."
docker compose down

echo "All services stopped and cleaned up."
