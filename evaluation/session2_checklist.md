# セッション2：Terraform でインフラを構築・変更・再構築 評価チェックリスト

## 事前準備
- [ ] セッション1が完了していること（VPC/EC2が構築済み）
- [ ] EC2のIPアドレスを確認した

## Step 1: セキュリティグループにHTTP追加
- [ ] Agentに指示してHTTP(80)のインバウンドルールを追加した
- [ ] `terraform apply` が成功した

## Step 2: nginxインストール（Agent経由）
- [ ] AgentがSSHでEC2に接続してnginxをインストール・起動した
- [ ] ブラウザで nginx のデフォルトページが表示された

## Step 3: terraform plan でインフラを変更
- [ ] EC2にタグ（Environment等）を追加した
- [ ] `terraform plan` で差分を確認し、内容を理解した
- [ ] `terraform apply` で変更を反映した

## Step 4: terraform destroy で全リソースを削除
- [ ] `terraform destroy` で全リソースを一括削除した
- [ ] AWSコンソール（またはterraform output）で削除を確認した

## Step 5: user_data で自動化して一発再構築
- [ ] EC2の定義に `user_data`（nginx自動インストール）を追加した
- [ ] `terraform apply` で全リソースを再構築した
- [ ] SSHなしでnginxが自動起動していることを確認した

## Step 6: カスタムページの改善・デプロイ
- [ ] カスタムWebページを作成してEC2にデプロイした
- [ ] ブラウザで改善されたページが表示された

## 成果物
- [ ] `terraform/vpc-ec2/` のEC2に `user_data` が設定されている
- [ ] EC2上でnginxが起動し、カスタムWebページが表示される

---

## 理解度チェック（自分の言葉で書いてみましょう）

- [ ] Q: `terraform plan` で差分を確認する目的は何ですか？
  - A: _______________
- [ ] Q: `terraform destroy` で削除した環境を再構築できるのはなぜですか？
  - A: _______________
- [ ] Q: `user_data` を使うメリットは何ですか？（Step 2の手動インストールとの対比）
  - A: _______________

## プロンプトの振り返り

- [ ] Agentへの指示で工夫したプロンプトを1つ記録した
  - 工夫した点: _______________
- [ ] terraform plan の出力を読んで「何が変わるか」を理解できた
  - 気づき: _______________
