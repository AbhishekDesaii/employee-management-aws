#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# deploy-backend.sh — used by the backend Jenkins pipeline.
# Rsyncs the checked-out repo into APP_DIR, (re)creates the systemd unit with
# the right env vars, and restarts the service. Safe to run repeatedly.
# -----------------------------------------------------------------------------

export DEBIAN_FRONTEND=noninteractive

APP_DIR="${APP_DIR:-/home/ubuntu/ems/backend}"
VENV_DIR="${VENV_DIR:-/opt/ems-venv}"
SERVICE="${SERVICE:-ems-backend}"
PORT="${PORT:-5000}"
SECRET_KEY="${SECRET_KEY:-$(openssl rand -hex 32)}"

log() { echo -e "\033[0;32m[INFO]\033[0m $*"; }

if [ "$(id -u)" -ne 0 ] && ! sudo -n true 2>/dev/null; then
  echo "ERROR: need root or passwordless sudo" >&2
  exit 1
fi
SUDO=""
if [ "$(id -u)" -ne 0 ]; then SUDO="sudo"; fi

WORKSPACE="${WORKSPACE:-$PWD}"
[ -f "${WORKSPACE}/requirements.txt" ] || { echo "ERROR: not the backend repo" >&2; exit 1; }

# -----------------------------------------------------------------------------
# 1. Copy code into place
# -----------------------------------------------------------------------------
$SUDO mkdir -p "${APP_DIR}"
$SUDO rsync -a --delete --exclude '.git' --exclude '__pycache__' \
  "${WORKSPACE}/" "${APP_DIR}/"

# -----------------------------------------------------------------------------
# 2. venv + dependencies
# -----------------------------------------------------------------------------
if [ ! -x "${VENV_DIR}/bin/python" ]; then
  $SUDO python3 -m venv "${VENV_DIR}"
fi
$SUDO "${VENV_DIR}/bin/pip" install --upgrade pip wheel
$SUDO "${VENV_DIR}/bin/pip" install -r "${APP_DIR}/requirements.txt"

# -----------------------------------------------------------------------------
# 3. systemd unit (idempotent)
# -----------------------------------------------------------------------------
$SUDO tee /etc/systemd/system/${SERVICE}.service >/dev/null <<EOF
[Unit]
Description=Employee Management Flask Backend (CI/CD)
After=network.target

[Service]
Type=simple
User=ubuntu
Group=ubuntu
WorkingDirectory=${APP_DIR}
Environment="HOST=0.0.0.0"
Environment="PORT=${PORT}"
Environment="FLASK_DEBUG=false"
Environment="SECRET_KEY=${SECRET_KEY}"
Environment="CORS_ORIGINS=*"
Environment="LOG_LEVEL=INFO"
Environment="GUNICORN_WORKERS=2"
ExecStart=${VENV_DIR}/bin/gunicorn app:create_app() -c gunicorn.conf.py
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
  if curl -sf "http://localhost:${PORT}/api/health" >/dev/null 2>&1; then
    log "Backend healthy on :${PORT} after $((i*2))s"
    break
  fi
  sleep 2
done
curl -s "http://localhost:${PORT}/api/health" || { echo "ERROR: backend failed health check" >&2; exit 1; }
echo
log "---- backend deploy complete ----"