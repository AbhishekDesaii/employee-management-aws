#!/usr/bin/env bash
set -euxo pipefail

# -----------------------------------------------------------------------------
# User-data: Express FRONTEND only (port 3000)
# API_BASE_URL points to the Flask backend's PRIVATE IP.
# -----------------------------------------------------------------------------

export DEBIAN_FRONTEND=noninteractive

APP_DIR="${app_dir}"
REPO_URL="${github_repo_url}"
TOKEN="${github_token}"
BACKEND_IP="${backend_ip}"

if [ -n "$TOKEN" ]; then
  REPO_URL="https://x-access-token:$${TOKEN}@$${REPO_URL#https://}"
fi

apt-get update -y
apt-get install -y git curl ca-certificates build-essential

curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

node --version

mkdir -p "$(dirname "$APP_DIR")"
git clone "$REPO_URL" "$APP_DIR"
cd "$APP_DIR/frontend"
npm install --omit=dev

cat >/etc/systemd/system/ems-frontend.service <<EOF
[Unit]
Description=Employee Management Express Frontend
After=network.target

[Service]
Type=simple
WorkingDirectory=$APP_DIR/frontend
Environment="PORT=3000"
Environment="API_BASE_URL=http://$BACKEND_IP:5000"
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ems-frontend
systemctl start ems-frontend

sleep 5
systemctl --no-pager status ems-frontend --lines=0 || true
curl -s http://localhost:3000/ | head -5
echo "frontend user-data complete"
