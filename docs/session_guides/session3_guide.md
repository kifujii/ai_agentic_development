# セッション3：Ansible運用基礎 詳細ガイド

## 📋 目的

このセッションでは、Ansibleを使った基本的な運用タスクの自動化を実践します。

### 学習目標

- Prompt Engineering（Ansible用）の実践（良いプロンプトと悪いプロンプトの比較）
- Context Engineering（サーバー情報）の実践
- Agent形式でのPlaybook生成の体験
- Agent形式での開発の理解（Ansible）
- Ansibleの基本概念を理解する
- インベントリファイルの設定方法を習得する
- Playbookの作成と実行方法を習得する
- 基本的な運用タスクの自動化を実践する

## 🎯 目指すべき構成

このセッション終了時点で、以下の構成が完成していることを目指します：

```
workspace/
└── ansible/
    ├── inventory.ini          # インベントリファイル
    ├── playbooks/
    │   ├── restart_server.yml # サーバー再起動Playbook
    │   └── install_packages.yml # パッケージインストールPlaybook
    └── group_vars/
        └── webservers.yml     # グループ変数
```

**自動化されるタスク**:
- サーバー再起動
- パッケージのインストール
- ファイルのコピー
- サービスの管理

## 📚 事前準備

- [セッション1](session1_guide.md) で構築したEC2インスタンスが起動していること
- Ansibleがインストールされていること
- EC2インスタンスへのSSH接続が可能なこと

## 🚀 手順

### 1. Prompt Engineering（Ansible用）（15分）

#### 1.1 悪いプロンプトと良いプロンプトの比較

**タスク**: サーバー再起動を自動化するAnsible Playbookを生成

Continueを起動して、以下のプロンプトを試してみましょう。

**悪いプロンプト例**:
```
サーバーを再起動するAnsible Playbookを作成してください
```

**良いプロンプト例**:
```
下記条件を満たすサーバー再起動を自動化するAnsible Playbookを生成してください。

要件:
- 対象サーバー: インベントリファイルのwebserversグループ
- 再起動前: サービス状態の確認、ログのバックアップ
- 再起動後: サービス状態の確認、ヘルスチェック
- エラーハンドリング: 失敗時のロールバック

注意事項:
- 足りていないパラメータがある場合は、そのまま実行するのではなく一度聞き返してください
- 冪等性を確保してください
- ハンドラーを使用してください
- コメントを適切に追加してください
```

**体験ポイント**:
- 明確な要件定義で一発で適切なPlaybookが生成される
- 冪等性、エラーハンドリング、ハンドラーの使用が適切に実装される

### 2. Context Engineering（サーバー情報）（15分）

#### 2.1 既存サーバー情報をコンテキストとして活用

既存のサーバー情報を取得して、コンテキストとして活用します。

以下のAnsibleコマンドを実行します：

```bash
# サーバー情報を取得（OS情報など）
ansible all -i workspace/ansible/inventory.ini -m setup -a "filter=ansible_distribution*"

# サービス情報を取得
ansible all -i workspace/ansible/inventory.ini -m shell -a "systemctl list-units --type=service --state=running"
```

#### 2.2 コンテキストをAgentに提供

取得したコンテキスト情報をContinueに提供します。

```
既存のサーバー情報:
{上記のAnsibleコマンドで取得した情報を貼り付け}

上記の情報を考慮して、サーバー再起動を自動化するAnsible Playbookを生成してください。
既存のサービス状態を確認し、適切に再起動してください。
```

### 3. Agent形式でのPlaybook生成（20分）

#### 3.1 チャット形式とAgent形式の比較体験

**チャット形式でのPlaybook生成（10分）**:
- プロンプト入力→Playbook生成→コピー→貼り付け→エラー修正の繰り返し

**Agent形式でのPlaybook生成（10分）**:
- Agentに指示→自動生成→検証→実行
- エラー検出と修正提案の自動化

### 4. Agent形式での開発の理解（Ansible）（10分）

#### 4.1 AnsibleでのAgent形式開発の特徴

- Playbook生成から実行までの自動化
- サーバー情報の自動取得とコンテキスト化
- エラー検出と修正提案の自動化
- human in the loopの実践

#### 4.2 フィードバックループの実践

- エラー修正プロセス: AIがエラー検出→修正提案→人間が承認
- 反復的改善: 人間のフィードバック→AIが改善→再検証
- 承認ワークフロー: AIが計画提示→人間が承認→実行

### 5. Ansibleインベントリの設定（15分）

#### 1.1 インベントリファイルの作成

`workspace/ansible/inventory.ini`を作成します。

<details>
<summary>📝 インベントリファイル例（クリックで展開）</summary>

```ini
[webservers]
web1 ansible_host=<ec2-public-ip> ansible_user=ec2-user ansible_ssh_private_key_file=training-key.pem

[webservers:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

**設定項目の説明**:
- `ansible_host`: EC2インスタンスのパブリックIP
- `ansible_user`: SSH接続ユーザー（Amazon Linux 2023の場合は`ec2-user`）
- `ansible_ssh_private_key_file`: キーペアファイルのパス
- `ansible_ssh_common_args`: SSH接続オプション

</details>

#### 1.2 SSH鍵の設定

```bash
# キーペアファイルの権限確認
chmod 400 training-key.pem

# SSH接続テスト
ssh -i training-key.pem ec2-user@<ec2-public-ip>
```

#### 1.3 接続テスト

```bash
# Ansible接続テスト
ansible all -i workspace/ansible/inventory.ini -m ping

# システム情報の取得
ansible all -i workspace/ansible/inventory.ini -m setup
```

<details>
<summary>📝 実行結果例（クリックで展開）</summary>

```
web1 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
```

</details>

### 6. サーバー再起動の自動化（30分）

#### 2.1 Continueを活用したPlaybook作成

Continueを起動（`Ctrl+L` / `Cmd+L`）して、以下のプロンプトを入力します：

```
Ansible Playbookを作成してください。

要件:
- サーバーを再起動する
- 再起動前後の稼働時間を表示する
- 再起動後にSSHサービスとcronサービスを再起動する
- エラーハンドリングを含める

出力形式:
- YAML形式のAnsible Playbook
- 適切なコメントを含める
- ベストプラクティスに従う
```

<details>
<summary>📝 生成Playbook例（クリックで展開）</summary>

```yaml
---
- name: サーバー再起動の自動化
  hosts: webservers
  become: yes
  
  handlers:
    - name: restart services
      systemd:
        name: "{{ item }}"
        state: restarted
      loop:
        - sshd
        - crond
  
  tasks:
    - name: 再起動前の状態確認
      shell: uptime
      register: uptime_before
      changed_when: false
    
    - name: 再起動前の状態を表示
      debug:
        msg: "再起動前の稼働時間: {{ uptime_before.stdout }}"
    
    - name: サーバーを再起動
      reboot:
        reboot_timeout: 300
        pre_reboot_delay: 10
        post_reboot_delay: 30
      register: reboot_result
      ignore_errors: yes
    
    - name: 再起動結果の確認
      debug:
        msg: "再起動結果: {{ reboot_result }}"
      when: reboot_result.failed
    
    - name: 再起動後の状態確認
      shell: uptime
      register: uptime_after
      changed_when: false
    
    - name: 再起動後の状態を表示
      debug:
        msg: "再起動後の稼働時間: {{ uptime_after.stdout }}"
    
    - name: サービスの再起動
      notify: restart services
```

</details>

#### 2.2 Playbookの保存

生成されたPlaybookを`workspace/ansible/playbooks/restart_server.yml`に保存します。

#### 2.3 Playbookの実行

```bash
# ディレクトリに移動
cd workspace/ansible

# ドライラン（実際には実行しない）
ansible-playbook -i inventory.ini playbooks/restart_server.yml --check

# 実行
ansible-playbook -i inventory.ini playbooks/restart_server.yml

# 詳細な出力
ansible-playbook -i inventory.ini playbooks/restart_server.yml -v
```

<details>
<summary>📝 実行結果例（クリックで展開）</summary>

```
PLAY [サーバー再起動の自動化] **********************************************

TASK [再起動前の状態確認] **********************************************
ok: [web1]

TASK [再起動前の状態を表示] **********************************************
ok: [web1] => {
    "msg": "再起動前の稼働時間:  10:30:00 up 2 days,  3:15,  1 user,  load average: 0.00, 0.01, 0.05"
}

TASK [サーバーを再起動] **********************************************
changed: [web1]

TASK [再起動後の状態確認] **********************************************
ok: [web1]

TASK [再起動後の状態を表示] **********************************************
ok: [web1] => {
    "msg": "再起動後の稼働時間:  10:35:00 up 0 min,  1 user,  load average: 0.00, 0.00, 0.00"
}

RUNNING HANDLER [restart services] **********************************************
ok: [web1] => (item=sshd)
ok: [web1] => (item=crond)

PLAY RECAP **********************************************
web1                      : ok=6    changed=1    unreachable=0    failed=0
```

</details>

### 3. その他の基本タスク（15分）

#### 3.1 パッケージのインストール

Continueを活用して、パッケージインストール用のPlaybookを作成します。

<details>
<summary>📝 Playbook例（クリックで展開）</summary>

```yaml
---
- name: パッケージのインストール
  hosts: webservers
  become: yes
  
  tasks:
    - name: 必要なパッケージをインストール
      yum:
        name:
          - htop
          - git
          - curl
        state: present
```

</details>

#### 3.2 ファイルのコピー

<details>
<summary>📝 Playbook例（クリックで展開）</summary>

```yaml
---
- name: ファイルのコピー
  hosts: webservers
  
  tasks:
    - name: 設定ファイルをコピー
      copy:
        src: config/app.conf
        dest: /etc/app/app.conf
        owner: root
        group: root
        mode: '0644'
```

</details>

#### 3.3 サービスの管理

<details>
<summary>📝 Playbook例（クリックで展開）</summary>

```yaml
---
- name: サービスの管理
  hosts: webservers
  become: yes
  
  tasks:
    - name: サービスを開始
      systemd:
        name: nginx
        state: started
        enabled: yes
```

</details>

### 4. サンプルコードの参照

[サンプルコード](../../sample_code/ansible/basic_playbook/) を参照して、より詳細な例を確認してください。

## ✅ チェックリスト

- [ ] Ansibleインベントリファイルを作成した
- [ ] SSH接続テストが成功した
- [ ] Ansible接続テストが成功した
- [ ] サーバー再起動のPlaybookを作成した
- [ ] Playbookの実行が成功した
- [ ] 再起動前後の状態確認を行った
- [ ] エラーハンドリングを実装した
- [ ] その他の基本タスクを実装した

## 🆘 トラブルシューティング

### SSH接続エラー

- セキュリティグループでSSH（ポート22）が許可されているか確認
- キーペアファイルの権限を確認（chmod 400）
- ホストキーの確認を無効化（StrictHostKeyChecking=no）

### 権限エラー

- `become: yes`を使用してsudo権限を取得
- 適切なユーザーで実行しているか確認

### タイムアウトエラー

- `reboot_timeout`を増やす
- ネットワーク接続を確認

## 📚 参考資料

- [Ansible公式ドキュメント](https://docs.ansible.com/)
- [サンプルコード](../../sample_code/ansible/basic_playbook/)

## ➡️ 次のステップ

セッション3が完了したら、[セッション4：Ansible自動化エージェント](session4_guide.md) に進んでください。
