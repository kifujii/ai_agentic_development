# セッション5：CloudWatch Agent & SSM Agent 評価チェックリスト

## Step 1: SSM Agent インストール
- [ ] `install_ssm_agent.yml` を作成した
- [ ] SSM Agent が active (running) 状態になった

## Step 2: SSM Agent 動作確認 → トラブルシューティング 🔧
- [ ] フリートマネージャーでEC2が表示されないことを確認した（Trap 1）
- [ ] Agentに原因調査を依頼した
- [ ] AgentがIAMロール不足を特定し、ロールを作成した
- [ ] インスタンスプロファイルをEC2に関連付けた
- [ ] フリートマネージャーにEC2が表示された

## Step 3: SSM Run Command
- [ ] AWSコンソールから Run Command を実行した
- [ ] サーバー情報が出力された

## Step 4: CloudWatch Agent インストール
- [ ] IAMロールに CloudWatchAgentServerPolicy をアタッチした
- [ ] `install_cwagent.yml` を作成した
- [ ] インストールが成功した

## Step 5: CloudWatch Agent 設定・起動
- [ ] `configure_cwagent.yml` を作成した
- [ ] CloudWatch Agent が running 状態になった

## Step 6: CloudWatch 確認 → トラブルシューティング 🔧
- [ ] Training/EC2 名前空間にメトリクスが見つからないことを確認した（Trap 2）
- [ ] Agentに原因調査を依頼した
- [ ] Agentが名前空間の設定不備を特定し、設定を修正した
- [ ] 修正後、Training/EC2 にメトリクスが表示された
- [ ] ロググループにログが表示された

## Step 7: CloudWatch Alarm
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
- [ ] Q: CloudWatch Agent の名前空間（namespace）を明示的に指定する理由は？
  - A: _______________

## プロンプトの振り返り

- [ ] トラブルシューティングでAgentがどのように問題を解決したか記録した
  - Trap 1（IAMロール）: _______________
  - Trap 2（名前空間）: _______________
- [ ] 「要件を正確に伝えないとどうなるか」を体験して気づいたこと
  - 気づき: _______________
