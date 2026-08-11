output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "backend_instance_id" {
  description = "Flask backend EC2 instance ID"
  value       = aws_instance.backend.id
}

output "backend_public_ip" {
  description = "Flask backend public IP"
  value       = aws_eip.backend.public_ip
}

output "backend_private_ip" {
  description = "Flask backend private IP (used by the frontend)"
  value       = aws_instance.backend.private_ip
}

output "backend_flask_url" {
  description = "Flask backend URL"
  value       = "http://${aws_eip.backend.public_ip}:5000"
}

output "frontend_instance_id" {
  description = "Express frontend EC2 instance ID"
  value       = aws_instance.frontend.id
}

output "frontend_public_ip" {
  description = "Express frontend public IP"
  value       = aws_eip.frontend.public_ip
}

output "frontend_express_url" {
  description = "Express frontend URL"
  value       = "http://${aws_eip.frontend.public_ip}:3000"
}

output "ssh_backend" {
  description = "SSH command for the backend"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_eip.backend.public_ip}"
}

output "ssh_frontend" {
  description = "SSH command for the frontend"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_eip.frontend.public_ip}"
}
