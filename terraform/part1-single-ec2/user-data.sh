#!/usr/bin/env bash
set -euxo pipefail

# -----------------------------------------------------------------------------
# Cloud-init user-data: install Flask backend + Express frontend on ONE instance
# -----------------------------------------------------------------------------

export DEBIAN_FRONTEND=noninteractive

APP_DIR="${app_dir}"
REPO_URL="${github_repo_url}"
TOKEN="${github_token}"
API_BASE_URL="${api_base_url}"

# Tokenized repo URL if a token is provided
if [ -n "$TOKEN" ]; then
  REPO_URL="https://x-access-token:$${TOKEN}@$${REPO_URL#https://}"
fi

# -----------------------------------------------------------------------------
# 1. System packages: Python 3, Node.js, git, build tools
# -----------------------------------------------------------------------------
apt-get update -y
apt-get install -y \
  git curl ca-certificates build-essential \
  python3 python3-pip python3-venv \
  nodejs npm

# Node 20.x from NodeSource (Ubuntu's default is too old)
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

node --version
python3 --version

# -----------------------------------------------------------------------------
# 2. Clone the application repository
# -----------------------------------------------------------------------------
mkdir -p "$(dirname "$APP_DIR")"
git clone "$REPO_URL" "$APP_DIR"
cd "$APP_DIR"

# -----------------------------------------------------------------------------
# 3. Backend (Flask) - venv + gunicorn on port 5000
# -----------------------------------------------------------------------------
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
Environment="SECRET_KEY=prod-secret-key-change-me"
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

# -----------------------------------------------------------------------------
# 4. Frontend (Express) - npm install + node server on port 3000
# -----------------------------------------------------------------------------
cd "$APP_DIR/frontend"
npm install --omit=dev

cat >/etc/systemd/system/ems-frontend.service <<EOF
[Unit]
Description=Employee Management Express Frontend
After=network.target ems-backend.service

[Service]
Type=simple
WorkingDirectory=$APP_DIR/frontend
Environment="PORT=3000"
Environment="API_BASE_URL=$API_BASE_URL"
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ems-frontend
systemctl start ems-frontend

# -----------------------------------------------------------------------------
# 5. Verify
# -----------------------------------------------------------------------------
sleep 5
systemctl --no-pager status ems-backend --lines=0 || true
systemctl --no-pager status ems-frontend --lines=0 || true
curl -s http://localhost:5000/api/health && echo
curl -s http://localhost:3000/ | head -5
echo "user-data complete"
