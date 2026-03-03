# セッション5：SSM Agent & CloudWatch Agent 導入 評価チェックリスト

## Step 1: IAMロール作成
- [ ] IAMロール `training-ec2-agent-role` が作成された
- [ ] `AmazonSSMManagedInstanceCore` ポリシーがアタッチされた
- [ ] `CloudWatchAgentServerPolicy` ポリシーがアタッチされた
- [ ] インスタンスプロファイルがEC2に関連付けられた

## Step 2: SSM Agent インストール・確認
- [ ] `install_ssm_agent.yml` を作成した
- [ ] SSM Agent が active (running) 状態になった
- [ ] フリートマネージャーにEC2が表示された

## Step 3: SSM Run Command
- [ ] AWSコンソールから Run Command を実行した
- [ ] サーバー情報が出力された

## Step 4: CloudWatch Agent インストール
- [ ] `install_cwagent.yml` を作成した
- [ ] インストールが成功した

## Step 5: CloudWatch Agent 設定・起動・確認
- [ ] `configure_cwagent.yml` を作成した
- [ ] CloudWatch Agent が running 状態になった
- [ ] Training/EC2 名前空間にメトリクスが表示された
- [ ] ロググループにログが表示された

## Step 6: CloudWatch Alarm
- [ ] `training-cpu-alarm` が作成された
- [ ] アラームがOK状態で表示された

## 成果物
- [ ] `ansible/playbooks/` に SSM/CloudWatch Agent 関連の Playbook が作成されている

---

## 理解度チェック（自分の言葉で書いてみましょう）

- [ ] Q: SSM Agent を導入するメリットは何ですか？
  - A: _______________
- [ ] Q: CloudWatch Agent でメトリクスとログを収集する目的は？
  - A: _______________
- [ ] Q: IAMロール（インスタンスプロファイル）はなぜ必要ですか？
  - A: _______________
- [ ] Q: CloudWatch Alarm はどのような場面で活用できますか？
  - A: _______________

## プロンプトの振り返り

- [ ] Agent への指示で工夫した点を記録した
  - 工夫した点: _______________
- [ ] うまくいかなかった場合にどう対応したか記録した
  - 対応内容: _______________
