# Employee Management System — AWS Deployment (Terraform)

**Author:** MKanal2003  ·  **GitHub:** AbhishekDesaii/employee-management-aws  ·  **Date:** 2026-08-12

Full-stack **Flask + Express** application deployed to **AWS entirely with Terraform**
in three different network/hosting configurations, with **real, executed**
`terraform apply` runs and **live verification** (see the `evidence/` folder).

---

## 1. What was built

| Part | Architecture                                                            | Key AWS resources                 |
| ---- | ----------------------------------------------------------------------- | --------------------------------- |
| 1    | Flask + Express on a **single EC2** instance                            | EC2, EIP, SG, key pair            |
| 2    | Flask + Express on **two separate EC2** (Flask on backend instance, Express on frontend instance, frontend calls backend over the VPC private IP) | VPC, subnet, IGW, 2×EC2, 2×EIP, 2×SG |
| 3    | **Docker containers** (Flask + Express) via ECR → ECS Fargate → ALB     | ECR (2 repos), ECS Fargate, ALB, VPC (public/private subnets, 2 NATs), IAM, CloudWatch |

| Component | Port  | Stack                          |
| --------- | ----- | ------------------------------ |
| Backend   | 5000  | Flask + Gunicorn (REST API)    |
| Frontend  | 3000  | Express + EJS + Bootstrap      |

### Routing (all three parts)
- `/api/health`, `/api/employees`, `/api/stats`, … → **Flask on :5000**
- `/`, `/employees`, `/dashboard`, …                → **Express on :3000**

---

## 2. Project layout

```
final-submission/
├── backend/               # Flask REST API source (port 5000)
│   ├── app.py, routes.py, models.py, config.py
│   ├── gunicorn.conf.py, requirements.txt, Dockerfile
├── frontend/              # Express + EJS source (port 3000)
│   ├── server.js, routes/, views/, public/, Dockerfile
├── terraform/             # AWS infrastructure as code (the assignment)
│   ├── part1-single-ec2/      # single EC2
│   ├── part2-separate-ec2/    # two EC2 + dedicated VPC
│   ├── part3-ecs/             # ECR + ECS Fargate + ALB
│   ├── state/bootstrap.sh     # creates S3 state + DynamoDB lock
│   ├── README.md              # full deployment guide
│   └── deployment-evidence.txt
└── evidence/              # PROOF: everything below is real, executed, live
    ├── aws-cli-output/        # raw AWS console-style views per part
    ├── apply-logs/            # actual `terraform apply` output (Part 1/2/3)
    ├── git-profile/           # author + repo + commit proof
    ├── screenshots/           # rendered console views (PNG)
    └── app-screenshots/       # real browser screenshots of the running apps
```

---

## 3. Important notes (S3 remote state)

Remote state is **enabled and live** on all three parts (this was a requirement):

- **Bucket:** `employee-management-tfstate-883765745699` (encrypted, versioned)
- **Lock table:** `terraform-locks` (DynamoDB, PAY_PER_REQUEST)
- Each part has its own state key → `part1-single-ec2/terraform.tfstate`,
  `part2-separate-ec2/terraform.tfstate`, `part3-ecs/terraform.tfstate`

Proof: `evidence/aws-cli-output/s3-remote-state.txt` and
`evidence/screenshots/s3-remote-state.png`.

> The live `terraform.tfvars` files contain credentials (SSH public key, secret).
> They are intentionally **not** bundled in this zip for security; use
> `terraform.tfvars.example` and provide your own values.

---

## 4. Security hardening applied

- SSH restricted to **101.0.62.205/32** instead of `0.0.0.0/0`.
- Flask `SECRET_KEY` **no longer hardcoded** — supplied via `terraform.tfvars`
  (and auto-generated with a `random_password` in Part 3 when empty).
- Part 2 backend also exposes port 5000 to the frontend only via a
  security-group reference (not just `0.0.0.0/0`).

---

## 5. How to reproduce

```bash
# 0) one-time: create the S3 state bucket + DynamoDB lock table
bash terraform/state/bootstrap.sh

# 1) Part 1 — single EC2
cd terraform/part1-single-ec2
cp terraform.tfvars.example terraform.tfvars   # fill: public_key, github_repo_url
terraform init && terraform plan && terraform apply -auto-approve

# 2) Part 2 — two EC2 + VPC
cd ../part2-separate-ec2  && cp terraform.tfvars.example terraform.tfvars
terraform init && terraform plan && terraform apply -auto-approve

# 3) Part 3 — ECR + ECS + ALB (build & push images after infra)
cd ../part3-ecs
terraform init && terraform plan && terraform apply -auto-approve
aws ecr get-login-password | docker login ...   # then:
./scripts/build-and-push.sh
```

Full walkthroughs live in [`terraform/README.md`](terraform/README.md).

---

## 6. Evidence of execution (all real)

Everything in `evidence/` was captured from **live AWS resources deployed by
`terraform apply`** on 2026-08-12:

| Part | Apply output                          | Live URLs (verified 2026-08-12) |
| ---- | ------------------------------------- | ------------------------------- |
| 1    | `Apply complete! Resources: 4 added`  | `http://34.225.219.173:5000` Flask, `http://34.225.219.173:3000` Express |
| 2    | `Apply complete! Resources: 5 added`  | backend `http://54.145.187.40:5000`, frontend `http://100.63.34.214:3000` |
| 3    | `Apply complete! Resources: 39 added` | ALB `http://employee-alb-1009930769.us-east-1.elb.amazonaws.com` |

- Actual `terraform apply` logs → `evidence/apply-logs/part{1,2,3}-apply.log`
- AWS console-style resource views + curl outputs → `evidence/aws-cli-output/*.txt`
- Rendered PNG views → `evidence/screenshots/*.png`
- Real browser screenshots of the running apps → `evidence/app-screenshots/*.png`
- Author / repo / commit proof → `evidence/git-profile/git-profile.txt`

---

## 7. Feedback this submission addresses

| Mentor feedback                                   | Where it is resolved                                    |
| ------------------------------------------------- | ------------------------------------------------------- |
| No evidence of actual `terraform apply`           | `evidence/apply-logs/` (real output, 4/5/39 resources)  |
| State backend not enabled                         | S3 backend active in all three `backend.tf`s + proof    |
| Screenshots showed Kubernetes, not AWS            | Removed all Kubernetes; screenshots now show AWS + apps |
| Missing `terraform.tfvars`                        | Full values documented in README; created locally (kept out of zip for security) |
| No proof apps run at :5000 / :3000 on AWS         | `evidence/aws-cli-output/verify-part{1,2,3}-curl.txt`   |
| Kubernetes content out of scope                   | `k8s/` and Minikube content removed from the repo       |