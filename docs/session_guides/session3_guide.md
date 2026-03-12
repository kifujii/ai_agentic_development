# セッション3：EC2 を count でスケールアウトしよう（任意・45分）

> このセッションは **任意（発展課題）** です。セッション2が完了し、余裕がある方向けです。

## 🎯 このセッションの到達状態

Terraform の `count` を使って EC2 を 2台に増やし、両方の nginx にアクセスできる状態を体験した後、`terraform destroy -target` で1台だけ削除して元に戻っています。

![目標構成](../images/session3_target.svg)

### セッション2からの変化

| | セッション2 | セッション3（途中） | セッション3（最終） |
|---|:---:|:---:|:---:|
| EC2 台数 | 1台 | **2台** | 1台（元に戻す） |
| Terraform の学び | plan/destroy/apply | **count / targeted destroy** | — |

> 🎓 **このセッションのポイント**: Terraform の `count` を使えば、**コード1行の変更でサーバーの台数を増減** できます。手動で同じことをすると、EC2起動 → SG設定 → nginx インストール... と何ステップも必要ですが、IaC なら一瞬です。

---

## 📚 事前準備

> ⚠️ **環境変数が未設定の場合**: `echo $TF_VAR_prefix` で値が表示されない場合は講師に確認してください。

- セッション2が完了していること（`user_data` 付きの EC2 が起動し、nginx にHTTPでアクセスできる状態）
- EC2のIPアドレスを確認：

```bash
terraform -chdir=terraform/vpc-ec2 output instance_public_ip
```

---

## 構築の流れ

```
Step 1: count で EC2 を2台に増やそう（15分）
    ↓
Step 2: 2台の EC2 を確認しよう（10分）
    ↓
Step 3: targeted destroy で1台だけ削除しよう（15分）
    ↓
振り返り（5分）
```

> ⏱️ **時間配分について**: 各 Step の所要時間は目安です。Claude Code の応答速度やエラー対応で前後することがあります。

---

## Step 1: count で EC2 を2台に増やそう（15分）

### やること

Terraform の `count` パラメータを使って、既存の EC2 定義を 2台構成に変更します。

### ゴール

- `aws_instance` リソースに `count = 2` が設定されている
- `outputs.tf` が複数台に対応している（splat 式 `[*]` の使用）
- `terraform plan` で「1台追加」の差分が表示されている
- `terraform apply` が成功し、EC2 が 2台 running になっている

> 💡 **ヒント**: `count` を使うと、リソース名が `aws_instance.training_ec2` → `aws_instance.training_ec2[0]`, `aws_instance.training_ec2[1]` のようにインデックス付きになります。output もこれに合わせて変更が必要です。
>
> 📖 **用語解説**:
> - `count = 2`: 同じ定義のリソースを2つ作る指定
> - `count.index`: 0から始まる連番（1台目=0, 2台目=1）。タグ名の区別などに使う
> - `[*]`（splat式）: 複数のリソースの値をまとめてリストにする書き方（例: `aws_instance.training_ec2[*].public_ip` → 全台のIPアドレスのリスト）
> - `moved` ブロック: リソース名の変更時に、既存リソースの再作成を防ぐ仕組み

### Claude Code への指示

<details>
<summary>📝 プロンプト例</summary>

```
terraform/vpc-ec2/ の EC2 を count で2台に増やしてください。
- moved ブロックで既存EC2の再作成を防ぐ
- outputs.tf を複数台対応に変更（既存の単数形 output も残す）
まず terraform plan で変更内容を確認してください。
```

</details>

### terraform plan の確認

Claude Code が `terraform plan` を実行すると、以下のような差分が表示されるはずです：

```
  # aws_instance.training_ec2 has moved to aws_instance.training_ec2[0]

  # aws_instance.training_ec2[1] will be created
  + resource "aws_instance" "training_ec2" {
      ...
    }

Plan: 1 to add, N to change, 0 to destroy.
```

> 💡 **`moved` ブロック** により、1台目の EC2 は `aws_instance.training_ec2` → `aws_instance.training_ec2[0]` に名前が移行されるだけで再作成されません（IPアドレスも変わりません）。2台目が新規作成されます。
>
> ⚠️ **`moved` ブロックがない場合**、Terraform は1台目を削除して作り直すため、IPアドレスが変わってしまいます。plan に `destroy` が含まれていたら、`moved` ブロックが正しく設定されているか確認してください。

あなたが plan の内容を確認したら、Claude Code に `terraform apply を実行してください` と伝えましょう。

### 確認（あなたがターミナルで実行）

```bash
terraform -chdir=terraform/vpc-ec2 output
```

2台分のIPアドレスとインスタンスIDが表示されれば OK ✅

---

## Step 2: 2台の EC2 を確認しよう（10分）

### やること

2台の EC2 が両方とも正常に稼働していることを確認します。

### ゴール

- 2台とも EC2 が running 状態
- 2台とも nginx が起動し、ブラウザでアクセスできる

### 確認手順（あなたがターミナル・ブラウザで実行）

1. あなたのターミナルで **terraform output** を実行して2台のIPアドレスを確認：

```bash
terraform -chdir=terraform/vpc-ec2 output instance_public_ips
```

2. **あなたがブラウザで両方にアクセス**:
   - `http://<1台目のIP>` → nginx ページが表示される
   - `http://<2台目のIP>` → nginx ページが表示される

> 💡 2台目のEC2も `user_data` が適用されているので、**自動的に nginx がインストール・起動** されています。手動で SSH してインストールする必要はありません。`user_data` の実行完了まで1〜2分待ってからアクセスしてください。

<details>
<summary>❓ 2台目のnginxが表示されない場合</summary>

`user_data` の実行に1〜2分かかります。少し待ってからリトライしてください。

それでも表示されない場合は、Claude Code に確認を依頼しましょう：

```
EC2（<2台目のIPアドレス>）にSSHで接続して、nginxが起動しているか確認してください。
起動していない場合は原因を調べて修正してください。

接続情報:
- SSH鍵: keys/training-key
- ユーザー: ec2-user
```

</details>

2台ともブラウザで nginx ページが表示されれば OK ✅

> 🎓 **ここがIaCの威力**: 手動なら「EC2作成 → SSH → dnf install → systemctl start」を**もう1回繰り返す**必要があります。Terraform + `user_data` なら `count = 2` に変えて `apply` するだけで、**全く同じ構成のサーバーが即座に増えます**。

---

## Step 3: targeted destroy で1台だけ削除しよう（15分）

### やること

`terraform destroy -target` を使って、**2台目の EC2 だけを削除** します。その後、コードを1台構成に戻して整合性を取ります。

### ゴール

- 2台目の EC2 のみが削除されている
- 1台目の EC2 はそのまま稼働中
- Terraform コードが1台構成に戻っている（`count` の削除 or `count = 1`）
- `terraform plan` で差分がない状態

### 手順

#### 3-1. targeted destroy で2台目だけ削除

<details>
<summary>📝 プロンプト例</summary>

```
terraform destroy -target を使って、2台目のEC2（aws_instance.training_ec2[1]）だけを削除してください。
1台目は残してください。

terraform -chdir=terraform/vpc-ec2 destroy -target='aws_instance.training_ec2[1]'
```

</details>

#### 3-2. コードを1台構成に戻す

> ⚠️ **重要**: targeted destroy はリソースだけを削除するので、**コード上はまだ `count = 2` のまま** です。このままだと次の `terraform apply` で2台目が再作成されてしまいます。
>
> 必ずコードも合わせて修正しましょう。**コードとインフラの状態を一致させる** のが Terraform の基本です。

<details>
<summary>📝 プロンプト例</summary>

```
terraform/vpc-ec2/ のEC2定義を1台構成に戻してください。

■ 変更内容
1. aws_instance の count を削除（または count = 1 にする）
2. Name タグを元の形式に戻す（"${var.prefix}-ec2"）
3. outputs.tf の整理
   - セッション3で追加した複数形の output（instance_public_ips 等）を削除
   - セッション1で作成した単数形の output（instance_public_ip 等）はそのまま維持

変更後、terraform plan を実行して差分がないことを確認してください。
```

</details>

### 確認（あなたがターミナルで実行）

```bash
terraform -chdir=terraform/vpc-ec2 plan
```

`No changes. Your infrastructure matches the configuration.` が表示されれば OK ✅

> 💡 **targeted destroy の注意点**: `-target` は緊急時や一時的な作業向けの機能です。通常の運用では、**コードを変更 → plan → apply** のフローで管理するのが正しい方法です。

---

## 📝 振り返り（5分）

### このセッションで体験したこと

| 作業 | 学び |
|------|------|
| count でEC2を2台に増加 | **コード1行で台数を制御** できるIaCの威力 |
| 2台のnginxを確認 | user_data + count で同一構成を即座にスケールアウト |
| targeted destroy で1台削除 | 特定リソースだけの選択的削除が可能 |
| コードを1台構成に戻す | **コードとインフラの整合性** を保つ重要性 |

### count を使うメリット

- サーバーの台数を **変数1つ** で管理できる
- 全台に同じ `user_data`（セットアップスクリプト）が適用される
- 増設も縮退も `terraform apply` だけで完了

### 実務での活用

| シーン | count の使い方 |
|--------|---------------|
| 負荷テスト | 一時的にサーバーを10台に増やす → テスト後に戻す |
| 障害対応 | 壊れたサーバーを削除 → count を維持して自動再作成 |
| コスト削減 | 夜間はサーバーを減らして費用を抑える |

### 📖 コードを理解しよう — count と splat 式を説明できるようになる

`count` や `[*]`（splat式）は Terraform の重要な機能です。Claude Code に解説を作ってもらい、理解を深めましょう：

<details>
<summary>📝 プロンプト例</summary>

```
このセッションで使った Terraform の count と splat 式について、初心者向けの解説ドキュメントを作成してください。
保存先: docs/session3_design.md

■ 含めてほしい内容
1. count = 2 を指定したとき、Terraform 内部で何が起きるかの図解
2. count.index の使い方と具体例（Name タグの付け方など）
3. splat 式 [*] の意味と使用例
4. terraform destroy -target の仕組みと注意点
5. count を使ったときと使わないときの outputs.tf の違い
6. 実務で count の代わりに for_each を使うケースの紹介（発展）
```

</details>

生成されたドキュメントを読んで、以下を確認しましょう：

- [ ] `count = 2` を指定するとリソースにインデックスが付く仕組みが説明できる
- [ ] `aws_instance.training_ec2[*].public_ip` が何を返すか説明できる
- [ ] `terraform destroy -target` を使った後にコードも修正する理由が説明できる

---

## ファイル構成

セッション完了時、以下の構成になっています（セッション2と同じ）：

```
terraform/
└── vpc-ec2/
    ├── main.tf          # VPC, Subnet, IGW, RT, SG(SSH+HTTP), KP, EC2(user_data付き, count=1)
    ├── variables.tf     # 変数定義
    └── outputs.tf       # VPC ID, Subnet ID, SG ID, Public IP, Instance ID
```

---

## ⚠️ リソースの削除

このセッションではリソースを一時的に増やしましたが、最後に1台構成に戻しています。
追加で削除が必要なリソースはありません。全体のクリーンアップはセッション6で行います。

---

## ✅ 完了チェック

以下のコマンドで、このセッションの完了状態を確認できます。

> ⚠️ **check.sh は Claude Code の外で実行してください**。
> `/exit` で bash に戻ってからコマンドを実行し、`claude -c` で再開できます。

```bash
./scripts/check.sh session3
```

---

## ➡️ 次のステップ

[セッション4：Ansible によるサーバー運用自動化](session4_guide.md) に進んでください。
