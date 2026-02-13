# 出力定義

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "VPC CIDRブロック"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_1_id" {
  description = "パブリックサブネット1のID"
  value       = aws_subnet.public_1.id
}

output "public_subnet_2_id" {
  description = "パブリックサブネット2のID"
  value       = aws_subnet.public_2.id
}

output "private_subnet_1_id" {
  description = "プライベートサブネット1のID"
  value       = aws_subnet.private_1.id
}

output "private_subnet_2_id" {
  description = "プライベートサブネット2のID"
  value       = aws_subnet.private_2.id
}

output "ec2_instance_id" {
  description = "EC2インスタンスID"
  value       = aws_instance.web.id
}

output "ec2_instance_public_ip" {
  description = "EC2インスタンスのパブリックIP"
  value       = aws_instance.web.public_ip
}

output "ec2_instance_private_ip" {
  description = "EC2インスタンスのプライベートIP"
  value       = aws_instance.web.private_ip
}

output "security_group_id" {
  description = "セキュリティグループID"
  value       = aws_security_group.ec2_sg.id
}
