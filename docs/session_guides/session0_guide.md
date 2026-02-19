# セッション0：AI x IaC基礎実践とAgent開発の理解 詳細ガイド

## 📋 目的

このセッションでは、プロンプトエンジニアリング、Context Engineering、フィードバックループ、開発方式比較を通じて、Agent形式での開発の本質を理解し、AI x IaCの基礎を習得します。

### 学習目標

- 良いプロンプトと悪いプロンプトの違いを理解し、効果的なプロンプトを作成できる
- コンテキスト情報を適切に活用して、品質の高いコードを生成できる
- チャット形式（コードコピー方式）とAgent形式の違いを体験できる
- Agent形式での開発の本質を理解し、開発体験の改善を実感できる
- フィードバックループ（エラー修正、反復的改善、承認ワークフロー）を実践できる

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
- Continueが正しく設定されていること（[Continueセットアップガイド](../setup/CONTINUE_SETUP.md) を参照）
- AWS認証情報が設定されていること

## 🚀 手順

### 1. 環境セットアップ（10分）

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

#### 1.4 Continueの起動確認

Continueは、VS Code/Cursorの拡張機能です。以下の方法で起動できます：

**方法1: ショートカットキー**
- **Windows/Linux**: `Ctrl + L`
- **Mac**: `Cmd + L`

**方法2: サイドバーから**
1. Continueアイコンをクリック（サイドバー左側）
2. チャットパネルが開きます

詳細は [Continueセットアップガイド](../setup/CONTINUE_SETUP.md) を参照してください。

### 2. プロンプトエンジニアリング実践（30分）

#### 2.1 悪いプロンプトでの体験（10分）

**タスク**: EC2インスタンスを作成するTerraformコードを生成する

Continueを起動（`Ctrl+L` / `Cmd+L`）して、以下の**悪いプロンプト**を試してみましょう。

**悪いプロンプト例**:
```
EC2を作成してください
```

**体験ポイント**:
- 生成されたコードに不足パラメータがある（リージョン、インスタンスタイプ、AMIなど）
- デフォルト値が不適切な場合がある
- 要件が不明確で何度も修正が必要
- エラーが発生しやすい
- セキュリティグループの設定が不適切な場合がある

**記録**: 生成されたコードを確認し、不足しているパラメータや問題点を記録してください。

#### 2.2 良いプロンプトでの体験（10分）

次に、以下の**良いプロンプト**を試してみましょう。

**良いプロンプト例**:
```
下記条件を満たすEC2インスタンスを構築するTerraformコードを生成してください。

要件:
- リージョン: ap-northeast-1
- インスタンスタイプ: t3.micro
- OS: Amazon Linux 2023
- セキュリティグループ: SSH（ポート22）のみ許可、送信は全許可
- タグ: Name = "training-ec2", Environment = "training"

注意事項:
- 足りていないパラメータなどがある場合は、そのまま構築するのではなく一度聞き返してください
- 変数定義を含めてください
- コメントを適切に追加してください
- ベストプラクティスに従ってください
```

**体験ポイント**:
- 明確な要件定義で一発で適切なコードが生成される
- 不足パラメータがある場合、AIが聞き返す（「足りていないパラメータがある場合は聞き返してください」の指示により）
- エラーが発生しにくい
- 修正回数が少ない
- セキュリティグループの設定が適切

**記録**: 生成されたコードを確認し、悪いプロンプトとの違いを記録してください。

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

#### 2.3 プロンプト改善の実践（10分）

悪いプロンプトから良いプロンプトへの段階的改善を実践しましょう。

**ステップ1**: 悪いプロンプトで生成されたコードを確認
- 不足しているパラメータを特定
- エラーが発生する可能性のある箇所を特定

**ステップ2**: プロンプトを改善
- 不足パラメータを明記
- 明確な要件定義を追加
- 「足りていないパラメータがある場合は聞き返してください」を追加

**ステップ3**: 改善したプロンプトで再生成
- 生成コードの品質を確認
- 改善前後の比較

**フィードバックループ**: 生成コードの確認→不足点の指摘→プロンプト改善→再生成

**記録**: 改善前後のコード品質、修正回数、作業時間を比較してください。

### 3. Context Engineering実践（15分）

#### 3.1 コンテキストなしでの生成（7分）

**タスク**: 既存のAWSリソース情報なしでEC2インスタンスを作成するTerraformコードを生成

Continueに以下のプロンプトを入力します：

```
EC2インスタンスを作成するTerraformコードを生成してください。
リージョンはap-northeast-1、インスタンスタイプはt3.microです。
```

**体験ポイント**:
- リソース名の重複の可能性（既存のセキュリティグループやVPCと衝突）
- CIDRブロックの衝突の可能性
- 既存リソースとの整合性が取れない
- エラーが発生しやすい

**記録**: 生成されたコードを確認し、既存リソースとの衝突の可能性を記録してください。

#### 3.2 コンテキストありでの生成（8分）

**タスク**: AWSリソース情報を取得してコンテキストとして提供し、既存リソースとの整合性を保ったコードを生成

1. 以下のAWS CLIコマンドを実行して、既存のAWSリソース情報を取得します：

```bash
# 既存のVPC情報を取得
aws ec2 describe-vpcs --region ap-northeast-1 --query 'Vpcs[*].[VpcId,CidrBlock]' --output json

# 既存のサブネット情報を取得
aws ec2 describe-subnets --region ap-northeast-1 --query 'Subnets[*].[SubnetId,CidrBlock,AvailabilityZone]' --output json

# 利用可能な可用性ゾーンを取得
aws ec2 describe-availability-zones --region ap-northeast-1 --query 'AvailabilityZones[*].ZoneName' --output json
```

2. 取得した情報をContinueに提供します：

```
既存のインフラ情報:
{上記のAWS CLIコマンドで取得した情報を貼り付け}

上記の情報を考慮して、新しいEC2インスタンスを作成するTerraformコードを生成してください。
既存のリソースと衝突しないように注意してください。
```

<details>
<summary>📝 実行結果例（クリックで展開）</summary>

```json
[
  [
    "vpc-0123456789abcdef0",
    "10.0.0.0/16"
  ]
]
[
  [
    "subnet-0123456789abcdef1",
    "10.0.1.0/24",
    "ap-northeast-1a"
  ],
  [
    "subnet-0123456789abcdef2",
    "10.0.2.0/24",
    "ap-northeast-1c"
  ]
]
[
  "ap-northeast-1a",
  "ap-northeast-1c",
  "ap-northeast-1d"
]
```

</details>

**体験ポイント**:
- 既存リソースとの整合性を保ったコード生成
- リソース名の重複回避
- CIDRブロックの適切な割り当て
- エラーが発生しにくい

**記録**: コンテキストありとコンテキストなしの生成コードを比較し、違いを記録してください。

### 4. チャット形式 vs Agent形式の比較（15分）

#### 4.1 チャット形式での開発（7分）

**タスク**: 同じEC2インスタンス作成をチャット形式（コードコピー方式）で実行

**プロセス**:
1. Continueにプロンプトを入力
2. 生成されたコードをコピー
3. ファイルに貼り付け
4. エラーが発生した場合、エラーメッセージをコピーしてContinueに質問
5. 修正コードをコピーして貼り付け
6. 繰り返し修正

**記録**: 作業時間、手動操作回数（コピー・貼り付け・ファイル編集）、エラー修正回数を記録してください。

#### 4.2 Agent形式での開発（8分）

**タスク**: 同じEC2インスタンス作成をAgent形式で実行

**プロセス**:
1. シンプルなAgentを起動（テンプレート提供）
2. 「EC2インスタンスを作成してください」と指示
3. Agentが自動的にコード生成→検証→実行
4. エラー発生時、Agentが自動検出→修正提案→人間が承認
5. 修正後の再実行

**記録**: 作業時間、手動操作回数、エラー修正回数を記録してください。

**比較**: チャット形式とAgent形式の作業時間、手動操作回数、エラー修正回数を比較してください。

### 5. Agent形式での開発の理解（20分）

#### 5.1 Agent形式の本質的理解（10分）

**Agent形式の特徴**:
- コード生成から実行までの自動化
- コンテキストの自動管理
- エラー検出と修正提案の自動化
- 人間の判断が必要な場面での中断と確認（human in the loop）

**Agent形式のメリット**:
- 開発速度の向上
- エラー修正の効率化
- コンテキスト管理の自動化
- 一貫性のあるコード生成

**Agent形式の適用場面**:
- 繰り返し作業の自動化
- 複雑な依存関係の管理
- エラーハンドリングの自動化

#### 5.2 Agent形式での実践（10分）

**タスク**: 同じEC2インスタンス作成をAgent形式で実践

**プロセス**:
1. Agentに自然言語で指示
   ```
   ap-northeast-1リージョンに、t3.microインスタンスタイプのEC2インスタンスを作成してください。
   セキュリティグループはSSH（ポート22）のみ許可し、Nameタグに"training-ec2"を設定してください。
   ```
2. Agentが計画を提示（承認ワークフロー）
   - Agentが実行計画を表示
   - 人間が承認
3. Agentがコード生成→検証→実行
4. エラー発生時、自動検出→修正提案→承認→再実行（エラー修正プロセス）
5. 「セキュリティグループをより厳格にしてください」などのフィードバック（反復的改善）
6. Agentが改善→再検証→実行

**フィードバックループの3つのパターン**:
1. **エラー修正プロセス**: AIがエラー検出→修正提案→人間が承認
2. **反復的改善**: 人間のフィードバック→AIが改善→再検証
3. **承認ワークフロー**: AIが計画提示→人間が承認→実行

**体験ポイント**:
- Agent形式での開発フローの理解
- フィードバックループの実践
- human in the loopの重要性の理解
- 開発体験の改善を実感

**記録**: Agent形式での開発体験を記録し、チャット形式との違いをまとめてください。


## ✅ チェックリスト

- [ ] 環境セットアップが完了した
- [ ] Continueが正常に動作することを確認した
- [ ] AWS認証情報が正しく設定されている
- [ ] 悪いプロンプトと良いプロンプトの比較体験を行った
- [ ] プロンプト改善の実践を行った
- [ ] コンテキストなしとコンテキストありでの生成を比較した
- [ ] チャット形式とAgent形式の比較体験を行った
- [ ] Agent形式での開発の理解を深めた
- [ ] フィードバックループの3つのパターンを体験した

## 🆘 トラブルシューティング

### Continueが起動しない

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
