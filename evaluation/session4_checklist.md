# セッション4：CloudWatch Agentインストール・セットアップ 評価チェックリスト

## Step 1: IAMロール（Terraform）
- [ ] IAMロールを作成した
- [ ] CloudWatchAgentServerPolicyをアタッチした
- [ ] インスタンスプロファイルを作成した

## Step 2: EC2にプロファイル関連付け
- [ ] インスタンスプロファイルをEC2に関連付けた

## Step 3: CloudWatch Agentインストール（Ansible）
- [ ] install_cwagent.yml を作成・実行した
- [ ] パッケージインストールが成功した

## Step 4: 設定・起動（Ansible）
- [ ] configure_cwagent.yml を作成・実行した
- [ ] CloudWatch Agentが running 状態になった

## Step 5: CloudWatch確認
- [ ] メトリクスまたはログが確認できた（可能な場合）

## 成果物
- [ ] `terraform/cloudwatch-iam/` にTerraformコードが存在する
- [ ] `ansible/playbooks/` にインストール・設定Playbookが存在する
