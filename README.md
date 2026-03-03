# AI駆動 Infrastructure as Code ワークショップ

> AWS CLI、Ansible、Terraform、そしてClaude Codeを活用した次世代IaC開発を学ぶ

## 概要

Claude CodeのAIエージェント機能を使って、TerraformやAnsibleのコードを自動生成・実行しながら、AWSインフラの構築と運用を実践的に学びます。

## セッション構成

| セッション | 内容 | 時間 | 必須/任意 | ガイド |
|-----------|------|------|-----------|--------|
| **1** | VPC + EC2 を段階的に構築 | 2h | 必須 | [ガイド](docs/session_guides/session1_guide.md) |
| **2** | Webアプリケーションを公開 | 2h | 必須 | [ガイド](docs/session_guides/session2_guide.md) |
| **3** | HTTPS 対応 | 45min | 任意 | [ガイド](docs/session_guides/session3_guide.md) |
| **4** | サーバー再起動の自動化 (Ansible) | 2h | 必須 | [ガイド](docs/session_guides/session4_guide.md) |
| **5** | SSM Agent & CloudWatch Agent 導入 | 2h | 必須 | [ガイド](docs/session_guides/session5_guide.md) |
| **6** | サーバー情報取得・運用レポート | 1h | 任意 | [ガイド](docs/session_guides/session6_guide.md) |

### 時間配分

```
Day 1 (4h + 任意45min): インフラ構築 (Terraform)
├── Session 1: VPC + EC2 を段階的に構築 (2h)             [必須]
├── Session 2: Webアプリケーションを公開 (2h)             [必須]
└── Session 3: HTTPS 対応 (45min)                        [任意]

Day 2 (4h + 任意1h): システム運用 (Ansible)
├── Session 4: サーバー再起動の自動化 (2h)               [必須]
├── Session 5: SSM Agent & CloudWatch Agent 導入 (2h)    [必須]
└── Session 6: サーバー情報取得・レポート (1h)            [任意]
```

### セッション間のつながり

```
Session 1: VPC + EC2 構築  ──→  Session 2: Webアプリ公開  ──→  Session 3: HTTPS対応（任意）
    ↓（EC2をAnsibleの操作対象として使用）
Session 4: サーバー再起動の自動化
    ↓
Session 5: SSM Agent & CloudWatch Agent 導入
    ↓
Session 6: サーバー情報取得・レポート（任意）
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
ai_agentic_development-2/
├── docs/
│   ├── TRAINING_MENU.md         # トレーニングメニュー
│   ├── images/                  # アーキテクチャ構成図
│   ├── session_guides/          # セッションガイド (1〜6)
│   └── setup/                   # セットアップ手順（Claude Code, 環境構築, FAQ）
├── evaluation/                  # 評価チェックリスト
├── scripts/
│   ├── setup_devspaces.sh       # 環境セットアップスクリプト
│   ├── check.sh                 # セッション完了チェックスクリプト
│   ├── generate_diagrams.py     # 構成図の自動生成（開発者向け）
│   └── requirements.txt         # Python依存パッケージ（開発者向け）
├── terraform/                   # Terraformコード（セッション中に作成）
├── ansible/                     # Ansibleコード（セッション中に作成）
├── .claude/                     # Claude Code設定（.gitignore対象、スクリプトで自動生成）
├── .env.template                # AWS認証情報テンプレート
└── README.md
```

## 注意事項

- ワークショップ終了後は作成したAWSリソースを **必ず以下の順序で削除** してください：

```bash
# プロジェクトルートから実行してください

# 1. セッション5: IAMリソース（実施した場合のみ）
# → Agentに「training-ec2-agent-role と training-ec2-agent-profile を削除して」と伝えてください

# 2. セッション1〜3: VPC/EC2（セッション3のHTTPS設定も含まれます）
terraform -chdir=terraform/vpc-ec2 destroy
```

- AWS認証情報は安全に管理してください

## 参考資料

- [Terraform公式ドキュメント](https://developer.hashicorp.com/terraform/docs)
- [Ansible公式ドキュメント](https://docs.ansible.com/)
- [AWS CLI公式ドキュメント](https://docs.aws.amazon.com/cli/)
- [Claude Code公式ドキュメント](https://docs.anthropic.com/en/docs/claude-code)

---

**Happy IaC Coding!**
