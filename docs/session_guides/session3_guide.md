# セッション3：サーバー再起動の自動化（Ansible入門）

## 🎯 このセッションのゴール

セッション1で構築したEC2に対して、Ansibleでサーバー再起動を自動化します。

![目標構成](../images/session3_target.svg)

| 作成するもの | 内容 |
|-------------|------|
| inventory.ini | 接続先サーバーの定義 |
| ansible.cfg | Ansible基本設定 |
| check_status.yml | サーバー状態確認 |
| restart_server.yml | サーバー再起動（前後チェック付き） |
| manage_services.yml | サービスの起動/停止/再起動 |

### 構築の流れ

```
Step 1: Ansible の接続設定
    ↓
Step 2: 接続テスト（ping）
    ↓
Step 3: サーバー状態を確認する Playbook
    ↓
Step 4: サーバー再起動の Playbook
    ↓
Step 5: サービス管理の Playbook
```

---

## 📚 事前準備

- セッション1のEC2が起動していること
- EC2のパブリックIPを確認：

```bash
cd terraform/vpc-ec2
terraform output instance_public_ip
```

---

## Step 1: Ansibleの接続設定を作ろう（15分）

### やること

EC2に接続するための設定ファイル（`ansible.cfg` と `inventory.ini`）を作成します。

### ゴール

`ansible/` フォルダに以下の2ファイルを作成する：

- **ansible.cfg**: インベントリファイルのパス、リモートユーザー（`ec2-user`）、SSH鍵のパス、host_key_checking無効
- **inventory.ini**: `webservers` グループに EC2 のIPを登録

> 💡 **ヒント**: Agentに「どの設定項目が必要か」を伝えましょう。IPアドレスは事前準備で確認した値に置き換えてください。

<details>
<summary>📝 プロンプト例</summary>

```
ansible/ フォルダに、以下の設定ファイルを作成してください。

1. ansible.cfg:
   - インベントリ: inventory.ini
   - リモートユーザー: ec2-user
   - SSH秘密鍵: ~/.ssh/training-key
   - host_key_checking 無効

2. inventory.ini:
   - グループ名: webservers
   - ホスト: web1 (IPアドレス: <EC2のIP>)
   - SSH鍵: ~/.ssh/training-key
   - StrictHostKeyChecking 無効
```

</details>

---

## Step 2: 接続テスト（5分）

### やること

Ansible の `ping` モジュールで EC2 への接続を確認します。

Agentに `ansible/ フォルダで接続テスト（ansible all -m ping）を実行して` と指示しましょう。

`web1 | SUCCESS` と表示されれば OK ✅

<details>
<summary>❓ 接続できない場合</summary>

- EC2が起動しているか確認
- IPアドレスが正しいか確認（`terraform output`）
- SSH鍵の権限を確認（`chmod 400 ~/.ssh/training-key`）
- セキュリティグループでSSHが許可されているか確認

</details>

---

## Step 3: サーバー状態を確認しよう（15分）

### やること

OS情報・メモリ・ディスクなどを確認するPlaybookを作成します。

### ゴール

`ansible/playbooks/check_status.yml` を作成して、以下の情報を確認・表示する：

- OS情報（ディストリビューション、バージョン）
- 稼働時間
- メモリ使用量
- ディスク使用量
- 実行中のサービス一覧

> 💡 **ヒント**: Ansibleの `gather_facts: yes` を使うとOS情報が自動収集されます。コマンド実行は `command` モジュール、結果表示は `debug` モジュールを使います。

<details>
<summary>📝 プロンプト例</summary>

```
ansible/playbooks/check_status.yml を作成してください。

対象: webserversグループ
確認する情報:
- OS情報（ディストリビューション、バージョン）
- 稼働時間（uptime）
- メモリ使用量（free -m）
- ディスク使用量（df -h）
- 実行中のサービス一覧

作成後、Playbookを実行してください。
```

</details>

サーバー情報が表示されれば OK ✅

---

## Step 4: サーバー再起動を自動化しよう（20分）

### やること

再起動前後の状態チェック付きの再起動Playbookを作成します。

### ゴール

`ansible/playbooks/restart_server.yml` を作成する。以下の処理を含めること：

1. **再起動前**: 稼働時間と重要サービス（sshd, crond）の状態を確認
2. **再起動**: サーバーを再起動（タイムアウト300秒）
3. **再起動後**: 稼働時間とサービスの正常性を再確認

> 💡 **ヒント**: 再起動には `reboot` モジュールが使えます。`become: yes` が必要です。再起動前後で同じ情報を取得・比較すると、運用で役立つPlaybookになります。

<details>
<summary>📝 プロンプト例</summary>

```
ansible/playbooks/restart_server.yml を作成してください。

対象: webserversグループ
処理の流れ:
1. 再起動前: 稼働時間と重要サービス（sshd, crond）の状態を確認・表示
2. 再起動: reboot モジュールを使用（タイムアウト300秒）
3. 再起動後: 稼働時間の確認、サービスの状態確認、ネットワーク接続確認

注意:
- become: yes を使用してください
- エラーハンドリングを含めてください

作成後、Playbookを実行してください。
```

</details>

再起動前後のログが表示され、「再起動完了」メッセージが出れば OK ✅

---

## Step 5: サービス管理を自動化しよう（15分）

### やること

任意のサービスを起動/停止/再起動するPlaybookを作成します。

### ゴール

`ansible/playbooks/manage_services.yml` を作成する。

- 変数でサービス名とアクション（started / stopped / restarted）を指定できるようにする
- 変更前後のサービス状態を表示する

> 💡 **ヒント**: Ansible の変数機能（`vars` セクション）を使うと、Playbookの再利用性が上がります。`systemd` モジュールでサービスの状態を管理できます。

<details>
<summary>📝 プロンプト例</summary>

```
ansible/playbooks/manage_services.yml を作成してください。

対象: webserversグループ
機能:
- 変数 target_service でサービス名を指定（デフォルト: crond）
- 変数 target_action でアクション指定（started/stopped/restarted）
- 変更前後のサービス状態を表示

作成後、crond を再起動するように実行してください。
```

</details>

サービスの状態変更が確認できれば OK ✅

---

## 📝 振り返り（5分）

| Terraform（セッション1） | Ansible（セッション3） |
|:---:|:---:|
| リソースの **作成・管理** | サーバーの **設定・運用** |
| AWSリソースを構築 | 構築済みサーバーを操作 |
| `terraform apply` | `ansible-playbook` |

---

## ファイル構成

```
ansible/
├── inventory.ini
├── ansible.cfg
└── playbooks/
    ├── check_status.yml
    ├── restart_server.yml
    └── manage_services.yml
```

<details>
<summary>📝 完成形のコード例（クリックで展開）</summary>

### ansible.cfg

```ini
[defaults]
inventory = inventory.ini
remote_user = ec2-user
private_key_file = ~/.ssh/training-key
host_key_checking = False
timeout = 30
```

### inventory.ini

```ini
[webservers]
web1 ansible_host=<EC2のパブリックIP>

[webservers:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/training-key
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

### playbooks/check_status.yml

```yaml
---
- name: サーバー状態確認
  hosts: webservers
  become: yes
  gather_facts: yes

  tasks:
    - name: OS情報の表示
      debug:
        msg: "{{ ansible_distribution }} {{ ansible_distribution_version }} ({{ ansible_kernel }})"

    - name: 稼働時間の確認
      command: uptime
      register: uptime_result
      changed_when: false

    - name: 稼働時間の表示
      debug:
        msg: "{{ uptime_result.stdout }}"

    - name: メモリ使用量
      command: free -m
      register: memory_result
      changed_when: false

    - name: メモリの表示
      debug:
        msg: "{{ memory_result.stdout_lines }}"

    - name: ディスク使用量
      command: df -h
      register: disk_result
      changed_when: false

    - name: ディスクの表示
      debug:
        msg: "{{ disk_result.stdout_lines }}"
```

### playbooks/restart_server.yml

```yaml
---
- name: サーバー再起動の自動化
  hosts: webservers
  become: yes

  vars:
    important_services:
      - sshd
      - crond

  tasks:
    - name: 再起動前 - 稼働時間
      command: uptime
      register: uptime_before
      changed_when: false

    - name: 再起動前 - 表示
      debug:
        msg: "再起動前: {{ uptime_before.stdout }}"

    - name: サーバーを再起動
      reboot:
        reboot_timeout: 300
        pre_reboot_delay: 10
        post_reboot_delay: 30

    - name: 再起動後 - 稼働時間
      command: uptime
      register: uptime_after
      changed_when: false

    - name: 再起動後 - 表示
      debug:
        msg: "再起動後: {{ uptime_after.stdout }}"

    - name: 再起動後 - サービス確認
      systemd:
        name: "{{ item }}"
        state: started
        enabled: yes
      loop: "{{ important_services }}"

    - name: 再起動完了
      debug:
        msg: "サーバーの再起動が正常に完了しました"
```

### playbooks/manage_services.yml

```yaml
---
- name: サービス管理
  hosts: webservers
  become: yes

  vars:
    target_service: "crond"
    target_action: "restarted"

  tasks:
    - name: 変更前の状態確認
      systemd:
        name: "{{ target_service }}"
      register: before
      changed_when: false
      ignore_errors: yes

    - name: 変更前の表示
      debug:
        msg: "{{ target_service }}: {{ before.status.ActiveState | default('不明') }}"

    - name: サービスの状態変更
      systemd:
        name: "{{ target_service }}"
        state: "{{ target_action }}"
        enabled: yes

    - name: 変更後の状態確認
      systemd:
        name: "{{ target_service }}"
      register: after
      changed_when: false

    - name: 変更後の表示
      debug:
        msg: "{{ target_service }}: {{ after.status.ActiveState }}"
```

</details>

---

## ➡️ 次のステップ

[セッション4：CloudWatch Agentインストール・セットアップ](session4_guide.md) に進んでください。
