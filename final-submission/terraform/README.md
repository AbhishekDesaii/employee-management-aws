# Terraform - AWS Deployment of Employee Management

Deploys the **Flask backend** and **Express frontend** to AWS in three different
configurations using [Terraform](https://terraform.io).

| Part | Configuration                                            | Directory               |
| ---- | -------------------------------------------------------- | ----------------------- |
| 1    | Flask + Express on a **single EC2** instance             | `part1-single-ec2/`     |
| 2    | Flask + Express on **two separate EC2** instances        | `part2-separate-ec2/`   |
| 3    | Flask + Express as **Docker containers** (ECR + ECS + ALB) | `part3-ecs/`          |

---

## Prerequisites

- AWS account + IAM credentials (Access Key / Secret Access Key)
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured (`aws configure`)
- [Terraform](https://developer.hashicorp.com/terraform/downloads) `>= 1.5`
- Docker (Part 3 only, for building/pushing images)

```bash
aws configure
```

---

## Remote State Management (S3)

Each part uses a **live S3 backend** (`backend.tf`) for remote state with
DynamoDB locking. The bucket and lock table are created once by:

```bash
./terraform/state/bootstrap.sh
```

This creates:
- S3 bucket `employee-management-tfstate-<account-id>` (versioning + SSE)
- DynamoDB table `terraform-locks` (PAY_PER_REQUEST)

No manual uncommenting is needed - the `backend "s3" {}` blocks are active.
A separate state key is used per part:

| Part | State key |
| ---- | --------- |
| 1    | `part1-single-ec2/terraform.tfstate` |
| 2    | `part2-separate-ec2/terraform.tfstate` |
| 3    | `part3-ecs/terraform.tfstate` |

> Note: if you used local state previously, run `terraform init -migrate-state`
> once to upload the existing state.

---

## Part 1 - Single EC2 Instance

Deploys one EC2 instance running **both** services: Flask on **:5000** and
Express on **:3000**. A public Elastic IP keeps the app address stable.

```
User ──► :3000  Express frontend  ──► :5000  Flask API  (localhost)
```

```bash
cd terraform/part1-single-ec2
cp terraform.tfvars.example terraform.tfvars   # edit: public_key, github_repo_url
terraform init
terraform plan
terraform apply -auto-approve
```

**Verify:**

```bash
terraform output public_ip       # -> 1.2.3.4
curl http://$(terraform output -raw public_ip):5000/api/health
curl http://$(terraform output -raw public_ip):3000/
```

**Files:** `main.tf`, `variables.tf`, `outputs.tf`, `user-data.sh`, `backend.tf`

---

## Part 2 - Two Separate EC2 Instances

Deploys a dedicated **VPC** with a public subnet + internet gateway, then two
EC2 instances:

- `employee-flask-backend` — Flask on **:5000** (publicly exposed)
- `employee-express-frontend` — Express on **:3000** (publicly exposed)

The frontend calls the backend over the VPC using the backend's **private IP**
(a security-group rule allows frontend → backend on port 5000).

```
                          ┌─ EC2 (backend)  Flask :5000  ◄── public
User ──► EC2 (frontend)   │
         Express :3000  ──┴─► backend PRIVATE_IP:5000 (over VPC SG rule)
```

```bash
cd terraform/part2-separate-ec2
cp terraform.tfvars.example terraform.tfvars   # edit: public_key, github_repo_url
terraform init
terraform plan
terraform apply -auto-approve
```

**Verify:**

```bash
terraform output backend_flask_url     # http://<ip>:5000/api/health
terraform output frontend_express_url  # http://<ip>:3000/
```

**Files:** `main.tf`, `variables.tf`, `outputs.tf`,
`user-data-backend.sh`, `user-data-frontend.sh`, `backend.tf`

---

## Part 3 - Docker (ECR + ECS + ALB + VPC)

Deploys a full containerized stack:

- **ECR**: two repositories (`employee-backend`, `employee-frontend`)
- **VPC**: public/private subnets, IGW, NAT gateway, route tables, SGs
- **ECS**: Fargate cluster with one service per app (private subnets)
- **ALB**: public Application Load Balancer
  - `/api/*` → backend target group (Flask :5000)
  - everything else → frontend target group (Express :3000)

```
Internet ──► ALB :80 ──┬─► /api/*   ──► ECS backend  (Flask :5000)
                       └─► default  ──► ECS frontend (Express :3000)
```

### Step 1 - Apply infrastructure

```bash
cd terraform/part3-ecs
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply -auto-approve   # creates ECR, VPC, ECS, ALB
```

### Step 2 - Build & push images

From the repo root (where `backend/` and `frontend/` live):

```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.us-east-1.amazonaws.com
./terraform/part3-ecs/scripts/build-and-push.sh
```

### Step 3 - Deploy & verify

```bash
terraform output app_url    # -> http://employee-alb-<hash>.elb.amazonaws.com
curl http://<alb-dns>/api/health
# open <alb-dns>/ in a browser
```

**Files:** `main.tf`, `vpc.tf`, `ecr.tf`, `iam.tf`, `ecs.tf`, `alb.tf`,
`variables.tf`, `outputs.tf`, `scripts/build-and-push.sh`, `backend.tf`

---

## Validation

All configurations were validated and **applied against live AWS**:

```bash
terraform init -backend=false
terraform validate
terraform fmt -recursive -check
terraform apply -auto-approve   # Executed for Part 1 (4), Part 2 (5), Part 3 (39 resources)
```

- Part 1 apply output: `Apply complete! Resources: 4 added` (instance
  `i-066109e4c5ce0cb0b`, EIP `34.225.219.173`)
- Part 2 apply output: `Apply complete! Resources: 5 added` (VPC
  `vpc-023ea767052b744a6`, backend `i-0441a2bd56c947e40` `54.145.187.40`,
  frontend `i-041a6cba9d228a72e`)
- Part 3 apply output: `Apply complete! Resources: 39 added` (ALB
  `employee-alb-1009930769.us-east-1.elb.amazonaws.com`)

Raw `terraform apply` logs and screenshots are in
[`docs/evidence/`](../docs/evidence/), and a summary of every verified
endpoint is in [`deployment-evidence.txt`](deployment-evidence.txt).

---

## Cleanup

Destroy each environment (they are independent):

```bash
cd terraform/part1-single-ec2 && terraform destroy -auto-approve
cd terraform/part2-separate-ec2 && terraform destroy -auto-approve
cd terraform/part3-ecs && terraform destroy -auto-approve
```

> Note: ECR images and the S3 state bucket are not destroyed by
> `terraform destroy`; remove them manually if no longer needed.
