# 変数定義

variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "プロジェクト名"
  type        = string
  default     = "training"
}

variable "environment" {
  description = "環境名"
  type        = string
  default     = "training"
}

variable "vpc_cidr" {
  description = "VPCのCIDRブロック"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "パブリックサブネット1のCIDRブロック"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "パブリックサブネット2のCIDRブロック"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_1_cidr" {
  description = "プライベートサブネット1のCIDRブロック"
  type        = string
  default     = "10.0.10.0/24"
}

variable "private_subnet_2_cidr" {
  description = "プライベートサブネット2のCIDRブロック"
  type        = string
  default     = "10.0.11.0/24"
}

variable "ami_id" {
  description = "EC2インスタンスのAMI ID"
  type        = string
  default     = "ami-0c3fd0f5d33134a76"  # Amazon Linux 2023 (ap-northeast-1)
}

variable "instance_type" {
  description = "EC2インスタンスタイプ"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2キーペア名"
  type        = string
  # デフォルト値は設定しない（必須）
}
