# -----------------------------------------------------------------------------
# S3 backend for remote Terraform state with locking.
# The bucket + DynamoDB lock table are created by terraform/state/bootstrap.sh.
# -----------------------------------------------------------------------------
terraform {
  backend "s3" {
    bucket         = "employee-management-tfstate-883765745699"
    key            = "part2-separate-ec2/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
