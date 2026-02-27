# セッション2：Webシステム構築（任意・発展）

## 🎯 このセッションのゴール

セッション1で構築したVPCを活用し、ALB + ECS + RDS を含むWebアプリケーションインフラを構築します。

![目標構成](../images/session2_target.svg)

| リソース | 設定値 |
|---------|-------|
| ALB | HTTP:80、パブリックサブネット |
| ECS (Fargate) | CPU:256, メモリ:512, タスク数:2 |
| ECR | Dockerイメージリポジトリ |
| RDS (MySQL 8.0) | db.t3.micro, 20GB |
| サブネット追加 | パブリック×2（ALB用）、プライベート×2（ECS/RDS用） |

> ⚠️ このセッションは **任意（発展課題）** です。RDS作成に10分以上かかる場合があります。

> 🎓 セッション1でプロンプトの書き方を学びました。このセッション以降は **自分でプロンプトを考えて** 進めましょう。各Stepには要件とヒントだけを示しています。

> ⚠️ **作業ディレクトリについて**: Continueへのプロンプトは **プロジェクトルート** から実行してください。ターミナルで確認コマンドを実行した後は `cd ../..` 等で戻ってください。

---

## 📚 事前準備

- セッション1が完了していること（VPC/EC2が構築済み）
- セッション1の VPC ID を確認して **メモしておく**こと：

```bash
cd terraform/vpc-ec2
terraform output vpc_id
cd ../..  # プロジェクトルートに戻る
```

> 💡 VPC IDは `vpc-0abc1234def56789` のような形式です。後のStepで何度も使うのでコピーしておきましょう。

---

## 構築の流れ

```
Step 1: サブネットを追加（ALB用 × 2, ECS/RDS用 × 2）
    ↓
Step 2: ALB + セキュリティグループを作成
    ↓
Step 3: ECR + ECS クラスター/サービスを作成
    ↓
Step 4: RDS データベースを作成
    ↓
Step 5: 動作確認
```

---

## Step 1: サブネットを追加しよう（15分）

### ゴール

`terraform/web-app/` フォルダに、ALB・ECS・RDS用のサブネットを作成する。

### 要件

- 既存のVPC ID は変数 (`var.vpc_id`) で指定する
- ALB用パブリックサブネット × 2:
  - `10.0.2.0/24` (ap-northeast-1a)
  - `10.0.3.0/24` (ap-northeast-1c)
- ECS/RDS用プライベートサブネット × 2:
  - `10.0.10.0/24` (ap-northeast-1a)
  - `10.0.11.0/24` (ap-northeast-1c)
- `terraform init` → `terraform apply` まで実行

> 💡 **ヒント**: 新しいフォルダ（`terraform/web-app/`）で始めるので、provider設定と `var.vpc_id` の変数定義も必要です。**VPC IDは `terraform.tfvars` ファイルに書いておくと、apply時に毎回入力する手間が省けます**。

<details>
<summary>📝 プロンプト例</summary>

```
terraform/web-app/ フォルダに、以下の要件でサブネットを作成するTerraformコードを作成してください。

前提:
- 既存のVPC ID は変数 (var.vpc_id) で指定します
- terraform.tfvars に vpc_id = "vpc-xxxxxxxxx" を設定してください
  （値はセッション1のVPC IDに置き換えます）

作成するサブネット:
- ALB用パブリックサブネット: 10.0.2.0/24 (ap-northeast-1a), 10.0.3.0/24 (ap-northeast-1c)
- ECS/RDS用プライベートサブネット: 10.0.10.0/24 (ap-northeast-1a), 10.0.11.0/24 (ap-northeast-1c)

terraform init と terraform apply まで実行してください。
```

> ⚠️ Agentが作成する `terraform.tfvars` の VPC ID がプレースホルダーのままの場合は、事前準備でメモした実際のVPC IDに書き換えてから apply してください。

</details>

---

## Step 2: ALBを作ろう（15分）

### ゴール

`terraform/web-app/` にALBとその関連リソースを追加する。

### 要件

- ALBセキュリティグループ: HTTP(80) を許可
- ALB: `training-web-alb`、パブリックサブネットに配置
- ターゲットグループ: HTTP:80、ヘルスチェック `/ → 200 OK`
- ALBリスナー: HTTP:80
- `terraform apply` まで実行

> 💡 **ヒント**: ALBは「外部からのHTTPリクエストを受けてバックエンドに振り分ける」役割です。セキュリティグループ → ALB → ターゲットグループ → リスナー の順で依存関係を意識しましょう。

<details>
<summary>📝 プロンプト例</summary>

```
terraform/web-app/ の既存コードに、以下を追加してください。

- ALBセキュリティグループ: HTTP(80)を許可
- ALB: training-web-alb, パブリックサブネットに配置
- ターゲットグループ: HTTP:80, ヘルスチェック / → 200 OK
- ALBリスナー: HTTP:80

terraform apply まで実行してください。
```

</details>

---

## Step 3: ECS/ECRを作ろう（15分）

### ゴール

`terraform/web-app/` にコンテナ実行環境を追加する。

### 要件

- ECRリポジトリ: `training-web-app`、プッシュ時スキャン有効
- ECSセキュリティグループ: ALBからの80番ポートのみ許可
- ECSクラスター: `training-web-cluster`
- ECSタスク定義: FARGATE、CPU:256、メモリ:512、**公開Dockerイメージ `nginx:latest` を使用**
- ECSサービス: タスク数1、**パブリックサブネット**に配置（`assign_public_ip = true`）、ALBに接続
- CloudWatch Logsグループ: `/ecs/training-web-app`

> 💡 **ヒント**: ECSのセキュリティグループは「ALBのSGからのみ」通信を許可するのがベストプラクティスです。`security_groups = [ALBのSG ID]` のように書きます。

> ⚠️ **なぜパブリックサブネット？**: ECSタスクがDockerイメージをpullするにはインターネット接続が必要です。NAT Gatewayを使わずにシンプルにするため、パブリックサブネットに配置します。

<details>
<summary>📝 プロンプト例</summary>

```
terraform/web-app/ の既存コードに、以下を追加してください。

- ECRリポジトリ: training-web-app, プッシュ時スキャン有効
- ECSセキュリティグループ: ALB SGからの80番ポートのみ許可、アウトバウンド全許可
- ECSクラスター: training-web-cluster
- ECSタスク定義: FARGATE, CPU:256, メモリ:512
  - コンテナイメージ: nginx:latest（まずは公開イメージを使用）
  - IAM実行ロール（ecsTaskExecutionRole）も作成してください
- ECSサービス: タスク数1, パブリックサブネットに配置, assign_public_ip = true, ALBターゲットグループに接続
- CloudWatch Logsグループ: /ecs/training-web-app

terraform apply まで実行してください。
```

</details>

---

## Step 4: RDSを作ろう（15分）

### ゴール

`terraform/web-app/` にデータベースを追加する。

### 要件

- RDSセキュリティグループ: ECS SGからの3306番ポートのみ許可
- RDSサブネットグループ: プライベートサブネットを使用
- RDSインスタンス: MySQL 8.0、db.t3.micro、20GB、DB名 `webappdb`
- パスワードは `sensitive = true` の変数で管理
- `skip_final_snapshot = true`

> 💡 **ヒント**: RDS のセキュリティグループも ECS と同様に「ECS のSGからのみ」に制限しましょう。パスワードを変数にする場合、apply 時に入力を求められます。

> ⏱️ RDSの作成には10分以上かかることがあります。

<details>
<summary>📝 プロンプト例</summary>

```
terraform/web-app/ の既存コードに、以下を追加してください。

- RDSセキュリティグループ: ECS SGからの3306番ポートのみ許可
- RDSサブネットグループ: プライベートサブネットを使用
- RDSインスタンス: MySQL 8.0, db.t3.micro, 20GB, DB名 webappdb

注意:
- db_password は変数で定義し、sensitive = true にしてください
- skip_final_snapshot = true にしてください

terraform apply まで実行してください。
```

</details>

---

## Step 5: 動作確認（10分）

### ALBの確認

```bash
cd terraform/web-app
terraform output alb_dns_name
cd ../..  # プロジェクトルートに戻る
```

ALBのDNS名が表示されたら、ブラウザでアクセスしてみましょう。

> ⚠️ ECSタスクが起動するまで **3〜5分** かかります。最初は `503 Service Temporarily Unavailable` が表示されることがあります。数分待ってからリロードしてください。

nginx のデフォルトページ（「Welcome to nginx!」）が表示されれば **Webシステム構築完了** ✅

---

## ファイル構成

```
terraform/
└── web-app/
    ├── main.tf          # 全リソース
    ├── variables.tf     # 変数定義
    └── outputs.tf       # ALB DNS, ECR URL 等
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

variable "vpc_id" {
  description = "VPC ID（セッション1で構築したVPC）"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "ALB用パブリックサブネット"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "ECS/RDS用プライベートサブネット"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "availability_zones" {
  type    = list(string)
  default = ["ap-northeast-1a", "ap-northeast-1c"]
}

variable "db_username" {
  description = "RDSユーザー名"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "RDSパスワード"
  type        = string
  sensitive   = true
}
```

### main.tf（主要部分のみ）

```hcl
provider "aws" {
  region = var.region
}

# --- サブネット ---
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = var.vpc_id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = { Name = "training-web-public-${count.index + 1}" }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = var.vpc_id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = { Name = "training-web-private-${count.index + 1}" }
}

# --- ALB ---
resource "aws_security_group" "alb_sg" {
  name   = "training-alb-sg"
  vpc_id = var.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "web_alb" {
  name               = "training-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "web_tg" {
  name        = "training-web-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    path    = "/"
    matcher = "200"
  }
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# --- ECS ---
resource "aws_security_group" "ecs_sg" {
  name   = "training-ecs-sg"
  vpc_id = var.vpc_id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecr_repository" "web_app" {
  name = "training-web-app"
  image_scanning_configuration { scan_on_push = true }
}

resource "aws_ecs_cluster" "web" {
  name = "training-web-cluster"
}

resource "aws_iam_role" "ecs_execution" {
  name = "training-ecs-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "web" {
  family                   = "training-web-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  container_definitions = jsonencode([{
    name  = "web-app"
    image = "nginx:latest"  # まずは公開イメージを使用
    portMappings = [{ containerPort = 80, protocol = "tcp" }]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "web" {
  name            = "training-web-service"
  cluster         = aws_ecs_cluster.web.id
  task_definition = aws_ecs_task_definition.web.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = aws_subnet.public[*].id  # パブリックサブネット（NAT不要）
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true  # イメージpullにインターネット接続が必要
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.web_tg.arn
    container_name   = "web-app"
    container_port   = 80
  }
  depends_on = [aws_lb_listener.web]
}

# --- RDS ---
resource "aws_security_group" "rds_sg" {
  name   = "training-rds-sg"
  vpc_id = var.vpc_id
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "web" {
  name       = "training-web-db-subnet"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_instance" "web" {
  identifier             = "training-web-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "webappdb"
  username               = var.db_username
  password               = var.db_password
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.web.name
  skip_final_snapshot    = true
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/training-web-app"
  retention_in_days = 7
}
```

### outputs.tf

```hcl
output "alb_dns_name" {
  value = aws_lb.web_alb.dns_name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.web_app.repository_url
}

output "rds_endpoint" {
  value     = aws_db_instance.web.endpoint
  sensitive = true
}
```

</details>

---

## ⚠️ リソースの削除

ワークショップ終了後に必ず削除してください：

```bash
cd terraform/web-app
terraform destroy
cd ../..  # プロジェクトルートに戻る
```

> ⚠️ **削除の順序**: web-app は vpc-ec2 のVPCに依存しています。**web-app を先に削除** してから vpc-ec2 を削除してください。

---

## ➡️ 次のステップ

[セッション3：サーバー再起動の自動化](session3_guide.md) に進んでください。
