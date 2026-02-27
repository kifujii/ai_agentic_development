# セッション2：EC2 + RDS でデータベース環境を構築しよう

## 🎯 このセッションのゴール

セッション1で構築したEC2から、RDS（MySQL）データベースに接続できる環境を構築します。

![目標構成](../images/session2_target.svg)

### 必須パート（2時間）

| リソース | 設定値 |
|---------|-------|
| プライベートサブネット × 2 | 10.0.20.0/24（1a）, 10.0.21.0/24（1c） |
| RDS用セキュリティグループ | MySQL(3306) を EC2のSGからのみ許可 |
| RDSサブネットグループ | プライベートサブネット × 2 |
| RDS (MySQL 8.0) | db.t3.micro, 20GB, DB名 `trainingdb` |

### 任意パート（+1時間）

| リソース | 設定値 |
|---------|-------|
| パブリックサブネット追加 | 10.0.2.0/24（1c） |
| ALB用セキュリティグループ | HTTP(80) を許可 |
| ALB | training-web-alb |
| ターゲットグループ | EC2をターゲットに登録 |

> 🎓 セッション1でプロンプトの書き方を学びました。このセッションでは **自分でプロンプトを考えて** 進めましょう。

---

## 📚 事前準備

- セッション1が完了していること（VPC/EC2が構築済み）
- セッション1の **VPC ID** と **EC2セキュリティグループID** を確認してメモ：

```bash
cd terraform/vpc-ec2
terraform output vpc_id
terraform output security_group_id
cd ../..  # プロジェクトルートに戻る
```

> ⚠️ **作業ディレクトリについて**: Continueへのプロンプトは **プロジェクトルート** から実行してください。

---

## 構築の流れ

```
【必須パート】
Step 1: プライベートサブネットを追加（25分）
    ↓
Step 2: RDS用セキュリティグループ作成（20分）
    ↓
Step 3: RDSインスタンスを作成（30分 ※作成待ち含む）
    ↓
Step 4: EC2からRDSに接続（25分）
    ↓
Step 5: データベース操作で動作確認（15分）
    ↓
振り返り（5分）

【任意パート】
Step 6: ALBを追加してHTTPアクセス可能にする（60分）
```

---

## Step 1: プライベートサブネットを追加しよう（25分）

### やること

RDSを配置するためのプライベートサブネットを2つ作成します。

> 💡 **なぜ2つ？** RDSのサブネットグループは、異なるアベイラビリティゾーン（AZ）に最低2つのサブネットが必要です。これはRDSの高可用性を確保するためのAWSの仕様です。

### ゴール

`terraform/vpc-ec2/` の既存コードに、以下を追加して apply する：

- プライベートサブネット1: `10.0.20.0/24`（ap-northeast-1a）
- プライベートサブネット2: `10.0.21.0/24`（ap-northeast-1c）
- 各サブネットに適切なNameタグ

> 💡 **ヒント**: プライベートサブネットはパブリックサブネットと異なり、`map_public_ip_on_launch = false`（デフォルト値なので省略可）で、インターネットゲートウェイへのルートは不要です。

<details>
<summary>📝 プロンプト例</summary>

```
terraform/vpc-ec2/ の既存コードに、RDS用のプライベートサブネットを2つ追加してください。

- プライベートサブネット1: 10.0.20.0/24 (ap-northeast-1a), Name = "training-private-subnet-1a"
- プライベートサブネット2: 10.0.21.0/24 (ap-northeast-1c), Name = "training-private-subnet-1c"
- outputs.tf にサブネットIDリストを追加

terraform apply まで実行してください。
```

</details>

### 確認

```bash
cd terraform/vpc-ec2
terraform output
cd ../..
```

プライベートサブネットIDが表示されれば OK ✅

---

## Step 2: RDS用セキュリティグループを作ろう（20分）

### やること

EC2からのMySQL接続（3306番ポート）のみを許可するセキュリティグループを作成します。

### ゴール

`terraform/vpc-ec2/` の既存コードに、以下を追加して apply する：

- RDS用セキュリティグループ: `training-rds-sg`
- インバウンド: MySQL(3306) を **EC2のセキュリティグループからのみ** 許可
- アウトバウンド: 全許可

> 💡 **ヒント**: セキュリティグループのインバウンドルールで、CIDRブロックではなく **別のセキュリティグループのID** を指定できます。これにより「EC2からのアクセスだけ」に制限できます。Terraformでは `security_groups = [aws_security_group.ec2_sg.id]` のように書きます。

<details>
<summary>📝 プロンプト例</summary>

```
terraform/vpc-ec2/ の既存コードに、RDS用のセキュリティグループを追加してください。

- 名前: training-rds-sg
- VPC: 既存のVPC
- インバウンド: MySQL(3306) を既存のEC2セキュリティグループ(training-ec2-sg)からのみ許可
- アウトバウンド: 全許可
- outputs.tf にRDSセキュリティグループIDを追加

terraform apply まで実行してください。
```

</details>

### 確認

```bash
cd terraform/vpc-ec2
terraform output
cd ../..
```

RDSセキュリティグループID（`sg-xxxxx`）が表示されれば OK ✅

---

## Step 3: RDSインスタンスを作ろう（30分）

### やること

MySQLデータベースインスタンスを作成します。

> ⏱️ **RDSの作成には10〜15分かかります**。apply実行後は待ち時間になるので、その間に次のStep 4の準備を読んでおきましょう。

### ゴール

`terraform/vpc-ec2/` の既存コードに、以下を追加して apply する：

- RDSサブネットグループ: `training-db-subnet-group`（プライベートサブネット × 2）
- RDSインスタンス:
  - 識別子: `training-db`
  - エンジン: MySQL 8.0
  - インスタンスクラス: `db.t3.micro`
  - ストレージ: 20GB
  - データベース名: `trainingdb`
  - ユーザー名: `admin`
  - パスワード: 変数で管理（`sensitive = true`）
  - `skip_final_snapshot = true`
  - マルチAZ: 無効（ワークショップ用）
  - パブリックアクセス: 無効

> 💡 **ヒント**: パスワードは `variable` で定義し `sensitive = true` にすると、terraform outputで非表示になります。apply時にパスワードの入力を求められるので、覚えやすいものを入力してください（例: `Training2024!`）。

<details>
<summary>📝 プロンプト例</summary>

```
terraform/vpc-ec2/ の既存コードに、RDSインスタンスを追加してください。

- RDSサブネットグループ: training-db-subnet-group（既存のプライベートサブネット2つを使用）
- RDSインスタンス:
  - identifier: training-db
  - engine: mysql 8.0
  - instance_class: db.t3.micro
  - allocated_storage: 20
  - db_name: trainingdb
  - username: admin
  - password: 変数で管理 (sensitive = true)
  - skip_final_snapshot: true
  - multi_az: false
  - publicly_accessible: false
  - RDS用セキュリティグループを使用
- outputs.tf に RDS エンドポイントを追加

terraform apply まで実行してください。
```

</details>

### 確認

apply が完了したら（10〜15分待ち）：

```bash
cd terraform/vpc-ec2
terraform output rds_endpoint
cd ../..
```

RDSエンドポイント（`training-db.xxxxx.ap-northeast-1.rds.amazonaws.com:3306`）が表示されれば OK ✅

---

## Step 4: EC2からRDSに接続しよう（25分）

### やること

セッション1のEC2にSSHログインし、mysqlクライアントをインストールしてRDSに接続します。

### 手順

1. **EC2のIPアドレスを確認**:

```bash
cd terraform/vpc-ec2
terraform output instance_public_ip
cd ../..
```

2. **EC2にSSHログイン**:

```bash
ssh -i ~/.ssh/training-key ec2-user@<EC2のIPアドレス>
```

3. **EC2内でmysqlクライアントをインストール**:

```bash
sudo dnf install -y mariadb105
```

4. **RDSに接続**（エンドポイントはStep 3で確認した値）:

```bash
mysql -h <RDSエンドポイント（:3306は除く）> -u admin -p trainingdb
```

パスワードを聞かれたら、Step 3で設定したパスワードを入力します。

5. 接続成功すると `mysql>` プロンプトが表示されます ✅

> 💡 **Agentを使う場合**: SSH先のEC2内での操作は、Agentの「ターミナル操作」として依頼することもできます。ただし、SSHセッション内でのコマンド実行はAgentの苦手分野の一つです。ここは手動操作が確実です。

<details>
<summary>❓ RDSに接続できない場合</summary>

- **RDSのステータスが `available` か確認**: RDS作成に10〜15分かかります
- **セキュリティグループの確認**: RDS SGのインバウンドルールでEC2 SGからの3306が許可されているか
- **エンドポイントが正しいか確認**: `terraform output rds_endpoint` で取得した値の `:3306` 部分を除いたホスト名を使用
- **サブネットの確認**: EC2とRDSが同じVPC内にあることを確認

</details>

---

## Step 5: データベース操作で動作確認（15分）

### やること

RDSに接続した状態で、簡単なデータベース操作を行い、正しく動作していることを確認します。

### 手順（mysql> プロンプトで実行）

```sql
-- テーブル作成
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100),
  email VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- データ挿入
INSERT INTO users (name, email) VALUES ('田中太郎', 'tanaka@example.com');
INSERT INTO users (name, email) VALUES ('佐藤花子', 'sato@example.com');

-- データ確認
SELECT * FROM users;

-- テーブル一覧
SHOW TABLES;
```

`users` テーブルにデータが表示されれば OK ✅

```sql
-- 接続を終了
EXIT;
```

EC2からもログアウト：

```bash
exit
```

---

## 📝 振り返り（5分）

### Session 1 → Session 2 で追加された要素

| 概念 | Session 1 | Session 2 |
|------|-----------|-----------|
| **サブネットの種類** | パブリックのみ | パブリック + プライベート |
| **セキュリティグループ** | CIDRで許可 | SG間参照で許可 |
| **AWSサービス** | EC2のみ | EC2 + RDS |
| **データの永続化** | なし | RDS（データベース） |

### プロンプトで意識したこと

- 「既存コードに追加」という文脈を常に伝える
- セキュリティグループの **参照関係**（EC2のSGからのみ許可）を明示する
- RDSのようなパラメータが多いリソースは **全ての設定値を列挙** する

> 任意パートのALBに進まない場合は、[セッション3](session3_guide.md) に進んでください。

---

## 【任意】Step 6: ALBを追加してHTTPアクセス可能にしよう（60分）

> このStepは **任意（発展課題）** です。EC2にnginxをインストールし、ALB経由でブラウザからアクセスできるようにします。

### やること

1. ALB用の2つ目のパブリックサブネットを追加
2. ALBとターゲットグループを作成
3. EC2にnginxをインストール
4. ブラウザでアクセスして確認

### 構成イメージ

```
User → ALB (HTTP:80) → EC2 (nginx:80)
       ↑ パブリックサブネット × 2（ALBには2AZ必要）
```

### Step 6-1: 2つ目のパブリックサブネット + ALBを追加（30分）

#### ゴール

`terraform/vpc-ec2/` の既存コードに、以下を追加して apply する：

- パブリックサブネット2: `10.0.2.0/24`（ap-northeast-1c）、パブリックIP自動割り当て有効
- IGWへのルートテーブル関連付け
- ALBセキュリティグループ: HTTP(80) を許可
- ALB: `training-web-alb`、パブリックサブネット × 2 に配置
- ターゲットグループ: HTTP:80、ヘルスチェック `/`
- ALBリスナー: HTTP:80 → ターゲットグループ
- **EC2のセキュリティグループ** に HTTP(80) のインバウンドルールを追加（ALB SGからのみ）
- EC2をターゲットグループに登録

<details>
<summary>📝 プロンプト例</summary>

```
terraform/vpc-ec2/ の既存コードに、ALB関連リソースを追加してください。

1. パブリックサブネット2: 10.0.2.0/24 (ap-northeast-1c), パブリックIP自動割り当て有効
   - 既存のルートテーブルに関連付け
2. ALBセキュリティグループ: training-alb-sg, HTTP(80)許可
3. ALB: training-web-alb, パブリックサブネット2つに配置
4. ターゲットグループ: training-web-tg, HTTP:80, ヘルスチェック /
5. ALBリスナー: HTTP:80 → ターゲットグループ
6. 既存のEC2セキュリティグループに HTTP(80) のインバウンドルール追加（ALB SGからのみ）
7. 既存のEC2をターゲットグループに登録（aws_lb_target_group_attachment）
8. outputs.tf に ALBのDNS名を追加

terraform apply まで実行してください。
```

</details>

### Step 6-2: EC2にnginxをインストール（15分）

EC2にSSHログインして nginx をインストールします：

```bash
ssh -i ~/.ssh/training-key ec2-user@<EC2のIP>
```

```bash
sudo dnf install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
exit
```

> 💡 **ヒント**: この作業はセッション3でAnsibleを使って自動化する内容のプレビューでもあります。

### Step 6-3: ブラウザで確認（5分）

```bash
cd terraform/vpc-ec2
terraform output alb_dns_name
cd ../..
```

表示されたALBのDNS名をブラウザで開き、nginxのデフォルトページが表示されれば **完了** 🎉

> ⚠️ ALBのヘルスチェックが正常になるまで1〜2分かかることがあります。

### 任意パートの振り返り

- ALBは **2つのAZ** にまたがるパブリックサブネットが必要
- セキュリティグループは **階層的**（ALB → EC2 → RDS）に設計する
- `aws_lb_target_group_attachment` でEC2をターゲットに登録する

---

## ファイル構成

セッション完了時、以下の構成になっています：

```
terraform/
└── vpc-ec2/
    ├── main.tf          # VPC, Subnet, IGW, RT, SG, KP, EC2, RDS, (ALB)
    ├── variables.tf     # 変数定義
    └── outputs.tf       # VPC ID, Subnet ID, SG ID, Public IP, RDS Endpoint, (ALB DNS)
```

> 💡 セッション1と同じフォルダ（`terraform/vpc-ec2/`）にコードを追加していくため、Terraformの状態ファイル（`terraform.tfstate`）で全リソースが一括管理されます。

<details>
<summary>📝 完成形のコード例 — 必須パート追加分（クリックで展開）</summary>

### variables.tf に追加

```hcl
variable "db_password" {
  description = "RDSパスワード"
  type        = string
  sensitive   = true
}
```

### main.tf に追加

```hcl
# --- プライベートサブネット（Step 1） ---
resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name = "training-private-subnet-1a"
  }
}

resource "aws_subnet" "private_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "${var.region}c"

  tags = {
    Name = "training-private-subnet-1c"
  }
}

# --- RDSセキュリティグループ（Step 2） ---
resource "aws_security_group" "rds_sg" {
  name        = "training-rds-sg"
  description = "Security group for training RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "training-rds-sg"
  }
}

# --- RDS（Step 3） ---
resource "aws_db_subnet_group" "training" {
  name       = "training-db-subnet-group"
  subnet_ids = [aws_subnet.private_1a.id, aws_subnet.private_1c.id]

  tags = {
    Name = "training-db-subnet-group"
  }
}

resource "aws_db_instance" "training" {
  identifier             = "training-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "trainingdb"
  username               = "admin"
  password               = var.db_password
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.training.name
  skip_final_snapshot    = true
  multi_az               = false
  publicly_accessible    = false

  tags = {
    Name = "training-db"
  }
}
```

### outputs.tf に追加

```hcl
output "rds_endpoint" {
  description = "RDSエンドポイント"
  value       = aws_db_instance.training.endpoint
}

output "rds_database_name" {
  description = "データベース名"
  value       = aws_db_instance.training.db_name
}

output "private_subnet_ids" {
  description = "プライベートサブネットID"
  value       = [aws_subnet.private_1a.id, aws_subnet.private_1c.id]
}
```

</details>

---

## ⚠️ リソースの削除

> **全セッション終了後**に削除してください。セッション1〜2のリソースは同じフォルダで管理されているため、一括で削除できます。

```bash
cd terraform/vpc-ec2
terraform destroy
cd ../..
```

> ⚠️ RDSの削除には数分かかります。`terraform destroy` がすべてのリソースの削除を完了するまで待ってください。

---

## ➡️ 次のステップ

[セッション3：サーバー再起動の自動化](session3_guide.md) に進んでください。
