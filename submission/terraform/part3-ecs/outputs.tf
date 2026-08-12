output "alb_dns_name" {
  description = "ALB DNS name - access the application here"
  value       = aws_lb.this.dns_name
}

output "app_url" {
  description = "Application URL (frontend + API through the ALB)"
  value       = "http://${aws_lb.this.dns_name}"
}

output "api_url" {
  description = "Flask backend API URL"
  value       = "http://${aws_lb.this.dns_name}/api"
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.this.name
}

output "ecr_backend_repo" {
  description = "ECR repository URI for the backend"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecr_frontend_repo" {
  description = "ECR repository URI for the frontend"
  value       = aws_ecr_repository.frontend.repository_url
}

output "push_command" {
  description = "Command to build and push images to ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${local.ecr_base} && ./scripts/build-and-push.sh"
}
