# セッション1：Agent形式でのVPC/Subnet/EC2構築 詳細ガイド

## 📋 目的

このセッションでは、プロンプトエンジニアリング、Context Engineering、フィードバックループを実践しながら、Agent形式でVPC/Subnet/EC2を構築し、Agent形式での開発体験を深めます。

### 学習目標

- プロンプトエンジニアリングの実践（悪いプロンプトから良いプロンプトへの改善）
- Context Engineeringの実践（既存AWSリソース情報の活用）
- Agent形式での構築体験
- フィードバックループの実践（エラー修正、反復的改善、承認ワークフロー）
- Agent形式での開発の振り返り

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

### 1. プロンプトエンジニアリングの実践（20分）

#### 1.1 悪いプロンプトから始める

**タスク**: VPC、パブリック/プライベートサブネット、EC2インスタンスを構築

Continueを起動して、以下の**悪いプロンプト**を試してみましょう。

**悪いプロンプト例**:
```
VPCとEC2を作成してください
```

**問題点の確認**:
- 不足パラメータ（CIDRブロック、可用性ゾーン、インスタンスタイプなど）
- 不明確な要件（パブリック/プライベートサブネットの指定がない）
- インターネットゲートウェイやNAT Gatewayの設定がない
- セキュリティグループの設定が不適切

**記録**: 生成されたコードを確認し、不足しているパラメータや問題点を記録してください。

#### 1.2 良いプロンプトへの改善

次に、以下の**良いプロンプト**を試してみましょう。

**良いプロンプト例**:
```
下記条件を満たすVPC、サブネット、EC2インスタンスを構築するTerraformコードを生成してください。

要件:
- VPC CIDR: 10.0.0.0/16
- パブリックサブネット: 10.0.1.0/24 (ap-northeast-1a)
- プライベートサブネット: 10.0.2.0/24 (ap-northeast-1c)
- EC2インスタンス: t3.micro, Amazon Linux 2023, パブリックサブネットに配置
- インターネットゲートウェイとNAT Gatewayを適切に設定
- セキュリティグループ: SSH（ポート22）のみ許可、送信は全許可

注意事項:
- 足りていないパラメータがある場合は、そのまま構築するのではなく一度聞き返してください
- 既存のVPCやサブネットと衝突しないように確認してください
- 変数定義を含めてください
- コメントを適切に追加してください
- ベストプラクティスに従ってください
```

**体験ポイント**:
- 明確な要件定義で一発で適切なコードが生成される
- 不足パラメータがある場合、AIが聞き返す
- 既存リソースとの衝突を回避できる
- エラーが発生しにくい

**記録**: 改善前後のコード品質、修正回数、作業時間を比較してください。

### 2. Context Engineeringの実践（20分）

#### 2.1 既存のAWSリソース情報を取得

既存のAWSリソース情報を取得して、コンテキストとして活用します。

以下のAWS CLIコマンドを実行します：

```bash
# 既存のVPC情報を取得
aws ec2 describe-vpcs --region ap-northeast-1 --query 'Vpcs[*].[VpcId,CidrBlock]' --output json

# 既存のサブネット情報を取得
aws ec2 describe-subnets --region ap-northeast-1 --query 'Subnets[*].[SubnetId,CidrBlock,AvailabilityZone]' --output json

# 既存のセキュリティグループ情報を取得
aws ec2 describe-security-groups --region ap-northeast-1 --query 'SecurityGroups[*].[GroupId,GroupName]' --output json

# 利用可能な可用性ゾーンを取得
aws ec2 describe-availability-zones --region ap-northeast-1 --query 'AvailabilityZones[*].ZoneName' --output json
```

#### 2.2 コンテキストをAgentに提供

取得したコンテキスト情報をContinueに提供します。

```
既存のインフラ情報:
{上記のAWS CLIコマンドで取得した情報を貼り付け}

上記の情報を考慮して、新しいVPC、サブネット、EC2インスタンスを作成するTerraformコードを生成してください。
既存のリソースと衝突しないように注意してください。
```

**体験ポイント**:
- 既存リソースとの整合性を保ったコード生成
- リソース名の重複回避
- CIDRブロックの適切な割り当て
- エラーが発生しにくい

**記録**: コンテキストありとコンテキストなしの生成コードを比較し、違いを記録してください。

### 3. Agent形式での構築とフィードバックループ（40分）

#### 3.1 Agentの拡張

セッション0で使用したシンプルなAgentを拡張して、VPC、Subnet、EC2の統合構築に対応させます。

```bash
# Agentテンプレートを確認
cat templates/ai_agents/simple_agent_template.py
```

#### 3.2 Agentが計画を提示（承認ワークフロー）

Agentに以下の指示を入力します：

```
下記条件を満たすVPC、サブネット、EC2インスタンスを構築するTerraformコードを生成してください。

要件:
- VPC CIDR: 10.0.0.0/16
- パブリックサブネット: 10.0.1.0/24 (ap-northeast-1a)
- プライベートサブネット: 10.0.2.0/24 (ap-northeast-1c)
- EC2インスタンス: t3.micro, Amazon Linux 2023, パブリックサブネットに配置
- インターネットゲートウェイとNAT Gatewayを適切に設定
```

**承認ワークフロー**:
1. Agentが実行計画を表示
2. 計画を確認（リソースの種類、数、依存関係など）
3. 人間が承認（`y`を入力）または修正要求

**記録**: Agentが提示した計画を確認し、承認前に必要な情報が含まれているか確認してください。

#### 3.3 Agentがコード生成→検証→実行

Agentが承認後、以下の処理を自動的に実行します：

1. **コード生成**: プロンプトとコンテキスト情報に基づいてTerraformコードを生成
2. **検証**: `terraform fmt`と`terraform validate`を自動実行
3. **実行**: `terraform init`と`terraform plan`を実行

**記録**: 生成されたコード、検証結果、実行計画を確認してください。

#### 3.4 エラー発生時の処理（エラー修正プロセス）

エラーが発生した場合、Agentが自動的に以下を実行します：

1. **エラー検出**: エラーメッセージを解析
2. **修正提案**: エラーの原因を特定し、修正案を提示
3. **人間の承認**: 修正案を確認し、承認（`y`）または拒否（`n`）
4. **修正適用**: 承認後、修正を適用して再実行

**例**:
```
エラー: Resource 'aws_vpc.training_vpc' already exists
修正提案: 既存のVPCを使用するか、新しいVPC名を指定してください。
承認しますか？ (y/n): y
```

**記録**: エラー修正プロセスの体験を記録してください。

#### 3.5 反復的改善の実践

構築後、以下のようなフィードバックをAgentに提供します：

```
セキュリティグループをより厳格にしてください。
SSHのアクセス元を特定のIPアドレスのみに制限してください。
```

**反復的改善プロセス**:
1. 人間のフィードバックを提供
2. Agentが改善案を提示
3. 人間が承認
4. Agentが改善を適用→再検証→実行

**記録**: 反復的改善の体験を記録してください。

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

### 4. Agent形式での開発の振り返り（10分）

#### 4.1 プロンプトエンジニアリングの効果

**振り返り項目**:
- 悪いプロンプトと良いプロンプトの違いは何でしたか？
- 良いプロンプトを使用することで、どのような改善が見られましたか？
- 不足パラメータの聞き返し機能は役に立ちましたか？

**記録**: プロンプトエンジニアリングの効果をまとめてください。

#### 4.2 Context Engineeringの重要性

**振り返り項目**:
- コンテキストなしとコンテキストありでの生成コードの違いは何でしたか？
- 既存リソース情報を提供することで、どのような問題を回避できましたか？
- Context Engineeringの重要性をどのように感じましたか？

**記録**: Context Engineeringの重要性をまとめてください。

#### 4.3 フィードバックループの体験

**振り返り項目**:
- エラー修正プロセスはどのように機能しましたか？
- 反復的改善プロセスはどのように機能しましたか？
- 承認ワークフローはどのように機能しましたか？
- human in the loopの重要性をどのように感じましたか？

**記録**: フィードバックループの体験をまとめてください。

#### 4.4 Agent形式での開発体験の改善点

**振り返り項目**:
- Agent形式での開発で、どのような点が改善されましたか？
- チャット形式（コードコピー方式）と比較して、どのような違いを感じましたか？
- 開発速度、エラー修正の効率、コンテキスト管理の自動化など、どの点が最も改善されましたか？
- Agent形式での開発の課題や改善点はありますか？

**記録**: Agent形式での開発体験の改善点をまとめてください。

## ✅ チェックリスト

- [ ] プロンプトエンジニアリングの実践を行った（悪いプロンプトと良いプロンプトの比較）
- [ ] Context Engineeringの実践を行った（既存AWSリソース情報の活用）
- [ ] Agent形式での構築を体験した
- [ ] 承認ワークフローを体験した
- [ ] エラー修正プロセスを体験した
- [ ] 反復的改善プロセスを体験した
- [ ] Agent形式での開発の振り返りを行った
- [ ] VPC、Subnet、EC2インスタンスが構築された

## 🆘 トラブルシューティング

### Agentがエラーを検出できない

- Agentのエラーハンドリング機能を確認
- エラーメッセージの形式を確認

### コンテキスト情報の取得エラー

- AWS認証情報が正しく設定されているか確認
- IAM権限が適切か確認

### 承認ワークフローが機能しない

- Agentの設定を確認
- 人間の承認プロセスが正しく実装されているか確認

## 📚 参考資料

- [Terraform公式ドキュメント](https://developer.hashicorp.com/terraform/docs)
- [AWS公式ドキュメント](https://docs.aws.amazon.com/)
- [サンプルコード](../../sample_code/terraform/vpc_subnet_ec2/)

## ➡️ 次のステップ

セッション1が完了したら、[セッション2：Terraform自動化エージェント](session2_guide.md) に進んでください。
