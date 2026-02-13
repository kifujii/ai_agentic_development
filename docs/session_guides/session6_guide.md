# セッション6：Webシステム構築と統合実践 詳細ガイド（任意・発展）

## 目標
実践的なWebアプリケーションインフラの構築とエージェント活用を実践する。

## 事前準備
- セッション2、4、5の完了
- Dockerの基本理解
- 統合エージェントの理解

## 手順

### 1. ネットワーク設計（20分）

#### 1.1 ALB（Application Load Balancer）の設計
```hcl
resource "aws_lb" "web_alb" {
  name               = "training-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name = "training-web-alb"
  }
}
```

#### 1.2 ターゲットグループの設定
```hcl
resource "aws_lb_target_group" "web_tg" {
  name     = "training-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
  }
}
```

### 2. ECS/ECRを使ったコンテナベースアプリケーションのデプロイ（25分）

#### 2.1 ECRリポジトリの作成
```hcl
resource "aws_ecr_repository" "web_app" {
  name                 = "training-web-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
```

#### 2.2 ECSクラスターとサービスの作成
```hcl
resource "aws_ecs_cluster" "web_cluster" {
  name = "training-web-cluster"
}

resource "aws_ecs_service" "web_service" {
  name            = "training-web-service"
  cluster         = aws_ecs_cluster.web_cluster.id
  task_definition = aws_ecs_task_definition.web_app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web_tg.arn
    container_name   = "web-app"
    container_port   = 80
  }
}
```

#### 2.3 タスク定義の作成
```hcl
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
```

### 3. RDSデータベースの構築と接続設定（10分）

#### 3.1 RDSインスタンスの作成
```hcl
resource "aws_db_instance" "web_db" {
  identifier             = "training-web-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage     = 20
  storage_type          = "gp2"
  db_name               = "webappdb"
  username              = "admin"
  password              = var.db_password
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.web_db_subnet.name
  skip_final_snapshot    = true

  tags = {
    Name = "training-web-db"
  }
}
```

#### 3.2 セキュリティグループの設定
```hcl
resource "aws_security_group" "rds_sg" {
  name        = "training-rds-sg"
  description = "Security group for RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }
}
```

### 4. 生成AIエージェントを活用した構築プロセスの自動化（5分）

#### 4.1 エージェントを使った自動構築
```python
# 統合エージェントを使用
agent = IntegratedInfrastructureAgent(
    api_key=os.getenv('OPENAI_API_KEY'),
    aws_context=get_aws_context()
)

# Webシステム構築の指示
instruction = """
以下のWebアプリケーションインフラを構築してください:
1. ALBを作成
2. ECSクラスターとサービスを作成
3. RDSデータベースを作成
4. セキュリティグループを適切に設定
5. すべてのリソースを連携
"""

result = agent.process(instruction, execute=True)
```

## チェックリスト

- [ ] ネットワーク設計が完了した
- [ ] ALBとターゲットグループが作成された
- [ ] ECRリポジトリが作成された
- [ ] ECSクラスターとサービスが作成された
- [ ] タスク定義が作成された
- [ ] RDSインスタンスが作成された
- [ ] セキュリティグループが適切に設定された
- [ ] エージェントを使った自動構築を実践した
- [ ] 構築結果を検証した

## トラブルシューティング

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

## 参考資料
- `sample_code/terraform/web_app/`
