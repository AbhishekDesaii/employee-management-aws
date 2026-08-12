# CI/CD Assignment — Jenkins Pipeline Setup

This document describes the **CI/CD pipeline** that deploys the **Flask backend**
and **Express frontend** to a single Amazon EC2 instance using **Jenkins**,
triggered by **GitHub webhooks**.

---

## 1. Architecture

```
                        ┌─────────────── GitHub (two repos) ───────────────┐
    push to main ───► ┌──────────────┐   push to main ───► ┌───────────────┐
                      │  backend repo │                     │ frontend repo │
                      └──────┬───────┘                     └───────┬───────┘
                             └───────────┐   ┌─────────────────────┘
                                         ▼   ▼
                                ┌──────────────────┐  (bridge)
                                │  GitHub Webhook  │
                                │  /github-webhook │
                                └────────┬─────────┘
                                         ▼
                              ┌─────────────────────┐
                              │  JENKINS  (EC2)      │  :8080
                              │  backend pipeline    │
                              │  frontend pipeline   │
                              └─────────┬───────────┘
                                        │ pipeline steps: checkout → install
                                        │ deps → test → deploy → smoke test
                              ┌─────────▼───────────┐
                              │  systemd  (same EC2) │
                              ├ ─ ems-backend :5000  │
                              └ ─ ems-frontend :3000 │
```

Two GitHub repositories hold the app code (see Section 5). Both deploy to the
same EC2 instance: Flask/Gunicorn on **:5000** and Express/Node on **:3000**,
managed by systemd so they restart on failure.

## 2. What was implemented

| Requirement                                  | Implementation                                      |
| -------------------------------------------- | --------------------------------------------------- |
| Jenkins on EC2                               | `ci-cd/jenkins/install-jenkins.sh` (Debian repo LTS) |
| Plugins: Git, GitHub, NodeJS, Python         | Installed automatically (git, github, pipeline-*, credentials-binding, timestamper) |
| Two pipelines (backend + frontend)           | `backend/Jenkinsfile`, `frontend/Jenkinsfile`        |
| Pull latest code                             | `checkout scm` (Git SCM configured in job)           |
| Install deps                                 | `pip install -r requirements-dev.txt` / `npm ci`     |
| Restart with process manager                 | systemd units `ems-backend`, `ems-frontend` (deploy.sh) |
| GitHub webhook trigger (push → build)        | `GitHubPushTrigger` + webhook registration in `configure-pipelines.sh` |
| Testing stage (optional)                     | pytest (`backend/tests/`), node:test (`frontend/test/`) |
| Environment variables for secrets            | Jenkins credentials (`github-token`) + pipeline env vars |
| Two separate GitHub repos                    | see Section 5                                    |

## 3. Repo map / files added

```
ci-cd/
├── jenkins/
│   ├── install-jenkins.sh        # installs Jenkins + plugins + tools
│   └── configure-pipelines.sh    # creates 2 jobs, credentials, webhooks
backend/
├── Jenkinsfile                   # Flask pipeline (root of backend repo)
├── deploy.sh                     # systemd deploy + health check
├── requirements-dev.txt          # test deps (pytest)
└── tests/test_app.py             # API smoke tests
frontend/
├── Jenkinsfile                   # Express pipeline (root of frontend repo)
├── deploy.sh                     # systemd deploy + health check
└── test/smoke.test.js            # node:test smoke tests
scripts/split-repos.sh            # publishes the two GitHub repos
```

## 4. How to run it end-to-end

```bash
# 1) Publish the two GitHub repos (run on your local machine)
export GITHUB_OWNER=<your-username>
bash scripts/split-repos.sh

# 2) On the EC2 instance (the one running the app):
wget -qO- https://raw.githubusercontent.com/<owner>/<repo>/main/ci-cd/jenkins/install-jenkins.sh | sudo bash

# 3) Configure the two pipelines
sudo bash ci-cd/jenkins/configure-pipelines.sh \
     --backend  https://github.com/<owner>/employee-management-backend \
     --frontend https://github.com/<owner>/employee-management-frontend

# 4) See it work
#    http://<EC2_PUBLIC_IP>:8080  →  employee-backend-pipeline / employee-frontend-pipeline
#    Run "Build Now" once to verify, then push to either repo and watch it auto-build.
```

Environment variables used by the pipelines (override in Jenkins → Job →
Configure → Environment variables, or set them as credentials):

| Variable        | Used by | Default                 | Notes                          |
| --------------- | ------- | ----------------------- | ------------------------------ |
| `APP_DIR`       | both    | `/home/ubuntu/ems/{b,f}`| Deploy directory               |
| `VENV_DIR`      | backend | `/opt/ems-venv`         | Python virtualenv              |
| `API_BASE_URL`  | frontend| `http://localhost:5000` | Backend URL for the frontend   |
| `SECRET_KEY`    | backend | random                  | Flask secret (set as credential) |

## 5. The two GitHub repositories

| Purpose | Repo name                           | Contents at root |
| ------- | ----------------------------------- | ---------------- |
| Backend | `employee-management-backend`       | `app.py`, `Jenkinsfile`, `deploy.sh`, `Dockerfile`, `tests/` |
| Frontend| `employee-management-frontend`      | `server.js`, `Jenkinsfile`, `deploy.sh`, `Dockerfile`, `test/` |

Each repo carries its **own Jenkinsfile** at the root, so Jenkins builds the
right app from the right source without any monorepo path logic.

## 6. Verification / evidence

1. `GitHub` → Settings → Webhooks: two webhooks pointing at
   `http://<EC2_PUBLIC_IP>:8080/github-webhook/` with event **push**.
2. `Jenkins` → job → *Build History* shows **green** builds after each push.
3. Pipeline log on a successful build:
   ```
   Started by GitHub push
   [Pipeline] stage (Checkout) ...
   [Pipeline] stage (Test)       ... 5 passed in 0.15s
   [Pipeline] stage (Deploy)     ... ems-backend restarted on :5000
   [Pipeline] stage (Smoke test) ... {"status":"healthy"}
   ```
4. `curl http://<instance-ip>:5000/api/health` → `{"status":"healthy"}`
5. `curl http://<instance-ip>:3000/` → HTTP 200 (front end HTML)

## 7. Notes

- The Jenkins instance and the app share the EC2 host for this assignment
  (also valid: Jenkins on its own host reaching this EC2 over SSH).
- Port **8080** must be open in the instance security group (Terraform
  `part1-single-ec2` already opens SSH/5000/3000/80 — add 8080 for Jenkins).
- Secrets (GitHub PAT, SECRET_KEY) are stored as Jenkins credentials, not in
  source control.