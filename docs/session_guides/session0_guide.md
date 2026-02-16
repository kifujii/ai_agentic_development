# セッション0：AI x IaC基礎実践 詳細ガイド

## 📋 目的

このセッションでは、Continue AIを活用しながら、Prompt Engineering、Context Engineering、AI Agentの実践を通じて、AI x IaCの基礎を習得します。

### 学習目標

- Continue AIの基本的な使い方を習得する
- 効果的なプロンプト設計方法を理解する
- コンテキスト情報の活用方法を理解する
- AIを活用したTerraformコード生成を実践する

## 🎯 目指すべき構成

このセッション終了時点で、以下の構成が完成していることを目指します：

```
workspace/
├── terraform/
│   └── ec2_instance.tf          # 生成されたTerraformコード
└── prompts/
    └── terraform_ec2_template.txt # プロンプトテンプレート
```

## 📚 事前準備

- [環境セットアップガイド](../setup/ENVIRONMENT_SETUP.md) を完了していること
- Continue AIが正しく設定されていること（[Continueセットアップガイド](../setup/CONTINUE_SETUP.md) を参照）
- AWS認証情報が設定されていること

## 🚀 手順

### 1. 環境セットアップ（15分）

#### 1.1 OpenShift DevSpaces環境の確認

```bash
# 現在のディレクトリ確認
pwd

# 環境変数の確認
env | grep -E "AWS"

# Python/Node.jsのバージョン確認
python3 --version
node --version
```

#### 1.2 AWS CLI/認証情報の設定

```bash
# AWS CLIのインストール確認
aws --version

# .envファイルから環境変数を読み込む
export $(cat .env | grep -v '^#' | xargs)

# 認証情報の確認
aws sts get-caller-identity
```

**注意**: `.env`ファイルを環境変数としてエクスポートすれば、AWS CLIとTerraformの両方が認証情報を使用できます。`aws configure`は不要です。

詳細は [環境セットアップガイド](../setup/ENVIRONMENT_SETUP.md) を参照してください。

#### 1.3 必要なツールのインストール確認

```bash
# Terraformのインストール確認
terraform version

# Ansibleのインストール確認
ansible --version

# Pythonパッケージのインストール確認
python3 -m pip list | grep -E "boto3|python-dotenv"
```

### 2. Continue AIの基本操作（10分）

#### 2.1 Continueの起動

Continue AIは、VS Code/Cursorの拡張機能です。以下の方法で起動できます：

**方法1: ショートカットキー**
- **Windows/Linux**: `Ctrl + L`
- **Mac**: `Cmd + L`

**方法2: サイドバーから**
1. Continueアイコンをクリック（サイドバー左側）
2. チャットパネルが開きます

#### 2.2 基本的な使い方

1. **コード生成**: 自然言語で指示を入力
2. **コード選択**: コードを選択してからContinueに質問すると、選択したコードをコンテキストとして使用します
3. **ファイル全体**: ファイルを開いた状態で質問すると、ファイル全体がコンテキストとして使用されます

詳細は [Continueセットアップガイド](../setup/CONTINUE_SETUP.md) を参照してください。

### 3. Prompt Engineering実践（30分）

#### 3.1 基本的なプロンプトの作成

**タスク**: EC2インスタンスを作成するTerraformコードを生成する

Continue AIを起動（`Ctrl+L` / `Cmd+L`）して、以下のプロンプトを試してみましょう。

**悪い例**:
```
EC2を作成して
```

**良い例**:
```
以下の要件でEC2インスタンスを作成するTerraformコードを生成してください。

要件:
- リージョン: ap-northeast-1
- インスタンスタイプ: t3.micro
- AMI: Amazon Linux 2023
- セキュリティグループ: SSH（ポート22）のみ許可
- タグ: Name = "training-ec2", Environment = "training"

出力形式:
- HCL形式のTerraformコード
- 変数定義を含める
- コメントを適切に追加
```

<details>
<summary>📝 回答例（クリックで展開）</summary>

```hcl
# variables.tf
variable "instance_type" {
  description = "EC2インスタンスタイプ"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
  default     = "ami-0c3fd0f5d33134a76" # Amazon Linux 2023
}

variable "tags" {
  description = "リソースタグ"
  type        = map(string)
  default = {
    Name        = "training-ec2"
    Environment = "training"
  }
}

# main.tf
provider "aws" {
  region = "ap-northeast-1"
}

# セキュリティグループ
resource "aws_security_group" "training_sg" {
  name        = "training-sg"
  description = "Training security group for EC2"

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

  tags = var.tags
}

# EC2インスタンス
resource "aws_instance" "training_ec2" {
  ami           = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.training_sg.id]

  tags = var.tags
}
```

</details>

#### 3.2 プロンプトテンプレートの作成

再利用可能なプロンプトテンプレートを作成しましょう。

1. `workspace/prompts/` ディレクトリを作成
2. `terraform_ec2_template.txt` を作成

<details>
<summary>📝 プロンプトテンプレート例（クリックで展開）</summary>

```
以下の要件で{resource_type}を作成するTerraformコードを生成してください。

要件:
- リージョン: {region}
- {specific_requirements}

出力形式:
- HCL形式のTerraformコード
- 変数定義を含める
- コメントを適切に追加
- ベストプラクティスに従う
```

</details>

#### 3.3 段階的なプロンプト最適化

1. **第1段階**: 基本的な要件を記述
2. **第2段階**: エラーフィードバックを反映
3. **第3段階**: ベストプラクティスを追加
4. **第4段階**: 再利用可能なテンプレート化

**実践**: Continue AIで段階的にプロンプトを改善し、生成コードの品質向上を確認しましょう。

### 4. Context Engineering実践（20分）

#### 4.1 AWSリソース情報のコンテキスト化

Continue AIに、AWSリソース情報をコンテキストとして提供する方法を実践します。

1. 以下のPythonスクリプトを作成して実行
2. 取得した情報をContinue AIに提供

```python
# get_aws_context.py
import boto3
import json

def get_aws_context():
    """AWSリソース情報を取得してコンテキスト化"""
    ec2 = boto3.client('ec2')
    
    # 利用可能なAMIの取得
    amis = ec2.describe_images(
        Owners=['amazon'],
        Filters=[
            {'Name': 'name', 'Values': ['amzn2-ami-hvm-*']},
            {'Name': 'state', 'Values': ['available']}
        ]
    )
    
    # リージョン情報の取得
    regions = ec2.describe_regions()
    
    context = {
        'available_amis': amis['Images'][:5],
        'regions': [r['RegionName'] for r in regions['Regions']],
        'current_region': ec2.meta.region_name
    }
    
    return context

if __name__ == "__main__":
    context = get_aws_context()
    print(json.dumps(context, indent=2, ensure_ascii=False))
```

<details>
<summary>📝 実行結果例（クリックで展開）</summary>

```json
{
  "available_amis": [
    {
      "ImageId": "ami-0c3fd0f5d33134a76",
      "Name": "amzn2-ami-hvm-2.0.20231218.0-x86_64-gp2",
      "Description": "Amazon Linux 2 AMI 2.0.20231218.0 x86_64 HVM gp2"
    }
  ],
  "regions": [
    "ap-northeast-1",
    "ap-northeast-3",
    "us-east-1"
  ],
  "current_region": "ap-northeast-1"
}
```

</details>

#### 4.2 既存コードのコンテキスト活用

既存のTerraformコードを開いて、Continue AIに質問することで、コード全体をコンテキストとして活用できます。

1. 既存のTerraformファイルを開く
2. Continue AIを起動
3. コードに関する質問をする

例：
```
「このTerraformコードを改善して、より再利用可能な形にしてください」
```

### 5. AI x IaCを使ったEC2の設計・構築・検証（25分）

#### 5.1 自然言語指示による設計

Continue AIを起動して、以下の指示を入力します：

```
ap-northeast-1リージョンに、t3.microインスタンスタイプのEC2インスタンスを作成してください。
セキュリティグループはSSH（ポート22）のみ許可し、Nameタグに"training-ec2"を設定してください。
```

#### 5.2 生成コードの保存

Continue AIが生成したコードを、`workspace/terraform/ec2_instance.tf` に保存します。

#### 5.3 生成コードの検証と修正

```bash
# Terraformディレクトリに移動
cd workspace/terraform

# Terraformフォーマット
terraform fmt

# Terraform検証
terraform init
terraform validate

# 実行計画の確認
terraform plan
```

<details>
<summary>📝 検証結果例（クリックで展開）</summary>

```
Terraform will perform the following actions:

  # aws_instance.training_ec2 will be created
  + resource "aws_instance" "training_ec2" {
      + ami                          = "ami-0c3fd0f5d33134a76"
      + instance_type                = "t3.micro"
      ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

</details>

#### 5.4 EC2インスタンスの構築と動作確認

```bash
# リソースの作成（実際に作成する場合は実行）
# terraform apply

# AWSコンソールでの確認
aws ec2 describe-instances --filters "Name=tag:Name,Values=training-ec2"
```

**注意**: 実際にリソースを作成する場合は、`terraform apply`を実行してください。ワークショップ終了後は、`terraform destroy`でリソースを削除してください。

## ✅ チェックリスト

- [ ] 環境セットアップが完了した
- [ ] Continue AIが正常に動作することを確認した
- [ ] AWS認証情報が正しく設定されている
- [ ] 基本的なプロンプトを作成した
- [ ] プロンプトテンプレートを作成した
- [ ] Context Engineeringの実践を行った
- [ ] EC2インスタンスのTerraformコードを生成した
- [ ] 生成コードの検証を行った

## 🆘 トラブルシューティング

### Continue AIが起動しない

- 拡張機能が正しくインストールされているか確認
- VS Code/Cursorを再起動
- Continueの設定ファイル（`.continue/config.json`）が正しいか確認

詳細は [Continueセットアップガイド](../setup/CONTINUE_SETUP.md) を参照してください。

### AWS認証エラー

- 認証情報が正しく設定されているか確認
- IAM権限が適切か確認

### Terraformエラー

- プロバイダーのバージョンを確認
- リソース名の重複を確認

## 📚 参考資料

- [Continue公式ドキュメント](https://continue.dev/docs)
- [Terraform公式ドキュメント](https://developer.hashicorp.com/terraform/docs)
- [AWS公式ドキュメント](https://docs.aws.amazon.com/)
- [サンプルコード](../../sample_code/terraform/basic_ec2/)

## ➡️ 次のステップ

セッション0が完了したら、[セッション1：VPC/Subnet/EC2構築](session1_guide.md) に進んでください。
