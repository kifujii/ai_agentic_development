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

> ⚠️ **リソース名の prefix について**: 複数人が同一AWS環境を使用するため、すべてのリソース名に **自分の prefix**（例: `user01`）を付けます。prefix は `.env` ファイルで設定済みで、Terraform では `var.prefix` として自動的に使えます。

> 💡 このEC2はセッション2でnginxをインストールしてWebページを公開し、セッション4以降でAnsibleの操作対象になります。

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

> 🎓 **このセッションのポイント**: Step が進むにつれてプロンプトのサポートが減っていきます。「Claude Code にどう伝えれば動いてくれるか」を自分で考える力を身につけましょう。

> 📖 **このガイドの読み方**:
> - `📝 プロンプト例` → **Claude Code に入力する**指示内容です
> - `bash` コマンドブロック → 特に注記がない限り、**あなたがターミナルで実行する**コマンドです
> - 「Claude Code が〜」 → Claude Code が自動的に行う処理です

> ⏱️ **時間配分について**: 各 Step の所要時間は目安です。Claude Code の応答速度やエラー対応で前後することがあります。時間が足りない場合は講師に相談し、**Step の途中でも区切って次に進む** ことを検討してください。

---

## 📚 事前準備

> ⚠️ **環境変数が未設定の場合**:
> 新しいターミナルを開いた際に `$TF_VAR_prefix` が未設定の場合は、セットアップスクリプトを再実行してください。
> ```bash
> ./scripts/setup.sh
> ```

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

> 💡 **なぜ `keys/` フォルダに保存するのか**: プロジェクトディレクトリ内に保存することで、他のセッションからも同じパスで参照できます。`~/.ssh/` に保存するとパスが環境依存になるため、プロジェクト内に保存します。

> ⚠️ **作業ディレクトリについて**: Claude Codeへのプロンプトは **プロジェクトルート**（このREADMEがあるフォルダ）から実行してください。

> 💡 **リソース名のPREFIXについて**: プロンプト例では `training-vpc` のような名前を使っていますが、Claude Code は CLAUDE.md の規則に従い、Terraform コードでは自動的に `var.prefix`（セットアップで設定した自分のユーザー名）をリソース名の先頭に付けます。例: `training-vpc` → `${var.prefix}-vpc`。これにより、他の受講者とリソース名が衝突しません。

---

## Step 1: VPCを作ろう — 🟢 お手本（25分）

> このStepでは **お手本プロンプト** を用意しています。Agent開発の流れを体験しましょう。

### やること

Claude CodeでVPCを作成するTerraformコードを生成・実行します。

### 手順

1. **あなた**がターミナルで Claude Code を起動します（`claude` コマンドを実行）
2. 以下のプロンプトを **Claude Code に** 入力します：

```
terraform/vpc-ec2/ フォルダに、以下の要件でVPCを作成するTerraformコードを作成してください。

- プロバイダー: aws（ap-northeast-1リージョン）
- variables.tf に prefix 変数を定義（デフォルト値なし、環境変数 TF_VAR_prefix から自動取得される）
- VPC CIDR: 10.0.0.0/16
- DNSホスト名とDNSサポートを有効化
- タグ: Name = "${var.prefix}-vpc"
- outputs.tf に VPC ID を出力

terraform init と terraform apply まで実行してください。
```

4. Claude Code が実行計画を提示します → **あなたが内容を確認して承認**
5. Claude Code が `terraform apply` の確認を求めたら → **あなたが `yes` を入力して承認**

### このプロンプトのポイント

| 要素 | プロンプト内の該当部分 | なぜ必要？ |
|------|---------------------|-----------|
| **保存先** | `terraform/vpc-ec2/ フォルダに` | ファイルの作成場所を明確にする |
| **prefix** | `${var.prefix}-vpc` | 他の受講者のリソースと名前が衝突しない |
| **具体的な値** | `CIDR: 10.0.0.0/16` など | 曖昧さをなくし、意図通りの結果を得る |
| **実行指示** | `terraform init と apply まで実行` | コード生成だけでなく実行まで自動化 |

> 💡 **AI Agent 開発の特徴**: あなたがプロンプトを入力するだけで、AI Agent が「コード生成→ファイル保存→terraform init→apply」まで自動で進めてくれます。

### 確認（あなたがターミナルで実行）

```bash
terraform -chdir=terraform/vpc-ec2 output
```

VPC ID（`vpc-xxxxx`）が表示されれば OK ✅

<details>
<summary>❓ うまくいかない場合</summary>

- エラーが出たら、**エラーメッセージをそのまま Claude Code に伝えて**ください — AI Agent が自動修正してくれます
- 「terraform init から再実行してください」と Claude Code に指示するのも効果的です
- あなたのターミナルで AWS認証情報が設定されているか確認してください（`aws sts get-caller-identity`）

</details>

---

### 🔧 AI とのトラブルシューティング — 基本パターン

> ワークショップ全体を通じて、何か問題が起きたときは以下のパターンで対応できます。
>
> ```
> 1. あなたが Claude Code にタスクを依頼する
> 2. AI Agent が実行し、あなたが結果を確認する（成功 or エラー）
> 3. エラーの場合 → エラーメッセージをそのまま Claude Code に共有
> 4. AI Agent が原因を分析し、修正案を提示・実行
> 5. あなたが結果を再確認
> 6. 解決するまで 3〜5 を繰り返す
> ```
>
> 💡 **ポイント**: AI Agent はエラーメッセージから多くの情報を読み取れます。「動きません」よりも **エラーの全文を貼り付ける** 方が、はるかに正確な診断ができます。
>
> このパターンは Terraform、Ansible、AWS CLI、どんなツールでも同じです。**セッション4の障害対応シミュレーション**ではこのパターンを実践的に体験します。

---

## Step 2: サブネットとインターネット接続を追加しよう — 🟡 ガイド付き（25分）

> このStepからは **自分でプロンプトを考えてみましょう**。要件を読んで、どう伝えればいいか考えてみてください。

### やること

Step 1 で作ったVPCに、パブリックサブネット・インターネットゲートウェイ・ルートテーブルを追加します。

### Claude Code へ伝える要件

以下の要件を満たすプロンプトを **自分で** 考えて **Claude Code に** 入力してみましょう：

- 📁 対象: `terraform/vpc-ec2/` の既存コード
- 🔧 追加するリソース:
  - パブリックサブネット: CIDR `10.0.1.0/24`（ap-northeast-1a）、パブリックIP自動割り当て有効
  - インターネットゲートウェイ: VPCにアタッチ
  - ルートテーブル: `0.0.0.0/0` → IGW、サブネットに関連付け
- 🏷️ 各リソースに適切なNameタグ
- 📤 outputs.tf にサブネットIDを追加
- 🚀 `terraform apply` まで実行

> 💡 **ヒント**: Step 1 のプロンプトの構造（保存先 → 要件 → 実行指示）を参考にしてみましょう。Claude Code に「既存コードに追加」と伝えるのがポイントです。

<details>
<summary>📝 プロンプト例（まず自分で考えてから開いてください）</summary>

```
terraform/vpc-ec2/ の既存コードに、以下のリソースを追加してください。

- パブリックサブネット: CIDR 10.0.1.0/24（ap-northeast-1a）、パブリックIP自動割り当て有効
- インターネットゲートウェイ: VPCにアタッチ
- ルートテーブル: 0.0.0.0/0 → IGW のルート設定、サブネットに関連付け
- 各リソースのNameタグは "${var.prefix}-xxx" 形式で付けてください
- outputs.tf にサブネットIDを追加

terraform apply まで実行してください。
```

</details>

### 確認（あなたがターミナルで実行）

```bash
terraform -chdir=terraform/vpc-ec2 output
```

サブネットID（`subnet-xxxxx`）が表示されれば OK ✅

> 💡 **ポイント**: 「既存コードに追加して」と Claude Code に伝えるだけで、Claude Code が既存ファイルを読み取り、適切な位置にコードを追加してくれます。

---

## Step 3: キーペアとセキュリティグループを作ろう — 🟠 ヒント付き（20分）

> このStepでは **ゴールとキーワードだけ** を示します。どんなプロンプトにするかは自分で考えてみましょう。

### やること

SSH接続に必要なキーペアとセキュリティグループを追加します。

### ゴール

- Claude Code が `terraform/vpc-ec2/` に **キーペア** と **セキュリティグループ** を追加している
- キーペアは事前準備で作った `keys/training-key.pub` を使用している
- セキュリティグループはSSH（22番ポート）のみ許可している
- `terraform output security_group_id` でセキュリティグループIDが表示される

> ⚠️ **output名について**: 後続のセッションでこのoutputを参照します。プロンプトで名前を必ず `security_group_id` と指定してください。

### 💡 Claude Code へのプロンプトのヒント

- キーペア名は `"${var.prefix}-key"` にしましょう
- アウトバウンドは全許可が一般的です

<details>
<summary>📝 プロンプト例（困ったら参考にしてください）</summary>

```
terraform/vpc-ec2/ の既存コードに、以下のリソースを追加してください。

- キーペア: 公開鍵ファイルは keys/training-key.pub を使用、名前は "${var.prefix}-key"
- セキュリティグループ:
  - 名前: "${var.prefix}-ec2-sg"
  - インバウンド: SSH（22番ポート）のみ許可
  - アウトバウンド: 全許可
  - VPCに関連付け
- outputs.tf にセキュリティグループIDを追加（output名: security_group_id）

terraform apply まで実行してください。
```

</details>

### 確認（あなたがターミナルで実行）

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

- Claude Code が `terraform/vpc-ec2/` に EC2 インスタンスを追加している（Amazon Linux 2023、t3.micro）
- Step 2 のパブリックサブネットに配置されている
- Step 3 のキーペアとセキュリティグループが適用されている
- `terraform output instance_public_ip` でパブリックIPが表示される
- `terraform output instance_id` でインスタンスIDが表示される

> 🤔 **考えてみよう**: AMI IDはリージョンや日時で変わります。Claude Code にどう指示すれば「常に最新のAMI」を使えるでしょうか？（ヒント: Terraformの `data source` という機能があります）

<details>
<summary>📝 どうしても困ったら（まずは5分自分で試してから！）</summary>

```
terraform/vpc-ec2/ の既存コードに、EC2インスタンスを追加してください。

- AMI: Amazon Linux 2023 の最新版（data source で自動取得してください）
- インスタンスタイプ: t3.micro
- サブネット: 既存のパブリックサブネットに配置
- キーペア: 既存のキーペアを使用
- セキュリティグループ: 既存のセキュリティグループを使用
- タグ: Name = "${var.prefix}-ec2"
- outputs.tf に以下を追加:
  - パブリックIPアドレス（output名: instance_public_ip）
  - インスタンスID（output名: instance_id）

terraform apply まで実行してください。
```

</details>

### 確認（あなたがターミナルで実行）

```bash
terraform -chdir=terraform/vpc-ec2 output instance_public_ip
```

IPアドレスが表示されれば OK ✅

---

## Step 5: SSH接続を確認しよう（15分）

構築した EC2 に SSH で接続して、環境が正しく構築されたか **あなた自身で** 確認します。

### 手順（すべてあなたがターミナルで実行）

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
| **コード生成→実行の自動化** | あなたがプロンプトを入力するだけで、AI Agent が terraform init → apply まで自動実行 |
| **段階的な構築** | Claude Code に「既存コードに追加」と指示するだけで段階的に構築できた |
| **承認ワークフロー** | AI Agent が提示する変更内容を、あなたが確認してから実行（human in the loop） |
| **エラー自動修正** | エラー発生時、AI Agent が自動で原因を分析し修正を提案 |

### プロンプトの書き方で気づいたこと

Step 1〜4を通して、効果的なプロンプトの要素が見えてきたはずです：

- **保存先**を明確にする
- **要件を具体的に**書く（値、名前、設定項目）
- **実行指示**まで含める
- 「既存コードに追加」のように**文脈を伝える**

> 次のセッション以降は、この経験を活かして **最初から自分でプロンプトを考えて** Claude Code に指示を出していきます。

### 📖 コードを理解しよう — Claude Code に設計書を作ってもらう

ここまでで作成した Terraform コードの内容を **人に説明できるレベル** まで理解しましょう。Claude Code に以下のように依頼してください：

<details>
<summary>📝 プロンプト例</summary>

```
terraform/vpc-ec2/ のコードについて、以下の内容を含む設計説明書を Markdown で作成してください。
保存先: docs/session1_design.md

■ 含めてほしい内容
1. 全体構成図（テキストベースのダイアグラム）
2. 各リソース（VPC, Subnet, IGW, RT, SG, KP, EC2）の役割と、なぜ必要なのかの説明
3. リソース間の依存関係（何が何を参照しているか）
4. variables.tf の各変数が何を制御しているか
5. セキュリティグループのルールが意味すること
6. 初心者向けの用語解説
```

</details>

生成された設計書を読んで、以下のポイントを確認しましょう：

- [ ] VPC とサブネットの関係を説明できる
- [ ] インターネットゲートウェイとルートテーブルがなぜ必要か説明できる
- [ ] セキュリティグループのインバウンド/アウトバウンドルールが何を意味するか説明できる
- [ ] `terraform plan` → `terraform apply` の流れが説明できる

> 💡 **なぜこの作業が重要か**: 生成AIがあればコードは書けますが、**コードの意味を理解していないとトラブル時に対応できません**。設計書を読んでわからない部分があれば、Claude Code に「〇〇の部分をもっと詳しく教えて」と質問しましょう。

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

variable "prefix" {
  description = "リソース名の接頭辞（受講者ごとにユニークな値）"
  type        = string
  # TF_VAR_prefix 環境変数から自動取得されます
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
    Name = "${var.prefix}-vpc"
  }
}

# --- サブネット & インターネット接続（Step 2） ---
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-public-subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --- キーペア & セキュリティグループ（Step 3） ---
resource "aws_key_pair" "training_key" {
  key_name   = "${var.prefix}-key"
  public_key = file("../../keys/training-key.pub")
}

resource "aws_security_group" "ec2_sg" {
  name        = "${var.prefix}-ec2-sg"
  description = "Security group for ${var.prefix} EC2"
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
    Name = "${var.prefix}-ec2-sg"
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
    Name = "${var.prefix}-ec2"
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

あなたのターミナルで以下のコマンドを実行して、このセッションの完了状態を確認できます：

```bash
./scripts/check.sh session1
```

---

## ⚠️ リソースの削除

> ワークショップ期間中はEC2を削除しないでください。**全セッション終了後**にあなたのターミナルで以下を実行して削除してください。

```bash
terraform -chdir=terraform/vpc-ec2 destroy
```

---

## ➡️ 次のステップ

[セッション2：Terraform でインフラを構築・変更・再構築しよう](session2_guide.md) に進んでください。
