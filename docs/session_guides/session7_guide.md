# セッション7：Webシステム構築 詳細ガイド（任意・発展）

## 📋 目的

このセッションでは、ContinueのAgent機能を活用して、実践的なWebアプリケーションインフラ（ALB、ECS、RDSを含む）を構築します。これまでのセッションで学んだPrompt Engineering、Context Engineering、フィードバックループを統合的に活用します。

### 学習目標

- ALB、ECS、RDSを含む複雑なインフラ構成を理解する
- ContinueのAgent機能を活用した複雑なインフラ構築を実践する
- 統合的なワークフローでのAgent開発を実践する
- 実践的なシナリオでの総合的なスキルを発揮する

## 🎯 最終的な目標構成

このセッション終了時点で、以下の構成が完成していることを目指します：

### Webアプリケーションインフラ構成図

```mermaid
graph TB
    subgraph Internet["Internet"]
        Users["ユーザー"]
    end
    
    subgraph VPC["VPC (10.0.0.0/16)"]
        subgraph PublicSubnets["パブリックサブネット"]
            ALB["Application Load Balancer<br/>ALB"]
        end
        
        subgraph PrivateSubnets["プライベートサブネット"]
            ECS["ECS Cluster<br/>Fargate Tasks x 2"]
            RDS["RDS MySQL<br/>db.t3.micro"]
        end
        
        ECR["ECR Repository<br/>Docker Images"]
    end
    
    Users --> ALB
    ALB --> ECS
    ECS --> RDS
    ECR -.->|"イメージプッシュ"| ECS
```

### ファイル構成

```
workspace/
└── terraform/
    └── web_app/
        ├── main.tf          # メインのTerraformコード
        ├── variables.tf     # 変数定義
        ├── outputs.tf       # 出力定義
        └── terraform.tfvars # 変数の値
```

### 構築されるAWSリソース

- ALB（Application Load Balancer） - パブリックサブネット
- ECSクラスターとサービス（Fargate） - プライベートサブネット
- ECRリポジトリ - Dockerイメージの保存
- RDSデータベース（MySQL 8.0） - プライベートサブネット
- セキュリティグループ（ALB、ECS、RDS用）
- ターゲットグループ（ALB用）

## 📚 事前準備

- [セッション3](session3_guide.md) が完了していること
- [セッション5](session5_guide.md) が完了していること
- [セッション6](session6_guide.md) が完了していること（推奨）
- Dockerの基本理解
- セッション2で構築したVPC/Subnetが利用可能であること（または新規作成）

## 🚀 Agent開発の進め方

### Agent開発のアドバイス

#### 1. 段階的な構築アプローチ

複雑なインフラは、以下の順序で段階的に構築することを推奨します：

1. **ネットワーク層**: ALB、ターゲットグループ、セキュリティグループ
2. **コンテナ層**: ECRリポジトリ、ECSクラスター、タスク定義、サービス
3. **データ層**: RDSサブネットグループ、セキュリティグループ、RDSインスタンス
4. **統合**: すべてのリソースを連携

各ステップで承認ワークフローを活用し、確認してから次に進みます。

#### 2. 複雑なPrompt Engineering

**統合構築用プロンプト例**:

```
terraform/web_app/ フォルダに、下記条件を満たすWebアプリケーションインフラを構築するTerraformコードを生成してください。

要件:
- VPC: 10.0.0.0/16（既存のVPCを使用する場合は既存VPC IDを指定）
- パブリックサブネット: 10.0.1.0/24, 10.0.2.0/24（2つのAZ）
- プライベートサブネット: 10.0.10.0/24, 10.0.11.0/24（2つのAZ）

1. ALB（Application Load Balancer）:
   - 名前: training-web-alb
   - タイプ: application
   - パブリックサブネットに配置
   - HTTP（ポート80）リスナー
   - ヘルスチェック: /, 200 OK

2. ECSクラスターとサービス:
   - クラスター名: training-web-cluster
   - サービス名: training-web-service
   - 起動タイプ: FARGATE
   - 希望タスク数: 2
   - CPU: 256, メモリ: 512
   - プライベートサブネットに配置
   - ALBターゲットグループに接続

3. ECRリポジトリ:
   - 名前: training-web-app
   - イメージタグの変更可能性: MUTABLE
   - プッシュ時のスキャンを有効化

4. RDSデータベース:
   - エンジン: MySQL 8.0
   - インスタンスクラス: db.t3.micro
   - ストレージ: 20GB
   - データベース名: webappdb
   - プライベートサブネットに配置
   - ECSセキュリティグループからのみアクセス可能（ポート3306）

5. セキュリティグループ:
   - ALB用: HTTP（80）を許可、送信は全許可
   - ECS用: ALBセキュリティグループからのみ受信（80）、RDSへの送信（3306）を許可
   - RDS用: ECSセキュリティグループからのみ受信（3306）を許可

依存関係:
1. VPC → サブネット → セキュリティグループ
2. サブネット → ALB、ECS、RDS
3. ALB → ECSサービス
4. ECS → RDS

注意事項:
- 足りていないパラメータがある場合は、そのまま構築するのではなく一度聞き返してください
- 既存のリソースと衝突しないように確認してください
- 依存関係を適切に設定してください
- 変数定義を含めてください
- コメントを適切に追加してください
- ベストプラクティスに従ってください
```

#### 3. Context Engineeringの活用

**既存インフラ情報の取得**:

Continueのチャット機能を使って、既存のVPC/Subnet情報を取得できます：

```
セッション2で構築したVPCとサブネットの情報を教えてください。
VPC ID、サブネットID、CIDRブロック、可用性ゾーンを含めてください。
```

取得した情報をコンテキストとして提供：

```
既存のインフラ情報:
- VPC ID: vpc-xxxxx
- パブリックサブネット: subnet-xxxxx (10.0.1.0/24), subnet-yyyyy (10.0.2.0/24)
- プライベートサブネット: subnet-zzzzz (10.0.10.0/24), subnet-wwwww (10.0.11.0/24)

上記の情報を利用して、Webアプリケーションインフラを構築してください。
```

#### 4. フィードバックループの実践

**複数ステップの承認ワークフロー**:

1. **ステップ1の承認**: ALBとターゲットグループのコード生成後、計画を確認
2. **ステップ2の承認**: ECSクラスターとサービスのコード生成後、計画を確認
3. **ステップ3の承認**: RDSのコード生成後、計画を確認
4. **ステップ4の承認**: 統合後の最終確認

**エラー発生時の対処**:

- エラーメッセージをコンテキストとして提供
- Agentに修正を依頼
- 必要に応じて、前のステップから再実行

### 考えながら進めるポイント

1. **どのような構築順序が効果的か**
   - 依存関係を考慮した構築順序
   - 各リソースの作成タイミング

2. **どのようなコンテキストが必要か**
   - 既存のVPC/Subnet情報
   - 利用可能なリソース情報
   - セキュリティ要件

3. **セキュリティ設定の考慮**
   - セキュリティグループの適切な設定
   - プライベートサブネットの活用
   - 最小権限の原則

4. **コスト最適化**
   - 適切なインスタンスサイズの選択
   - 不要なリソースの回避

## 📝 振り返り

以下の点について振り返り、学んだことをまとめてください：

- **複雑なインフラ構築の体験**: ALB、ECS、RDSを含む複雑なインフラをどのように構築したか
- **統合的なワークフロー**: 複数のリソースを統合的に管理する方法をどのように実践したか
- **Agent形式での開発の総合理解**: これまでのセッションで学んだことを統合して、どのような開発体験を実現できたか
- **実践的なスキルの習得**: 実際の業務で使えるレベルのスキルをどのように習得したか

<details>
<summary>📝 解答例（クリックで展開）</summary>

### 完成したTerraformコード例

#### variables.tf

```hcl
variable "region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "パブリックサブネットID"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "プライベートサブネットID"
  type        = list(string)
}

variable "db_username" {
  description = "RDSデータベースユーザー名"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "RDSデータベースパスワード"
  type        = string
  sensitive   = true
}
```

#### main.tf

```hcl
provider "aws" {
  region = var.region
}

# ALBセキュリティグループ
resource "aws_security_group" "alb_sg" {
  name        = "training-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
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

  tags = {
    Name = "training-alb-sg"
    Environment = "training"
  }
}

# ECSセキュリティグループ
resource "aws_security_group" "ecs_sg" {
  name        = "training-ecs-sg"
  description = "Security group for ECS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB"
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

  tags = {
    Name = "training-ecs-sg"
    Environment = "training"
  }
}

# RDSセキュリティグループ
resource "aws_security_group" "rds_sg" {
  name        = "training-rds-sg"
  description = "Security group for RDS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from ECS"
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

  tags = {
    Name = "training-rds-sg"
    Environment = "training"
  }
}

# ALB
resource "aws_lb" "web_alb" {
  name               = "training-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name = "training-web-alb"
    Environment = "training"
  }
}

# ターゲットグループ
resource "aws_lb_target_group" "web_tg" {
  name     = "training-web-tg"
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
    Name = "training-web-tg"
    Environment = "training"
  }
}

# ALBリスナー
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# ECRリポジトリ
resource "aws_ecr_repository" "web_app" {
  name                 = "training-web-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "training-web-app"
    Environment = "training"
  }
}

# ECSクラスター
resource "aws_ecs_cluster" "web_cluster" {
  name = "training-web-cluster"

  tags = {
    Name = "training-web-cluster"
    Environment = "training"
  }
}

# ECSタスク定義
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
    environment = [
      {
        name  = "DB_HOST"
        value = aws_db_instance.web_db.endpoint
      },
      {
        name  = "DB_NAME"
        value = "webappdb"
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/training-web-app"
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])

  tags = {
    Name = "training-web-app"
    Environment = "training"
  }
}

# ECSサービス
resource "aws_ecs_service" "web_service" {
  name            = "training-web-service"
  cluster         = aws_ecs_cluster.web_cluster.id
  task_definition = aws_ecs_task_definition.web_app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.web_tg.arn
    container_name   = "web-app"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.web_listener]

  tags = {
    Name = "training-web-service"
    Environment = "training"
  }
}

# RDSサブネットグループ
resource "aws_db_subnet_group" "web_db_subnet" {
  name       = "training-web-db-subnet"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "training-web-db-subnet"
    Environment = "training"
  }
}

# RDSインスタンス
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
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"

  tags = {
    Name = "training-web-db"
    Environment = "training"
  }
}

# CloudWatch Logsグループ
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/training-web-app"
  retention_in_days = 7

  tags = {
    Name = "training-ecs-logs"
    Environment = "training"
  }
}
```

#### outputs.tf

```hcl
output "alb_dns_name" {
  description = "ALBのDNS名"
  value       = aws_lb.web_alb.dns_name
}

output "ecr_repository_url" {
  description = "ECRリポジトリURL"
  value       = aws_ecr_repository.web_app.repository_url
}

output "rds_endpoint" {
  description = "RDSエンドポイント"
  value       = aws_db_instance.web_db.endpoint
  sensitive   = true
}

output "ecs_cluster_name" {
  description = "ECSクラスター名"
  value       = aws_ecs_cluster.web_cluster.name
}
```

### 段階的な構築プロンプト例

**ステップ1: ALBの構築**

```
terraform/web_app/ フォルダに、Application Load Balancerを作成するTerraformコードを生成してください。

要件:
- 名前: training-web-alb
- タイプ: application
- パブリックサブネットに配置
- HTTP（ポート80）リスナー
- ターゲットグループとヘルスチェック設定

既存のインフラ情報:
- VPC ID: vpc-xxxxx
- パブリックサブネットID: subnet-xxxxx, subnet-yyyyy
```

**ステップ2: ECSの構築**

```
terraform/web_app/ フォルダに、ECSクラスターとサービスを作成するTerraformコードを生成してください。

要件:
- クラスター名: training-web-cluster
- サービス名: training-web-service
- 起動タイプ: FARGATE
- 希望タスク数: 2
- プライベートサブネットに配置
- 既存のALBターゲットグループに接続

既存のリソース:
- ALBターゲットグループARN: （ステップ1で作成）
- プライベートサブネットID: subnet-zzzzz, subnet-wwwww
```

**ステップ3: RDSの構築**

```
terraform/web_app/ フォルダに、RDSデータベースを作成するTerraformコードを生成してください。

要件:
- エンジン: MySQL 8.0
- インスタンスクラス: db.t3.micro
- ストレージ: 20GB
- データベース名: webappdb
- プライベートサブネットに配置
- ECSセキュリティグループからのみアクセス可能

既存のリソース:
- プライベートサブネットID: subnet-zzzzz, subnet-wwwww
- ECSセキュリティグループID: （ステップ2で作成）
```

</details>

## ✅ チェックリスト

- [ ] 最終的な目標構成を理解した
- [ ] 段階的な構築アプローチを実践した
- [ ] ALBとターゲットグループを構築した
- [ ] ECRリポジトリを作成した
- [ ] ECSクラスターとサービスを構築した
- [ ] RDSデータベースを構築した
- [ ] セキュリティグループを適切に設定した
- [ ] すべてのリソースを連携した
- [ ] 統合的なワークフローでのAgent開発を実践した
- [ ] 構築結果を検証した

## 🆘 トラブルシューティング

### ALB接続エラー

- セキュリティグループの設定を確認（ALB → ECS）
- ターゲットグループのヘルスチェックを確認
- ECSタスクが正常に起動しているか確認

### ECSタスク起動エラー

- タスク定義の確認（コンテナイメージ、リソース設定）
- ネットワーク設定の確認（サブネット、セキュリティグループ）
- IAMロールの確認（タスク実行ロール、タスクロール）
- CloudWatch Logsの確認

### RDS接続エラー

- セキュリティグループの設定を確認（ECS → RDS）
- サブネットグループの設定を確認
- データベース認証情報の確認

### 統合的な問題

- 依存関係が正しく設定されているか確認
- 各リソースの状態を確認
- エラーメッセージをコンテキストとして提供し、Agentに修正を依頼

## 📚 参考資料

- [Terraform公式ドキュメント](https://developer.hashicorp.com/terraform/docs)
- [AWS公式ドキュメント](https://docs.aws.amazon.com/)
- [ALB公式ドキュメント](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [ECS公式ドキュメント](https://docs.aws.amazon.com/ecs/)
- [RDS公式ドキュメント](https://docs.aws.amazon.com/rds/)
- [セッション6ガイド](session6_guide.md)

## 🎉 ワークショップ完了

セッション7が完了したら、ワークショップは完了です！お疲れ様でした！

**重要**: 作成したリソースは、ワークショップ終了後に必ず削除してください：

```bash
cd workspace/terraform/web_app
terraform destroy
```

## ➡️ 次のステップ

ワークショップ完了後は、実務での活用を検討してください。継続的な学習とスキル向上を推奨します。
