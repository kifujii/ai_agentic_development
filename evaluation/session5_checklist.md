# セッション5：CloudWatch Agent & SSM Agent 評価チェックリスト

## Step 1: IAMロール作成
- [ ] AWS CLIでIAMロール・インスタンスプロファイルを作成した
- [ ] EC2にプロファイルを関連付けた

## Step 2: SSM Agent インストール
- [ ] `install_ssm_agent.yml` を作成した
- [ ] SSM Agent が active (running) 状態になった

## Step 3: SSM Agent 動作確認
- [ ] Systems Manager フリートマネージャーにインスタンスが表示された

## Step 4: SSM Run Command
- [ ] AWSコンソールから Run Command を実行した
- [ ] サーバー情報が出力された

## Step 5: CloudWatch Agent インストール
- [ ] `install_cwagent.yml` を作成した
- [ ] インストールが成功した

## Step 6: CloudWatch Agent 設定・起動
- [ ] `configure_cwagent.yml` を作成した
- [ ] CloudWatch Agent が running 状態になった

## Step 7: CloudWatch 確認
- [ ] カスタム名前空間（Training/EC2）にメトリクスが表示された
- [ ] ロググループにログが表示された

## Step 8: CloudWatch Alarm
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
- [ ] Q: CloudWatch Alarm はどんな場面で役立ちますか？
  - A: _______________
- [ ] Q: IAMロール（インスタンスプロファイル）はなぜ必要ですか？
  - A: _______________

## プロンプトの振り返り

- [ ] Ansible Playbook 作成で工夫したプロンプトを1つ記録した
  - 工夫した点: _______________
- [ ] エラーが発生した場面とその対処を記録した
  - 状況と対処: _______________
