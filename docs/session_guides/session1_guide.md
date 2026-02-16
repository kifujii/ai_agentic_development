# セッション1：VPC/Subnet/EC2構築 詳細ガイド

## 📋 目的

このセッションでは、AWSインフラの基本構成（VPC、Subnet、EC2）をTerraformで手動構築し、インフラストラクチャの理解を深めます。

### 学習目標

- VPC、サブネット、EC2の基本概念を理解する
- Terraformを使ったインフラ構築の基本を習得する
- AWSリソースの依存関係を理解する
- 構築結果の検証方法を習得する

## 🎯 目指すべき構成

このセッション終了時点で、以下の構成が完成していることを目指します：

```
workspace/
└── terraform/
    └── vpc-subnet-ec2/
        ├── main.tf          # メインのTerraformコード
        ├── variables.tf     # 変数定義
        ├── outputs.tf       # 出力定義
        └── terraform.tfvars # 変数の値
```

**構築されるAWSリソース**:
- VPC（10.0.0.0/16）
- パブリックサブネット（10.0.1.0/24, 10.0.2.0/24）
- プライベートサブネット（10.0.10.0/24, 10.0.11.0/24）
- インターネットゲートウェイ
- ルートテーブル
- EC2インスタンス（t3.micro）

## 📚 事前準備

- [セッション0](session0_guide.md) が完了していること
- AWS認証情報が設定されていること
- Terraformがインストールされていること

## 🚀 手順

### 1. VPC設計（15分）

#### 1.1 CIDRブロックの設計

推奨設計:

| リソース | CIDRブロック | 可用性ゾーン |
|---------|-------------|------------|
| VPC | 10.0.0.0/16 | - |
| パブリックサブネット1 | 10.0.1.0/24 | ap-northeast-1a |
| パブリックサブネット2 | 10.0.2.0/24 | ap-northeast-1c |
| プライベートサブネット1 | 10.0.10.0/24 | ap-northeast-1a |
| プライベートサブネット2 | 10.0.11.0/24 | ap-northeast-1c |

#### 1.2 可用性ゾーンの確認

```bash
# 利用可能なAZの確認
aws ec2 describe-availability-zones --region ap-northeast-1
```

<details>
<summary>📝 実行結果例（クリックで展開）</summary>

```json
{
    "AvailabilityZones": [
        {
            "ZoneName": "ap-northeast-1a",
            "State": "available"
        },
        {
            "ZoneName": "ap-northeast-1c",
            "State": "available"
        },
        {
            "ZoneName": "ap-northeast-1d",
            "State": "available"
        }
    ]
}
```

</details>

### 2. サブネット設計（15分）

#### 2.1 パブリック/プライベートサブネットの理解

- **パブリックサブネット**: インターネットゲートウェイへのルートを持つ
- **プライベートサブネット**: インターネットゲートウェイへのルートを持たない

#### 2.2 ルートテーブルの理解

- パブリックサブネット: `0.0.0.0/0` → インターネットゲートウェイ
- プライベートサブネット: ローカル通信のみ

### 3. EC2インスタンスの設計（15分）

#### 3.1 インスタンスタイプの選択

- トレーニング用: `t3.micro` (無料枠対象)

#### 3.2 セキュリティグループの設計

最小権限の原則に従い、SSHのみ許可します。

<details>
<summary>📝 セキュリティグループ設定例（クリックで展開）</summary>

```hcl
resource "aws_security_group" "training_sg" {
  name        = "training-sg"
  description = "Training security group for EC2"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # 本番環境では制限すべき
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "training-sg"
  }
}
```

</details>

#### 3.3 キーペアの作成

```bash
# キーペアの作成（AWS CLI）
aws ec2 create-key-pair --key-name training-key --query 'KeyMaterial' --output text > training-key.pem
chmod 400 training-key.pem
```

**注意**: キーペアはTerraformで管理することもできます。

### 4. Terraformコードの作成（30分）

#### 4.1 ディレクトリ構造の作成

```bash
mkdir -p workspace/terraform/vpc-subnet-ec2
cd workspace/terraform/vpc-subnet-ec2
```

#### 4.2 Continue AIを活用したコード生成

Continue AIを起動（`Ctrl+L` / `Cmd+L`）して、以下のプロンプトを入力します：

```
VPC、パブリック/プライベートサブネット、インターネットゲートウェイ、
ルートテーブル、EC2インスタンスを含むTerraformコードを生成してください。

要件:
- VPC CIDR: 10.0.0.0/16
- パブリックサブネット: 10.0.1.0/24 (ap-northeast-1a), 10.0.2.0/24 (ap-northeast-1c)
- プライベートサブネット: 10.0.10.0/24 (ap-northeast-1a), 10.0.11.0/24 (ap-northeast-1c)
- EC2インスタンス: t3.micro, パブリックサブネットに配置
- セキュリティグループ: SSH（ポート22）のみ許可

出力形式:
- HCL形式のTerraformコード
- 変数定義を含める
- コメントを適切に追加
- ベストプラクティスに従う
```

<details>
<summary>📝 生成コード例（クリックで展開）</summary>

```hcl
# variables.tf
variable "region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "vpc_cidr" {
  description = "VPC CIDRブロック"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "EC2インスタンスタイプ"
  type        = string
  default     = "t3.micro"
}

# main.tf
provider "aws" {
  region = var.region
}

# VPC
resource "aws_vpc" "training_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "training-vpc"
  }
}

# インターネットゲートウェイ
resource "aws_internet_gateway" "training_igw" {
  vpc_id = aws_vpc.training_vpc.id

  tags = {
    Name = "training-igw"
  }
}

# パブリックサブネット1
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.training_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "training-public-subnet-1"
  }
}

# パブリックサブネット2
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.training_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "training-public-subnet-2"
  }
}

# プライベートサブネット1
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.training_vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "training-private-subnet-1"
  }
}

# プライベートサブネット2
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.training_vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "training-private-subnet-2"
  }
}

# パブリックルートテーブル
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.training_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.training_igw.id
  }

  tags = {
    Name = "training-public-rt"
  }
}

# パブリックサブネットとルートテーブルの関連付け
resource "aws_route_table_association" "public_subnet_1_assoc" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_2_assoc" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# セキュリティグループ
resource "aws_security_group" "training_sg" {
  name        = "training-sg"
  description = "Training security group for EC2"
  vpc_id      = aws_vpc.training_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "training-sg"
  }
}

# EC2インスタンス
resource "aws_instance" "training_ec2" {
  ami           = "ami-0c3fd0f5d33134a76" # Amazon Linux 2023
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_subnet_1.id

  vpc_security_group_ids = [aws_security_group.training_sg.id]

  tags = {
    Name = "training-ec2"
  }
}

# outputs.tf
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.training_vpc.id
}

output "public_subnet_ids" {
  description = "パブリックサブネットID"
  value       = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

output "instance_public_ip" {
  description = "EC2インスタンスのパブリックIP"
  value       = aws_instance.training_ec2.public_ip
}
```

</details>

#### 4.3 サンプルコードの参照

Continue AIで生成したコードを参考に、[サンプルコード](../../sample_code/terraform/vpc_subnet_ec2/) も確認してください。

### 5. Terraformの実行（15分）

#### 5.1 初期化

```bash
# Terraformディレクトリに移動
cd workspace/terraform/vpc-subnet-ec2

# 初期化
terraform init
```

#### 5.2 実行計画の確認

```bash
# 実行計画の確認
terraform plan
```

<details>
<summary>📝 実行計画例（クリックで展開）</summary>

```
Terraform will perform the following actions:

  # aws_instance.training_ec2 will be created
  + resource "aws_instance" "training_ec2" {
      + ami                          = "ami-0c3fd0f5d33134a76"
      + instance_type                = "t3.micro"
      ...
    }

  # aws_internet_gateway.training_igw will be created
  + resource "aws_internet_gateway" "training_igw" {
      ...
    }

  # aws_security_group.training_sg will be created
  + resource "aws_security_group" "training_sg" {
      ...
    }

  # aws_subnet.private_subnet_1 will be created
  + resource "aws_subnet" "private_subnet_1" {
      ...
    }

  # aws_subnet.private_subnet_2 will be created
  + resource "aws_subnet" "private_subnet_2" {
      ...
    }

  # aws_subnet.public_subnet_1 will be created
  + resource "aws_subnet" "public_subnet_1" {
      ...
    }

  # aws_subnet.public_subnet_2 will be created
  + resource "aws_subnet" "public_subnet_2" {
      ...
    }

  # aws_vpc.training_vpc will be created
  + resource "aws_vpc" "training_vpc" {
      ...
    }

Plan: 8 to add, 0 to change, 0 to destroy.
```

</details>

#### 5.3 リソースの作成

```bash
# リソースの作成
terraform apply

# 確認プロンプトで "yes" を入力
```

**注意**: 実際にリソースを作成する場合は、`terraform apply`を実行してください。ワークショップ終了後は、`terraform destroy`でリソースを削除してください。

### 6. 構築結果の検証（10分）

#### 6.1 AWSコンソールでの確認

- VPCが作成されているか
- サブネットが作成されているか
- EC2インスタンスが起動しているか
- セキュリティグループが設定されているか

#### 6.2 AWS CLIでの確認

```bash
# VPCの確認
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=training-vpc"

# サブネットの確認
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=training-vpc" --query 'Vpcs[0].VpcId' --output text)
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID"

# EC2インスタンスの確認
aws ec2 describe-instances --filters "Name=tag:Name,Values=training-ec2"

# セキュリティグループの確認
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=training-sg"
```

#### 6.3 Terraform出力の確認

```bash
# 出力値の確認
terraform output
```

<details>
<summary>📝 出力例（クリックで展開）</summary>

```
vpc_id = "vpc-0123456789abcdef0"
public_subnet_ids = [
  "subnet-0123456789abcdef1",
  "subnet-0123456789abcdef2"
]
instance_public_ip = "54.199.xxx.xxx"
```

</details>

#### 6.4 接続テスト（可能な場合）

```bash
# パブリックIPの取得
INSTANCE_IP=$(terraform output -raw instance_public_ip)

# SSH接続テスト
ssh -i training-key.pem ec2-user@$INSTANCE_IP
```

## ✅ チェックリスト

- [ ] VPC設計が完了した
- [ ] サブネット設計が完了した
- [ ] EC2インスタンスの設計が完了した
- [ ] Terraformコードを作成した
- [ ] `terraform init`が成功した
- [ ] `terraform plan`で実行計画を確認した
- [ ] `terraform apply`でリソースを作成した
- [ ] AWSコンソールで構築結果を確認した
- [ ] AWS CLIで構築結果を確認した
- [ ] 接続テストが成功した（可能な場合）

## 🆘 トラブルシューティング

### Terraform初期化エラー

- プロバイダーのバージョンを確認
- ネットワーク接続を確認

### リソース作成エラー

- IAM権限を確認
- リソース制限を確認（例: VPC数、EC2インスタンス数）

### 接続エラー

- セキュリティグループの設定を確認
- キーペアの権限を確認（chmod 400）

## 🧹 クリーンアップ

```bash
# リソースの削除
terraform destroy

# キーペアの削除（AWS CLIで作成した場合）
aws ec2 delete-key-pair --key-name training-key
```

## 📚 参考資料

- [Terraform公式ドキュメント](https://developer.hashicorp.com/terraform/docs)
- [AWS公式ドキュメント](https://docs.aws.amazon.com/)
- [サンプルコード](../../sample_code/terraform/vpc_subnet_ec2/)

## ➡️ 次のステップ

セッション1が完了したら、[セッション2：Terraform自動化エージェント](session2_guide.md) に進んでください。
