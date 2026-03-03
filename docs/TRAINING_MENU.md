# 生成AI活用トレーニングメニュー

## 基本情報

| 項目 | 内容 |
|------|------|
| 期間 | 2日間（必須8h + 任意1.75h） |
| 形式 | ハンズオン形式のバイブコーディング |
| 環境 | OpenShift DevSpaces + AWS |
| 技術 | Terraform, Ansible, Claude Code（AWS Bedrock） |
| 前提 | 事前勉強会で生成AIとIaCの基礎を学習済み |

---

## セッション構成

| # | 内容 | 時間 | 必須/任意 | ツール |
|---|------|------|-----------|--------|
| 1 | VPC + EC2 を段階的に構築 | 2h | 必須 | Terraform |
| 2 | Terraform でインフラを構築・変更・再構築 | 2h | 必須 | Terraform |
| 3 | EC2 を count でスケールアウト | 45min | 任意 | Terraform |
| 4 | Ansible によるサーバー運用自動化 | 2h | 必須 | Ansible |
| 5 | SSM Agent & CloudWatch Agent 導入 | 2h | 必須 | Ansible + AWS CLI |
| 6 | サーバー情報取得・運用レポート | 1h | 任意 | Ansible |

### 時間配分

```
Day 1 (4h + 任意45min): インフラ構築 (Terraform)
├── Session 1: VPC + EC2 を段階的に構築 (2h)             [必須]
├── Session 2: Terraform でインフラを構築・変更・再構築 (2h) [必須]
└── Session 3: EC2 を count でスケールアウト (45min)       [任意]

Day 2 (4h + 任意1h): システム運用 (Ansible)
├── Session 4: Ansible によるサーバー運用自動化 (2h)      [必須]
├── Session 5: SSM Agent & CloudWatch Agent 導入 (2h)    [必須]
└── Session 6: サーバー情報取得・レポート (1h)            [任意]
```

- 必須合計: 8h / 任意合計: 1.75h / 全体: 9.75h（任意含む）
- ⏱️ 各セッションの時間にはバッファ（約10〜15分）を含んでいます。環境トラブルやAgent応答待ちに充ててください。

---

## 各セッションの概要

### セッション1：VPC + EC2 を段階的に構築（必須・2h）

Claude CodeのAIエージェント機能を使って、VPC → サブネット → セキュリティグループ → EC2 の順で段階的にAWSインフラを構築します。

**構築ステップ**:
1. VPC作成
2. サブネット＆インターネットゲートウェイ追加
3. キーペア＆セキュリティグループ追加
4. EC2インスタンス作成
5. SSH接続確認

**学ぶこと**: Agent開発の基本（自動化、承認ワークフロー、エラー自動修正）

→ [セッション1ガイド](session_guides/session1_guide.md)

---

### セッション2：Terraform でインフラを構築・変更・再構築（必須・2h）

Terraform のライフサイクル（変更 → 削除 → 再構築）を一通り体験します。`terraform plan` で差分確認、`terraform destroy` で一括削除、`user_data` で自動化して `terraform apply` で一発再構築。IaC の真価を実感します。

**構築ステップ**:
1. セキュリティグループにHTTP(80)を追加
2. SSHでnginxをインストール（手動）
3. `terraform plan` でタグ追加等の変更体験
4. `terraform destroy` で全リソース一括削除
5. `user_data` で自動化して一発再構築
6. カスタムWebページの改善・デプロイ

**学ぶこと**: `terraform plan/destroy/apply` のライフサイクル、`user_data` による自動化、IaC の再現性

→ [セッション2ガイド](session_guides/session2_guide.md)

---

### セッション3：EC2 を count でスケールアウト（任意・45min）

Terraform の `count` パラメータでEC2を2台に増やし、「コード1行でサーバーの台数を増減できる」IaC の威力を体験します。`terraform destroy -target` で1台だけの選択的削除も学びます。

**構築ステップ**:
1. `count = 2` でEC2を2台に増加
2. 2台のnginxにブラウザでアクセス確認
3. `terraform destroy -target` で2台目だけ削除 → 1台に戻す

**学ぶこと**: `count` によるスケールアウト、`terraform destroy -target` による選択的削除、コードとインフラの整合性

→ [セッション3ガイド](session_guides/session3_guide.md)

---

### セッション4：Ansible によるサーバー運用自動化（必須・2h）

セッション1のEC2に対して、Ansibleでサーバー運用を自動化します。後半では **nginx の障害対応シミュレーション** を通じて、Claude Code と協力してトラブルシューティングする実践力を身につけます。

**構築ステップ**:
1. Ansible接続設定（inventory + config）
2. 接続テスト
3. サーバー状態確認Playbook
4. サーバー再起動Playbook
5. サービス管理Playbook
6. 🔧 障害対応シミュレーション（nginx停止→原因調査→復旧→Playbook化）

**学ぶこと**: TerraformとAnsibleの役割の違い、**AIと協力するトラブルシューティングパターン**

→ [セッション4ガイド](session_guides/session4_guide.md)

---

### セッション5：SSM Agent & CloudWatch Agent 導入（必須・2h）

Ansibleを使ってSSM AgentとCloudWatch Agentをインストール・設定します。IAMロールの準備からAgent導入、CloudWatch Alarm作成まで一連の監視基盤を構築します。

**構築ステップ**:
1. IAMロール作成（AWS CLI）
2. SSM Agentインストール・確認（Ansible + フリートマネージャー）
3. SSM Run Command 体験
4. CloudWatch Agentインストール（Ansible）
5. CloudWatch Agent設定・起動・確認（Ansible + CloudWatchコンソール）
6. CloudWatch Alarm 作成

**学ぶこと**: ツールの使い分け（Terraform vs Ansible vs AWS CLI vs SSM）、監視基盤の構築

→ [セッション5ガイド](session_guides/session5_guide.md)

---

### セッション6：サーバー情報取得・運用レポート（任意・1h）

Ansibleでサーバー情報を自動収集し、Jinja2テンプレートで運用レポートを生成します。

**構築ステップ**:
1. サーバー情報収集Playbook
2. Jinja2レポートテンプレート
3. レポート自動生成

→ [セッション6ガイド](session_guides/session6_guide.md)

---

## セッション間のつながり

```
Session 1: VPC + EC2 構築  ──→  Session 2: 構築・変更・再構築  ──→  Session 3: countスケールアウト（任意）
    ↓（EC2をAnsibleの操作対象として使用）
Session 4: Ansible によるサーバー運用自動化 + 🔧 トラブルシューティング
    ↓
Session 5: SSM Agent & CloudWatch Agent 導入
    ↓
Session 6: サーバー情報取得・レポート（任意）
```

---

## 前提条件

### 事前勉強会で学習済み
- LLMの基本概念、Prompt Engineeringの基礎
- Terraformの基本概念とコマンド（init, plan, apply）
- Ansibleの基本概念とPlaybook構造

### 必要な環境
- AWSアカウント（トレーニング用）
- OpenShift DevSpacesへのアクセス
- Claude Code（AWS Bedrock使用）

### 必要なスキル
- 基本的なLinuxコマンド
- YAML/JSONの基本的な理解

---

## 評価

各セッションの評価チェックリストは `evaluation/` ディレクトリを参照してください。
