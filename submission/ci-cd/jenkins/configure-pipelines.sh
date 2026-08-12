#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# configure-pipelines.sh
# Creates the two Jenkins pipelines (backend + frontend) on a running Jenkins
# master. Needs an admin API token from a user that can manage jobs.
#
# Usage:
#   export JENKINS_URL=http://localhost:8080
#   export JENKINS_ADMIN_USER=admin
#   export JENKINS_ADMIN_TOKEN=<api-token>
#   export GITHUB_TOKEN=<fine-grained or classic PAT for cloning + webhooks>
#   export BACKEND_REPO=https://github.com/<owner>/employee-management-backend
#   export FRONTEND_REPO=https://github.com/<owner>/employee-management-frontend
#   sudo bash configure-pipelines.sh
# -----------------------------------------------------------------------------

JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
JENKINS_ADMIN_USER="${JENKINS_ADMIN_USER:-admin}"
JENKINS_ADMIN_TOKEN="${JENKINS_ADMIN_TOKEN:?set to a Jenkins API token}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
BACKEND_REPO="${BACKEND_REPO:?set to the backend GitHub repo URL}"
FRONTEND_REPO="${FRONTEND_REPO:?set to the frontend GitHub repo URL}"

log() { echo -e "\033[0;32m[INFO]\033[0m $*"; }
step() { echo -e "\033[0;34m[JOB]\033[0m $*"; }

JENKINS_HOME="${JENKINS_HOME:-/var/lib/jenkins}"

endpoint() {
  curl -sf -u "${JENKINS_ADMIN_USER}:${JENKINS_ADMIN_TOKEN}" \
    "${JENKINS_URL}${1}" "${@:2}"
}

# -----------------------------------------------------------------------------
# 1. Wait for Jenkins to be ready
# -----------------------------------------------------------------------------
for i in $(seq 1 60); do
  endpoint "/login" >/dev/null 2>&1 && break
  sleep 5
done
log "Jenkins API reachable at ${JENKINS_URL}"

# -----------------------------------------------------------------------------
# 2. Store the GitHub token as a Jenkins credential (used by SCM + webhook)
# -----------------------------------------------------------------------------
if [ -n "${GITHUB_TOKEN}" ]; then
  log "Creating GitHub credential 'github-token'..."
  CRED_XML=$(mktemp)
  cat > "${CRED_XML}" <<'XML'
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>github-token</id>
  <description>GitHub PAT for cloning repos + webhook deployments</description>
  <username>github-push</username>
  <password>__GITHUB_TOKEN__</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
XML
  sed -i "s|__GITHUB_TOKEN__|${GITHUB_TOKEN}|" "${CRED_XML}"
  endpoint "/credentials/store/system/domain/_/createCredentials" \
    --data-urlencode "json={\"credentials\": {\"scope\": \"GLOBAL\", \"id\": \"github-token\", \"secret\": \"${GITHUB_TOKEN}\", \"\$class\": \"com.cloudbees.plugins.credentials.impl.StringCredentialsImpl\"}}" \
    || log "(credential may already exist — continuing)"
  rm -f "${CRED_XML}"
fi

# -----------------------------------------------------------------------------
# 3. Create/update the two pipeline jobs (Jenkinsfile in each repo)
# -----------------------------------------------------------------------------
make_job() { # $1 = repo URL, $2 = job name
  local repo_url="$1" job="$2"
  step "Configuring pipeline '${job}' -> ${repo_url}"
  JOB_XML=$(mktemp)
  cat > "${JOB_XML}" <<XML
<flow-definition plugin="workflow-job">
  <description>CI/CD for ${job} (Flask) — built from Jenkinsfile</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <com.cloudbees.jenkins.GitHubPushTrigger>
          <spec></spec>
        </com.cloudbees.jenkins.GitHubPushTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps">
    <scm class="hudson.plugins.git.GitSCM" plugin="git">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>${repo_url}</url>
          <credentialsId>github-token</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
XML

  if endpoint "/job/${job}/config.xml" >/dev/null 2>&1; then
    endpoint "/job/${job}/config.xml" -X POST -H 'Content-Type: application/xml' \
      --data-binary @"${JOB_XML}" >/dev/null 2>&1
    log "Updated existing job '${job}'."
  else
    endpoint "/job/${job}" -X POST -H 'Content-Type: application/xml' \
      --data-binary @"${JOB_XML}" >/dev/null 2>&1
    log "Created job '${job}'."
  fi
  rm -f "${JOB_XML}"
}

make_job "${BACKEND_REPO}" "employee-backend-pipeline"
make_job "${FRONTEND_REPO}" "employee-frontend-pipeline"

# -----------------------------------------------------------------------------
# 4. GitHub webhooks (push -> trigger the right pipeline)
# -----------------------------------------------------------------------------
if [ -n "${GITHUB_TOKEN}" ]; then
  log "Registering GitHub webhooks (requires 'gh' CLI or a PAT + API call)..."
  for repo in "${BACKEND_REPO}" "${FRONTEND_REPO}"; do
    owner_repo="${repo#https://github.com/}"
    owner_repo="${owner_repo%.git}"
    hs_url="${JENKINS_URL%/}/github-webhook/"
    if command -v gh &>/dev/null; then
      gh api -X POST "repos/${owner_repo}/hooks" \
        -F name=web -f config[url]="${hs_url}" \
        -F config[content_type]=json -F config[insecure_ssl]=0 \
        -f events[0]=push || log "webhook for ${owner_repo} failed/skipped"
    else
      curl -sf -X POST "https://api.github.com/repos/${owner_repo}/hooks" \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        -d "{\"name\": \"web\", \"active\": true, \"events\": [\"push\"], \
             \"config\": {\"url\": \"${hs_url}\", \"content_type\": \"json\"}}" \
        >/dev/null && log "Webhook added for ${owner_repo}" \
        || log "Webhook for ${owner_repo} failed — add it in GitHub UI."
    fi
  done
fi

step "Done. Open ${JENKINS_URL} -> Build Now on each pipeline to verify."
step "Pushing to the backend/frontend repos now auto-triggers deployment."