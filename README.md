# AI駆動 Infrastructure as Code ワークショップ

> AWS CLI、Ansible、Terraform、そしてContinueを活用した次世代IaC開発を学ぶ

## 概要

このワークショップでは、AIアシスタント（Continue）を活用しながら、モダンなInfrastructure as Code（IaC）開発手法を実践的に学びます。

### 学習内容

| ツール | 用途 |
|--------|------|
| **AWS CLI** | AWSリソースの操作・管理 |
| **Terraform** | インフラストラクチャのプロビジョニング |
| **Ansible** | 構成管理・アプリケーションデプロイ |
| **Continue** | AIによるコード生成・レビュー支援（AWS Bedrock使用） |

## ワークショップ内容

### セッション構成

| セッション | 内容 | 時間 | ガイド |
|-----------|------|------|--------|
| **セッション0** | AI x IaC基礎実践とAgent開発の理解 | 1.5時間 | [詳細ガイド](docs/session_guides/session0_guide.md) |
| **セッション1** | Agent形式でのVPC/Subnet/EC2構築 | 1.5時間 | [詳細ガイド](docs/session_guides/session1_guide.md) |
| **セッション2** | Terraform自動化エージェント開発 | 1.5時間 | [詳細ガイド](docs/session_guides/session2_guide.md) |
| **セッション3** | Ansible運用基礎とAgent形式でのPlaybook生成 | 1時間 | [詳細ガイド](docs/session_guides/session3_guide.md) |
| **セッション4** | Ansible自動化エージェント開発 | 1.5時間 | [詳細ガイド](docs/session_guides/session4_guide.md) |
| **セッション5** | 統合管理エージェント開発 | 1.5時間 | [詳細ガイド](docs/session_guides/session5_guide.md) |
| **セッション6** | Webシステム構築（任意） | 1時間 | [詳細ガイド](docs/session_guides/session6_guide.md) |

### トレーニング概要

- **期間**: 2日間（合計8時間、1日4時間）
- **形式**: ハンズオン形式のライブコーディング
- **環境**: OpenShift DevSpaces + AWS
- **技術スタック**: Terraform, Ansible, Continue（AWS Bedrock）

詳細は [`docs/TRAINING_MENU.md`](docs/TRAINING_MENU.md) を参照してください。

## クイックスタート

### 1. 環境セットアップ

環境セットアップの詳細手順は、[環境セットアップガイド](docs/setup/ENVIRONMENT_SETUP.md) を参照してください。

**重要**: セットアップスクリプト（`./scripts/setup_devspaces.sh`）を実行すると、Continue拡張機能がCLI経由で自動インストールされます。

**主な手順**:
1. DevSpaces環境への資材の持ち込み（デフォルトのワークスペースを作成）
2. 環境セットアップスクリプトの実行（ワークスペース起動後に実行: `./scripts/setup_devspaces.sh`）
   - このスクリプトで必要なツールと拡張機能が自動インストールされます
3. AWS認証情報の設定
4. Continue の動作確認

### 2. ワークショップの開始

環境セットアップが完了したら、[セッション0](docs/session_guides/session0_guide.md) から開始してください。

各セッションガイドには、以下の情報が含まれています：
- **目的**: セッションで達成すべき目標
- **目指すべき構成**: 最終的に作成する構成の概要
- **手順**: ステップバイステップの手順
- **回答例**: 折りたたみ可能な回答例（クリックで展開）

## ディレクトリ構成

```
ai_agentic/
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
│       ├── ENVIRONMENT_SETUP.md  # 環境セットアップガイド
│       ├── CONTINUE_SETUP.md      # Continueセットアップ
│       ├── DEVSPACES_SETUP.md    # DevSpaces環境セットアップ
│       └── FAQ.md                 # よくある質問
├── sample_code/                  # サンプルコード
│   ├── terraform/                 # Terraformサンプル
│   │   ├── basic_ec2/            # 基本的なEC2
│   │   ├── vpc_subnet_ec2/       # VPC/Subnet/EC2
│   │   └── s3_bucket/             # S3バケット
│   └── ansible/                   # Ansibleサンプル
│       ├── basic_playbook/       # 基本Playbook
│       └── monitoring_setup/      # 監視セットアップ
├── templates/                     # テンプレート
│   └── ai_agents/                 # AIエージェントテンプレート
├── evaluation/                    # 評価チェックリスト
│   ├── session0_checklist.md
│   ├── session1_checklist.md
│   └── ...
├── scripts/                       # スクリプト
│   ├── setup_devspaces.sh        # DevSpacesセットアップスクリプト
│   └── requirements.txt          # Python依存関係
├── .continue/                     # Continue設定
│   └── config.json                # Continue設定ファイル
└── README.md                      # このファイル
```

## Continueの効果的な使い方

Continueは、VS Code/Cursorの拡張機能として動作します。ショートカットキー（`Ctrl+L` / `Cmd+L`）または左側のサイドバーから起動できます。

### プロンプトエンジニアリング

**悪いプロンプト例**:
```
EC2を作成して
```

**良いプロンプト例**:
```
下記条件を満たすEC2インスタンスを構築するTerraformコードを生成してください。

要件:
- リージョン: ap-northeast-1
- インスタンスタイプ: t3.micro
- OS: Amazon Linux 2023
- セキュリティグループ: SSH（ポート22）のみ許可、送信は全許可
- タグ: Name = "training-ec2", Environment = "training"

注意事項:
- 足りていないパラメータなどがある場合は、そのまま構築するのではなく一度聞き返してください
- 既存のEC2インスタンスと衝突しないように確認してください
- 変数定義を含めてください
- コメントを適切に追加してください
- ベストプラクティスに従ってください
```

### コード生成

良いプロンプトを使用してコード生成を行います。詳細は [`templates/prompts/`](templates/prompts/) を参照してください。

### コードレビュー

コードを選択してから：
```
「このTerraformコードのセキュリティ上の問題点を指摘してください」
```

### トラブルシューティング

```
「このエラーメッセージの原因と解決方法を教えてください：
[エラーメッセージを貼り付け]」
```

### ベストプラクティス

```
「このAnsible Playbookをより冪等性が高く、
再利用可能な形にリファクタリングしてください」
```

詳細は [`docs/setup/CONTINUE_SETUP.md`](docs/setup/CONTINUE_SETUP.md) を参照してください。

## Agent開発体験の5つの要素

このワークショップでは、以下の5つの要素を通じてAgent形式での開発を体験します：

1. **プロンプトエンジニアリング**: 良いプロンプトと悪いプロンプトの比較体験、不足パラメータの聞き返し機能の体験、段階的なプロンプト改善の実践
2. **Context Engineering**: コンテキスト情報の構造化と管理、AWSリソース情報のコンテキスト化、既存コードのコンテキスト活用
3. **フィードバックループ**: エラー修正プロセス（AIがエラー検出→修正提案→人間が承認）、反復的改善（人間のフィードバック→AIが改善→再検証）、承認ワークフロー（AIが計画提示→人間が承認→実行）
4. **開発方式比較**: チャット形式（コードコピー方式）vs Agent形式の比較体験、開発体験の改善を実感
5. **Agent形式での開発の理解**: Agent形式の本質的理解、Agent形式のメリットと適用場面、実践的なAgent開発スキルの習得

詳細は [`docs/TRAINING_MENU.md`](docs/TRAINING_MENU.md) を参照してください。

## インストール済みツール

セットアップスクリプトが自動的に以下のツールをインストールします：

| ツール | 用途 |
|--------|------|
| AWS CLI v2 | AWS リソース管理 |
| Terraform | インフラプロビジョニング |
| Ansible | 構成管理 |
| Python 3.11+ | スクリプト実行環境 |
| Git | バージョン管理 |
| jq | JSON処理 |

詳細は [`docs/setup/DEVSPACES_SETUP.md`](docs/setup/DEVSPACES_SETUP.md) を参照してください。

## 参考資料

- [Terraform公式ドキュメント](https://developer.hashicorp.com/terraform/docs)
- [Ansible公式ドキュメント](https://docs.ansible.com/)
- [AWS CLI公式ドキュメント](https://docs.aws.amazon.com/cli/)
- [Continue公式ドキュメント](https://continue.dev/docs)
- [OpenShift DevSpacesドキュメント](https://access.redhat.com/documentation/en-us/red_hat_openshift_dev_spaces/)

## 注意事項

- ワークショップ終了後は作成したAWSリソースを削除してください
  ```bash
  terraform destroy
  ```
- AWS認証情報は安全に管理してください
- 本番環境への適用前に十分なテストを行ってください

## トラブルシューティング

よくある問題と解決方法は [`docs/setup/FAQ.md`](docs/setup/FAQ.md) を参照してください。

## 評価

各セッションの評価チェックリストは [`evaluation/`](evaluation/) ディレクトリを参照してください。

## ライセンス

このプロジェクトはトレーニング目的で作成されています。

---

**Happy IaC Coding!**
