# セッション2：Webアプリケーションを公開 評価チェックリスト

## 事前準備
- [ ] セッション1が完了していること（VPC/EC2が構築済み）
- [ ] EC2のIPアドレスを確認した

## Step 1: セキュリティグループにHTTP追加
- [ ] EC2セキュリティグループにHTTP(80)のインバウンドルールを追加した
- [ ] terraform apply が成功した

## Step 2: nginxインストール
- [ ] EC2にnginxをインストール・起動した
- [ ] `systemctl status nginx` で active (running) を確認した

## Step 3: ブラウザ確認
- [ ] `http://<EC2のIP>` でnginxデフォルトページが表示された

## Step 4: カスタムWebページ
- [ ] AgentにHTMLページを作成させた
- [ ] scpでEC2に転送し、nginxで公開した
- [ ] ブラウザでカスタムページが表示された

## Step 5: ページ改善
- [ ] ページに機能を追加して再デプロイした
- [ ] ブラウザで改善が反映されていることを確認した

## 成果物
- [ ] `terraform/vpc-ec2/` のSGにHTTPルールが追加されている
- [ ] `web/index.html` が作成されている
