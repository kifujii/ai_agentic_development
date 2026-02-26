# セッション1：VPC + EC2 を段階的に構築 評価チェックリスト

## 事前準備
- [ ] 環境セットアップが完了している
- [ ] SSH鍵ペアを生成した

## Step 1: VPC作成
- [ ] Agent形式でVPC作成のプロンプトを入力した
- [ ] `terraform apply` でVPCを作成した
- [ ] `terraform output` でVPC IDを確認した

## Step 2: サブネット＆インターネット接続
- [ ] 既存コードへの追加指示でサブネットを作成した
- [ ] インターネットゲートウェイとルートテーブルを設定した
- [ ] `terraform output` でサブネットIDを確認した

## Step 3: キーペア＆セキュリティグループ
- [ ] キーペアを登録した
- [ ] セキュリティグループ（SSH許可）を作成した

## Step 4: EC2インスタンス
- [ ] EC2インスタンスを作成した
- [ ] パブリックIPが出力された

## Step 5: SSH接続確認
- [ ] SSH接続に成功した

## 成果物
- [ ] `terraform/vpc-ec2/` にTerraformコードが存在する
- [ ] VPC, Subnet, IGW, RT, SG, KP, EC2 が構築されている
