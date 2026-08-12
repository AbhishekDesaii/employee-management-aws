#!/usr/bin/env bash
set -euo pipefail

# deploy_ec2.sh
# Reference helper for deploying to EC2.
# The primary deployment method for this assignment is Terraform:
#   cd terraform/part1-single-ec2 && terraform apply -auto-approve
#   cd terraform/part2-separate-ec2 && terraform apply -auto-approve
# This script is kept for reference only.

echo "Use the Terraform configs under terraform/ instead:"
echo "  terraform/part1-single-ec2  - single EC2 (Flask + Express)"
echo "  terraform/part2-separate-ec2 - two separate EC2 instances"
echo "  terraform/part3-ecs          - Docker (ECR + ECS + ALB)"
exit 0