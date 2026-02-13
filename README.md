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

### 1. DevSpaces環境への資材の持ち込み

**重要**: セットアップスクリプトは **OpenShift DevSpaces環境内** で実行する想定です。

#### 1.1 DevSpacesワークスペースの作成
1. OpenShift DevSpacesのURLにアクセス
2. ログイン
3. 新しいワークスペースを作成（スタック: Python 3.11 または Node.js 18）

#### 1.2 Gitリポジトリのクローン
DevSpaces環境内のターミナルで以下のコマンドを実行：

```bash
# リポジトリをクローン
git clone https://github.com/kifujii/ai_agentic_development.git
cd ai_agentic_development

# trainingブランチに切り替え
git checkout training

# プロジェクトディレクトリに移動
cd ai_agentic
```

### 2. 環境セットアップ

**DevSpaces環境内**で以下のコマンドを実行：

```bash
# セットアップスクリプトの実行
chmod +x scripts/setup_devspaces.sh
./scripts/setup_devspaces.sh

# スクリプト実行後、PATHを更新（新しいターミナルを開くか、以下を実行）
source ~/.bashrc
```

**注意**: セットアップスクリプトは自動的にPythonパッケージもインストールします（`pip3 install --user`を使用）。

詳細は `docs/setup/DEVSPACES_SETUP.md` を参照してください。

**よくある質問**: セットアップに関する質問は `docs/setup/FAQ.md` を参照してください。

### 3. 認証情報の設定

セットアップスクリプトが`.env.template`ファイルを作成します。`.env`ファイルを作成して認証情報を設定してください：

```bash
# .envファイルを作成（.env.templateを参考に）
cat > .env << EOF
AWS_ACCESS_KEY_ID=your-access-key-here
AWS_SECRET_ACCESS_KEY=your-secret-key-here
AWS_DEFAULT_REGION=ap-northeast-1
OPENAI_API_KEY=your-openai-api-key-here
ANTHROPIC_API_KEY=your-anthropic-api-key-here
EOF

# AWS認証情報の設定（オプション: .envファイルの代わりにaws configureを使用）
aws configure
```

### 4. トレーニングの開始

セットアップが完了したら、各セッションのガイドを参照してください：

- **セッション0**: `docs/session_guides/session0_guide.md`
- **セッション1**: `docs/session_guides/session1_guide.md`
- 以降も同様

**セットアップ完了後の確認事項**:
- [ ] 新しいターミナルを開くか、`source ~/.bashrc`を実行してPATHを更新した
- [ ] `.env`ファイルを作成して認証情報を設定した
- [ ] `aws configure`を実行してAWS認証情報を設定した（.envファイルを使用しない場合）
- [ ] すべてのツールが正しくインストールされていることを確認した（`terraform version`、`ansible --version`など）

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
