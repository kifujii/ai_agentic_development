# セッション3：動的 Web アプリを作ろう（任意・45分）

> このセッションは **任意（発展課題）** です。セッション2が完了し、余裕がある方向けです。

## 🎯 このセッションのゴール

セッション2ではnginxで静的HTMLを公開しました。このセッションでは、**Python Flask** で動的Webアプリを作成し、**nginx をリバースプロキシとして構成** します。

![目標構成](../images/session3_target.svg)

### セッション2からの変化

| | セッション2 | セッション3 |
|---|:---:|:---:|
| nginx の役割 | HTMLファイルを直接配信 | リバースプロキシ（Flaskに転送） |
| コンテンツ | 静的HTML | Python Flask アプリ |
| データ保存 | なし | SQLite |

> 🎓 **nginx リバースプロキシ** とは、ブラウザからのリクエストをnginxが受け取り、裏側のアプリケーション（Flask）に転送する構成です。実務で最も一般的なWebアプリのデプロイパターンです。

---

## 📚 事前準備

- セッション2が完了していること（EC2にnginxがインストール済み）
- EC2のIPアドレスを確認：

```bash
cd terraform/vpc-ec2
terraform output instance_public_ip
cd ../..
```

---

## 構築の流れ

```
Step 1: Flask アプリの作成・デプロイ（30分）
    ↓
Step 2: ブラウザで動作確認（10分）
    ↓
振り返り（5分）
```

---

## Step 1: Flask アプリの作成・デプロイ（30分）

### やること

EC2上に Python Flask アプリをデプロイして、nginx からリバースプロキシで接続します。

### ゴール

以下の状態を目指します：

1. **Flask アプリ**: メッセージの投稿・一覧表示ができるゲストブック
2. **SQLite**: メッセージをデータベースに保存
3. **nginx**: ポート80でリクエストを受け、Flaskアプリ（ポート5000）に転送
4. **systemd サービス**: Flaskアプリがバックグラウンドで自動起動

### Agentへの指示

以下の要件を Agentに伝えて、セットアップ〜デプロイまでを一括で実行してもらいましょう。要件をどのようなプロンプトにまとめるかは自分で考えてみてください。

**伝える情報：**
- EC2の接続情報（IP、SSH鍵、ユーザー名）
- nginxはセッション2でインストール済み

**やってほしいこと：**
1. Python環境セットアップ（pip、Flask のインストール）
2. ゲストブックアプリの作成
   - 投稿フォーム（名前、メッセージ）
   - 投稿一覧（新しい順）
   - SQLiteでデータ保存
   - 見た目の良いHTML（CSSインライン）
3. systemd サービスとして登録・起動
4. nginx をリバースプロキシに設定変更（ポート80 → Flask 5000）
5. テストデータを1件投入して動作確認

<details>
<summary>📝 プロンプト例</summary>

```
EC2にSSHで接続して、以下の作業をすべて実行してください。

■ 接続情報
- IP: <EC2のIPアドレス>
- SSH鍵: ~/.ssh/training-key
- ユーザー: ec2-user
- nginxはインストール・起動済みです

■ 1. Python Flask 環境セットアップ
- pip3 で flask をインストール
- アプリ用ディレクトリ: /opt/guestbook/

■ 2. ゲストブックアプリ作成（/opt/guestbook/app.py）
- Flask アプリ（host=127.0.0.1, port=5000）
- SQLite データベース（/opt/guestbook/guestbook.db）
- テーブル: messages (id, name, message, created_at)
- 機能:
  - GET /: メッセージ一覧（新しい順）+ 投稿フォーム
  - POST /: メッセージ投稿 → リダイレクト
- HTMLはテンプレート文字列でOK。モダンなデザイン（CSSインライン）

■ 3. systemd サービス登録
- /etc/systemd/system/guestbook.service を作成
- ExecStart: python3 /opt/guestbook/app.py
- サービスを起動・有効化

■ 4. nginx リバースプロキシ設定
- nginx の default.conf または server ブロックを変更
- location / を proxy_pass http://127.0.0.1:5000 に設定
- nginx を再起動

■ 5. テストデータを1件投入して動作確認
```

</details>

---

## Step 2: ブラウザで動作確認しよう（10分）

ブラウザで `http://<EC2のIPアドレス>` にアクセスします。

- ✅ ゲストブックが表示される
- ✅ テストデータが一覧に表示されている
- ✅ フォームからメッセージを投稿できる
- ✅ 投稿後、一覧に新しいメッセージが表示される

上記がすべて確認できれば **セッション3完了** 🎉

<details>
<summary>❓ 表示されない場合</summary>

Agentにトラブルシューティングを依頼しましょう。以下の情報を伝えると効率的です：

- **症状**: ブラウザで何が表示されるか（エラー画面、nginx のデフォルトページ、など）
- **確認してほしいこと**:
  - Flask アプリのサービス状態（`systemctl status guestbook`）
  - nginx の設定テスト（`nginx -t`）
  - Flask アプリのログ（`journalctl -u guestbook`）
  - nginx のエラーログ（`/var/log/nginx/error.log`）

</details>

---

## 📝 振り返り（5分）

### このセッションで構築した構成

```
ブラウザ → nginx (port 80) → Flask (port 5000) → SQLite
            リバースプロキシ     アプリサーバー        データベース
```

この構成は **実務で最も一般的な Web アプリのデプロイパターン** です。nginx がリクエストを受け取り、裏側のアプリケーションサーバーに転送します。

### セッション4への接続

- Flask アプリを **systemd サービス** として登録しました
- セッション4では Ansible を使って、このようなサービスの管理（起動/停止/再起動）を自動化します

---

## ファイル構成

> このセッションでは Terraform ファイルは変更しません。EC2上に直接構築します。

```
# EC2上に作成されるファイル
/opt/guestbook/
├── app.py              # Flask アプリケーション
└── guestbook.db        # SQLite データベース

/etc/systemd/system/
└── guestbook.service   # systemd サービスファイル

/etc/nginx/             # nginx リバースプロキシ設定（既存ファイルの変更）
```

---

## ➡️ 次のステップ

[セッション4：サーバー再起動の自動化（Ansible入門）](session4_guide.md) に進んでください。
