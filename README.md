# 🤖 AI駆動 Infrastructure as Code ワークショップ

> AWS CLI、Ansible、Terraform、そしてContinue AIを活用した次世代IaC開発を学ぶ

## 📋 概要

このワークショップでは、AIアシスタント（Continue）を活用しながら、モダンなInfrastructure as Code（IaC）開発手法を実践的に学びます。

### 学習内容

| ツール | 用途 |
|--------|------|
| **AWS CLI** | AWSリソースの操作・管理 |
| **Terraform** | インフラストラクチャのプロビジョニング |
| **Ansible** | 構成管理・アプリケーションデプロイ |
| **Continue** | AIによるコード生成・レビュー支援（OpenShiftAI使用） |

## 🎯 ワークショップ内容

### セッション構成

| セッション | 内容 | 時間 | ガイド |
|-----------|------|------|--------|
| **セッション0** | AI x IaC基礎実践 | 1.5時間 | [詳細ガイド](docs/session_guides/session0_guide.md) |
| **セッション1** | VPC/Subnet/EC2構築 | 1.5時間 | [詳細ガイド](docs/session_guides/session1_guide.md) |
| **セッション2** | Terraform自動化エージェント | 1時間 | [詳細ガイド](docs/session_guides/session2_guide.md) |
| **セッション3** | Ansible運用基礎 | 1時間 | [詳細ガイド](docs/session_guides/session3_guide.md) |
| **セッション4** | Ansible自動化エージェント | 1時間 | [詳細ガイド](docs/session_guides/session4_guide.md) |
| **セッション5** | 統合管理エージェント | 1時間 | [詳細ガイド](docs/session_guides/session5_guide.md) |
| **セッション6** | Webシステム構築（任意） | 1時間 | [詳細ガイド](docs/session_guides/session6_guide.md) |

### トレーニング概要

- **期間**: 2日間（合計8時間、1日4時間）
- **形式**: ハンズオン形式のライブコーディング
- **環境**: OpenShift DevSpaces + AWS
- **技術スタック**: Terraform, Ansible, Continue AI（OpenShiftAI）

詳細は [`docs/TRAINING_MENU.md`](docs/TRAINING_MENU.md) を参照してください。

## 🚀 クイックスタート

### 1. 環境セットアップ

環境セットアップの詳細手順は、[環境セットアップガイド](docs/setup/ENVIRONMENT_SETUP.md) を参照してください。

**主な手順**:
1. DevSpaces環境への資材の持ち込み
2. 環境セットアップスクリプトの実行
3. AWS認証情報の設定
4. Continue AIのセットアップ

### 2. ワークショップの開始

環境セットアップが完了したら、[セッション0](docs/session_guides/session0_guide.md) から開始してください。

各セッションガイドには、以下の情報が含まれています：
- **目的**: セッションで達成すべき目標
- **目指すべき構成**: 最終的に作成する構成の概要
- **手順**: ステップバイステップの手順
- **回答例**: 折りたたみ可能な回答例（クリックで展開）

## 📁 ディレクトリ構成

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
│       ├── CONTINUE_SETUP.md      # Continue AIセットアップ
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
│   └── interactive_agent.py      # 対話型AIエージェント（参考用）
├── .continue/                     # Continue設定
│   └── config.json                # Continue設定ファイル
├── requirements.txt               # Python依存関係
└── README.md                      # このファイル
```

## 💡 Continue AIの効果的な使い方

Continue AIは、VS Code/Cursorの拡張機能として動作します。ショートカットキー（`Ctrl+L` / `Cmd+L`）で起動できます。

### 1. コード生成

```
「VPC、パブリック/プライベートサブネット、NAT Gatewayを含む
AWS ネットワーク構成の Terraform コードを生成してください」
```

### 2. コードレビュー

コードを選択してから：
```
「このTerraformコードのセキュリティ上の問題点を指摘してください」
```

### 3. トラブルシューティング

```
「このエラーメッセージの原因と解決方法を教えてください：
[エラーメッセージを貼り付け]」
```

### 4. ベストプラクティス

```
「このAnsible Playbookをより冪等性が高く、
再利用可能な形にリファクタリングしてください」
```

詳細は [`docs/setup/CONTINUE_SETUP.md`](docs/setup/CONTINUE_SETUP.md) を参照してください。

## 🛠️ インストール済みツール

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

## 📚 参考資料

- [Terraform公式ドキュメント](https://developer.hashicorp.com/terraform/docs)
- [Ansible公式ドキュメント](https://docs.ansible.com/)
- [AWS CLI公式ドキュメント](https://docs.aws.amazon.com/cli/)
- [Continue公式ドキュメント](https://continue.dev/docs)
- [OpenShift DevSpacesドキュメント](https://access.redhat.com/documentation/en-us/red_hat_openshift_dev_spaces/)

## ⚠️ 注意事項

- ワークショップ終了後は作成したAWSリソースを削除してください
  ```bash
  terraform destroy
  ```
- AWS認証情報は安全に管理してください
- 本番環境への適用前に十分なテストを行ってください

## 🆘 トラブルシューティング

よくある問題と解決方法は [`docs/setup/FAQ.md`](docs/setup/FAQ.md) を参照してください。

## 📝 評価

各セッションの評価チェックリストは [`evaluation/`](evaluation/) ディレクトリを参照してください。

## 📄 ライセンス

このプロジェクトはトレーニング目的で作成されています。

---

**Happy IaC Coding! 🎉**
