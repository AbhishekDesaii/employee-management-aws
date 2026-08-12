# -----------------------------------------------------------------------------
# Part 1: Flask + Express on a SINGLE EC2 instance
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote S3 backend (recommended) - see backend.tf
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "employee-management"
      Part      = "part1-single-ec2"
      ManagedBy = "terraform"
    }
  }
}

# -----------------------------------------------------------------------------
# Data sources
# -----------------------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]
}

data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# Key pair
# -----------------------------------------------------------------------------
resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = var.public_key
}

# -----------------------------------------------------------------------------
# Security group: SSH, Flask (5000), Express (3000), HTTP (80)
# -----------------------------------------------------------------------------
resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-sg"
  description = "Allow SSH, Flask, Express, HTTP for employee app"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }
  ingress {
    description = "Flask API"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Express frontend"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------------------------------------------------------
# EC2 instance (single) running BOTH Flask and Express
# -----------------------------------------------------------------------------
resource "aws_instance" "this" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.this.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user-data.sh", {
    github_repo_url = var.github_repo_url
    github_token    = var.github_token
    app_dir         = var.app_dir
    api_base_url    = "http://localhost:5000"
    secret_key      = var.secret_key
  })

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.name_prefix}-single-ec2"
  }
}

# -----------------------------------------------------------------------------
# Elastic IP so the app keeps the same public IP
# -----------------------------------------------------------------------------
resource "aws_eip" "this" {
  instance = aws_instance.this.id

  tags = {
    Name = "${var.name_prefix}-eip"
  }
}
