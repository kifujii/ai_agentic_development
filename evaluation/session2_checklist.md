# セッション2：Webアプリケーションを公開 評価チェックリスト

## 事前準備
- [ ] セッション1が完了していること（VPC/EC2が構築済み）
- [ ] EC2のIPアドレスを確認した

## Step 1: セキュリティグループにHTTP追加
- [ ] Agentに指示してHTTP(80)のインバウンドルールを追加した
- [ ] terraform apply が成功した

## Step 2: nginxインストール（Agent経由）
- [ ] AgentがSSHでEC2に接続してnginxをインストール・起動した
- [ ] Agent から active (running) の報告を受けた

## Step 3: ブラウザ確認
- [ ] `http://<EC2のIP>` でnginxデフォルトページが表示された

## Step 4: カスタムWebページ作成・デプロイ（Agent経由）
- [ ] AgentにHTMLページの作成とデプロイをまとめて指示した
- [ ] Agentがファイル作成→転送→配置まで実行した
- [ ] ブラウザでカスタムページが表示された

## Step 5: ページ改善・再デプロイ（Agent経由）
- [ ] Agentにページ改善と再デプロイを指示した
- [ ] ブラウザで改善が反映されていることを確認した

## 成果物
- [ ] `terraform/vpc-ec2/` のSGにHTTPルールが追加されている
- [ ] `web/index.html` が作成されている
