variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "プロジェクト名"
  type        = string
  default     = "training-ec2"
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
  default     = "ami-0c3fd0f5d33134a76"
}

variable "instance_type" {
  description = "インスタンスタイプ"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "キーペア名"
  type        = string
}
