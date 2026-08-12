#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# split-repos.sh
# Publish the backend/ and frontend/ folders as their OWN GitHub repositories,
# each with the required CI/CD files at the root:
#   employee-management-backend   ->  Dockerfile, Jenkinsfile, deploy.sh, tests/
#   employee-management-frontend  ->  Dockerfile, Jenkinsfile, deploy.sh, test/
#
# Creates the repos (gh CLI), resets their git history (clean single-repo app)
# and pushes main. Both repos need the Jenkinsfile which is already present.
#
# Usage:
#   export GITHUB_OWNER=AbhishekDesaii
#   bash scripts/split-repos.sh
# -----------------------------------------------------------------------------

GITHUB_OWNER="${GITHUB_OWNER:?set GITHUB_OWNER to your GitHub username/org}"
BACKEND_REPO="${BACKEND_REPO:-${GITHUB_OWNER}/employee-management-backend}"
FRONTEND_REPO="${FRONTEND_REPO:-${GITHUB_OWNER}/employee-management-frontend}"

log() { echo -e "\033[0;32m[INFO]\033[0m $*"; }

command -v gh >/dev/null || { echo "ERROR: gh CLI required" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "ERROR: gh not authenticated" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

publish() { # $1 = source folder, $2 = owner/repo, $3 = repo name
  local src="$1" full="$2" name="$3"
  [ -d "$src" ] || { log "skip $src (missing)"; return; }

  log "Publishing $src -> $full"
  local dir="$TMP/$name"
  mkdir -p "$dir"

  # Copy app + CI/CD files (exclude junk that must not be committed)
  rsync -a \
    --exclude 'node_modules' --exclude '__pycache__' --exclude '*.pyc' \
    --exclude '.env' --exclude '*.log' \
    "$src/" "$dir/"

  git -C "$dir" init -q -b main
  git -C "$dir" add -A
  git -C "$dir" -c user.name="CI Setup" -c user.email="ci@example.com" \
    commit -q -m "Initial commit: automated CI/CD setup for $name"

  gh repo create "$full" --private --source "$dir" --push \
    || gh repo view "$full" >/dev/null 2>&1 && {
      log "Repo $full already exists — updating with gh repo edit --push via push"
      git -C "$dir" remote add origin "git@github.com:${full}.git" 2>/dev/null || true
      git -C "$dir" push -q -u origin main 2>/dev/null || log "push skipped (already up to date)"
    }
  log "  --> https://github.com/${full}"
}

publish backend "$BACKEND_REPO" employee-management-backend
publish frontend "$FRONTEND_REPO" employee-management-frontend

log ""
log "Next steps:"
log "  1. cd ci-cd/jenkins && sudo bash install-jenkins.sh"
log "  2. export BACKEND_REPO=https://github.com/${BACKEND_REPO} FRONTEND_REPO=https://github.com/${FRONTEND_REPO}"
log "  3. sudo bash configure-pipelines.sh"
log "Webhooks are registered for both repos, so pushes auto-trigger a build."