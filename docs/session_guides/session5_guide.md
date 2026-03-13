# セッション5：SSM Agent & CloudWatch Agent の導入（必須・55分）

## 🎯 このセッションの到達状態

EC2に SSM Agent と CloudWatch Agent がインストール・稼働し、AWS API 経由でのリモート管理と CPU/メモリの監視ができる状態になっています。このセッションでは **Terraform は使わず、Ansible + AWS CLI** で実施します。

> 🎓 **なぜ2つのAgent（ソフトウェア）を入れるのか？**
> - **SSM Agent**: AWS API 経由でEC2にリモートアクセス（Session Manager）。SSHなしで管理できる。
> - **CloudWatch Agent**: CPU/メモリ/ディスクのメトリクスやログをCloudWatchに送信。監視に必須。
>
> ⚠️ **用語の注意**: このセッションに登場する「SSM Agent」「CloudWatch Agent」は **EC2上で動くAWSのソフトウェア** です。Claude Code（AI Agent）とは別物です。

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
前半: SSM Agent を導入してリモート管理できるようにしよう    (20分)
    ↓
後半: CloudWatch Agent で監視基盤を構築しよう              (20分)
    ↓
AWS CLI で確認                                              (10分)
    ↓
振り返り                                                   (5分)
```

> ⏱️ **時間配分について**: 各ステップの所要時間は目安です。IAMロールの反映やメトリクスの表示に数分かかることがあります。時間が足りない場合は講師に相談してください。

---

## 前半: SSM Agent を導入してリモート管理できるようにしよう（20分）

### チャレンジ

EC2 を **Systems Manager からリモート管理できる状態** にしてください。

### 達成条件

- EC2 が **Systems Manager のマネージドインスタンス** として登録されている（AWS CLI で確認）
- **SSM Run Command** で SSH を使わずに EC2 にコマンドを実行できる

### やること

Claude Code に「EC2 を Systems Manager で管理できるようにしたい」と伝えて、必要な作業を相談してください。何が必要かは Claude Code と一緒に考えましょう。

> 💡 **ヒント**: EC2 上のソフトウェアが AWS のサービスと通信するには「許可」が必要です。Claude Code に相談すれば、何をどういう順番で作ればいいか教えてくれます。

<details>
<summary>🔍 困ったら: もう少し具体的なヒント</summary>

- EC2 が AWS サービス（Systems Manager）と通信するには **IAM ロール** が必要です
- SSM Agent のインストールは **Ansible Playbook** で行いましょう
- Amazon Linux 2023 には SSM Agent がプリインストールされている場合があります
- プレフィックスとして環境変数 `TF_VAR_prefix` の値を使ってください
- IAM の変更は反映に 1〜2 分かかることがあります

</details>

### SSM Agent の動作確認

SSM Agent が正しく動作しているかを AWS CLI で確認します。あなたのターミナルで以下を実行してください：

```bash
aws ssm describe-instance-information --query "InstanceInformationList[].{ID:InstanceId,Ping:PingStatus,Agent:AgentVersion}" --output table
```

あなたの EC2 が `Online` で表示されれば、SSM Agent は正常に稼働しています。

> 💡 表示されるまで **1〜2分** かかることがあります。表示されない場合は少し待ってから再実行してください。

### Run Command を体験 — SSH なしでコマンド実行

SSM Agent が入ったことで、**SSH を使わずに AWS API 経由でコマンドを実行** できるようになりました。Claude Code に以下のように伝えて、Run Command を体験してみましょう：

```
SSM の Run Command を使って、EC2 上で以下のコマンドを実行してください。
結果も表示してください。SSH は使わないでください。

hostname
uptime
free -m
df -h
```

> 💡 **これが SSM の真価**: SSHポートを開けなくても、AWS API 経由でサーバー管理ができます。運用の現場では、セキュリティグループで SSH を閉じたまま管理できることが大きなメリットです。

### Ansible との比較を考えてみましょう

| 項目 | SSM Run Command | Ansible |
|------|----------------|---------|
| 接続方式 | AWS API 経由 | SSH |
| 実行方法 | AWS CLI / コンソール | ターミナル |
| 適した用途 | 緊急対応、一回限りの操作 | 繰り返す定型作業、自動化 |

Run Command でサーバー情報が取得できれば前半完了 ✅

---

## 後半: CloudWatch Agent で監視基盤を構築しよう（20分）

### チャレンジ

EC2 の **CPU・メモリ・ディスクの使用率を CloudWatch で監視できる状態** にしてください。さらに、CPU 使用率が高くなったら **アラーム** で通知される仕組みも作ってください。

### 達成条件

- CloudWatch にカスタムメトリクス（CPU/メモリ/ディスク）が送信されている
- CloudWatch Logs にシステムログが送信されている
- **CloudWatch Alarm** で CPU 使用率のアラームが設定されている

### やること

Claude Code に「EC2 のメトリクスとログを CloudWatch で監視できるようにしたい」と伝えて、必要な作業を相談してください。

> 💡 **ヒント**: 前半で SSM Agent を導入した流れを思い出してください。CloudWatch Agent も同じように「インストール → 設定 → 起動」の流れです。アラームは AWS CLI で作成できます。

<details>
<summary>🔍 困ったら: もう少し具体的なヒント</summary>

- CloudWatch Agent のインストール・設定は **Ansible Playbook** で行いましょう
- 設定ファイルでは収集するメトリクス（CPU、メモリ、ディスク）とログを指定します
- プレフィックスとして環境変数 `TF_VAR_prefix` の値を使ってください
- CloudWatch Alarm は **AWS CLI** で作成すると簡単です
- メトリクスが CloudWatch に表示されるまで **2〜5分** かかります

</details>

### AWS CLI で確認（10分）

CloudWatch Agent 起動後、**数分待ってから** あなたのターミナルで以下を実行して確認します：

**メトリクスの確認**:

```bash
aws cloudwatch list-metrics --namespace "${TF_VAR_prefix}/EC2" --query "Metrics[].MetricName" --output table
```

CPU、メモリ、ディスク関連のメトリクス名が表示されれば OK です。

> 💡 メトリクスが表示されるまで **2〜5分** かかります。何も表示されない場合は少し待ってから再実行してください。

**ロググループの確認**:

```bash
aws logs describe-log-groups --log-group-name-prefix "/${TF_VAR_prefix}/ec2" --query "logGroups[].logGroupName" --output table
```

**アラームの確認**:

```bash
aws cloudwatch describe-alarms --alarm-name-prefix "${TF_VAR_prefix}" --query "MetricAlarms[].{Name:AlarmName,State:StateValue}" --output table
```

> 💡 現時点ではCPU使用率が低いため、アラームのステータスは「OK」のはずです。

メトリクス・ロググループ・アラームが確認できれば後半完了 ✅

---

## 📝 振り返り（5分）

### このセッションで体験したこと

| 作業 | ツール | 学び |
|------|--------|------|
| SSM Agent 導入 | Ansible + AWS CLI | EC2がAWSサービスと通信するには **権限（IAM）** が必要 |
| SSM Run Command | AWS CLI (Claude Code) | SSH不要のリモート管理 |
| CloudWatch Agent 導入 | Ansible | メトリクス・ログ収集の自動化 |
| CloudWatch Alarm | AWS CLI (Claude Code) | 監視設定も Claude Code で自動化 |

### ツールの使い分け

| ツール | 用途 | このセッションでの使い方 |
|--------|------|------------------------|
| Terraform | インフラの構築 | 今回は使わなかった |
| Ansible | サーバー内の設定・ソフトウェア管理 | SSM Agent / CloudWatch Agent のインストール・設定 |
| AWS CLI | AWSリソースの操作 | IAMロール、CloudWatch Alarm |
| SSM | 緊急時のリモート管理 | Run Command で SSH なしのサーバー操作 |

### 📖 コードを理解しよう — AWS サービス連携の全体像を把握する

このセッションでは IAM、SSM、CloudWatch と多くの AWS サービスが登場しました。Claude Code に以下を聞いて、**関係性と設定の意味** を理解しましょう：

- IAM ロール・インスタンスプロファイル・ポリシーの関係
- SSM Agent の仕組み（EC2 と Systems Manager がどう通信するか）
- CloudWatch Agent の設定ファイルの各項目の意味
- CloudWatch Alarm の仕組み

---

## ⚠️ リソースの削除

ワークショップ終了後にリソースを削除してください。Claude Code に以下のように伝えるのが最も簡単です：

```
セッション5で作成した IAMリソース、CloudWatch Alarm、ロググループをすべて削除してください。
プレフィックスは環境変数 TF_VAR_prefix の値を使ってください。
```

> 💡 手動で削除する場合は、IAM（インスタンスプロファイル → ポリシーデタッチ → ロール削除）、CloudWatch Alarm、ロググループの順で削除します。

> CloudWatch Agent と SSM Agent は EC2 上のソフトウェアなので、EC2 削除時に一緒に消えます。

---

## ✅ 完了チェック

あなたのターミナルで以下のコマンドを実行して、このセッションの完了状態を確認できます：

> ⚠️ **check.sh は Claude Code の外で実行してください**。
> `/exit` で bash に戻ってからコマンドを実行し、`claude -c` で再開できます。

```bash
./scripts/check.sh session5
```

> 💡 Run Command の実行結果は自動チェックの対象外です。`aws ssm describe-instance-information` でマネージドインスタンスの登録を各自で確認してください。

---

## ➡️ 次のステップ

[セッション6：運用レポートの自動生成（任意）](session6_guide.md) に進んでください。
