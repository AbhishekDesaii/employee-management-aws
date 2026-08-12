output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_eip.this.public_ip
}

output "public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_eip.this.public_dns
}

output "flask_url" {
  description = "Flask backend URL"
  value       = "http://${aws_eip.this.public_ip}:5000"
}

output "express_url" {
  description = "Express frontend URL"
  value       = "http://${aws_eip.this.public_ip}:3000"
}

output "ssh_command" {
  description = "SSH command to access the instance"
  value       = "ssh -i ${var.key_name}.pem ubuntu@${aws_eip.this.public_ip}"
}
