# セッション2：RDS データベースを追加 評価チェックリスト

## 事前準備
- [ ] セッション1のVPC IDとEC2セキュリティグループIDを確認した

## Step 1: プライベートサブネット追加
- [ ] プライベートサブネット × 2（10.0.20.0/24, 10.0.21.0/24）を作成した
- [ ] terraform apply が成功した

## Step 2: RDS用セキュリティグループ
- [ ] RDS用SG（training-rds-sg）を作成した
- [ ] インバウンドルール: EC2のSGからのMySQL(3306)のみ許可

## Step 3: RDSインスタンス
- [ ] RDSサブネットグループを作成した
- [ ] RDS MySQL 8.0 インスタンス（db.t3.micro）を作成した
- [ ] terraform output でRDSエンドポイントが確認できた

## Step 4: EC2からRDSに接続
- [ ] EC2にmysqlクライアントをインストールした
- [ ] EC2からRDSにmysqlコマンドで接続できた

## Step 5: データベース操作
- [ ] テーブル作成・データ挿入・SELECTが成功した

## 成果物
- [ ] `terraform/vpc-ec2/` にSession 1 + 2 のTerraformコードが存在する
