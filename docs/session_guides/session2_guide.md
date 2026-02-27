# セッション2：Webアプリケーションを公開しよう（必須・2時間）

## 🎯 このセッションのゴール

セッション1で構築したEC2にWebサーバーをインストールし、ブラウザからアクセスできるWebアプリケーションを公開します。

![目標構成](../images/session2_target.svg)

### このセッションで変更・追加するリソース

| リソース | 変更内容 |
|---------|---------|
| セキュリティグループ | HTTP(80) のインバウンドルールを追加 |
| EC2 上のソフトウェア | nginx（Webサーバー）をインストール |
| Webコンテンツ | カスタムHTMLページをデプロイ |

> 🎓 このセッションでは「Terraform でインフラを変更 → EC2 にソフトウェアを導入 → アプリをデプロイ」という **一連の流れ** を体験します。

---

## 📚 事前準備

- セッション1が完了していること（VPC/EC2が構築済み）
- EC2のIPアドレスを確認してメモ：

```bash
cd terraform/vpc-ec2
terraform output instance_public_ip
cd ../..  # プロジェクトルートに戻る
```

> ⚠️ **作業ディレクトリについて**: Continueへのプロンプトは **プロジェクトルート** から実行してください。

---

## 構築の流れ

```
Step 1: セキュリティグループに HTTP(80) を追加（25分）
    ↓
Step 2: EC2 に nginx をインストール（25分）
    ↓
Step 3: ブラウザでアクセス確認（10分）
    ↓
Step 4: カスタム Web ページを作成・デプロイ（30分）
    ↓
Step 5: Web ページを改善してみよう（25分）
    ↓
振り返り（5分）
```

---

## Step 1: セキュリティグループに HTTP を追加しよう（25分）

### やること

現在のEC2セキュリティグループはSSH(22)のみ許可していますが、Webアプリを公開するためにHTTP(80)のアクセスも許可する必要があります。

### ゴール

`terraform/vpc-ec2/` の既存コードを修正して apply する：

- 既存のセキュリティグループに **HTTP(80)** のインバウンドルールを追加
- ソース: `0.0.0.0/0`（全体に公開）

> 💡 **ヒント**: `aws_security_group` リソースの `ingress` ブロックを追加します。SSH のルールはそのまま残し、HTTP 用のルールを新たに追加してください。

<details>
<summary>📝 プロンプト例</summary>

```
terraform/vpc-ec2/ の既存コードで、EC2のセキュリティグループに HTTP(80) のインバウンドルールを追加してください。
ソースは 0.0.0.0/0 で、既存の SSH ルールはそのまま残してください。

terraform apply まで実行してください。
```

</details>

### 確認

まず `terraform output` で全出力を確認します：

```bash
cd terraform/vpc-ec2
terraform output
```

AWSコンソールまたは以下のコマンドで、HTTP(80)ルールが追加されていることを確認：

```bash
# セッション1で security_group_id を output に定義している場合
aws ec2 describe-security-groups \
  --group-ids "$(terraform output -raw security_group_id)" \
  --query 'SecurityGroups[0].IpPermissions'
cd ../..
```

> 💡 `terraform output -raw security_group_id` でエラーが出る場合は、`terraform output` の結果からSG IDを確認し、直接指定してください：
> ```bash
> aws ec2 describe-security-groups --group-ids sg-xxxxx --query 'SecurityGroups[0].IpPermissions'
> ```

HTTP(80) のルールが表示されれば OK ✅

---

## Step 2: EC2 に nginx をインストールしよう（25分）

### やること

EC2にSSHログインして、Webサーバー（nginx）をインストール・起動します。

> 💡 この手動操作は、セッション4でAnsibleを使って自動化する内容のプレビューでもあります。「手動だと面倒だな」と感じてもらうのがポイントです。

### 手順

1. **EC2にSSHログイン**:

```bash
ssh -i ~/.ssh/training-key ec2-user@<EC2のIPアドレス>
```

2. **nginxをインストール・起動**:

```bash
sudo dnf install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

3. **nginxが動作しているか確認**:

```bash
sudo systemctl status nginx
```

`active (running)` と表示されれば OK ✅

> ⚠️ まだEC2からログアウトしないでください。Step 3の確認後にStep 4で使います。

---

## Step 3: ブラウザでアクセスしてみよう（10分）

### やること

ブラウザで `http://<EC2のIPアドレス>` にアクセスします。

**nginxのデフォルトページ（Welcome to nginx）** が表示されれば成功 🎉

<details>
<summary>❓ ページが表示されない場合</summary>

- **セキュリティグループの確認**: HTTP(80)が `0.0.0.0/0` で許可されているか
- **nginxの状態確認**: EC2内で `sudo systemctl status nginx` を実行
- **IPアドレスの確認**: `http://` で始まるURL（`https://`ではない）を使用しているか
- **ファイアウォール**: EC2のOS側でポート80がブロックされていないか（Amazon Linux 2023はデフォルトで許可）

</details>

---

## Step 4: カスタムWebページを作成・デプロイしよう（30分）

### やること

ContinueのAgentにカスタムHTMLページを作成してもらい、EC2にデプロイします。

### ゴール

- Agentにトレーニング用のWebページ（HTML）を作成させる
- 作成したファイルをEC2にコピーしてnginxで公開する
- ブラウザでカスタムページが表示されることを確認する

> 💡 **ポイント**: ここでは「Agent にどう伝えればイメージ通りのページが作れるか」を考えてみましょう。デザインの指示も含めてプロンプトを工夫してみてください。

### 手順

#### 1. AgentにHTMLページを作成させる

Continueに、例えば以下のような内容のWebページの作成を依頼します：

- トレーニング参加者向けのダッシュボードページ
- 参加者の名前（自分の名前）を表示
- 今日の日付を表示
- セッション1〜5の一覧と進捗状況
- 見た目が良いデザイン（CSSも含む）

> どんなページにするかは自由です。自分で考えてプロンプトを書いてみましょう。

<details>
<summary>📝 プロンプト例</summary>

```
以下の要件でHTMLファイルを1つ作成してください。ファイルは web/index.html に保存してください。

- タイトル: 「AI駆動IaCワークショップ ダッシュボード」
- ヘッダーに研修名と参加者名（あなたの名前）を表示
- セッション1〜5の一覧をカード形式で表示（セッション名、概要、所要時間）
- レスポンシブデザイン（スマホでも見やすい）
- CSSはHTMLファイル内にインラインで記述
- モダンなデザイン（グラデーション背景、影付きカード等）
```

</details>

#### 2. EC2にファイルをコピー

作成したHTMLファイルをEC2に転送します。

> ⚠️ **重要**: `scp` コマンドはEC2ではなく **ローカル（プロジェクトルート）** で実行します。EC2にログイン中の場合は、先に `exit` でログアウトしてください。

```bash
# Step 2でSSH接続中の場合、まずログアウト
exit

# プロジェクトルートに戻ったことを確認
# （プロンプトがEC2ではなくローカルになっていればOK）

# ファイルをEC2に転送
scp -i ~/.ssh/training-key web/index.html ec2-user@<EC2のIPアドレス>:/tmp/index.html
```

EC2にSSHログインしてファイルを配置：

```bash
ssh -i ~/.ssh/training-key ec2-user@<EC2のIPアドレス>
sudo cp /tmp/index.html /usr/share/nginx/html/index.html
exit
```

#### 3. ブラウザで確認

`http://<EC2のIPアドレス>` にアクセスして、カスタムページが表示されることを確認 ✅

---

## Step 5: Webページを改善してみよう（25分）

### やること

Step 4で作成したページに機能を追加して、もう一度デプロイします。

### ゴール

ページを改善して、再デプロイする一連の流れを体験する。

> 💡 **ポイント**: 「既存のファイルを改善して」とAgentに伝えるとき、**何を変えたいのか具体的に** 伝えることが重要です。

### 改善のアイデア（好きなものを選んでください）

- 現在の時刻をリアルタイム表示するJavaScriptを追加
- ダークモード切り替えボタンを追加
- セッションの進捗を更新できるチェックボックスを追加
- アニメーション効果を追加
- AWS構成の簡易図を表示

<details>
<summary>📝 プロンプト例</summary>

```
web/index.html を改善してください。

- 現在の日時をリアルタイムで表示するセクションを追加（JavaScriptで毎秒更新）
- ダークモード/ライトモードを切り替えるトグルボタンを追加
- 各セッションにチェックボックスを追加し、完了したセッションをマークできるようにする
```

</details>

### 再デプロイ

Step 4と同じ手順で再デプロイします：

```bash
scp -i ~/.ssh/training-key web/index.html ec2-user@<EC2のIPアドレス>:/tmp/index.html
ssh -i ~/.ssh/training-key ec2-user@<EC2のIPアドレス>
sudo cp /tmp/index.html /usr/share/nginx/html/index.html
exit
```

ブラウザで `http://<EC2のIPアドレス>` をリロードして、改善が反映されていることを確認 ✅

---

## 📝 振り返り（5分）

### このセッションで体験したこと

| 作業 | ツール | 学び |
|------|--------|------|
| SG にHTTPルール追加 | Terraform + Agent | 既存インフラの変更もAgentで |
| nginx インストール | SSH（手動） | 手動運用の手間を実感 → Session 4で自動化 |
| HTML ページ作成 | Agent | デザイン含めたコード生成 |
| ファイル転送・デプロイ | scp + SSH | 手動デプロイの流れ |

### プロンプトで意識したこと

- **既存コードの変更**は「何を変えて、何を残すか」を明確にする
- **デザイン要件**はできるだけ具体的に伝える（色、レイアウト、機能）
- **改善依頼**は「現状の何が不満で、どうしたいか」を伝える

---

## ファイル構成

セッション完了時、以下の構成になっています：

```
terraform/
└── vpc-ec2/
    ├── main.tf          # VPC, Subnet, IGW, RT, SG(SSH+HTTP), KP, EC2
    ├── variables.tf     # 変数定義
    └── outputs.tf       # VPC ID, Subnet ID, SG ID, Public IP

web/
└── index.html           # カスタムWebページ
```

---

## ⚠️ リソースの削除

> ワークショップ期間中はリソースを削除しないでください。**全セッション終了後**に削除してください。

```bash
cd terraform/vpc-ec2
terraform destroy
cd ../..
```

---

## ➡️ 次のステップ

- **任意課題に挑戦**: [セッション3：動的 Web アプリを作ろう](session3_guide.md)
- **次のセッションへ**: [セッション4：サーバー再起動の自動化（Ansible入門）](session4_guide.md)
