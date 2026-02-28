# セッション3：動的 Web アプリ 評価チェックリスト

## 事前準備
- [ ] セッション2が完了していること（EC2にnginxがインストール済み）
- [ ] EC2のIPアドレスを確認した

## Step 1: Flask アプリの作成・デプロイ
- [ ] Python Flask がインストールされた
- [ ] ゲストブックアプリ（app.py）が作成された
- [ ] systemd サービスとして登録・起動された
- [ ] nginx がリバースプロキシとして設定された

## Step 2: ブラウザ確認
- [ ] `http://<EC2のIP>` でゲストブックが表示された
- [ ] フォームからメッセージを投稿できた
- [ ] 投稿後、一覧に新しいメッセージが表示された

## 成果物（EC2上）
- [ ] `/opt/guestbook/app.py` が作成されている
- [ ] `/opt/guestbook/guestbook.db` が作成されている
- [ ] `/etc/systemd/system/guestbook.service` が作成されている
- [ ] nginx のリバースプロキシ設定が有効
