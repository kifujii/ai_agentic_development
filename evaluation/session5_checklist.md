# セッション5：CloudWatch Agent & SSM Agent 評価チェックリスト

## Step 1: IAMロール作成
- [ ] AWS CLIでIAMロール・インスタンスプロファイルを作成した
- [ ] EC2にプロファイルを関連付けた

## Step 2: SSM Agent インストール
- [ ] install_ssm_agent.yml を作成した
- [ ] SSM Agent が active (running) 状態になった

## Step 3: SSM Agent 動作確認
- [ ] Systems Manager フリートマネージャーにインスタンスが表示された

## Step 4: SSM Run Command
- [ ] AWSコンソールから Run Command を実行した
- [ ] サーバー情報が出力された

## Step 5: CloudWatch Agent インストール
- [ ] install_cwagent.yml を作成した
- [ ] インストールが成功した

## Step 6: CloudWatch Agent 設定・起動
- [ ] configure_cwagent.yml を作成した
- [ ] Agent が running 状態になった

## Step 7: CloudWatch 確認
- [ ] カスタム名前空間（Training/EC2）にメトリクスが表示された
- [ ] ロググループにログが表示された

## Step 8: CloudWatch Alarm
- [ ] training-cpu-alarm が作成された
- [ ] アラームがOK状態で表示された

## 成果物
- [ ] `ansible/playbooks/` に SSM/CW Agent 関連の Playbook が作成されている
