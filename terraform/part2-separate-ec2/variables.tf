variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "employee"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone" {
  description = "Availability zone for the public subnet"
  type        = string
  default     = "us-east-1a"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name for the SSH key pair"
  type        = string
  default     = "employee-management"
}

variable "public_key" {
  description = "Your SSH public key to inject into the instance"
  type        = string
}

variable "ssh_cidr" {
  description = "CIDR allowed to SSH into the instances"
  type        = string
  default     = "0.0.0.0/0"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 20
}

variable "github_repo_url" {
  description = "Git URL of the application repository (use token for private repos)"
  type        = string
}

variable "github_token" {
  description = "Optional GitHub token to authenticate cloning a private repo"
  type        = string
  default     = ""
}

variable "app_dir" {
  description = "Directory where the app will be cloned on the instance"
  type        = string
  default     = "/home/ubuntu/employee-management"
}
