# -----------------------------------------------------------------------------
# Part 3: Flask + Express as Docker containers via ECR + ECS (Fargate) + ALB
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote S3 backend (recommended) - see backend.tf
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "employee-management"
      Part      = "part3-ecs"
      ManagedBy = "terraform"
    }
  }
}

provider "random" {}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  ecr_base   = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

# Ephemeral random Flask secret if none was supplied via tfvars
resource "random_password" "flask_secret" {
  length  = 32
  special = false
  upper   = true
  lower   = true
  numeric = true
  keepers = { stack = var.name_prefix }
  count   = var.secret_key == "" ? 1 : 0
}
