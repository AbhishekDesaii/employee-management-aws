#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# install-jenkins.sh
# Installs Jenkins (LTS) on Ubuntu 24.04, plus the tools the pipelines need
# (git, Python, Node.js). Run as root or with sudo on a fresh Ubuntu instance.
#
# Afterwards: http://<EC2_PUBLIC_IP>:8080  (unlock key shown below)
# -----------------------------------------------------------------------------

export DEBIAN_FRONTEND=noninteractive

JENKINS_VERSION="${JENKINS_VERSION:-2.492.1}"   # LTS (adjustable)
JENKINS_HTTP_PORT="${JENKINS_HTTP_PORT:-8080}"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run as root (e.g. 'sudo bash install-jenkins.sh')" >&2
  exit 1
fi

log() { echo -e "\033[0;32m[INFO]\033[0m $*"; }

# -----------------------------------------------------------------------------
# 1. System packages needed by Jenkins + the pipelines
# -----------------------------------------------------------------------------
log "Installing system packages (git, Python, Node.js, Java)..."
apt-get update -y
apt-get install -y \
  git curl ca-certificates gnupg default-jre-headless \
  python3 python3-pip python3-venv python3-pytest \
  nodejs npm

# Node 20.x (Ubuntu's bundled Node is too old for some tooling)
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# -----------------------------------------------------------------------------
# 2. Jenkins (official Debian repo -> LTS)
# -----------------------------------------------------------------------------
if ! systemctl is-active --quiet jenkins; then
  log "Installing Jenkins from the official repo..."
  curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
    gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] \
https://pkg.jenkins.io/debian-stable binary/" > /etc/apt/sources.list.d/jenkins.list
  apt-get update -y
  apt-get install -y jenkins
fi

# -----------------------------------------------------------------------------
# 3. Allow the 'jenkins' user to restart our systemd services (during deploy)
# -----------------------------------------------------------------------------
cat > /etc/sudoers.d/jenkins-deploy <<'SUDOERS'
jenkins ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart ems-backend, /usr/bin/systemctl restart ems-frontend, /usr/bin/systemctl daemon-reload
SUDOERS
chmod 440 /etc/sudoers.d/jenkins-deploy

# -----------------------------------------------------------------------------
# 4. Enable + start Jenkins
# -----------------------------------------------------------------------------
systemctl enable jenkins
systemctl start jenkins

# Wait for it to come up
log "Waiting for Jenkins to start on port ${JENKINS_HTTP_PORT}..."
for i in $(seq 1 60); do
  if curl -sf "http://localhost:${JENKINS_HTTP_PORT}/login" >/dev/null 2>&1; then
    break
  fi
  sleep 5
done

JENKINS_HOME="${JENKINS_HOME:-/var/lib/jenkins}"
log "Jenkins is installed and running."
log "  URL:      http://<instance-public-ip>:${JENKINS_HTTP_PORT}"
log "  Unlock:   sudo cat ${JENKINS_HOME}/secrets/initialAdminPassword"
log "  Run next: sudo bash configure-pipelines.sh <admin-token>"

# -----------------------------------------------------------------------------
# 5. Install the plugins the pipelines need (Git, GitHub, Pipeline, NodeJS)
# -----------------------------------------------------------------------------
JENKINS_CLI_JAR="${JENKINS_HOME}/jenkins-cli.jar"
curl -sf -o "${JENKINS_CLI_JAR}" \
  "http://localhost:${JENKINS_HTTP_PORT}/jnlpJars/jenkins-cli.jar"

PLUGINS="git github pipeline-stage-view pipeline-utility-steps \
  github-branch-source credentials-binding timestamper"
java -jar "${JENKINS_CLI_JAR}" -s "http://localhost:${JENKINS_HTTP_PORT}/" \
  install-plugin "${PLUGINS}" --restart

log "Installed plugins: git, github, github-branch-source, pipeline-*, credentials-binding, timestamper"
log "---- install-jenkins.sh complete ----"