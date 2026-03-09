# AI駆動IaCワークショップ

このプロジェクトは、Terraform / Ansible を使ったインフラ構築を AI Agent と協力して学ぶ研修ワークショップです。

## ルール

- 受講者から与えられた指示に基づいて作業してください
- **先回りして次のステップの作業を行わないでください**
- 1つのタスクが完了したら、結果を報告して次の指示を待ってください
- 作業結果は必ず受講者に分かりやすく説明してください

## リソース命名規則（重要）

複数の受講者が同一のAWS環境を使用しています。**すべてのAWSリソース名には必ず prefix を付けてください。**

- Terraform の場合: `var.prefix` 変数を使用（環境変数 `TF_VAR_prefix` から自動取得）
- AWS CLI の場合: 環境変数 `$PREFIX` を使用
- 例: VPC名 → `${var.prefix}-vpc`、IAMロール名 → `${PREFIX}-ec2-agent-role`

**prefix を付けずにリソースを作成すると、他の受講者のリソースと名前が衝突します。**

## プロジェクト構成

- `terraform/` — Terraform の設定ファイル（受講者が作成）
- `ansible/` — Ansible の設定・Playbook（受講者が作成）
- `keys/` — SSH鍵（Git管理外）
- `scripts/` — セットアップ用スクリプト

## 接続情報

- SSH鍵: `keys/training-key`
- SSHユーザー: `ec2-user`
- EC2のIPアドレスは受講者から指示されます

## 環境

- ハンズオン環境: ブラウザ版 VSCode（code-server on AWS EC2）
- ツール（Terraform, Ansible, AWS CLI, Claude Code）はプリインストール済み
- AWS認証情報は環境に事前設定済み
