#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# deploy_minikube.sh
# Builds the images, deploys the app to Minikube, and verifies everything.
#
# Usage:
#   ./scripts/deploy_minikube.sh [--reset]
# -----------------------------------------------------------------------------

APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$APP_DIR"

NAMESPACE="employee-system"

log() { echo -e "\033[1;36m[deploy]\033[0m $*"; }
die() { echo -e "\033[1;31m[ERROR]\033[0m $*"; exit 1; }

command -v minikube >/dev/null || die "minikube not found. Install from https://minikube.sigs.k8s.io"
command -v kubectl >/dev/null || die "kubectl not found."

# -----------------------------------------------------------------------------
# 1. Make sure Minikube is running
# -----------------------------------------------------------------------------
if ! minikube status >/dev/null 2>&1; then
  log "Minikube is not running. Starting it..."
  minikube start --driver=docker --cpus=2 --memory=3000
fi
log "Minikube status:"
minikube status | grep -E "host|kubelet|apiserver" || true

# -----------------------------------------------------------------------------
# 2. Enable the nginx ingress addon (needed for the Ingress resource)
# -----------------------------------------------------------------------------
if ! minikube addons list | grep -q "ingress.*enabled"; then
  log "Enabling ingress addon..."
  minikube addons enable ingress
fi

# -----------------------------------------------------------------------------
# 3. Build the images inside the Minikube docker daemon
# -----------------------------------------------------------------------------
log "Building backend image into Minikube..."
minikube image build -t employee-backend:latest ./backend
log "Building frontend image into Minikube..."
minikube image build -t employee-frontend:latest ./frontend

# -----------------------------------------------------------------------------
# 4. Apply the manifests (namespace, configmap, secret, pvc, deployments, services, ingress)
# -----------------------------------------------------------------------------
log "Applying Kubernetes manifests..."
kubectl apply -k k8s/

# -----------------------------------------------------------------------------
# 5. Wait for the pods to be Ready
# -----------------------------------------------------------------------------
log "Waiting for pods to become ready..."
kubectl -n "$NAMESPACE" wait --for=condition=ready pod \
  --selector=app=employee-backend --timeout=120s
kubectl -n "$NAMESPACE" wait --for=condition=ready pod \
  --selector=app=employee-frontend --timeout=120s

log "Pods:"
kubectl -n "$NAMESPACE" get pods

# -----------------------------------------------------------------------------
# 6. Verify services + ingress
# -----------------------------------------------------------------------------
log "Services:"
kubectl -n "$NAMESPACE" get svc
log "Ingress:"
kubectl -n "$NAMESPACE" get ingress

# -----------------------------------------------------------------------------
# 7. End-to-end check through the ingress
# -----------------------------------------------------------------------------
MINIKUBE_IP=$(minikube ip)
log "Checking backend health via ingress..."
curl -s --max-time 20 -H "Host: employee.local" "http://$MINIKUBE_IP/api/health" || die "Backend health check failed"

log "Checking frontend page via ingress..."
curl -s --max-time 20 -H "Host: employee.local" "http://$MINIKUBE_IP/" -o /dev/null || die "Frontend check failed"

echo
log "Deployment complete!"
echo "  Add this line to /etc/hosts to browse the app:"
echo "    $MINIKUBE_IP employee.local"
echo "  Then open http://employee.local in your browser."
