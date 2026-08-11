# -----------------------------------------------------------------------------
# Part 2: Flask + Express on TWO SEPARATE EC2 instances
# Dedicated VPC, subnets, route tables, and security groups
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
      Part      = "part2-separate-ec2"
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

# -----------------------------------------------------------------------------
# Key pair
# -----------------------------------------------------------------------------
resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = var.public_key
}

# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${var.name_prefix}-vpc" }
}

# One public subnet (frontend + backend can both be public for this assignment)
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 0)
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone

  tags = { Name = "${var.name_prefix}-public-subnet" }
}

# Internet gateway + route table
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name_prefix}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "${var.name_prefix}-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# -----------------------------------------------------------------------------
# Security groups
# -----------------------------------------------------------------------------

# Backend SG: SSH + Flask 5000 from internet, and 5000 from the frontend SG only
resource "aws_security_group" "backend" {
  name        = "${var.name_prefix}-backend-sg"
  description = "Flask backend: SSH + port 5000"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }
  ingress {
    description = "Flask API from internet"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description     = "Flask API from frontend SG"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-backend-sg" }
}

# Frontend SG: SSH + Express 3000 from internet
resource "aws_security_group" "frontend" {
  name        = "${var.name_prefix}-frontend-sg"
  description = "Express frontend: SSH + port 3000"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }
  ingress {
    description = "Express from internet"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-frontend-sg" }
}

# -----------------------------------------------------------------------------
# EC2 instances
# -----------------------------------------------------------------------------

# Flask backend instance
resource "aws_instance" "backend" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.this.key_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.backend.id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user-data-backend.sh", {
    github_repo_url = var.github_repo_url
    github_token    = var.github_token
    app_dir         = var.app_dir
  })

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = { Name = "${var.name_prefix}-flask-backend" }
}

# Express frontend instance.
# Its API_BASE_URL points at the backend's PRIVATE IP (intra-VPC traffic
# over the "frontend->backend" security-group rule).
resource "aws_instance" "frontend" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.this.key_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.frontend.id]
  associate_public_ip_address = true

  depends_on = [aws_instance.backend]

  user_data = templatefile("${path.module}/user-data-frontend.sh", {
    github_repo_url = var.github_repo_url
    github_token    = var.github_token
    app_dir         = var.app_dir
    backend_ip      = aws_instance.backend.private_ip
  })

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = { Name = "${var.name_prefix}-express-frontend" }
}

# Elastic IPs for stable public access
resource "aws_eip" "backend" {
  instance = aws_instance.backend.id
  tags     = { Name = "${var.name_prefix}-backend-eip" }
}

resource "aws_eip" "frontend" {
  instance = aws_instance.frontend.id
  tags     = { Name = "${var.name_prefix}-frontend-eip" }
}
