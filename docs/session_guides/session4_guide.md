# セッション4：CloudWatch Agentインストール・セットアップ

## 🎯 このセッションのゴール

Terraform（IAMロール）+ Ansible（Agent設定）を組み合わせて、CloudWatch Agentを導入します。

![目標構成](../images/session4_target.svg)

| やること | ツール |
|---------|-------|
| IAMロール・インスタンスプロファイル作成 | Terraform |
| EC2にプロファイル関連付け | AWS CLI |
| CloudWatch Agentインストール | Ansible |
| CloudWatch Agent設定・起動 | Ansible |

### 構築の流れ

```
Step 1: IAMロールを作る（Terraform）
    ↓
Step 2: EC2にプロファイルを関連付け
    ↓
Step 3: CloudWatch Agentをインストール（Ansible）
    ↓
Step 4: 設定ファイルを配置して起動（Ansible）
    ↓
Step 5: CloudWatchで確認
```

---

## 📚 事前準備

- セッション1のEC2が起動していること
- セッション3のAnsible環境が構築済みであること
- `ansible all -m ping` が成功すること

---

## Step 1: IAMロールを作ろう（15分）

### やること

CloudWatch AgentがメトリクスやログをCloudWatchに送信するためのIAMロールを作成します。

### ゴール

`terraform/cloudwatch-iam/` フォルダに、以下を含むTerraformコードを作成して apply する：

- IAMロール: `training-cloudwatch-agent-role`（EC2からのAssumeRole）
- アタッチするポリシー: `CloudWatchAgentServerPolicy`, `AmazonSSMManagedInstanceCore`
- インスタンスプロファイル: `training-cloudwatch-agent-profile`
- outputs にプロファイル名とARNを出力

> 💡 **ヒント**: IAMロールには「信頼ポリシー（Trust Policy）」が必要です。EC2 サービスがこのロールを引き受ける（AssumeRole）ことを許可します。

<details>
<summary>📝 プロンプト例</summary>

```
terraform/cloudwatch-iam/ フォルダに、以下の要件でIAMリソースを作成するTerraformコードを生成してください。

- IAMロール: training-cloudwatch-agent-role
  - 信頼ポリシー: EC2からのAssumeRole
  - アタッチするポリシー: CloudWatchAgentServerPolicy, AmazonSSMManagedInstanceCore
- インスタンスプロファイル: training-cloudwatch-agent-profile
- outputs.tf にプロファイル名とARNを出力

terraform init と terraform apply まで実行してください。
```

</details>

---

## Step 2: EC2にプロファイルを関連付けよう（10分）

### やること

Step 1 で作ったインスタンスプロファイルを、セッション1のEC2に関連付けます。

### ゴール

AWS CLI コマンド `aws ec2 associate-iam-instance-profile` を使って関連付ける。

必要な情報：
- **EC2インスタンスID**: `terraform/vpc-ec2/` で `terraform output instance_id` を実行して取得
- **インスタンスプロファイル名**: `terraform/cloudwatch-iam/` で `terraform output instance_profile_name` を実行して取得

> 💡 **ヒント**: Agentに「まず2つのoutputを取得してから、associate コマンドを実行して」と伝えると、自動的に値を取得して実行してくれます。

<details>
<summary>📝 プロンプト例</summary>

```
以下の手順を実行してください。

1. terraform/vpc-ec2/ で terraform output instance_id を実行してEC2インスタンスIDを取得
2. terraform/cloudwatch-iam/ で terraform output instance_profile_name を実行してプロファイル名を取得
3. 取得した値を使って、以下のコマンドを実行:
   aws ec2 associate-iam-instance-profile --instance-id <取得したID> --iam-instance-profile Name=<取得したプロファイル名>
```

</details>

---

## Step 3: CloudWatch Agentをインストールしよう（15分）

### やること

Ansible Playbookで CloudWatch Agent をEC2にインストールします。

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

## Step 4: CloudWatch Agentを設定・起動しよう（20分）

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

## Step 5: CloudWatchで確認しよう（10分）

AWSコンソールで確認：

1. **CloudWatch → メトリクス → カスタム名前空間 → Training/EC2** でメトリクスを確認
2. **CloudWatch → ロググループ → /training/ec2/** でログを確認

> 💡 メトリクスとログが反映されるまで数分かかることがあります。

---

## ファイル構成

```
terraform/
└── cloudwatch-iam/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf

ansible/
├── inventory.ini          # セッション3で作成済み
├── ansible.cfg            # セッション3で作成済み
└── playbooks/
    ├── install_cwagent.yml
    └── configure_cwagent.yml
```

<details>
<summary>📝 完成形のコード例（クリックで展開）</summary>

### terraform/cloudwatch-iam/main.tf

```hcl
provider "aws" {
  region = "ap-northeast-1"
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cw_agent" {
  name               = "training-cloudwatch-agent-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "cw_policy" {
  role       = aws_iam_role.cw_agent.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.cw_agent.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "cw_agent" {
  name = "training-cloudwatch-agent-profile"
  role = aws_iam_role.cw_agent.name
}
```

### terraform/cloudwatch-iam/outputs.tf

```hcl
output "instance_profile_name" {
  value = aws_iam_instance_profile.cw_agent.name
}

output "instance_profile_arn" {
  value = aws_iam_instance_profile.cw_agent.arn
}

output "iam_role_arn" {
  value = aws_iam_role.cw_agent.arn
}
```

### ansible/playbooks/install_cwagent.yml

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

### ansible/playbooks/configure_cwagent.yml

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

ワークショップ終了後に削除してください：

```bash
cd terraform/cloudwatch-iam
terraform destroy
```

> CloudWatch AgentはEC2上のソフトウェアなので、EC2削除時に一緒に消えます。IAMリソースはTerraformで別途削除が必要です。

---

## ➡️ 次のステップ

[セッション5：サーバー情報取得・運用レポート作成（任意）](session5_guide.md) に進んでください。
