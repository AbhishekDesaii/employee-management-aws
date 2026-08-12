# Employee Management - AWS Deployment (Terraform)

A full-stack employee management application with an **Express (EJS) frontend**, a **Flask REST API** backend, deployed to **AWS** via **Terraform** in three different configurations.

---

## Tech Stack

| Category       | Technology                      |
| -------------- | ------------------------------- |
| **Frontend**   | Express, EJS, Bootstrap         |
| **Backend**    | Python, Flask, Gunicorn         |
| **Container**  | Docker (ECS/Fargate, Part 3)    |
| **Cloud**      | AWS (EC2, VPC, ECS, ECR, ALB)   |
| **IaC**        | Terraform (S3 remote state)     |

---

## Project Structure

```
employee-management/
├── backend/
│   ├── Dockerfile                 # Flask API image
│   ├── app.py                     # Flask app factory
│   ├── routes.py                  # API route handlers
│   ├── models.py                  # In-memory data layer
│   ├── config.py                  # Config from env vars
│   └── requirements.txt
├── frontend/
│   ├── Dockerfile                 # Express image
│   ├── server.js                  # Express server
│   ├── routes/index.js            # Page routes
│   └── views/                     # EJS templates
├── terraform/                     # AWS deployments (3 parts)
│   ├── part1-single-ec2/          # Flask + Express on one EC2
│   ├── part2-separate-ec2/        # Flask + Express on two EC2
│   ├── part3-ecs/                 # Docker (ECR + ECS + ALB)
│   └── state/bootstrap.sh         # Creates S3 state backend
├── ci-cd/jenkins/                 # Jenkins install + pipeline config
├── scripts/split-repos.sh         # Publish separate backend/frontend repos
└── README.md
```

---

## Terraform AWS Deployment

See [terraform/README.md](terraform/README.md) for full instructions covering the
three AWS configurations:

| Part | Configuration                                              | Directory                |
| ---- | ---------------------------------------------------------- | ------------------------ |
| 1    | Flask + Express on a single EC2 instance                   | `terraform/part1-single-ec2/` |
| 2    | Flask + Express on two separate EC2 instances              | `terraform/part2-separate-ec2/` |
| 3    | Flask + Express as Docker containers (ECR + ECS + ALB)     | `terraform/part3-ecs/` |

## CI/CD (Jenkins)

A **Jenkins** pipeline automates deployment of the Flask backend and Express
frontend to EC2, triggered by **GitHub webhooks**:

- `backend/Jenkinsfile` + `frontend/Jenkinsfile` — the two pipelines
- `ci-cd/jenkins/` — install + configure scripts for Jenkins, plugins, webhooks
- `backend/deploy.sh` + `frontend/deploy.sh` — systemd deploy helpers
- `scripts/split-repos.sh` — publishes the two standalone GitHub repos
- [docs/cicd.md](docs/cicd.md) — full assignment write-up

All three parts use an **S3 remote backend** (with DynamoDB locking) so Terraform
state is shared and protected.

```bash
cd terraform/part1-single-ec2   # or part2-separate-ec2 / part3-ecs
terraform init && terraform plan && terraform apply -auto-approve
```

---

## API Endpoints

| Method | Endpoint             | Description             |
| ------ | -------------------- | ----------------------- |
| GET    | `/api/health`        | Health check            |
| GET    | `/api/employees`     | List all employees      |
| GET    | `/api/employees/:id` | Get employee by ID      |
| POST   | `/api/employees`     | Create an employee      |
| PUT    | `/api/employees/:id` | Update an employee      |
| DELETE | `/api/employees/:id` | Delete an employee      |
| GET    | `/api/departments`   | List departments        |
| GET    | `/api/projects`      | List projects           |
| GET    | `/api/stats`         | Dashboard statistics    |