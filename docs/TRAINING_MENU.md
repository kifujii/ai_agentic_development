# 生成AI活用トレーニングメニュー

## 基本情報

| 項目 | 内容 |
|------|------|
| 期間 | 2日間（必須8h45min + 任意1.75h） |
| 形式 | ハンズオン形式のバイブコーディング |
| 環境 | ブラウザ版 VSCode（code-server on AWS EC2）+ AWS |
| 技術 | Terraform, Ansible, Claude Code（AWS Bedrock） |
| 前提 | 事前勉強会で生成AIとIaCの基礎を学習済み |

---

## セッション構成

| # | 内容 | 時間 | 必須/任意 | ツール |
|---|------|------|-----------|--------|
| 0 | Claude Code に慣れよう | 45min | 必須 | Claude Code |
| 1 | VPC + EC2 を段階的に構築 | 2h | 必須 | Terraform |
| 2 | Webアプリケーションを公開 | 2h | 必須 | Terraform |
| 3 | HTTPS 対応 | 45min | 任意 | nginx SSL + Terraform |
| 4 | サーバー再起動の自動化 | 2h | 必須 | Ansible |
| 5 | SSM Agent & CloudWatch Agent 導入 | 2h | 必須 | Ansible + AWS CLI |
| 6 | サーバー情報取得・運用レポート | 1h | 任意 | Ansible |

### 時間配分

```
Day 1 (4h45min + 任意45min): Claude Code 入門 & インフラ構築 (Terraform)
├── Session 0: Claude Code に慣れよう (45min)              [必須]
├── Session 1: VPC + EC2 を段階的に構築 (2h)              [必須]
├── Session 2: Webアプリケーションを公開 (2h)              [必須]
└── Session 3: HTTPS 対応 (45min)                         [任意]

Day 2 (4h + 任意1h): システム運用 (Ansible)
├── Session 4: サーバー再起動の自動化 (2h)                [必須]
├── Session 5: SSM Agent & CloudWatch Agent 導入 (2h)     [必須]
└── Session 6: サーバー情報取得・レポート (1h)             [任意]
```

- 必須合計: 8h45min / 任意合計: 1.75h / 全体: 10h30min（任意含む）
- ⏱️ 各セッションの時間にはバッファ（約10〜15分）を含んでいます。環境トラブルやAgent応答待ちに充ててください。

---

## 各セッションの概要

### セッション0：Claude Code に慣れよう（必須・45min）

Session 1 以降で使うClaude Code（AIコーディングエージェント）の基本操作を体験します。AWSリソースは使わず、安全な環境で自由に試せます。

**体験すること**:
1. Claude Code の起動と基本操作
2. 承認ワークフロー（ファイル作成・コマンド実行）
3. プロンプトの書き方を自由に試す
4. ワークショップ環境の確認

**学ぶこと**: AIエージェントとの協業の基本（指示の出し方、承認フロー、エラー対処）

→ [セッション0ガイド](session_guides/session0_guide.md)

---

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

### セッション2：Webアプリケーションを公開（必須・2h）

セッション1のEC2にWebサーバーをインストールし、ブラウザからアクセスできるWebアプリケーションを公開します。

**構築ステップ**:
1. セキュリティグループにHTTP(80)を追加
2. EC2にnginxをインストール
3. ブラウザでアクセス確認
4. カスタムWebページを作成・デプロイ
5. Webページの改善・再デプロイ

**学ぶこと**: Terraformでのインフラ変更、Agentを使ったコンテンツ生成、デプロイの流れ

→ [セッション2ガイド](session_guides/session2_guide.md)

---

### セッション3：HTTPS 対応（任意・45min）

セッション2のHTTPサイトをHTTPS対応にします。Terraformでセキュリティグループにポート443を追加し、EC2上で自己署名証明書の作成とnginxのSSL設定を行います。

**構築ステップ**:
1. Agentに環境構築〜アプリ作成〜デプロイを一括指示
2. ブラウザで動作確認

**学ぶこと**: 1つのプロンプトで複雑な作業を一括指示する技術

→ [セッション3ガイド](session_guides/session3_guide.md)

---

### セッション4：サーバー再起動の自動化（必須・2h）

セッション1のEC2に対して、Ansibleでサーバー再起動を自動化します。

**構築ステップ**:
1. Ansible接続設定（inventory + config）
2. 接続テスト
3. サーバー状態確認Playbook
4. サーバー再起動Playbook
5. サービス管理Playbook
6. nginx管理Playbook

**学ぶこと**: TerraformとAnsibleの役割の違い（構築 vs 運用）

→ [セッション4ガイド](session_guides/session4_guide.md)

---

### セッション5：SSM Agent & CloudWatch Agent 導入（必須・2h）

Ansibleのみを使ってSSM AgentとCloudWatch Agentを段階的にインストール・設定します。

**構築ステップ**:
1. IAMロール作成（AWS CLI）
2. SSM Agentインストール（Ansible）
3. SSM Agent動作確認
4. SSM Run Command 体験
5. CloudWatch Agentインストール（Ansible）
6. CloudWatch Agent設定・起動（Ansible）
7. CloudWatchで確認
8. CloudWatch Alarm 作成

**学ぶこと**: Ansible でのソフトウェア導入、ツールの使い分け（Terraform vs Ansible vs AWS CLI vs SSM）

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
Session 0: Claude Code 入門（操作スキルを習得）
    ↓
Session 1: VPC + EC2 構築  ──→  Session 2: Webアプリ公開  ──→  Session 3: HTTPS対応（任意）
    ↓（EC2をAnsibleの操作対象として使用）
Session 4: サーバー再起動の自動化
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
- AWSアカウント（トレーニング用、事前設定済み）
- ブラウザ版 VSCode（code-server）へのアクセス（URL とパスワードは講師から配布）
- Claude Code（AWS Bedrock使用、事前設定済み）

### 必要なスキル
- 基本的なLinuxコマンド
- YAML/JSONの基本的な理解

---

## 評価

各セッションの評価チェックリストは `evaluation/` ディレクトリを参照してください。
