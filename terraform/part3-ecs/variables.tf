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

variable "azs" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "backend_cpu" {
  description = "CPU (in units) for the backend Fargate task"
  type        = number
  default     = 256
}

variable "backend_memory" {
  description = "Memory (in MB) for the backend Fargate task"
  type        = number
  default     = 512
}

variable "frontend_cpu" {
  description = "CPU (in units) for the frontend Fargate task"
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "Memory (in MB) for the frontend Fargate task"
  type        = number
  default     = 512
}

variable "backend_desired_count" {
  description = "Desired number of backend tasks"
  type        = number
  default     = 1
}

variable "frontend_desired_count" {
  description = "Desired number of frontend tasks"
  type        = number
  default     = 1
}
