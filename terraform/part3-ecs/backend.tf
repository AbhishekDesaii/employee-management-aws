# -----------------------------------------------------------------------------
# S3 backend for remote Terraform state (recommended).
# -----------------------------------------------------------------------------
# backend "s3" {
#   bucket         = "employee-management-tfstate"
#   key            = "part3-ecs/terraform.tfstate"
#   region         = "us-east-1"
#   encrypt        = true
#   dynamodb_table = "terraform-locks"
# }
