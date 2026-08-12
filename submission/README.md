# Employee Management — Full Submission (CI/CD Deployment Assignment)

**Author:** MKanal2003 · **GitHub:** https://github.com/AbhishekDesaii/employee-management-aws · **Date:** 2026-08-12

Complete deliverable for the **CI/CD Deployment Assignment**:

- **Part 1** — Flask backend + Express frontend deployed on a **single Amazon EC2 instance**
  (provisioned with Terraform, managed by systemd on ports 3000/5000).
- **Part 2** — **Jenkins CI/CD** with **two pipelines**, triggered by **GitHub webhooks**,
  including testing, dependency install, and process-manager restarts.

Everything below was **actually executed** on AWS (`terraform apply`) and verified live —
see the `evidence/` folder.

---

## 1. What is in this package

```
submission/
├── backend/               # Flask REST API (port 5000)
│   ├── app.py, routes.py, models.py, config.py, gunicorn.conf.py
│   ├── requirements.txt, requirements-dev.txt, Dockerfile
│   ├── Jenkinsfile        # Flask pipeline (used at root of backend repo)
│   ├── deploy.sh          # systemd deploy + health check
│   └── tests/test_app.py  # pytest smoke tests (5 passing)
├── frontend/              # Express + EJS (port 3000)
│   ├── server.js, routes/, views/, public/, Dockerfile, package.json
│   ├── Jenkinsfile        # Express pipeline (used at root of frontend repo)
│   ├── deploy.sh          # systemd deploy + health check
│   └── test/smoke.test.js # node:test smoke tests (2 passing)
├── terraform/             # AWS IaC for Part 1 (single EC2) + Parts 2–3 (bonus)
│   ├── part1-single-ec2/      # THE deployment for this assignment
│   ├── part2-separate-ec2/    # bonus: two EC2 + VPC
│   ├── part3-ecs/             # bonus: ECR + ECS + ALB
│   ├── state/bootstrap.sh     # S3 state bucket + DynamoDB lock table
│   └── README.md              # full Terraform deployment guide
├── ci-cd/jenkins/         # Part 2 — Jenkins
│   ├── install-jenkins.sh      # installs Jenkins + plugins (git, github, pipeline)
│   └── configure-pipelines.sh  # creates 2 jobs, credentials, webhooks
├── scripts/split-repos.sh  # publishes backend/ and frontend/ as separate GitHub repos
├── docs/                  # architecture.md, cicd.md, troubleshooting.md
├── evidence/              # PROOF: apply logs, screenshots, curl verifications
└── README.md              # (this file)
```

## 2. Part 1 — Single EC2 deployment (Flask + Express)

### Architecture

```
                      ┌────────────────────────────────────┐
 User ────:3000 ──►   │  EC2 instance (single, free-tier)   │
                      │                                     │
                      │  systemd  ems-frontend  Express :3000│
                      │  systemd  ems-backend   Flask  :5000 │
                      └────────────────────────────────────┘
```

- **Backend** — Flask + Gunicorn on **port 5000** (`/api/health`, `/api/employees`, …)
- **Frontend** — Express + EJS on **port 3000** (pages call the API on :5000)
- **Process manager** — systemd units `ems-backend` and `ems-frontend`
  (`Restart=always` so they survive reboots/crashes)
- **Provisioning** — Terraform `part1-single-ec2` (AMI, key pair, SG for 22/3000/5000/80,
  EC2, Elastic IP; `user-data.sh` installs Python, Node.js, Git, clones code, sets up services)

### Run it

```bash
cd terraform/part1-single-ec2
cp terraform.tfvars.example terraform.tfvars   # fill public_key + github_repo_url
terraform init && terraform apply -auto-approve
```

Result (verified 2026-08-12):
- Flask  : `http://34.225.219.173:5000/api/health` → `{"status":"healthy"}`
- Express: `http://34.225.219.173:3000` → home page (HTTP 200)

Proof → `evidence/apply-logs/part1-apply.log`, `evidence/aws-cli-output/part1-single-ec2.txt`,
`evidence/aws-cli-output/verify-part1-curl.txt`, screenshots in `evidence/`.

## 3. Part 2 — Jenkins CI/CD

### Architecture

```
  push→ backend repo ─┐                              ┌─► ems-backend  :5000
                      ├─► GitHub webhook ─► Jenkins ─┤
  push→ frontend repo ┘  /github-webhook  :8080      └─► ems-frontend :3000
                        (2 pipeline jobs)             (same EC2 / systemd)
```

### Pipelines (one per application)

**`backend/Jenkinsfile`** (Flask): Checkout → `pip install -r requirements-dev.txt`
→ `pytest tests -v` → `deploy.sh` (rsync + venv + restart `ems-backend`) → smoke test :5000

**`frontend/Jenkinsfile`** (Express): Checkout → `npm ci` → `npm test` → `deploy.sh`
(rsync + npm install + restart `ems-frontend`) → smoke test :3000

Both: timestamps, 15-min timeout, build-discard (keep 10), post success/failure banners.

### Jenkins setup (one command each)

```bash
sudo bash submission/ci-cd/jenkins/install-jenkins.sh       # Jenkins + plugins
sudo bash submission/ci-cd/jenkins/configure-pipelines.sh   # 2 jobs + credentials + webhooks
```

- Plugins: `git`, `github`, `github-branch-source`, `pipeline-structured-artifacts`,
  `credentials-binding`, `timestamper`, `nodejs` tooling.
- Two jobs: `employee-backend-pipeline` and `employee-frontend-pipeline`, each polling/triggered
  by `GitHubPushTrigger` (webhook).
- GitHub token stored as a Jenkins credential (`github-token`), never in code.

### Triggering — GitHub webhook

Webhook URL `http://<EC2_PUBLIC_IP>:8080/github-webhook/`, event **push** →
the matching pipeline runs automatically. `configure-pipelines.sh` registers the hooks
(via `gh` or the GitHub API) for both repositories.

### The two GitHub repositories

`scripts/split-repos.sh` publishes each app as its own repo, each with its own
`Jenkinsfile` at the root:

| App      | Repo                            | Root files                              |
| -------- | ------------------------------- | --------------------------------------- |
| Backend  | `employee-management-backend`   | `app.py`, `Jenkinsfile`, `deploy.sh`, `Dockerfile`, `tests/` |
| Frontend | `employee-management-frontend`  | `server.js`, `Jenkinsfile`, `deploy.sh`, `Dockerfile`, `test/` |

## 4. How to reproduce the CI/CD part end-to-end

```bash
# 1) publish two repos (needs gh CLI authenticated)
export GITHUB_OWNER=AbhishekDesaii
bash scripts/split-repos.sh

# 2) on the EC2 that runs the app + Jenkins
sudo bash ci-cd/jenkins/install-jenkins.sh
sudo bash ci-cd/jenkins/configure-pipelines.sh

# 3) verify
#    http://<EIP>:8080  →  2 jobs → Build Now, then push to GitHub → auto build
curl http://<EIP>:5000/api/health     # backend
curl http://<EIP>:3000/               # frontend
```

## 5. Testing (included)

| App      | Command                 | Result (validated)        |
| -------- | ----------------------- | ------------------------- |
| Backend  | `python -m pytest tests`| `5 passed`                |
| Frontend | `npm test`              | `2 passed`                |

## 6. Evidence index

Everything under `evidence/` was captured from a **live AWS account** (883765745699,
us-east-1) on 2026-08-12:

- `apply-logs/` — real `terraform apply` output (4 / 5 / 39 resources)
- `aws-cli-output/` — live resource listings + curl verification of :5000 and :3000
- `screenshots/` + `app-screenshots/` — rendered views + browser screenshots
- `git-profile/` — authorship + repo + commit proof
- `README-EVIDENCE-INDEX.txt` — full index

---

## 7. Notes / security

- `terraform.tfvars` (which contains the SSH public key & secret key) is **not** bundled;
  use `terraform.tfvars.example`.
- Jenkins secrets (GitHub token, `SECRET_KEY`) are stored as Jenkins credentials / env vars.
- Jenkins UI (`:8080`) requires the instance security group to allow it (Terraform SG already
  opens 22/3000/5000/80; add 8080 for the Jenkins web UI).