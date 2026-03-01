# セッション5：CloudWatch Agent & SSM Agent のインストール（必須・2時間）

## 🎯 このセッションのゴール

AnsibleでEC2に **SSM Agent** と **CloudWatch Agent** を段階的にインストール・設定します。このセッションでは **Terraform は使わず、Ansible のみ** で実施します。

![目標構成](../images/session5_target.svg)

| Step | インストールするもの | 目的 |
|------|---------------------|------|
| 前半 | SSM Agent | AWSコンソールからのリモート管理 |
| 後半 | CloudWatch Agent | メトリクス・ログの収集 |

> 🎓 **なぜ2つのAgentを入れるのか？**
> - **SSM Agent**: AWSコンソールからEC2にリモートアクセス（Session Manager）。SSHなしで管理できる。
> - **CloudWatch Agent**: CPU/メモリ/ディスクのメトリクスやログをCloudWatchに送信。監視に必須。

---

## 📚 事前準備

> ⚠️ **DevSpacesのワークスペースを再構築した場合**:
> 休憩後のタイムアウトや翌日の作業開始時にワークスペースを再構築した場合は、環境セットアップスクリプトを再実行してください。
> ```bash
> ./scripts/setup_devspaces.sh
> ```
> プロジェクト内のファイル（SSH鍵、Terraformの状態、Ansibleの設定、生成したコード）は保持されています。

- セッション4のAnsible環境が構築済みであること
- 接続確認：

```bash
cd ansible
```

```bash
ansible all -m ping
```

```bash
cd ..
```

> ⚠️ **作業ディレクトリについて**: Continueへのプロンプトは **プロジェクトルート** から実行してください。

---

## 構築の流れ

```
Step 1: IAMロールの作成（AWS CLI）（15分）
    ↓
Step 2: SSM Agent のインストール（Ansible）（15分）
    ↓
Step 3: SSM Agent の動作確認（10分）
    ↓
Step 4: SSM Run Command の体験（15分）
    ↓
Step 5: CloudWatch Agent のインストール（Ansible）（15分）
    ↓
Step 6: CloudWatch Agent の設定・起動（Ansible）（20分）
    ↓
Step 7: CloudWatch での確認（10分）
    ↓
Step 8: CloudWatch Alarm の作成（10分）
    ↓
振り返り（10分）
```

---

## Step 1: IAMロールを作成しよう（15分）

### やること

CloudWatch Agent と SSM Agent が AWS と通信するには、EC2 に IAM ロール（インスタンスプロファイル）が必要です。Agentに AWS CLI コマンドで作成してもらいます。

### ゴール

以下のリソースを AWS CLI で作成する：

- IAMロール: `training-ec2-agent-role`（EC2 の AssumeRole）
- アタッチするポリシー: `CloudWatchAgentServerPolicy`, `AmazonSSMManagedInstanceCore`
- インスタンスプロファイル: `training-ec2-agent-profile`
- EC2 にプロファイルを関連付け

> 💡 **ヒント**: Agentに「AWS CLIで IAM ロールとインスタンスプロファイルを作成して、EC2に関連付けて」と伝えると、必要なコマンドを順番に実行してくれます。

<details>
<summary>📝 プロンプト例</summary>

```
以下の手順を AWS CLI で実行してください。

1. IAM ロール training-ec2-agent-role を作成
   - 信頼ポリシー: EC2 サービスからの AssumeRole を許可
2. ポリシーをアタッチ:
   - arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
   - arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
3. インスタンスプロファイル training-ec2-agent-profile を作成
4. ロールをインスタンスプロファイルに追加
5. terraform/vpc-ec2 で terraform output instance_id を実行してEC2のIDを取得
   （エラーの場合は terraform output で全出力を確認し、インスタンスIDを探してください）
6. EC2 にインスタンスプロファイルを関連付け
```

</details>

<details>
<summary>❓ 「There is an existing association」エラーが出た場合</summary>

すでにプロファイルが関連付けられている場合は **このStepはスキップしてOK** です。

関連付けを変更したい場合：

現在の関連付けIDを確認：
```bash
aws ec2 describe-iam-instance-profile-associations --filters "Name=instance-id,Values=<インスタンスID>"
```

関連付けを解除：
```bash
aws ec2 disassociate-iam-instance-profile --association-id <association-id>
```

再度関連付け：
```bash
aws ec2 associate-iam-instance-profile --instance-id <ID> --iam-instance-profile Name=training-ec2-agent-profile
```

</details>

---

## Step 2: SSM Agent をインストールしよう（15分）

### やること

Ansible Playbook で EC2 に SSM Agent をインストールします。

> 💡 Amazon Linux 2023 には SSM Agent が**プリインストール**されている場合があります。Playbook では「インストール確認 → 未インストールならインストール → 起動」の流れにすると安全です。

### ゴール

`ansible/playbooks/install_ssm_agent.yml` を作成して、以下を行う：

- SSM Agent がインストール済みか確認
- 未インストールの場合はインストール
- SSM Agent を起動・有効化
- ステータスを確認・表示

<details>
<summary>📝 プロンプト例</summary>

```
ansible/playbooks/install_ssm_agent.yml を作成してください。

対象: webserversグループ
タスク:
- amazon-ssm-agent がインストール済みか確認
- 未インストールの場合は yum でインストール
- amazon-ssm-agent サービスを起動・有効化（systemd）
- ステータスを確認して表示

作成後、Playbookを実行してください。
```

</details>

Agent が `active (running)` 状態になれば OK ✅

---

## Step 3: SSM Agent の動作確認（10分）

### やること

AWSコンソールで SSM Agent が正しく動作しているか確認します。

### 手順

1. **AWS コンソール** → **Systems Manager** → **フリートマネージャー** を開く
2. EC2 インスタンスが **マネージドインスタンス** として表示されていることを確認

> ⚠️ IAMロールの反映に 1〜2分かかることがあります。表示されない場合は少し待ってからリロードしてください。

SSM でインスタンスが管理対象として表示されれば OK ✅

---

## Step 4: SSM Run Command を体験しよう（15分）

### やること

SSM Agent が入ったことで、**AWSコンソール から直接コマンドを実行** できるようになりました。SSH不要のリモート管理を体験します。

### 手順

1. **AWSコンソール**にログインし、上部の検索バーに `Systems Manager` と入力して開く
2. 左メニューから **「ノード管理」→「Run Command」** をクリック
3. オレンジ色の **「コマンドを実行」** ボタンをクリック
4. 「コマンドドキュメント」の検索欄に `AWS-RunShellScript` と入力して選択
5. 「コマンドパラメータ」欄に以下を入力：

```bash
echo "=== SSM Run Command テスト ==="
hostname
uptime
free -m
df -h
```

6. 下にスクロールして **「ターゲット」** セクションで「インスタンスを手動で選択する」を選び、EC2 にチェック
7. さらに下にスクロールしてオレンジ色の **「実行」** ボタンをクリック
8. ステータスが「成功」になったら、インスタンスIDをクリックして **出力を確認**

> 💡 **これが SSM の真価**: SSHポートを開けなくても、AWSコンソールからサーバー管理ができます。

### Ansible との比較を考えてみましょう

| 項目 | SSM Run Command | Ansible |
|------|----------------|---------|
| 接続方式 | AWS API 経由 | SSH |
| 実行場所 | AWSコンソール | ターミナル |
| 適した用途 | 緊急対応、一回限りの操作 | 繰り返す定型作業、自動化 |

出力にサーバー情報が表示されれば OK ✅

---

## Step 5: CloudWatch Agent をインストールしよう（15分）

### やること

Ansible Playbook で CloudWatch Agent をインストールします。

### ゴール

`ansible/playbooks/install_cwagent.yml` を作成して、以下を行う：

- `amazon-cloudwatch-agent` パッケージを yum でインストール
- インストール結果を表示
- バージョン確認

> 💡 **ヒント**: CloudWatch Agent のコマンドは `/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl` にあります。`-a status` でステータスを確認できます。

<details>
<summary>📝 プロンプト例</summary>

```
ansible/playbooks/install_cwagent.yml を作成してください。

対象: webserversグループ
タスク:
- amazon-cloudwatch-agent パッケージをyumでインストール
- インストール結果を表示
- バージョン確認（/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status）

作成後、Playbookを実行してください。
```

</details>

インストール成功のメッセージが出れば OK ✅

---

## Step 6: CloudWatch Agent を設定・起動しよう（20分）

### やること

CloudWatch Agent の設定ファイルを配置し、Agent を起動します。

### ゴール

`ansible/playbooks/configure_cwagent.yml` を作成して、以下を行う：

1. 設定ファイル（JSON）を `/opt/aws/amazon-cloudwatch-agent/etc/` に配置
2. Agent を起動
3. ステータス確認

設定内容：
- メトリクス収集間隔: 60秒
- 収集するメトリクス: CPU使用率、メモリ使用率、ディスク使用率
- 収集するログ: `/var/log/messages`, `/var/log/secure`
- メトリクス名前空間: `Training/EC2`

> 💡 **ヒント**: CloudWatch Agent の設定はJSON形式です。Ansibleの `copy` モジュールで `content` にJSON を書いて配置できます。起動は `-a fetch-config` コマンドを使います。

<details>
<summary>📝 プロンプト例</summary>

```
ansible/playbooks/configure_cwagent.yml を作成してください。

対象: webserversグループ
タスク:
1. CloudWatch Agent設定ファイル（JSON）を /opt/aws/amazon-cloudwatch-agent/etc/ に配置
2. CloudWatch Agentを起動
3. ステータス確認

設定内容:
- メトリクス収集間隔: 60秒
- 収集するメトリクス: CPU使用率、メモリ使用率、ディスク使用率
- 収集するログ: /var/log/messages, /var/log/secure
- メトリクス名前空間: Training/EC2

作成後、Playbookを実行してください。
```

</details>

Agent が running 状態になれば OK ✅

---

## Step 7: CloudWatch で確認しよう（10分）

AWSコンソールで確認：

1. **CloudWatch → メトリクス → カスタム名前空間 → Training/EC2** でメトリクスを確認
2. **CloudWatch → ロググループ → /training/ec2/** でログを確認

> 💡 メトリクスとログが反映されるまで数分かかることがあります。

メトリクスまたはロググループが表示されれば OK ✅

---

## Step 8: CloudWatch Alarm を作成しよう（10分）

### やること

CloudWatch Agent が収集したメトリクスに対してアラームを設定します。Agentに AWS CLI で作成してもらいます。

### ゴール

CPU使用率が80%を超えたらアラーム状態になる CloudWatch Alarm を作成する。

> 💡 **ヒント**: Agentに「CloudWatch Alarmを作成して」と伝えると、必要なAWS CLIコマンドを実行してくれます。

<details>
<summary>📝 プロンプト例</summary>

```
AWS CLI で以下の CloudWatch Alarm を作成してください。

- アラーム名: training-cpu-alarm
- メトリクス: Training/EC2 名前空間の cpu_usage_user
- 条件: 1分間の平均が80%以上
- 比較期間: 1期間
- アクション: なし（通知は不要）

作成後、CloudWatch のアラームコンソールで確認できるか教えてください。
```

</details>

### 確認

**AWS コンソール** → **CloudWatch → アラーム** で `training-cpu-alarm` が表示されていれば OK ✅

> 💡 現時点ではCPU使用率が低いため、ステータスは「OK」のはずです。

---

## 📝 振り返り（10分）

### このセッションで体験したこと

| 作業 | ツール | 学び |
|------|--------|------|
| IAMロール作成 | AWS CLI (Agent) | CLI操作もAgentに任せられる |
| SSM Agent導入 | Ansible | プリインストール確認の重要性 |
| SSM Run Command | AWSコンソール | SSH不要のリモート管理 |
| CW Agent導入 | Ansible | パッケージ管理の自動化 |
| CW Agent設定 | Ansible | JSON設定のテンプレート化 |
| CW Alarm | AWS CLI (Agent) | 監視設定もAgentで自動化 |

### ツールの使い分け

| ツール | 用途 | このセッションでの使い方 |
|--------|------|------------------------|
| Terraform | インフラの構築 | 今回は使わなかった |
| Ansible | サーバー内の設定・ソフトウェア管理 | SSM/CW Agentのインストール・設定 |
| AWS CLI | AWSリソースの操作 | IAMロール、CloudWatch Alarm |
| SSM | 緊急時のリモート管理 | Run Commandでサーバー操作 |

---

## ファイル構成

```
ansible/
├── inventory.ini            # セッション4で作成済み
├── ansible.cfg              # セッション4で作成済み
└── playbooks/
    ├── install_ssm_agent.yml
    ├── install_cwagent.yml
    └── configure_cwagent.yml
```

<details>
<summary>📝 完成形のコード例（クリックで展開）</summary>

### playbooks/install_ssm_agent.yml

```yaml
---
- name: SSM Agentのインストール
  hosts: webservers
  become: yes

  tasks:
    - name: SSM Agentがインストール済みか確認
      command: rpm -q amazon-ssm-agent
      register: ssm_installed
      changed_when: false
      ignore_errors: yes

    - name: インストール状態の表示
      debug:
        msg: "{{ '既にインストール済み' if ssm_installed.rc == 0 else '未インストール → インストールします' }}"

    - name: SSM Agentインストール
      yum:
        name: amazon-ssm-agent
        state: present
      when: ssm_installed.rc != 0

    - name: SSM Agent起動・有効化
      systemd:
        name: amazon-ssm-agent
        state: started
        enabled: yes

    - name: ステータス確認
      command: systemctl status amazon-ssm-agent
      register: ssm_status
      changed_when: false

    - name: ステータス表示
      debug:
        msg: "{{ ssm_status.stdout_lines[:5] }}"
```

### playbooks/install_cwagent.yml

```yaml
---
- name: CloudWatch Agentのインストール
  hosts: webservers
  become: yes

  tasks:
    - name: CloudWatch Agentインストール
      yum:
        name: amazon-cloudwatch-agent
        state: present
      register: install_result

    - name: インストール結果
      debug:
        msg: "{{ '新規インストール' if install_result.changed else '既にインストール済み' }}"

    - name: バージョン確認
      command: /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status
      register: status
      changed_when: false
      ignore_errors: yes

    - name: ステータス表示
      debug:
        msg: "{{ status.stdout_lines }}"
      when: status.rc == 0
```

### playbooks/configure_cwagent.yml

```yaml
---
- name: CloudWatch Agent設定・起動
  hosts: webservers
  become: yes

  vars:
    cwagent_config:
      agent:
        metrics_collection_interval: 60
        run_as_user: root
      metrics:
        namespace: Training/EC2
        metrics_collected:
          cpu:
            measurement: [cpu_usage_idle, cpu_usage_user, cpu_usage_system]
            totalcpu: true
          mem:
            measurement: [mem_used_percent, mem_available_percent]
          disk:
            measurement: [disk_used_percent]
            resources: ["/"]
      logs:
        logs_collected:
          files:
            collect_list:
              - file_path: /var/log/messages
                log_group_name: /training/ec2/messages
                log_stream_name: "{instance_id}"
                retention_in_days: 7
              - file_path: /var/log/secure
                log_group_name: /training/ec2/secure
                log_stream_name: "{instance_id}"
                retention_in_days: 7

  tasks:
    - name: 設定ファイル配置
      copy:
        content: "{{ cwagent_config | to_nice_json }}"
        dest: /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
        mode: '0644'

    - name: CloudWatch Agent起動
      command: >
        /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl
        -a fetch-config -m ec2
        -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
        -s

    - name: ステータス確認
      command: /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status
      register: status
      changed_when: false

    - name: ステータス表示
      debug:
        msg: "{{ status.stdout_lines }}"
```

</details>

---

## ⚠️ リソースの削除

ワークショップ終了後に IAM リソースを削除してください：

インスタンスプロファイルからロールを削除：
```bash
aws iam remove-role-from-instance-profile --instance-profile-name training-ec2-agent-profile --role-name training-ec2-agent-role
```

ポリシーのデタッチ：
```bash
aws iam detach-role-policy --role-name training-ec2-agent-role --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
```

```bash
aws iam detach-role-policy --role-name training-ec2-agent-role --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
```

リソース削除：
```bash
aws iam delete-instance-profile --instance-profile-name training-ec2-agent-profile
```

```bash
aws iam delete-role --role-name training-ec2-agent-role
```

> 💡 Agentに「training-ec2-agent-role と training-ec2-agent-profile を削除して」と伝えれば、上記コマンドを実行してくれます。

> CloudWatch Agent と SSM Agent は EC2 上のソフトウェアなので、EC2 削除時に一緒に消えます。

---

## ➡️ 次のステップ

[セッション6：サーバー情報取得・運用レポート作成（任意）](session6_guide.md) に進んでください。
