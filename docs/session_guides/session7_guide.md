# セッション7：Webシステム構築 詳細ガイド（任意・発展）

## 📋 目的

このセッションでは、Continueを活用して、実践的なWebアプリケーションインフラの構築を実践します。

### 学習目標

- ALB、ECS、RDSを含む複雑なインフラ構成を理解する
- Continueを活用した複雑なインフラ構築を実践する
- 統合エージェントを使った自動構築を実践する

## 🎯 目指すべき構成

このセッション終了時点で、以下の構成が完成していることを目指します：

```
workspace/
└── terraform/
    └── web_app/
        ├── main.tf          # メインのTerraformコード
        ├── variables.tf     # 変数定義
        ├── outputs.tf       # 出力定義
        └── terraform.tfvars # 変数の値
```

**構築されるAWSリソース**:
- ALB（Application Load Balancer）
- ECSクラスターとサービス
- ECRリポジトリ
- RDSデータベース
- セキュリティグループ

## 📚 事前準備

- [セッション3](session3_guide.md) が完了していること
- [セッション5](session5_guide.md) が完了していること
- [セッション6](session6_guide.md) が完了していること（推奨）
- Dockerの基本理解

## 🚀 手順

### 1. ネットワーク設計（20分）

#### 1.1 ALBの設計

Continueを起動（`Ctrl+L` / `Cmd+L`）して、以下のプロンプトを入力します：

```
Application Load Balancerを作成するTerraformコードを生成してください。

要件:
- 名前: training-web-alb
- タイプ: application
- パブリックサブネットに配置
- セキュリティグループを設定
- 削除保護は無効

出力形式:
- HCL形式のTerraformコード
- 変数定義を含める
- コメントを適切に追加
```

<details>
<summary>📝 生成コード例（クリックで展開）</summary>

```hcl
# variables.tf
variable "alb_name" {
  description = "ALB名"
  type        = string
  default     = "training-web-alb"
}

variable "public_subnet_ids" {
  description = "パブリックサブネットID"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ALBセキュリティグループID"
  type        = string
}

# main.tf
resource "aws_lb" "web_alb" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = var.alb_name
  }
}

resource "aws_lb_target_group" "web_tg" {
  name     = "${var.alb_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
  }

  tags = {
    Name = "${var.alb_name}-tg"
  }
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}
```

</details>

### 2. ECS/ECRを使ったコンテナベースアプリケーションのデプロイ（25分）

#### 2.1 ECRリポジトリの作成

Continueを起動して、以下のプロンプトを入力します：

```
ECRリポジトリを作成するTerraformコードを生成してください。

要件:
- 名前: training-web-app
- イメージタグの変更可能性: MUTABLE
- プッシュ時のスキャンを有効化

出力形式:
- HCL形式のTerraformコード
```

<details>
<summary>📝 生成コード例（クリックで展開）</summary>

```hcl
resource "aws_ecr_repository" "web_app" {
  name                 = "training-web-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "training-web-app"
  }
}
```

</details>

#### 2.2 ECSクラスターとサービスの作成

Continueを起動して、以下のプロンプトを入力します：

```
ECSクラスターとサービスを作成するTerraformコードを生成してください。

要件:
- クラスター名: training-web-cluster
- サービス名: training-web-service
- 起動タイプ: FARGATE
- 希望タスク数: 2
- プライベートサブネットに配置
- ALBターゲットグループに接続

出力形式:
- HCL形式のTerraformコード
- タスク定義を含める
```

<details>
<summary>📝 生成コード例（クリックで展開）</summary>

```hcl
resource "aws_ecs_cluster" "web_cluster" {
  name = "training-web-cluster"

  tags = {
    Name = "training-web-cluster"
  }
}

resource "aws_ecs_task_definition" "web_app" {
  family                   = "training-web-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name  = "web-app"
    image = "${aws_ecr_repository.web_app.repository_url}:latest"
    portMappings = [{
      containerPort = 80
      protocol      = "tcp"
    }]
  }])
}

resource "aws_ecs_service" "web_service" {
  name            = "training-web-service"
  cluster         = aws_ecs_cluster.web_cluster.id
  task_definition = aws_ecs_task_definition.web_app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web_tg.arn
    container_name   = "web-app"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.web_listener]
}
```

</details>

### 3. RDSデータベースの構築と接続設定（10分）

#### 3.1 RDSインスタンスの作成

Continueを起動して、以下のプロンプトを入力します：

```
RDSインスタンスを作成するTerraformコードを生成してください。

要件:
- エンジン: MySQL 8.0
- インスタンスクラス: db.t3.micro
- ストレージ: 20GB
- データベース名: webappdb
- プライベートサブネットに配置
- ECSセキュリティグループからのみアクセス可能

出力形式:
- HCL形式のTerraformコード
- セキュリティグループを含める
```

<details>
<summary>📝 生成コード例（クリックで展開）</summary>

```hcl
resource "aws_db_subnet_group" "web_db_subnet" {
  name       = "training-web-db-subnet"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "training-web-db-subnet"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "training-rds-sg"
  description = "Security group for RDS"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.ecs_security_group_id]
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

resource "aws_db_instance" "web_db" {
  identifier             = "training-web-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  db_name                = "webappdb"
  username               = var.db_username
  password               = var.db_password
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.web_db_subnet.name
  skip_final_snapshot    = true

  tags = {
    Name = "training-web-db"
  }
}
```

</details>

### 4. 統合エージェントを活用した自動構築（5分）

#### 4.1 エージェントを使った自動構築

[セッション6](session6_guide.md) で実装した統合エージェントを使用して、Webシステム全体を自動構築します。

Continueを起動して、以下のプロンプトを入力します：

```
以下のWebアプリケーションインフラを構築するTerraformコードを生成してください:

1. ALBを作成（パブリックサブネット）
2. ECSクラスターとサービスを作成（FARGATE、プライベートサブネット）
3. ECRリポジトリを作成
4. RDSデータベースを作成（MySQL、プライベートサブネット）
5. セキュリティグループを適切に設定
6. すべてのリソースを連携

出力形式:
- HCL形式のTerraformコード
- 変数定義を含める
- 依存関係を適切に記述
- コメントを追加
```

生成されたコードを`workspace/terraform/web_app/`に保存し、実行します。

## ✅ チェックリスト

- [ ] ネットワーク設計が完了した
- [ ] ALBとターゲットグループが作成された
- [ ] ECRリポジトリが作成された
- [ ] ECSクラスターとサービスが作成された
- [ ] タスク定義が作成された
- [ ] RDSインスタンスが作成された
- [ ] セキュリティグループが適切に設定された
- [ ] 統合エージェントを使った自動構築を実践した
- [ ] 構築結果を検証した

## 🆘 トラブルシューティング

### ALB接続エラー

- セキュリティグループの設定を確認
- ターゲットグループのヘルスチェックを確認

### ECSタスク起動エラー

- タスク定義の確認
- ネットワーク設定の確認
- IAMロールの確認

### RDS接続エラー

- セキュリティグループの設定を確認
- サブネットグループの設定を確認

## 📚 参考資料

- [Terraform公式ドキュメント](https://developer.hashicorp.com/terraform/docs)
- [AWS公式ドキュメント](https://docs.aws.amazon.com/)
- [サンプルコード](../../sample_code/terraform/)

## 🎉 ワークショップ完了

セッション7が完了したら、ワークショップは完了です！お疲れ様でした！

作成したリソースは、ワークショップ終了後に必ず削除してください：

```bash
cd workspace/terraform/web_app
terraform destroy
```
