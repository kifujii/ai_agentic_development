# セッション1：環境セットアップとVPC/Subnet/EC2構築 詳細ガイド

## 目標
AWSインフラの基本構成を手動で構築し、理解を深める。

## 事前準備
- AWS認証情報の設定完了
- Terraformのインストール確認
- 作業ディレクトリの作成

## 手順

### 1. VPC設計（15分）

#### 1.1 CIDRブロックの設計
推奨設計:
- VPC CIDR: `10.0.0.0/16`
- パブリックサブネット1: `10.0.1.0/24` (ap-northeast-1a)
- パブリックサブネット2: `10.0.2.0/24` (ap-northeast-1c)
- プライベートサブネット1: `10.0.10.0/24` (ap-northeast-1a)
- プライベートサブネット2: `10.0.11.0/24` (ap-northeast-1c)

#### 1.2 可用性ゾーンの選択
```bash
# 利用可能なAZの確認
aws ec2 describe-availability-zones --region ap-northeast-1
```

### 2. サブネット設計（15分）

#### 2.1 パブリック/プライベートサブネットの設計
- **パブリックサブネット**: インターネットゲートウェイへのルートを持つ
- **プライベートサブネット**: インターネットゲートウェイへのルートを持たない

#### 2.2 ルートテーブルの理解
- パブリックサブネット: 0.0.0.0/0 → インターネットゲートウェイ
- プライベートサブネット: ローカル通信のみ

### 3. EC2インスタンスの設計（15分）

#### 3.1 インスタンスタイプの選択
- トレーニング用: `t3.micro` (無料枠対象)

#### 3.2 セキュリティグループの設計
```hcl
# SSHのみ許可（最小権限の原則）
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  # 本番環境では制限すべき
}
```

#### 3.3 キーペアの作成
```bash
# キーペアの作成（AWS CLI）
aws ec2 create-key-pair --key-name training-key --query 'KeyMaterial' --output text > training-key.pem
chmod 400 training-key.pem

# またはTerraformで管理
```

### 4. Terraformコードの手動作成と実行（15分）

#### 4.1 ディレクトリ構造の作成
```bash
mkdir -p terraform/vpc-subnet-ec2
cd terraform/vpc-subnet-ec2
```

#### 4.2 Terraformコードの作成
`main.tf`の作成（`sample_code/terraform/vpc_subnet_ec2/`を参照）

#### 4.3 Terraformの実行
```bash
# 初期化
terraform init

# 実行計画の確認
terraform plan

# リソースの作成
terraform apply

# 確認（必要に応じて）
terraform show
```

### 5. 構築結果の検証（10分）

#### 5.1 AWSコンソールでの確認
- VPCが作成されているか
- サブネットが作成されているか
- EC2インスタンスが起動しているか
- セキュリティグループが設定されているか

#### 5.2 AWS CLIでの確認
```bash
# VPCの確認
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=training-vpc"

# サブネットの確認
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<vpc-id>"

# EC2インスタンスの確認
aws ec2 describe-instances --filters "Name=tag:Name,Values=training-ec2"

# セキュリティグループの確認
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=training-sg"
```

#### 5.3 接続テスト（可能な場合）
```bash
# パブリックIPの取得
INSTANCE_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=training-ec2" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

# SSH接続テスト
ssh -i training-key.pem ec2-user@$INSTANCE_IP
```

## チェックリスト

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

## トラブルシューティング

### Terraform初期化エラー
- プロバイダーのバージョンを確認
- ネットワーク接続を確認

### リソース作成エラー
- IAM権限を確認
- リソース制限を確認（例: VPC数、EC2インスタンス数）

### 接続エラー
- セキュリティグループの設定を確認
- キーペアの権限を確認（chmod 400）

## クリーンアップ
```bash
# リソースの削除
terraform destroy

# キーペアの削除（AWS CLIで作成した場合）
aws ec2 delete-key-pair --key-name training-key
```

## 参考資料
- `sample_code/terraform/vpc_subnet_ec2/`
