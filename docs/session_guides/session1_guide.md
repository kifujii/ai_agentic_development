# セッション1：VPC + EC2 を段階的に構築しよう（必須・2時間）

## 🎯 このセッションの到達状態

以下のAWS環境が構築され、SSH接続できる状態になっています。

![目標構成](../images/session1_target.svg)

| リソース | 設定値 |
|---------|-------|
| VPC | 10.0.0.0/16 |
| パブリックサブネット | 10.0.1.0/24（ap-northeast-1a） |
| インターネットゲートウェイ | VPCにアタッチ |
| ルートテーブル | 0.0.0.0/0 → IGW |
| セキュリティグループ | SSH（22番ポート）のみ許可 |
| キーペア | SSH接続用 |
| EC2インスタンス | t3.micro / Amazon Linux 2023 |

> 💡 このEC2はセッション2でWebアプリケーションを公開し、セッション4以降でAnsibleの操作対象になります。

### 構築の流れ

```
Step 1: VPC を作る           ← お手本プロンプトで体験
    ↓
Step 2: サブネット＆IGW 追加  ← 要件からプロンプトを考える
    ↓
Step 3: キーペア＆SG 追加    ← ヒントだけで挑戦
    ↓
Step 4: EC2 インスタンス作成  ← 自力で挑戦！
    ↓
Step 5: SSH 接続で動作確認
```

> 🎓 **このセッションのポイント**: Step が進むにつれてプロンプトのサポートが減っていきます。「Agentにどう伝えれば動いてくれるか」を自分で考える力を身につけましょう。

---

## 📚 事前準備

> ⚠️ **DevSpacesのワークスペースを再構築した場合**:
> 休憩後のタイムアウトや翌日の作業開始時にワークスペースを再構築した場合は、環境セットアップスクリプトを再実行してください。
> ```bash
> ./scripts/setup_devspaces.sh
> ```
> プロジェクト内のファイル（SSH鍵、Terraformの状態、生成したコード）は保持されています。

1. [環境セットアップガイド](../setup/ENVIRONMENT_SETUP.md) が完了していること
2. SSH鍵ペアを生成しておくこと：

```bash
mkdir -p keys
```

```bash
ssh-keygen -t rsa -b 4096 -f keys/training-key -N ""
```

```bash
chmod 400 keys/training-key
```

> 💡 **なぜ `keys/` フォルダに保存するのか**: DevSpacesではタイムアウト時に環境が再構築されますが、プロジェクトディレクトリ内のファイルは保持されます。`~/.ssh/` に保存するとワークスペースを再構築した場合に鍵が失われてしまうため、プロジェクト内に保存します。

> ⚠️ **作業ディレクトリについて**: Claude Codeへのプロンプトは **プロジェクトルート**（このREADMEがあるフォルダ）から実行してください。

---

## Step 1: VPCを作ろう — 🟢 お手本（25分）

> このStepでは **お手本プロンプト** を用意しています。Agent開発の流れを体験しましょう。

### やること

Claude CodeでVPCを作成するTerraformコードを生成・実行します。

### 手順

1. ターミナルでClaude Codeを起動します（`claude` コマンドを実行）
2. 以下のプロンプトを入力します：

```
terraform/vpc-ec2/ フォルダに、以下の要件でVPCを作成するTerraformコードを作成してください。

- プロバイダー: aws（ap-northeast-1リージョン）
- VPC CIDR: 10.0.0.0/16
- DNSホスト名とDNSサポートを有効化
- タグ: Name = "training-vpc"
- outputs.tf に VPC ID を出力

terraform init と terraform apply まで実行してください。
```

4. Agentが実行計画を提示します → **内容を確認して承認**
5. `terraform apply` の確認が出たら → **`yes` を入力して承認**

### このプロンプトのポイント

| 要素 | プロンプト内の該当部分 | なぜ必要？ |
|------|---------------------|-----------|
| **保存先** | `terraform/vpc-ec2/ フォルダに` | ファイルの作成場所を明確にする |
| **具体的な値** | `CIDR: 10.0.0.0/16` など | 曖昧さをなくし、意図通りの結果を得る |
| **実行指示** | `terraform init と apply まで実行` | コード生成だけでなく実行まで自動化 |

> 💡 **Agent開発の特徴**: プロンプトひとつで「コード生成→ファイル保存→terraform init→apply」まで自動で進みます。

### 確認

```bash
terraform -chdir=terraform/vpc-ec2 output
```

VPC ID（`vpc-xxxxx`）が表示されれば OK ✅

<details>
<summary>❓ うまくいかない場合</summary>

- エラーが出たら、**エラーメッセージをそのままAgentに伝えて**ください — Agentが自動修正してくれます
- 「terraform init から再実行してください」と指示するのも効果的です
- AWS認証情報が設定されているか確認してください（`aws sts get-caller-identity`）

</details>

---

## Step 2: サブネットとインターネット接続を追加しよう — 🟡 ガイド付き（25分）

> このStepからは **自分でプロンプトを考えてみましょう**。要件を読んで、どう伝えればいいか考えてみてください。

### やること

Step 1 で作ったVPCに、パブリックサブネット・インターネットゲートウェイ・ルートテーブルを追加します。

### Agentへ伝える要件

以下の要件を満たすプロンプトを **自分で** 考えて入力してみましょう：

- 📁 対象: `terraform/vpc-ec2/` の既存コード
- 🔧 追加するリソース:
  - パブリックサブネット: CIDR `10.0.1.0/24`（ap-northeast-1a）、パブリックIP自動割り当て有効
  - インターネットゲートウェイ: VPCにアタッチ
  - ルートテーブル: `0.0.0.0/0` → IGW、サブネットに関連付け
- 🏷️ 各リソースに適切なNameタグ
- 📤 outputs.tf にサブネットIDを追加
- 🚀 `terraform apply` まで実行

> 💡 **ヒント**: Step 1 のプロンプトの構造（保存先 → 要件 → 実行指示）を参考にしてみましょう。「既存コードに追加」という指示がポイントです。

<details>
<summary>📝 プロンプト例（まず自分で考えてから開いてください）</summary>

```
terraform/vpc-ec2/ の既存コードに、以下のリソースを追加してください。

- パブリックサブネット: CIDR 10.0.1.0/24（ap-northeast-1a）、パブリックIP自動割り当て有効
- インターネットゲートウェイ: VPCにアタッチ
- ルートテーブル: 0.0.0.0/0 → IGW のルート設定、サブネットに関連付け
- 各リソースに適切なNameタグを付けてください
- outputs.tf にサブネットIDを追加

terraform apply まで実行してください。
```

</details>

### 確認

```bash
terraform -chdir=terraform/vpc-ec2 output
```

サブネットID（`subnet-xxxxx`）が表示されれば OK ✅

> 💡 **ポイント**: 「既存コードに追加して」と伝えるだけで、Agentが既存ファイルを読み取り、適切な位置にコードを追加してくれます。

---

## Step 3: キーペアとセキュリティグループを作ろう — 🟠 ヒント付き（20分）

> このStepでは **ゴールとキーワードだけ** を示します。どんなプロンプトにするかは自分で考えてみましょう。

### やること

SSH接続に必要なキーペアとセキュリティグループを追加します。

### ゴール

- `terraform/vpc-ec2/` に **キーペア** と **セキュリティグループ** が追加されている
- キーペアは事前準備で作った `keys/training-key.pub` を使用している
- セキュリティグループはSSH（22番ポート）のみ許可している
- `terraform output security_group_id` でセキュリティグループIDが表示される

> ⚠️ **output名について**: 後続のセッションでこのoutputを参照します。名前は必ず `security_group_id` にしてください。

### 💡 プロンプトのヒント

- キーペア名は `"training-key"` にしましょう
- アウトバウンドは全許可が一般的です

<details>
<summary>📝 プロンプト例（困ったら参考にしてください）</summary>

```
terraform/vpc-ec2/ の既存コードに、以下のリソースを追加してください。

- キーペア: 公開鍵ファイルは keys/training-key.pub を使用、名前は "training-key"
- セキュリティグループ:
  - インバウンド: SSH（22番ポート）のみ許可
  - アウトバウンド: 全許可
  - VPCに関連付け
- outputs.tf にセキュリティグループIDを追加（output名: security_group_id）

terraform apply まで実行してください。
```

</details>

### 確認

```bash
terraform -chdir=terraform/vpc-ec2 output
```

セキュリティグループID（`sg-xxxxx`）が表示されれば OK ✅

> ⚠️ **セキュリティ注意**: SSH を `0.0.0.0/0` から許可するのはワークショップ用です。本番では `allowed_cidr` のような変数を使って自分のIPのみ（例: `"203.0.113.10/32"`）に制限しましょう。

---

## Step 4: EC2インスタンスを作ろう — 🔴 自力で挑戦！（25分）

> このStepは **自力で挑戦** です。ここまでの経験を活かして、自分でプロンプトを書いてみましょう！

### やること

EC2インスタンスを追加して、SSH接続できる環境を完成させましょう。

### ゴール

- `terraform/vpc-ec2/` に EC2 インスタンスが追加されている（Amazon Linux 2023、t3.micro）
- Step 2 のパブリックサブネットに配置されている
- Step 3 のキーペアとセキュリティグループが適用されている
- `terraform output instance_public_ip` でパブリックIPが表示される
- `terraform output instance_id` でインスタンスIDが表示される

> 🤔 **考えてみよう**: AMI IDはリージョンや日時で変わります。Agentにどう指示すれば「常に最新のAMI」を使えるでしょうか？（ヒント: Terraformの `data source` という機能があります）

<details>
<summary>📝 どうしても困ったら（まずは5分自分で試してから！）</summary>

```
terraform/vpc-ec2/ の既存コードに、EC2インスタンスを追加してください。

- AMI: Amazon Linux 2023 の最新版（data source で自動取得してください）
- インスタンスタイプ: t3.micro
- サブネット: 既存のパブリックサブネットに配置
- キーペア: 既存のキーペアを使用
- セキュリティグループ: 既存のセキュリティグループを使用
- タグ: Name = "training-ec2"
- outputs.tf に以下を追加:
  - パブリックIPアドレス（output名: instance_public_ip）
  - インスタンスID（output名: instance_id）

terraform apply まで実行してください。
```

</details>

### 確認

```bash
terraform -chdir=terraform/vpc-ec2 output instance_public_ip
```

IPアドレスが表示されれば OK ✅

---

## Step 5: SSH接続を確認しよう（15分）

構築した EC2 に SSH で接続して、環境が正しく構築されたか確認します。

### 手順

1. **IPアドレスを確認**:

```bash
terraform -chdir=terraform/vpc-ec2 output instance_public_ip
```

2. **SSH接続**（表示されたIPアドレスに置き換えてください）:

```bash
ssh -i keys/training-key ec2-user@<表示されたIPアドレス>
```

3. 接続できたら `exit` で切断:

```bash
exit
```

接続できれば **セッション1完了** 🎉

> 💡 このEC2は次のセッション以降でAnsibleから操作します。**ワークショップ期間中は削除しないでください。**

<details>
<summary>❓ SSH接続できない場合</summary>

- **数分待ってから再試行** — EC2起動直後は接続できないことがあります（1〜2分）
- セキュリティグループでSSH（22番ポート）が許可されているか確認
- キーペアファイルの権限を確認（`chmod 400 keys/training-key`）
- パブリックIPが割り当てられているか確認（`terraform output`）
- EC2インスタンスが起動しているか確認

</details>

---

## 📝 振り返り（10分）

### Agent開発で体験したこと

| 特徴 | 体験したこと |
|------|------------|
| **コード生成→実行の自動化** | プロンプトだけで terraform init → apply まで自動実行 |
| **段階的な構築** | 既存コードへの「追加」指示で段階的に構築できた |
| **承認ワークフロー** | 変更内容を確認してから実行（human in the loop） |
| **エラー自動修正** | エラー発生時、Agentが自動で修正を提案 |

### プロンプトの書き方で気づいたこと

Step 1〜4を通して、効果的なプロンプトの要素が見えてきたはずです：

- **保存先**を明確にする
- **要件を具体的に**書く（値、名前、設定項目）
- **実行指示**まで含める
- 「既存コードに追加」のように**文脈を伝える**

> 次のセッション以降は、この経験を活かして **最初から自分でプロンプトを考えて** 進めていきます。

---

## ファイル構成

セッション完了時、以下の構成になっています：

```
terraform/
└── vpc-ec2/
    ├── main.tf          # VPC, Subnet, IGW, RT, SG, KP, EC2
    ├── variables.tf     # 変数定義
    └── outputs.tf       # VPC ID, Subnet ID, SG ID, Public IP
```

<details>
<summary>📝 完成形のコード例（クリックで展開）</summary>

### variables.tf

```hcl
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

variable "subnet_cidr" {
  description = "パブリックサブネットのCIDRブロック"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2インスタンスタイプ"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH接続用のキーペア名"
  type        = string
  default     = "training-key"
}
```

### main.tf

```hcl
provider "aws" {
  region = var.region
}

# --- VPC（Step 1） ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "training-vpc"
  }
}

# --- サブネット & インターネット接続（Step 2） ---
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "training-public-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "training-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "training-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --- キーペア & セキュリティグループ（Step 3） ---
resource "aws_key_pair" "training_key" {
  key_name   = var.key_name
  public_key = file("../../keys/training-key.pub")
}

resource "aws_security_group" "ec2_sg" {
  name        = "training-ec2-sg"
  description = "Security group for training EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # ⚠️ ワークショップ用。本番ではIPを制限すること
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "training-ec2-sg"
  }
}

# --- EC2インスタンス（Step 4） ---
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "training_ec2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public.id
  key_name      = aws_key_pair.training_key.key_name

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name = "training-ec2"
  }
}
```

### outputs.tf

```hcl
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "パブリックサブネットID"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "セキュリティグループID"
  value       = aws_security_group.ec2_sg.id
}

output "instance_public_ip" {
  description = "EC2インスタンスのパブリックIP"
  value       = aws_instance.training_ec2.public_ip
}

output "instance_id" {
  description = "EC2インスタンスID"
  value       = aws_instance.training_ec2.id
}
```

</details>

---

## ✅ 完了チェック

以下のコマンドで、このセッションの完了状態を確認できます：

```bash
./scripts/check.sh session1
```

---

## ⚠️ リソースの削除

> ワークショップ期間中はEC2を削除しないでください。**全セッション終了後**に削除してください。

```bash
terraform -chdir=terraform/vpc-ec2 destroy
```

---

## ➡️ 次のステップ

[セッション2：Webアプリケーションを公開しよう](session2_guide.md) に進んでください。
