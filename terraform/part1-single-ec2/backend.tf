# -----------------------------------------------------------------------------
# S3 backend for remote Terraform state (recommended).
# Before `terraform apply`, create the bucket + DynamoDB table (see
# state/bootstrap.sh) and uncomment this block. Then run `terraform init`.
# -----------------------------------------------------------------------------
# backend "s3" {
#   bucket         = "employee-management-tfstate"
#   key            = "part1-single-ec2/terraform.tfstate"
#   region         = "us-east-1"
#   encrypt        = true
#   dynamodb_table = "terraform-locks"
# }
