#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# deploy-frontend.sh — used by the frontend Jenkins pipeline.
# Rsyncs the checked-out repo into APP_DIR, (re)creates the systemd unit with
# the right env vars, and restarts the service. Safe to run repeatedly.
# -----------------------------------------------------------------------------

export DEBIAN_FRONTEND=noninteractive

APP_DIR="${APP_DIR:-/home/ubuntu/ems/frontend}"
SERVICE="${SERVICE:-ems-frontend}"
PORT="${PORT:-3000}"
API_BASE_URL="${API_BASE_URL:-http://localhost:5000}"

log() { echo -e "\033[0;32m[INFO]\033[0m $*"; }

if [ "$(id -u)" -ne 0 ] && ! sudo -n true 2>/dev/null; then
  echo "ERROR: need root or passwordless sudo" >&2
  exit 1
fi
SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi

WORKSPACE="${WORKSPACE:-$PWD}"
[ -f "${WORKSPACE}/package.json" ] || { echo "ERROR: not the frontend repo" >&2; exit 1; }

# -----------------------------------------------------------------------------
# 1. Copy code into place (fresh node_modules so lockfile is respected)
# -----------------------------------------------------------------------------
$SUDO mkdir -p "${APP_DIR}"
$SUDO rsync -a --delete --exclude '.git' --exclude 'node_modules' \
  "${WORKSPACE}/" "${APP_DIR}/"

# -----------------------------------------------------------------------------
# 2. Install npm deps
# -----------------------------------------------------------------------------
cd "${APP_DIR}"
${SUDO:-} git init -q 2>/dev/null || true   # allow 'npm ci' without npmrc repo dep
if [ -f package-lock.json ]; then
  ${SUDO:-} npm ci --omit=dev --no-audit --no-fund
else
  ${SUDO:-} npm install --omit=dev --no-audit --no-fund
fi

# -----------------------------------------------------------------------------
# 3. systemd unit (idempotent)
# -----------------------------------------------------------------------------
$SUDO tee /etc/systemd/system/${SERVICE}.service >/dev/null <<EOF
[Unit]
Description=Employee Management Express Frontend (CI/CD)
After=network.target ems-backend.service

[Service]
Type=simple
User=ubuntu
Group=ubuntu
WorkingDirectory=${APP_DIR}
Environment="PORT=${PORT}"
Environment="API_BASE_URL=${API_BASE_URL}"
Environment=NODE_ENV=production
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

$SUDO systemctl daemon-reload
$SUDO systemctl enable ${SERVICE}
$SUDO systemctl restart ${SERVICE}

# -----------------------------------------------------------------------------
# 4. Verify
# -----------------------------------------------------------------------------
sleep 4
for i in $(seq 1 10); do
  if curl -sf "http://localhost:${PORT}/" >/dev/null 2>&1; then
    log "Frontend healthy on :${PORT}"
    break
  fi
  sleep 2
done
curl -sf -o /dev/null -w "Frontend HTTP %{http_code}\n" "http://localhost:${PORT}/" \
  || { echo "ERROR: frontend failed health check" >&2; exit 1; }
log "---- frontend deploy complete ----"