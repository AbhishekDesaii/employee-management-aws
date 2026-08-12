#!/usr/bin/env bash
set -euxo pipefail

# -----------------------------------------------------------------------------
# User-data: Flask BACKEND only (port 5000)
# -----------------------------------------------------------------------------

export DEBIAN_FRONTEND=noninteractive

APP_DIR="${app_dir}"
REPO_URL="${github_repo_url}"
TOKEN="${github_token}"
SECRET_KEY="${secret_key}"
if [ -z "$SECRET_KEY" ]; then
  SECRET_KEY="$(openssl rand -hex 32)"
fi

if [ -n "$TOKEN" ]; then
  REPO_URL="https://x-access-token:$${TOKEN}@$${REPO_URL#https://}"
fi

apt-get update -y
apt-get install -y git curl ca-certificates build-essential python3 python3-pip python3-venv

mkdir -p "$(dirname "$APP_DIR")"
git clone "$REPO_URL" "$APP_DIR"
cd "$APP_DIR"

python3 -m venv /opt/ems-venv
/opt/ems-venv/bin/pip install --upgrade pip
/opt/ems-venv/bin/pip install -r backend/requirements.txt

cat >/etc/systemd/system/ems-backend.service <<EOF
[Unit]
Description=Employee Management Flask Backend
After=network.target

[Service]
Type=simple
WorkingDirectory=$APP_DIR/backend
Environment="HOST=0.0.0.0"
Environment="PORT=5000"
Environment="FLASK_DEBUG=false"
Environment="SECRET_KEY=$SECRET_KEY"
Environment="CORS_ORIGINS=*"
Environment="LOG_LEVEL=INFO"
Environment="GUNICORN_WORKERS=2"
ExecStart=/opt/ems-venv/bin/gunicorn app:create_app() -c gunicorn.conf.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ems-backend
systemctl start ems-backend

sleep 5
systemctl --no-pager status ems-backend --lines=0 || true
curl -s http://localhost:5000/api/health && echo
echo "backend user-data complete"
