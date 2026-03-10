# セッション5：SSM Agent & CloudWatch Agent の導入（必須・2時間）

## 🎯 このセッションの到達状態

EC2に SSM Agent と CloudWatch Agent がインストール・稼働し、AWSコンソールからリモート管理と CPU/メモリの監視ができる状態になっています。このセッションでは **Terraform は使わず、Ansible + AWS CLI** で実施します。

![目標構成](../images/session5_target.svg)

| Step | インストールするもの | 目的 |
|------|---------------------|------|
| 前半 | SSM Agent | AWSコンソールからのリモート管理 |
| 後半 | CloudWatch Agent | メトリクス・ログの収集 |

> 🎓 **なぜ2つのAgent（ソフトウェア）を入れるのか？**
> - **SSM Agent**: AWSコンソールからEC2にリモートアクセス（Session Manager）。SSHなしで管理できる。
> - **CloudWatch Agent**: CPU/メモリ/ディスクのメトリクスやログをCloudWatchに送信。監視に必須。
>
> ⚠️ **用語の注意**: このセッションに登場する「SSM Agent」「CloudWatch Agent」は **EC2上で動くAWSのソフトウェア** です。Claude Code（AI Agent）とは別物です。

> 💡 **セッション1で紹介したトラブルシューティングパターンを活用しましょう**: 何か問題が起きたら、エラーメッセージを Claude Code に共有して原因調査・修正を依頼してください。

---

## 📚 事前準備

> ⚠️ **環境変数が未設定の場合**:
> 新しいターミナルを開いた際に `$TF_VAR_prefix` が未設定の場合は、セットアップスクリプトを再実行してください。
> ```bash
> ./scripts/setup.sh
> ```

- セッション4のAnsible環境が構築済みであること
- あなたのターミナルで接続確認：

```bash
ANSIBLE_CONFIG=ansible/ansible.cfg ansible -i ansible/inventory.ini all -m ping
```

> ⚠️ **作業ディレクトリ**: すべての操作は **プロジェクトルート** から実行してください。

---

## 構築の流れ

```
Step 1: IAM ロールの作成（15分）
    ↓
Step 2: SSM Agent のインストールと確認（20分）
    ↓
Step 3: SSM Run Command の体験（15分）
    ↓
Step 4: CloudWatch Agent のインストール（15分）
    ↓
Step 5: CloudWatch Agent の設定・起動・確認（25分）
    ↓
Step 6: CloudWatch Alarm の作成（10分）
    ↓
振り返り（10分）
```

> ⏱️ **時間配分について**: 各 Step の所要時間は目安です。IAMロールの反映やメトリクスの表示に数分かかることがあります。時間が足りない場合は講師に相談してください。

---

## Step 1: IAM ロールを作成しよう（15分）

### やること

SSM Agent と CloudWatch Agent が AWS サービスと通信するためには、EC2 に適切な **IAM ロール（権限）** が必要です。最初にこれを準備します。

> 💡 **なぜ IAM ロールが必要？**: EC2 上のソフトウェアが AWS サービス（Systems Manager, CloudWatch）と通信するには、「このEC2はこのサービスを使ってよい」という許可が必要です。それが IAM ロールです。

### ゴール

以下のリソースが AWS 上に作成されている：

- IAMロール: `<PREFIX>-ec2-agent-role`（EC2 の AssumeRole）
- アタッチ済みポリシー:
  - `AmazonSSMManagedInstanceCore`（SSM Agent 用）
  - `CloudWatchAgentServerPolicy`（CloudWatch Agent 用）
- インスタンスプロファイル: `<PREFIX>-ec2-agent-profile`
- EC2 にプロファイルが関連付けられている

> 💡 `<PREFIX>` は `.env` で設定した自分のプレフィックスです（例: `user01`）。`echo $TF_VAR_prefix` で確認できます。

<details>
<summary>📝 プロンプト例</summary>

```
AWS CLI を使って以下の IAM リソースを作成し、EC2 に関連付けてください。
プレフィックスとして環境変数 TF_VAR_prefix の値を使ってください。

■ 作成するもの
1. IAMロール: ${TF_VAR_prefix}-ec2-agent-role
   - EC2 が AssumeRole できる信頼ポリシー
2. ポリシーのアタッチ:
   - AmazonSSMManagedInstanceCore
   - CloudWatchAgentServerPolicy
3. インスタンスプロファイル: ${TF_VAR_prefix}-ec2-agent-profile
   - 上記ロールを追加
4. EC2 にインスタンスプロファイルを関連付け
   - インスタンスID: terraform -chdir=terraform/vpc-ec2 output -raw instance_id で確認できます

作成後、IAMロールのポリシー一覧を表示して確認してください。
```

</details>

`<PREFIX>-ec2-agent-role` が作成され、EC2 に関連付けられれば OK ✅

> 💡 IAMロールの反映に 1〜2分かかることがあります。

> 💡 インスタンスプロファイルの作成直後に EC2 への関連付け（`associate-iam-instance-profile`）が `InvalidParameterValue` エラーで失敗する場合があります。その場合は **10〜15秒待ってから再実行** してください。

---

## Step 2: SSM Agent をインストール・確認しよう（20分）

### やること

Ansible Playbook で EC2 に SSM Agent をインストールし、フリートマネージャーで管理対象として表示されることを確認します。

> 💡 Amazon Linux 2023 には SSM Agent が**プリインストール**されている場合があります。Playbook では「インストール確認 → 未インストールならインストール → 起動」の流れにすると安全です。

### ゴール

- `ansible/playbooks/install_ssm_agent.yml` が作成され、実行済み
- SSM Agent が `active (running)` 状態
- **AWSコンソールのフリートマネージャーに EC2 が表示されている**

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

### フリートマネージャーで確認（あなたがAWSコンソールで操作）

1. **あなたが** AWSコンソールにログインし、上部の検索バーに `Systems Manager` と入力して開く
2. 左メニューから **「ノード管理」→「フリートマネージャー」** をクリック
3. EC2 インスタンスが **マネージドインスタンス** として表示されていることを確認

> 💡 表示されるまで **1〜2分** かかることがあります。表示されない場合はページをリロードしてください。

フリートマネージャーに EC2 が表示されれば OK ✅

---

## Step 3: SSM Run Command を体験しよう（15分）

### やること

SSM Agent が入ったことで、**AWSコンソール から直接コマンドを実行** できるようになりました。SSH不要のリモート管理を体験します。

### 手順（あなたがAWSコンソールで操作）

1. **あなたが** AWSコンソールにログインし、上部の検索バーに `Systems Manager` と入力して開く
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

## Step 4: CloudWatch Agent をインストールしよう（15分）

### やること

Ansible Playbook で CloudWatch Agent をインストールします。

### ゴール

`ansible/playbooks/install_cwagent.yml` が作成され、実行すると：

- `amazon-cloudwatch-agent` パッケージがインストールされている
- インストール結果とバージョンが表示される

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

## Step 5: CloudWatch Agent を設定・起動・確認しよう（25分）

### やること

CloudWatch Agent の設定ファイルを配置し、CloudWatch Agent を起動します。起動後、AWSコンソールでメトリクスとログが正しく収集されていることを確認します。

### ゴール

- `ansible/playbooks/configure_cwagent.yml` が作成され、実行済み
- CloudWatch Agent が `running` 状態で起動している
- AWSコンソールの CloudWatch → メトリクス → **`<PREFIX>/EC2`** 名前空間にメトリクスが表示されている

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
- メトリクス名前空間: ${TF_VAR_prefix}/EC2
- メトリクス収集間隔: 60秒
- 収集するメトリクス: CPU使用率、メモリ使用率、ディスク使用率
- 収集するログ:
  - /var/log/messages → ロググループ: /${TF_VAR_prefix}/ec2/messages（retention: 7日）
  - /var/log/secure → ロググループ: /${TF_VAR_prefix}/ec2/secure（retention: 7日）

作成後、Playbookを実行してください。
```

</details>

### AWSコンソールで確認（あなたがAWSコンソールで操作）

CloudWatch Agent 起動後、**数分待ってから** 以下を確認します：

1. **あなたが** CloudWatch → メトリクス → すべてのメトリクス を開く
2. **カスタム名前空間** の一覧から `<PREFIX>/EC2` を探す（例: `user01/EC2`）
3. メトリクス（CPU、メモリ、ディスク）が表示されていることを確認

> 💡 メトリクスが表示されるまで **2〜5分** かかることがあります。表示されない場合はページをリロードしてしばらく待ってください。

4. **CloudWatch → ロググループ** を開く
5. `/<PREFIX>/ec2/messages` と `/<PREFIX>/ec2/secure` が存在することを確認

メトリクスまたはロググループが表示されれば OK ✅

---

## Step 6: CloudWatch Alarm を作成しよう（10分）

### やること

CloudWatch Agent が収集したメトリクスに対してアラームを設定します。Claude Code に AWS CLI で作成してもらいます。

### ゴール

CPU使用率が80%を超えたらアラーム状態になる CloudWatch Alarm `<PREFIX>-cpu-alarm` が作成されている。

> 💡 **ヒント**: Claude Code に「CloudWatch Alarmを作成して」と伝えると、AI Agent が必要なAWS CLIコマンドを実行してくれます。

<details>
<summary>📝 プロンプト例</summary>

```
AWS CLI で以下の CloudWatch Alarm を作成してください。
プレフィックスとして環境変数 TF_VAR_prefix の値を使ってください。

- アラーム名: ${TF_VAR_prefix}-cpu-alarm
- メトリクス: ${TF_VAR_prefix}/EC2 名前空間の cpu_usage_user
- 条件: 1分間の平均が80%以上
- 比較期間: 1期間
- アクション: なし（通知は不要）

作成後、CloudWatch のアラームコンソールで確認できるか教えてください。
```

</details>

### 確認（あなたがAWSコンソールで確認）

**あなたが** AWSコンソール → CloudWatch → アラーム で `<PREFIX>-cpu-alarm` が表示されていれば OK ✅

> 💡 現時点ではCPU使用率が低いため、ステータスは「OK」のはずです。

---

## 📝 振り返り（10分）

### このセッションで体験したこと

| 作業 | ツール | 学び |
|------|--------|------|
| IAMロール作成 | AWS CLI (Claude Code) | EC2がAWSサービスと通信するには **権限（IAM）** が必要 |
| SSM Agent導入 | Ansible | パッケージ管理・サービス管理の自動化 |
| SSM Run Command | AWSコンソール | SSH不要のリモート管理 |
| CloudWatch Agent導入・設定 | Ansible | メトリクス・ログ収集の自動化 |
| CW Alarm作成 | AWS CLI (Claude Code) | 監視設定も Claude Code で自動化 |

### ツールの使い分け

| ツール | 用途 | このセッションでの使い方 |
|--------|------|------------------------|
| Terraform | インフラの構築 | 今回は使わなかった |
| Ansible | サーバー内の設定・ソフトウェア管理 | SSM Agent / CloudWatch Agent のインストール・設定 |
| AWS CLI | AWSリソースの操作 | IAMロール、CloudWatch Alarm |
| SSM | 緊急時のリモート管理 | Run Commandでサーバー操作 |

### 📖 コードを理解しよう — AWS サービス連携の全体像を把握する

このセッションでは IAM、SSM、CloudWatch と多くの AWS サービスが登場しました。これらの **関係性と設定の意味** を理解しましょう：

<details>
<summary>📝 プロンプト例</summary>

```
このセッションで構築した AWS サービス連携について、以下の内容を含む解説ドキュメントを作成してください。
保存先: docs/session5_design.md

■ 含めてほしい内容
1. EC2 → IAM ロール → SSM / CloudWatch の関係図（テキストベース）
2. IAM ロール・インスタンスプロファイル・ポリシーの関係と、それぞれが何を許可しているか
3. SSM Agent の仕組み（EC2 と Systems Manager がどう通信するか）
4. CloudWatch Agent の設定ファイル（JSON）の各項目の意味
   - metrics セクション: 何を収集しているか
   - logs セクション: 何を送信しているか
5. CloudWatch Alarm の仕組み（メトリクス → 評価 → 状態遷移）
6. ansible/playbooks/ の各 Playbook が行っている処理の要約
```

</details>

生成されたドキュメントを読んで、以下を確認しましょう：

- [ ] IAMロールとインスタンスプロファイルの違いが説明できる
- [ ] CloudWatch Agent の設定ファイルで何を収集しているか説明できる
- [ ] SSM の Run Command が SSH と何が違うか説明できる
- [ ] CloudWatch Alarm がどの条件で発火するか説明できる

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
    prefix: "{{ lookup('env', 'TF_VAR_prefix') | default('training', true) }}"
    cwagent_config:
      agent:
        metrics_collection_interval: 60
        run_as_user: root
      metrics:
        namespace: "{{ prefix }}/EC2"
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
                log_group_name: "/{{ prefix }}/ec2/messages"
                log_stream_name: "{instance_id}"
                retention_in_days: 7
              - file_path: /var/log/secure
                log_group_name: "/{{ prefix }}/ec2/secure"
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

ワークショップ終了後にあなたのターミナルで IAM リソースを削除してください。
`<PREFIX>` の部分は自分のプレフィックスに置き換えてください（`echo $TF_VAR_prefix` で確認できます）。

> 💡 Claude Code に「セッション5で作成したIAMリソース、CloudWatch Alarm、ロググループをすべて削除して。プレフィックスは ${TF_VAR_prefix} です」と伝えれば、AI Agent がまとめて実行してくれます。

インスタンスプロファイルからロールを削除：
```bash
aws iam remove-role-from-instance-profile --instance-profile-name ${TF_VAR_prefix}-ec2-agent-profile --role-name ${TF_VAR_prefix}-ec2-agent-role
```

ポリシーのデタッチ：
```bash
aws iam detach-role-policy --role-name ${TF_VAR_prefix}-ec2-agent-role --policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy
```

```bash
aws iam detach-role-policy --role-name ${TF_VAR_prefix}-ec2-agent-role --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
```

リソース削除：
```bash
aws iam delete-instance-profile --instance-profile-name ${TF_VAR_prefix}-ec2-agent-profile
```

```bash
aws iam delete-role --role-name ${TF_VAR_prefix}-ec2-agent-role
```

CloudWatch Alarm の削除：
```bash
aws cloudwatch delete-alarms --alarm-names ${TF_VAR_prefix}-cpu-alarm
```

CloudWatch ロググループの削除（作成した場合のみ）：
```bash
aws logs delete-log-group --log-group-name /${TF_VAR_prefix}/ec2/messages
```

```bash
aws logs delete-log-group --log-group-name /${TF_VAR_prefix}/ec2/secure
```

> CloudWatch Agent と SSM Agent は EC2 上のソフトウェアなので、EC2 削除時に一緒に消えます。

---

## ✅ 完了チェック

あなたのターミナルで以下のコマンドを実行して、このセッションの完了状態を確認できます：

```bash
./scripts/check.sh session5
```

---

## ➡️ 次のステップ

[セッション6：サーバー情報取得・運用レポート作成（任意）](session6_guide.md) に進んでください。
