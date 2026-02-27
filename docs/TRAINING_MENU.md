# 生成AI活用トレーニングメニュー

## 基本情報

| 項目 | 内容 |
|------|------|
| 期間 | 2日間（合計7.5時間） |
| 形式 | ハンズオン形式のライブコーディング |
| 環境 | OpenShift DevSpaces + AWS |
| 技術 | Terraform, Ansible, Continue（AWS Bedrock） |
| 前提 | 事前勉強会で生成AIとIaCの基礎を学習済み |

---

## セッション構成

| # | 内容 | 時間 | 必須/任意 | ツール |
|---|------|------|-----------|--------|
| 1 | VPC + EC2 を段階的に構築 | 2h | 必須 | Terraform |
| 2 | RDS データベースを追加 | 2h | 必須 | Terraform |
| 2.5 | ALB を追加 | 1h | 任意 | Terraform |
| 3 | サーバー再起動の自動化 | 1.5h | 必須 | Ansible |
| 4 | CloudWatch Agentインストール | 1.5h | 必須 | Terraform + Ansible |
| 5 | サーバー情報取得・運用レポート | 1h | 任意 | Ansible |

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

- 必須合計: 7h / 任意合計: 2h / 全体: 9h（任意含む）

---

## 各セッションの概要

### セッション1：VPC + EC2 を段階的に構築（必須・2h）

ContinueのAgent機能を使って、VPC → サブネット → セキュリティグループ → EC2 の順で段階的にAWSインフラを構築します。

**構築ステップ**:
1. VPC作成
2. サブネット＆インターネットゲートウェイ追加
3. キーペア＆セキュリティグループ追加
4. EC2インスタンス作成
5. SSH接続確認

**学ぶこと**: Agent開発の基本（自動化、承認ワークフロー、エラー自動修正）

→ [セッション1ガイド](session_guides/session1_guide.md)

---

### セッション2：RDS データベースを追加（必須・2h）

セッション1のVPCにプライベートサブネットとRDSを追加し、EC2からデータベースに接続できる環境を構築します。

**構築ステップ**:
1. プライベートサブネット追加（×2）
2. RDS用セキュリティグループ作成
3. RDSインスタンス作成
4. EC2からRDSに接続
5. データベース操作で動作確認

→ [セッション2ガイド](session_guides/session2_guide.md)

---

### セッション2.5：ALB を追加（任意・1h）

EC2にnginxをインストールし、ALB（ロードバランサー）経由でブラウザからHTTPアクセスできるようにします。

**構築ステップ**:
1. パブリックサブネット追加 + ALB作成
2. EC2にnginxインストール
3. ブラウザでアクセス確認

→ [セッション2.5ガイド](session_guides/session2_5_guide.md)

---

### セッション3：サーバー再起動の自動化（必須・1.5h）

セッション1のEC2に対して、Ansibleでサーバー再起動を自動化します。

**構築ステップ**:
1. Ansible接続設定（inventory + config）
2. 接続テスト
3. サーバー状態確認Playbook
4. サーバー再起動Playbook
5. サービス管理Playbook

**学ぶこと**: TerraformとAnsibleの役割の違い（構築 vs 運用）

→ [セッション3ガイド](session_guides/session3_guide.md)

---

### セッション4：CloudWatch Agentインストール（必須・1.5h）

Terraform（IAMロール）+ Ansible（Agent設定）を組み合わせてCloudWatch Agentを導入します。

**構築ステップ**:
1. IAMロール作成（Terraform）
2. EC2にプロファイル関連付け
3. CloudWatch Agentインストール（Ansible）
4. 設定・起動（Ansible）
5. CloudWatchで確認

**学ぶこと**: Terraform + Ansible のツール横断的なAgent開発

→ [セッション4ガイド](session_guides/session4_guide.md)

---

### セッション5：サーバー情報取得・運用レポート（任意・1h）

Ansibleでサーバー情報を自動収集し、Jinja2テンプレートで運用レポートを生成します。

**構築ステップ**:
1. サーバー情報収集Playbook
2. Jinja2レポートテンプレート
3. レポート自動生成

→ [セッション5ガイド](session_guides/session5_guide.md)

---

## セッション間のつながり

```
Session 1: VPC + EC2 構築  ──→  Session 2: RDS追加  ──→  Session 2.5: ALB追加（任意）
    ↓（EC2をAnsibleの操作対象として使用）
Session 3: サーバー再起動の自動化
    ↓
Session 4: CloudWatch Agent導入
    ↓
Session 5: サーバー情報取得・レポート（任意）
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
- Continue（AWS Bedrock使用）

### 必要なスキル
- 基本的なLinuxコマンド
- YAML/JSONの基本的な理解

---

## 評価

各セッションの評価チェックリストは `evaluation/` ディレクトリを参照してください。
