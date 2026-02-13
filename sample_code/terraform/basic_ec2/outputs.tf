output "instance_id" {
  description = "EC2インスタンスID"
  value       = aws_instance.main.id
}

output "instance_public_ip" {
  description = "パブリックIP"
  value       = aws_instance.main.public_ip
}

output "instance_private_ip" {
  description = "プライベートIP"
  value       = aws_instance.main.private_ip
}
