# セッション3：EC2 + RDS で動的アプリケーションを構築しよう（任意・1.5時間）

> このセッションは **任意（発展課題）** です。セッション2が完了し、余裕がある方向けです。

## 🎯 このセッションのゴール

セッション2では静的HTMLをnginxで公開しました。このセッションでは **RDS（MySQL）** を追加し、データベースと連携した動的なWebアプリケーションをブラウザで動かします。

![目標構成](../images/session3_target.svg)

### このセッションで作成するリソース

| リソース | 設定値 |
|---------|-------|
| パブリックサブネット追加 | 10.0.2.0/24（ap-northeast-1c）※RDSサブネットグループ用 |
| RDS用セキュリティグループ | MySQL(3306) を EC2 SG からのみ許可 |
| DBサブネットグループ | パブリックサブネット × 2（1a + 1c） |
| RDS (MySQL) | db.t3.micro, training-db |

> 🎓 **セッション2からのステップアップ**: 静的HTML → データベース連携の動的Webアプリへ

---

## 📚 事前準備

- セッション2が完了していること（EC2にnginxがインストール済み）
- EC2のIPアドレスを確認：

```bash
cd terraform/vpc-ec2
terraform output instance_public_ip
cd ../..
```

> ⚠️ **作業ディレクトリについて**: Continueへのプロンプトは **プロジェクトルート** から実行してください。

---

## 構築の流れ

```
Step 1: RDS 関連リソースを Terraform で作成（30分）
    ↓
Step 2: EC2 から RDS に接続確認（10分）
    ↓
Step 3: PHP 環境をセットアップ（15分）
    ↓
Step 4: 動的 Web アプリを作成・デプロイ（25分）
    ↓
Step 5: ブラウザで動作確認（5分）
    ↓
振り返り（5分）
```

---

## Step 1: RDS 関連リソースを Terraform で作成しよう（30分）

### やること

RDSインスタンスを作成するために必要なリソース一式をTerraformで作成します。

### ゴール

`terraform/vpc-ec2/` の既存コードに、以下を追加して apply する：

- パブリックサブネット2: `10.0.2.0/24`（ap-northeast-1c）
- 既存ルートテーブルへの関連付け
- RDS用セキュリティグループ: MySQL(3306) を **EC2のSGからのみ** 許可
- DBサブネットグループ: パブリックサブネット × 2
- RDSインスタンス: `db.t3.micro`, MySQL 8.0, `training-db`
  - ユーザー名: `admin`, パスワード: `trainingpass123`（研修用の簡易パスワード）
  - ストレージ: 20GB
  - `skip_final_snapshot = true`（研修用なのでスナップショット不要）
  - `publicly_accessible = false`

> 💡 **ヒント**: RDSはDBサブネットグループが必要で、**異なるAZ**に最低2つのサブネットが必要です。

<details>
<summary>📝 プロンプト例</summary>

```
terraform/vpc-ec2/ の既存コードに、RDS関連リソースを追加してください。

1. パブリックサブネット2: 10.0.2.0/24 (ap-northeast-1c)
   - 既存のルートテーブルに関連付け
2. RDS用セキュリティグループ: MySQL(3306) を EC2のセキュリティグループからのみ許可
3. DBサブネットグループ: パブリックサブネット2つで構成
4. RDSインスタンス:
   - エンジン: mysql 8.0
   - インスタンスクラス: db.t3.micro
   - 識別子: training-db
   - DB名: trainingdb
   - ユーザー: admin / パスワード: trainingpass123
   - ストレージ: 20GB
   - skip_final_snapshot = true
   - publicly_accessible = false
5. outputs.tf に RDSのエンドポイントを追加

terraform apply まで実行してください。
```

</details>

### 確認

```bash
cd terraform/vpc-ec2
terraform output rds_endpoint
cd ../..
```

> ⚠️ **RDSの作成には5〜10分かかります。** 待っている間にStep 2の準備をしましょう。

RDSのエンドポイント（`training-db.xxxx.ap-northeast-1.rds.amazonaws.com:3306`）が表示されれば OK ✅

---

## Step 2: EC2 から RDS に接続確認しよう（10分）

### やること

EC2にSSHログインし、MySQLクライアントでRDSに接続できるか確認します。

### 手順

```bash
ssh -i ~/.ssh/training-key ec2-user@<EC2のIPアドレス>
```

```bash
# MySQL クライアントをインストール
sudo dnf install -y mariadb105

# RDS に接続（エンドポイントは Step 1 の output で確認した値）
mysql -h <RDSのエンドポイント（:3306は除く）> -u admin -ptrainingpass123 trainingdb
```

接続できたら、テスト用のテーブルを作成：

```sql
CREATE TABLE messages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  message TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO messages (name, message) VALUES ('テスト', 'RDS接続成功！');

SELECT * FROM messages;
```

データが表示されれば OK ✅ 確認後、`exit` で MySQL を終了します（**EC2からはログアウトしないでください**）。

---

## Step 3: PHP 環境をセットアップしよう（15分）

### やること

EC2にPHPをインストールし、nginxでPHPが動作するように設定します。

### 手順（EC2にログイン中）

```bash
# PHP と MySQL 拡張をインストール
sudo dnf install -y php-fpm php-mysqlnd php-json

# PHP-FPM を起動
sudo systemctl start php-fpm
sudo systemctl enable php-fpm
```

nginxの設定を変更してPHPを有効にします：

```bash
# nginx の設定を編集
sudo tee /etc/nginx/conf.d/php.conf > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.php index.html;

    location ~ \.php$ {
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF

# デフォルトの server ブロックを無効化
sudo sed -i 's/listen       80;/listen       8080;/' /etc/nginx/nginx.conf

# nginx を再起動
sudo systemctl restart nginx
```

PHPが動作するか確認：

```bash
echo "<?php phpinfo(); ?>" | sudo tee /usr/share/nginx/html/info.php
curl -s http://localhost/info.php | head -5
```

HTMLが出力されれば OK ✅

---

## Step 4: 動的 Web アプリを作成・デプロイしよう（25分）

### やること

ContinueのAgentに、RDSに接続してデータを表示・追加できるWebアプリ（PHP）を作成してもらいます。

### ゴール

- メッセージの一覧表示
- 新しいメッセージの投稿フォーム
- 見た目の良いデザイン

> 💡 **ポイント**: Agentに「DBの接続情報」と「どんな機能が欲しいか」を具体的に伝えましょう。

<details>
<summary>📝 プロンプト例</summary>

```
web/app.php ファイルを作成してください。以下の要件でPHPのWebアプリケーションを作ってください。

データベース接続情報:
- ホスト: <RDSのエンドポイント（:3306は除く）>
- ユーザー: admin
- パスワード: trainingpass123
- DB名: trainingdb

機能:
- messages テーブルの一覧表示（新しい順）
- 新しいメッセージを投稿するフォーム（名前とメッセージ）
- 投稿後はリダイレクトしてページをリロード

デザイン:
- モダンで見やすいデザイン（CSSインライン）
- ヘッダーに「メッセージボード」のタイトル
- レスポンシブデザイン
```

</details>

### デプロイ

作成したPHPファイルをEC2に転送します（ローカルのターミナルで実行、EC2からログアウトしてから）：

```bash
exit  # EC2からログアウト

scp -i ~/.ssh/training-key web/app.php ec2-user@<EC2のIPアドレス>:/tmp/app.php
ssh -i ~/.ssh/training-key ec2-user@<EC2のIPアドレス>
sudo cp /tmp/app.php /usr/share/nginx/html/index.php
exit
```

---

## Step 5: ブラウザで動作確認しよう（5分）

ブラウザで `http://<EC2のIPアドレス>` にアクセスします。

- メッセージボードが表示される
- Step 2 で追加した「テスト」メッセージが一覧に表示されている
- フォームからメッセージを投稿できる
- 投稿後、一覧に新しいメッセージが表示される

上記がすべて確認できれば **セッション3完了** 🎉

<details>
<summary>❓ 表示されない場合</summary>

- **502 Bad Gateway**: PHP-FPM が起動していない → `sudo systemctl restart php-fpm`
- **DB接続エラー**: RDSエンドポイントが正しいか、セキュリティグループでEC2→RDS(3306)が許可されているか確認
- **ページが変わらない**: ブラウザのキャッシュをクリアしてリロード

</details>

---

## 📝 振り返り（5分）

### セッション2からの進化

| セッション2 | セッション3 |
|:---:|:---:|
| 静的HTML | 動的PHP + MySQL |
| ファイルを配置するだけ | DB連携アプリ |
| Webサーバーのみ | Web + DB の2層構成 |

### プロンプトで意識したこと

- **DB接続情報**は正確に伝える（ホスト、ユーザー、パスワード、DB名）
- **機能要件**と**デザイン要件**を分けて伝える
- 既存のテーブル構造を伝えることで、Agentが適切なSQLを生成できる

---

## ファイル構成

```
terraform/
└── vpc-ec2/
    ├── main.tf          # VPC, Subnet×2, SG(SSH+HTTP+RDS), EC2, RDS
    ├── variables.tf
    └── outputs.tf       # + rds_endpoint

web/
├── index.html           # セッション2で作成
└── app.php              # セッション3で作成
```

---

## ⚠️ リソースの削除

> ⚠️ **RDS削除には5〜10分かかります。** ワークショップ終了後に削除してください。

```bash
cd terraform/vpc-ec2
terraform destroy
cd ../..
```

---

## ➡️ 次のステップ

[セッション4：サーバー再起動の自動化（Ansible入門）](session4_guide.md) に進んでください。
