# AI駆動 Infrastructure as Code ワークショップ

> AWS CLI、Ansible、Terraform、そしてClaude Codeを活用した次世代IaC開発を学ぶ

## 概要

Claude Code の AI Agent 機能を使って、Terraform や Ansible のコードを自動生成・実行しながら、AWS インフラの構築と運用を実践的に学びます。

## セッション構成

| セッション | 内容 | 時間 | 必須/任意 |
|-----------|------|------|-----------|
| **0** | Claude Code に慣れよう | 20min | 必須 |
| **1** | VPC + EC2 を段階的に構築 | 1h | 必須 |
| **2** | Terraform でインフラを構築・変更・再構築 | 45min | 必須 |
| **3** | Web サーバーを冗長構成にしよう | 30min | 任意 |
| **4** | Ansible によるサーバー運用自動化 | 1h | 必須 |
| **5** | SSM Agent & CloudWatch Agent 導入 | 55min | 必須 |
| **6** | 運用レポートの自動生成 | 45min | 任意 |
| **7** | 未知の技術を AI で攻略する | 1.5h | 必須 |
| **8** | 本番リリースの設計判断 | 1.5h | 必須 |
| **9** | インシデント対応とポストモーテム | 1h | 必須 |
| **10** | ゼロからシステム構築チャレンジ | 1.5h | 任意 |

### 時間配分

```
Day 1 (4h + 任意30min): Claude Code 入門 → Terraform → Ansible → 監視基盤
├── Session 0: Claude Code に慣れよう (20min)                [必須]
├── Session 1: VPC + EC2 を段階的に構築 (1h)                [必須]
├── Session 2: Terraform でインフラを構築・変更・再構築 (45min) [必須]
├── Session 3: Web サーバーを冗長構成にしよう (30min)         [任意]
├── Session 4: Ansible によるサーバー運用自動化 (1h)         [必須]
└── Session 5: SSM Agent & CloudWatch Agent 導入 (55min)    [必須]

Day 2 (4h + 任意2h15min): 応用・実践（シナリオ型）
├── Session 6: 運用レポートの自動生成 (45min)                [任意]
├── Session 7: 未知の技術を AI で攻略する (1.5h)            [必須]
├── Session 8: 本番リリースの設計判断 (1.5h)                [必須]
├── Session 9: インシデント対応とポストモーテム (1h)         [必須]
└── Session 10: ゼロからシステム構築チャレンジ (1.5h)       [任意]
```

### セッション間のつながり

```
Session 0: Claude Code 入門（操作スキルを習得）
    ↓
Session 1: VPC + EC2 構築  ──→  Session 2: 構築・変更・再構築  ──→  Session 3: Web サーバー冗長構成（任意）
    ↓（EC2をAnsibleの操作対象として使用）
Session 4: Ansible によるサーバー運用自動化 + 🔧 トラブルシューティング
    ↓
Session 5: SSM Agent & CloudWatch Agent 導入
    ↓
--- Day 2: 応用・実践（各セッション独立） ---

Session 6: 運用レポートの自動生成（任意）
Session 7: 未知の技術を AI で攻略する（Lambda + API Gateway）
Session 8: 本番リリースの設計判断（高可用性 + コスト最適化）
Session 9: インシデント対応とポストモーテム（障害復旧 + 報告書）
Session 10: ゼロからシステム構築チャレンジ（任意）
```

## クイックスタート

1. ブラウザで VSCode にアクセス → [環境セットアップガイド](docs/setup/ENVIRONMENT_SETUP.md)
2. セッション0 から開始 → [セッション0：Claude Code に慣れよう](docs/session_guides/session0_guide.md)

> 💡 セッションガイドは講師の指示に従って進めてください。

## ディレクトリ構成

```
ai_agentic_development/
├── docs/
│   ├── TRAINING_MENU.md         # トレーニングメニュー
│   ├── images/                  # アーキテクチャ構成図
│   ├── session_guides/          # セッションガイド (0〜10)
│   └── setup/                   # セットアップ手順（環境構築, Tips, FAQ）
├── evaluation/                  # 評価チェックリスト
├── scripts/
│   └── check.sh                 # セッション完了チェックスクリプト
├── terraform/                   # Terraformコード（セッション中に作成）
├── ansible/                     # Ansibleコード（セッション中に作成）
├── keys/                        # SSH鍵（セッション1で作成、Git管理外）
├── .claude/                     # Claude Code設定（.gitignore対象、環境構築時に自動配置）
└── README.md
```

## 注意事項

- ワークショップ終了後は作成したAWSリソースを **必ず削除** してください。Claude Code を起動して以下のプロンプトを実行するのが最も簡単です：

```
ワークショップで作成したすべての AWS リソースを削除してください。
- terraform/ 配下の各ディレクトリで terraform destroy を実行
- AWS CLI で作成した IAM ロール・インスタンスプロファイル・CloudWatch Alarm・ロググループも削除
- プレフィックスは環境変数 TF_VAR_prefix の値を使ってください
```

> 💡 Claude Code を使わず手動で削除する場合は、各セッションガイドの「リソースの削除」セクションを参照してください。依存関係があるため、**応用セッション → セッション5 → セッション1〜3** の順で削除してください。

- AWS認証情報は安全に管理してください

## 参考資料

- [Terraform公式ドキュメント](https://developer.hashicorp.com/terraform/docs)
- [Ansible公式ドキュメント](https://docs.ansible.com/)
- [AWS CLI公式ドキュメント](https://docs.aws.amazon.com/cli/)
- [Claude Code公式ドキュメント](https://docs.anthropic.com/en/docs/claude-code)

---

**Happy IaC Coding!**
