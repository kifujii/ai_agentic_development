# セッション5：SSM Agent & CloudWatch Agent の導入（必須・1.5時間）

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

> ⚠️ **環境変数が未設定の場合**: `echo $TF_VAR_prefix` で値が表示されない場合は講師に確認してください。

- セッション4のAnsible環境が構築済みであること
- あなたのターミナルで接続確認：

```bash
ANSIBLE_CONFIG=ansible/ansible.cfg ansible -i ansible/inventory.ini all -m ping
```

> ⚠️ **作業ディレクトリ**: すべての操作は **プロジェクトルート** から実行してください。

---

## 構築の流れ

```
Step 1: IAM ロールの作成（10分）
    ↓
Step 2: SSM Agent のインストールと確認（20分）
    ↓
Step 3: SSM Run Command の体験（10分）
    ↓
Step 4: CloudWatch Agent のインストール（10分）
    ↓
Step 5: CloudWatch Agent の設定・起動・確認（20分）
    ↓
Step 6: CloudWatch Alarm の作成（10分）
    ↓
振り返り（10分）
```

> ⏱️ **時間配分について**: 各 Step の所要時間は目安です。IAMロールの反映やメトリクスの表示に数分かかることがあります。時間が足りない場合は講師に相談してください。

---

## Step 1: IAM ロールを作成しよう（10分）

### やること

SSM Agent と CloudWatch Agent が AWS サービスと通信するためには、EC2 に適切な **IAM ロール（権限）** が必要です。最初にこれを準備します。

> 💡 **なぜ IAM ロールが必要？**: EC2 上のソフトウェアが AWS サービス（Systems Manager, CloudWatch）と通信するには、「このEC2はこのサービスを使ってよい」という許可が必要です。それが IAM ロールです。

### ゴール

以下が完了している：

- SSM と CloudWatch に必要な権限を持つ IAM ロールが作成されている
- EC2 にインスタンスプロファイルが関連付けられている

> 💡 `<PREFIX>` は自分のプレフィックスです（例: `user01`）。`echo $TF_VAR_prefix` で確認できます。環境構築時に自動設定されています。

<details>
<summary>📝 プロンプト例</summary>

```
EC2 で SSM Agent と CloudWatch Agent を使えるようにするための IAM ロールを作成して、
EC2 に関連付けてください。

- プレフィックスとして環境変数 TF_VAR_prefix の値を使ってください
- EC2のインスタンスIDは terraform -chdir=terraform/vpc-ec2 output -raw instance_id で確認できます
- 作成後、ポリシー一覧を表示して確認してください
```

</details>

IAM ロールが作成され、EC2 に関連付けられれば OK ✅

> 💡 IAMロールの反映に 1〜2分かかることがあります。

> 💡 インスタンスプロファイルの作成直後に EC2 への関連付け（`associate-iam-instance-profile`）が `InvalidParameterValue` エラーで失敗する場合があります。その場合は **10〜15秒待ってから再実行** してください。

---

## Step 2: SSM Agent をインストール・確認しよう（20分）

### やること

Ansible Playbook で EC2 に SSM Agent をインストールし、フリートマネージャーで管理対象として表示されることを確認します。

> 💡 Amazon Linux 2023 には SSM Agent が**プリインストール**されている場合があります。Playbook では「インストール確認 → 未インストールならインストール → 起動」の流れにすると安全です。

### ゴール

- SSM Agent がインストールされ、起動している
- **AWSコンソールのフリートマネージャーに EC2 が表示されている**

<details>
<summary>📝 プロンプト例</summary>

```
EC2 に SSM Agent をインストールして起動する Ansible Playbook を作成してください。
既にインストール済みの場合はスキップするようにしてください。

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

## Step 3: SSM Run Command を体験しよう（10分）

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

## Step 4: CloudWatch Agent をインストールしよう（10分）

### やること

Ansible Playbook で CloudWatch Agent をインストールします。

### ゴール

CloudWatch Agent がインストールされている。

<details>
<summary>📝 プロンプト例</summary>

```
EC2 に CloudWatch Agent をインストールする Ansible Playbook を作成してください。

作成後、Playbookを実行してください。
```

</details>

インストール成功のメッセージが出れば OK ✅

---

## Step 5: CloudWatch Agent を設定・起動・確認しよう（20分）

### やること

CloudWatch Agent の設定ファイルを配置し、CloudWatch Agent を起動します。起動後、AWSコンソールでメトリクスとログが正しく収集されていることを確認します。

### ゴール

- CloudWatch Agent が `running` 状態で起動している
- AWSコンソールの CloudWatch にメトリクスが表示されている

<details>
<summary>📝 プロンプト例</summary>

```
CloudWatch Agent の設定を行い、起動する Ansible Playbook を作成してください。

- CPU・メモリ・ディスクのメトリクスを収集
- システムログを CloudWatch Logs に送信
- プレフィックスとして環境変数 TF_VAR_prefix の値を使ってください

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

> 💡 **名前空間の命名について**: カスタム名前空間（`<PREFIX>/EC2`）は大文字の `EC2`、ロググループ（`/<PREFIX>/ec2/...`）は小文字の `ec2` です。これは AWS の慣習に合わせたもので、意図的な使い分けです。

メトリクスまたはロググループが表示されれば OK ✅

---

## Step 6: CloudWatch Alarm を作成しよう（10分）

### やること

CloudWatch Agent が収集したメトリクスに対してアラームを設定します。Claude Code に AWS CLI で作成してもらいます。

### ゴール

CloudWatch Agent が収集しているメトリクスに対して、CPU 使用率のアラームが設定されている。

<details>
<summary>📝 プロンプト例</summary>

```
Step 5 で収集を始めた CPU メトリクスに対して、使用率が高くなったらアラームが上がるように
CloudWatch Alarm を AWS CLI で作成してください。
プレフィックスとして環境変数 TF_VAR_prefix の値を使ってください。
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
    ├── (SSM Agent インストール Playbook)
    ├── (CloudWatch Agent インストール Playbook)
    └── (CloudWatch Agent 設定・起動 Playbook)
```

> 💡 Playbook のファイル名やタスクの構成は Claude Code に任せて大丈夫です。

---

## ⚠️ リソースの削除

ワークショップ終了後にあなたのターミナルで IAM リソースを削除してください。
`<PREFIX>` の部分は自分のプレフィックスに置き換えてください（`echo $TF_VAR_prefix` で確認できます）。

> 💡 Claude Code に「セッション5で作成した IAMリソース、CloudWatch Alarm、ロググループをすべて削除してください。プレフィックスは環境変数 TF_VAR_prefix の値を使ってください」と伝えれば、AI Agent がまとめて実行してくれます。

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

> ⚠️ **check.sh は Claude Code の外で実行してください**。
> `/exit` で bash に戻ってからコマンドを実行し、`claude -c` で再開できます。

```bash
./scripts/check.sh session5
```

> 💡 Step 3（SSM Run Command）はAWSコンソールでの手動操作のため、自動チェックの対象外です。フリートマネージャーでの確認は各自で行ってください。

---

## ➡️ 次のステップ

[セッション6：運用レポートの自動生成（任意）](session6_guide.md) に進んでください。
