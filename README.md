# 生成AI活用トレーニングメニュー設計

このリポジトリには、生成AIを活用したIaC（Infrastructure as Code）トレーニングのための資料とサンプルコードが含まれています。

## ディレクトリ構造

```
.
├── docs/                          # ドキュメント
│   ├── TRAINING_MENU.md          # トレーニングメニュー詳細
│   ├── session_guides/           # セッションガイド
│   │   ├── session0_guide.md     # AI x IaC基礎実践
│   │   ├── session1_guide.md     # VPC/Subnet/EC2構築
│   │   ├── session2_guide.md     # Terraform自動化エージェント
│   │   ├── session3_guide.md     # Ansible運用基礎
│   │   ├── session4_guide.md     # Ansible自動化エージェント
│   │   ├── session5_guide.md     # 統合管理エージェント
│   │   └── session6_guide.md     # Webシステム構築（任意）
│   └── setup/                     # セットアップ手順
│       └── DEVSPACES_SETUP.md    # DevSpaces環境セットアップ
├── sample_code/                  # サンプルコード
│   ├── terraform/                 # Terraformサンプル
│   │   ├── basic_ec2/            # 基本的なEC2
│   │   ├── vpc_subnet_ec2/       # VPC/Subnet/EC2
│   │   └── s3_bucket/            # S3バケット
│   └── ansible/                   # Ansibleサンプル
│       ├── basic_playbook/       # 基本Playbook
│       └── monitoring_setup/      # 監視セットアップ
├── templates/                     # テンプレート
│   └── ai_agents/                 # AIエージェントテンプレート
│       ├── simple_agent_template.py
│       ├── terraform_agent_template.py
│       ├── ansible_agent_template.py
│       └── integrated_agent_template.py
├── evaluation/                    # 評価チェックリスト
│   ├── session0_checklist.md
│   ├── session1_checklist.md
│   ├── session2_checklist.md
│   ├── session3_checklist.md
│   ├── session4_checklist.md
│   ├── session5_checklist.md
│   ├── session6_checklist.md
│   └── README.md
├── scripts/                       # スクリプト
│   └── setup_devspaces.sh        # DevSpacesセットアップスクリプト
├── requirements.txt               # Python依存関係
└── README.md                     # このファイル
```

## クイックスタート

### 1. 環境セットアップ

```bash
# セットアップスクリプトの実行
chmod +x scripts/setup_devspaces.sh
./scripts/setup_devspaces.sh

# Pythonパッケージのインストール
pip install -r requirements.txt
```

詳細は `docs/setup/DEVSPACES_SETUP.md` を参照してください。

### 2. 認証情報の設定

`.env` ファイルを作成して認証情報を設定してください：

```bash
cp .env.template .env
# .envファイルを編集して認証情報を設定
```

### 3. トレーニングの開始

各セッションのガイドを参照してください：

- **セッション0**: `docs/session_guides/session0_guide.md`
- **セッション1**: `docs/session_guides/session1_guide.md`
- 以降も同様

## トレーニング概要

- **期間**: 2日間（合計8時間、1日4時間）
- **形式**: ハンズオン形式のバイブコーディング
- **環境**: OpenShift DevSpaces + AWS
- **技術スタック**: Terraform, Ansible, 生成AIエージェント開発

詳細は `docs/TRAINING_MENU.md` を参照してください。

## 前提条件

- AWSアカウント（トレーニング用）
- AWS Admin権限を持つアクセスキーとシークレットキー
- OpenShift DevSpacesへのアクセス
- 生成AI APIキー（OpenAI、Anthropicなど）

## 成果物

各セッションで以下の成果物を作成します：

- **セッション0**: Prompt Engineering、Context Engineering、AI Agentの実践成果
- **セッション1**: VPC、Subnet、EC2インスタンスが構築されたAWS環境
- **セッション2**: Terraformコード生成・実行を自動化する生成AIエージェント
- **セッション3**: サーバー再起動を自動化するAnsible Playbook
- **セッション4**: Ansible Playbook生成・実行を自動化する生成AIエージェント
- **セッション5**: インフラ管理タスクを統合的に自動化する生成AIエージェント
- **セッション6（任意）**: Webアプリケーションが動作するインフラ環境

## 評価

各セッションの評価チェックリストは `evaluation/` ディレクトリを参照してください。

## 参考資料

- [Terraform公式ドキュメント](https://www.terraform.io/docs)
- [Ansible公式ドキュメント](https://docs.ansible.com/)
- [AWS公式ドキュメント](https://docs.aws.amazon.com/)
- [OpenShift DevSpacesドキュメント](https://access.redhat.com/documentation/en-us/red_hat_openshift_dev_spaces/)

## ライセンス

このプロジェクトはトレーニング目的で作成されています。
