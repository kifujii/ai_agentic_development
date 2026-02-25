# セッション5：CloudWatch Agentインストール・セットアップ 評価チェックリスト

## 評価項目

### 1. IAMリソースの構築（Terraform）（20点）

#### 1.1 IAMロールの作成（10点）
- [ ] IAMロールを作成した
- [ ] CloudWatchAgentServerPolicy をアタッチした
- [ ] 信頼ポリシーにEC2を設定した

#### 1.2 インスタンスプロファイルの作成（10点）
- [ ] インスタンスプロファイルを作成した
- [ ] EC2インスタンスに関連付けた

### 2. CloudWatch Agentのインストール（Ansible）（25点）

#### 2.1 インストールPlaybook（10点）
- [ ] install_cwagent.yml を作成した
- [ ] amazon-cloudwatch-agent パッケージをインストールした
- [ ] インストール確認を実装した

#### 2.2 設定Playbook（15点）
- [ ] configure_cwagent.yml を作成した
- [ ] 設定ファイル（JSON）を生成・配置した
- [ ] CPUメトリクスの収集を設定した
- [ ] メモリメトリクスの収集を設定した
- [ ] ディスクメトリクスの収集を設定した
- [ ] ログ収集を設定した
- [ ] CloudWatch Agentの起動・有効化を実装した

### 3. 動作確認（20点）

- [ ] CloudWatch Agentが正常に動作している
- [ ] ステータス確認コマンドが正常に応答する
- [ ] CloudWatchコンソールでメトリクスを確認した（可能な場合）
- [ ] CloudWatch Logsでログを確認した（可能な場合）

### 4. ツール横断的なAgent開発（20点）

- [ ] TerraformとAnsibleの両方をAgent開発で使用した
- [ ] TerraformとAnsibleの使い分けを理解した
- [ ] ツール間の情報連携を実践した（例：IAMロール情報の受け渡し）
- [ ] フィードバックループを活用した

### 5. 振り返り（15点）

- [ ] ツール横断的なAgent開発の体験を振り返った
- [ ] IAMロールの設計について振り返った
- [ ] 複雑なPlaybook作成の体験を振り返った
- [ ] Agent開発の効率性について振り返った

## 成果物チェックリスト

### 必須成果物
- [ ] terraform/cloudwatch-iam/ (main.tf, variables.tf, outputs.tf)
- [ ] ansible/playbooks/install_cwagent.yml
- [ ] ansible/playbooks/configure_cwagent.yml

### 推奨成果物
- [ ] 振り返りレポート
- [ ] CloudWatchメトリクスのスクリーンショット

## 次のステップ
セッション6に進む前に、以下を確認してください：
- [ ] CloudWatch Agentが正常に動作している
- [ ] Ansible接続テストが成功している
