# AI駆動 Infrastructure as Code ワークショップ

> AWS CLI、Ansible、Terraform、そしてContinueを活用した次世代IaC開発を学ぶ

## 概要

ContinueのAgent機能を使って、TerraformやAnsibleのコードを自動生成・実行しながら、AWSインフラの構築と運用を実践的に学びます。

## セッション構成

| セッション | 内容 | 時間 | 必須/任意 | ガイド |
|-----------|------|------|-----------|--------|
| **1** | VPC + EC2 を段階的に構築 | 2h | 必須 | [ガイド](docs/session_guides/session1_guide.md) |
| **2** | RDS データベースを追加 | 2h | 必須 | [ガイド](docs/session_guides/session2_guide.md) |
| **2.5** | ALB を追加 | 1h | 任意 | [ガイド](docs/session_guides/session2_5_guide.md) |
| **3** | サーバー再起動の自動化 (Ansible) | 1.5h | 必須 | [ガイド](docs/session_guides/session3_guide.md) |
| **4** | CloudWatch Agentインストール | 1.5h | 必須 | [ガイド](docs/session_guides/session4_guide.md) |
| **5** | サーバー情報取得・運用レポート | 1h | 任意 | [ガイド](docs/session_guides/session5_guide.md) |

### 時間配分

```
Day 1 (4h + 任意1h): インフラ構築 (Terraform)
├── Session 1  : VPC + EC2 を段階的に構築 (2h)         [必須]
├── Session 2  : RDS データベースを追加 (2h)            [必須]
└── Session 2.5: ALB を追加 (1h)                        [任意]

Day 2 (4h): システム運用 (Ansible)
├── Session 3: サーバー再起動の自動化 (1.5h)            [必須]
├── Session 4: CloudWatch Agent導入 (1.5h)              [必須]
└── Session 5: サーバー情報取得・レポート (1h)           [任意]
```

### セッション間のつながり

```
Session 1: VPC + EC2 構築  ──→  Session 2: RDS追加  ──→  Session 2.5: ALB追加（任意）
    ↓（EC2をAnsibleの操作対象として使用）
Session 3: サーバー再起動の自動化
    ↓
Session 4: CloudWatch Agent導入
    ↓
Session 5: サーバー情報取得・レポート（任意）
```

## クイックスタート

### 1. 環境セットアップ

[環境セットアップガイド](docs/setup/ENVIRONMENT_SETUP.md) の手順に従ってください。

```bash
# DevSpaces環境でセットアップスクリプトを実行
./scripts/setup_devspaces.sh
```

### 2. ワークショップ開始

環境セットアップ完了後、[セッション1](docs/session_guides/session1_guide.md) から開始してください。

## ディレクトリ構成

```
ai_agentic/
├── docs/
│   ├── TRAINING_MENU.md         # トレーニングメニュー
│   ├── images/                  # アーキテクチャ構成図
│   ├── session_guides/          # セッションガイド (1〜5, 2.5)
│   └── setup/                   # セットアップ手順
├── evaluation/                  # 評価チェックリスト
├── scripts/
│   ├── setup_devspaces.sh       # セットアップスクリプト
│   ├── generate_diagrams.py     # 構成図生成スクリプト
│   └── requirements.txt
├── terraform/                   # Terraformコード（セッション中に作成）
├── ansible/                     # Ansibleコード（セッション中に作成）
├── .continue/                   # Continue設定
└── README.md
```

## 注意事項

- ワークショップ終了後は作成したAWSリソースを **必ず以下の順序で削除** してください（依存関係のため逆順だとエラーになります）：

```bash
# プロジェクトルートから実行してください

# 1. セッション4: IAMロール（実施した場合のみ）
cd terraform/cloudwatch-iam && terraform destroy && cd ../..

# 2. セッション1+2: VPC/EC2/RDS（最後に削除 ※RDS削除に数分かかります）
cd terraform/vpc-ec2 && terraform destroy && cd ../..
```

- AWS認証情報は安全に管理してください

## 参考資料

- [Terraform公式ドキュメント](https://developer.hashicorp.com/terraform/docs)
- [Ansible公式ドキュメント](https://docs.ansible.com/)
- [AWS CLI公式ドキュメント](https://docs.aws.amazon.com/cli/)
- [Continue公式ドキュメント](https://continue.dev/docs)

---

**Happy IaC Coding!**
