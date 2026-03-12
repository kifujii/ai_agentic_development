# AI駆動 Infrastructure as Code ワークショップ

> AWS CLI、Ansible、Terraform、そしてClaude Codeを活用した次世代IaC開発を学ぶ

## 概要

Claude Code の AI Agent 機能を使って、Terraform や Ansible のコードを自動生成・実行しながら、AWS インフラの構築と運用を実践的に学びます。

## セッション構成

| セッション | 内容 | 時間 | 必須/任意 | ガイド |
|-----------|------|------|-----------|--------|
| **0** | Claude Code に慣れよう | 45min | 必須 | [ガイド](docs/session_guides/session0_guide.md) |
| **1** | VPC + EC2 を段階的に構築 | 2h | 必須 | [ガイド](docs/session_guides/session1_guide.md) |
| **2** | Terraform でインフラを構築・変更・再構築 | 2h | 必須 | [ガイド](docs/session_guides/session2_guide.md) |
| **3** | EC2 を count でスケールアウト | 45min | 任意 | [ガイド](docs/session_guides/session3_guide.md) |
| **4** | Ansible によるサーバー運用自動化 | 2h | 必須 | [ガイド](docs/session_guides/session4_guide.md) |
| **5** | SSM Agent & CloudWatch Agent 導入 | 2h | 必須 | [ガイド](docs/session_guides/session5_guide.md) |
| **6** | サーバー情報取得・運用レポート | 1h | 任意 | [ガイド](docs/session_guides/session6_guide.md) |
| **7** | 未知の技術を AI で攻略する | 2h | 必須 | [ガイド](docs/session_guides/session7_guide.md) |
| **8** | 本番リリースの設計判断 | 2h | 必須 | [ガイド](docs/session_guides/session8_guide.md) |
| **9** | インシデント対応とポストモーテム | 1.5h | 必須 | [ガイド](docs/session_guides/session9_guide.md) |
| **10** | ゼロからシステム構築チャレンジ | 2h | 任意 | [ガイド](docs/session_guides/session10_guide.md) |

### 時間配分

```
Day 1 (4h45min + 任意45min): Claude Code 入門 & インフラ構築 (Terraform)
├── Session 0: Claude Code に慣れよう (45min)              [必須]
├── Session 1: VPC + EC2 を段階的に構築 (2h)              [必須]
├── Session 2: Terraform でインフラを構築・変更・再構築 (2h) [必須]
└── Session 3: EC2 を count でスケールアウト (45min)       [任意]

Day 2 (4h + 任意1h): システム運用 (Ansible)
├── Session 4: Ansible によるサーバー運用自動化 (2h)      [必須]
├── Session 5: SSM Agent & CloudWatch Agent 導入 (2h)    [必須]
└── Session 6: サーバー情報取得・レポート (1h)            [任意]

Day 3 (5.5h + 任意2h): 応用・実践 (シナリオ型)
├── Session 7: 未知の技術を AI で攻略する (2h)            [必須]
├── Session 8: 本番リリースの設計判断 (2h)                [必須]
├── Session 9: インシデント対応とポストモーテム (1.5h)     [必須]
└── Session 10: ゼロからシステム構築チャレンジ (2h)       [任意]
```

### セッション間のつながり

```
Session 0: Claude Code 入門（操作スキルを習得）
    ↓
Session 1: VPC + EC2 構築  ──→  Session 2: 構築・変更・再構築  ──→  Session 3: countスケールアウト（任意）
    ↓（EC2をAnsibleの操作対象として使用）
Session 4: Ansible によるサーバー運用自動化 + 🔧 トラブルシューティング
    ↓
Session 5: SSM Agent & CloudWatch Agent 導入
    ↓
Session 6: サーバー情報取得・レポート（任意）

--- Day 3: 応用・実践（各セッション独立） ---

Session 7: 未知の技術を AI で攻略する（Lambda + API Gateway）
Session 8: 本番リリースの設計判断（高可用性 + コスト最適化）
Session 9: インシデント対応とポストモーテム（障害復旧 + 報告書）
Session 10: ゼロからシステム構築チャレンジ（任意）
```

## クイックスタート

### 1. 環境セットアップ

[環境セットアップガイド](docs/setup/ENVIRONMENT_SETUP.md) の手順に従って、ハンズオン環境へのアクセスと初期設定を行ってください。

### 2. ワークショップ開始

環境セットアップ完了後、[セッション0](docs/session_guides/session0_guide.md) から開始してください。

## ディレクトリ構成

```
ai_agentic_development/
├── docs/
│   ├── TRAINING_MENU.md         # トレーニングメニュー
│   ├── images/                  # アーキテクチャ構成図
│   ├── session_guides/          # セッションガイド (0〜10)
│   └── setup/                   # セットアップ手順（Claude Code, 環境構築, FAQ）
├── evaluation/                  # 評価チェックリスト
├── scripts/
│   ├── setup.sh                 # 環境セットアップスクリプト
│   ├── check.sh                 # セッション完了チェックスクリプト
│   ├── generate_diagrams.py     # 構成図の自動生成（開発者向け）
│   └── requirements.txt         # Python依存パッケージ（開発者向け）
├── terraform/                   # Terraformコード（セッション中に作成）
├── ansible/                     # Ansibleコード（セッション中に作成）
├── .claude/                     # Claude Code設定（.gitignore対象、環境構築時に自動配置）
├── .env.template                # PREFIX設定テンプレート
└── README.md
```

## 注意事項

- ワークショップ終了後は作成したAWSリソースを **必ず以下の順序で削除** してください：

```bash
# プロジェクトルートから実行してください

# 1. セッション5: IAM/CloudWatchリソース（実施した場合のみ）
# → Claude Code に「${TF_VAR_prefix}-ec2-agent-role、${TF_VAR_prefix}-ec2-agent-profile、
#   ${TF_VAR_prefix}-cpu-alarm、ロググループ /${TF_VAR_prefix}/ec2/* を削除して」と伝えてください

# 2. セッション7: Lambda/API Gateway（実施した場合のみ）
# → terraform -chdir=terraform/<セッション7で作成したディレクトリ> destroy

# 3. セッション1〜3, 8: VPC/EC2
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
