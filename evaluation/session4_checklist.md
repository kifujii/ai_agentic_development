# セッション4：サーバー再起動の自動化 評価チェックリスト

## 評価項目

### 1. Ansibleの基礎理解（15点）

- [ ] インベントリファイルの構造を理解した
- [ ] Playbookの構造（hosts, tasks, handlers）を理解した
- [ ] 冪等性の概念を理解した
- [ ] Ansibleとcfgの役割を理解した

### 2. 環境構築（20点）

#### 2.1 インベントリファイルの作成（10点）
- [ ] inventory.ini を作成した
- [ ] EC2インスタンスの情報を正しく設定した
- [ ] SSH接続情報を正しく設定した

#### 2.2 接続テスト（10点）
- [ ] `ansible all -m ping` が成功した
- [ ] SSH接続が正常に動作する

### 3. Playbook作成（35点）

#### 3.1 サーバー状態確認Playbook（10点）
- [ ] check_status.yml を作成した
- [ ] OS情報、稼働時間、ディスク使用量を取得できる
- [ ] 実行結果が正しく表示される

#### 3.2 サーバー再起動Playbook（15点）
- [ ] restart_server.yml を作成した
- [ ] 再起動前の状態確認が実装されている
- [ ] rebootモジュールを使用している
- [ ] 再起動後のヘルスチェックが実装されている
- [ ] エラーハンドリングが実装されている

#### 3.3 サービス管理Playbook（10点）
- [ ] manage_services.yml を作成した
- [ ] サービスの起動/停止/再起動が可能
- [ ] サービス状態の確認が実装されている

### 4. Agent開発の活用（20点）

- [ ] Prompt Engineering（Ansible用）を実践した
- [ ] Context Engineering（セッション2のEC2情報活用）を実践した
- [ ] 段階的な構築アプローチを実践した
- [ ] フィードバックループを活用した

### 5. 振り返り（10点）

- [ ] Ansibleの基礎理解について振り返った
- [ ] Prompt Engineering（Ansible用）の効果を振り返った
- [ ] TerraformとAnsibleの役割の違いを理解した
- [ ] Agent形式での開発体験について振り返った

## 成果物チェックリスト

### 必須成果物
- [ ] inventory.ini
- [ ] ansible.cfg
- [ ] playbooks/restart_server.yml
- [ ] playbooks/check_status.yml
- [ ] playbooks/manage_services.yml

### 推奨成果物
- [ ] 振り返りレポート
- [ ] 実行結果のスクリーンショット

## 次のステップ
セッション5に進む前に、以下を確認してください：
- [ ] Ansible接続テストが成功している
- [ ] サーバー再起動Playbookが正常に動作する
- [ ] EC2インスタンスが起動している
