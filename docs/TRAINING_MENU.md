# 生成AI活用トレーニングメニュー

## 基本情報

| 項目 | 内容 |
|------|------|
| 期間 | 2日間（必須8h45min + 任意8.75h） |
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
| 2 | Terraform でインフラを構築・変更・再構築 | 2h | 必須 | Terraform |
| 3 | EC2 を count でスケールアウト | 45min | 任意 | Terraform |
| 4 | Ansible によるサーバー運用自動化 | 2h | 必須 | Ansible |
| 5 | SSM Agent & CloudWatch Agent 導入 | 2h | 必須 | Ansible + AWS CLI |
| 6 | サーバー情報取得・運用レポート | 1h | 任意 | Ansible |
| 7 | 応用: Web アプリ構築・デプロイ | 2h | 任意 | 全ツール |
| 8 | 応用: インフラの冗長化 | 2h | 任意 | 全ツール |
| 9 | 応用: インフラ監視と通知の自動化 | 2h | 任意 | 全ツール |

### 時間配分

```
Day 1 (4h45min + 任意45min): Claude Code 入門 & インフラ構築 (Terraform)
├── Session 0: Claude Code に慣れよう (45min)              [必須]
├── Session 1: VPC + EC2 を段階的に構築 (2h)              [必須]
├── Session 2: Terraform でインフラを構築・変更・再構築 (2h) [必須]
└── Session 3: EC2 を count でスケールアウト (45min)       [任意]

Day 2 (4h + 任意7h): システム運用 (Ansible) & 応用
├── Session 4: Ansible によるサーバー運用自動化 (2h)      [必須]
├── Session 5: SSM Agent & CloudWatch Agent 導入 (2h)    [必須]
├── Session 6: サーバー情報取得・レポート (1h)            [任意]
├── Session 7: 応用: Web アプリ構築・デプロイ (2h)        [任意]
├── Session 8: 応用: インフラの冗長化 (2h)                [任意]
└── Session 9: 応用: インフラ監視と通知の自動化 (2h)      [任意]
```

- 必須合計: 8h45min / 任意合計: 8.75h / 全体: 17h30min（任意含む）
- ⏱️ 各セッションの時間にはバッファ（約10〜15分）を含んでいます。環境トラブルやAgent応答待ちに充ててください。
- 💡 応用セッション（7〜9）は各セッション独立しています。興味のあるものを選んで取り組んでください。

---

## 各セッションの概要

### セッション0：Claude Code に慣れよう（必須・45min）

Session 1 以降で使う Claude Code（AI コーディング Agent）の基本操作を体験します。AWS リソースは使わず、安全な環境で自由に試せます。

**体験すること**:
1. Claude Code の起動と基本操作
2. 承認ワークフロー（ファイル作成・コマンド実行）
3. スラッシュコマンド（`/help`, `/exit`, `/compact`）
4. プロンプトの書き方を自由に試す
5. ワークショップ環境の確認

**学ぶこと**: AI Agent との協業の基本（指示の出し方、承認フロー、エラー対処）

---

### セッション1：VPC + EC2 を段階的に構築（必須・2h）

Claude Code の AI Agent 機能を使って、VPC → サブネット → セキュリティグループ → EC2 の順で段階的にAWSインフラを構築します。

**構築ステップ**:
0. **Plan モードで設計を相談**（AI と対話しながらインフラ設計）
1. VPC作成（お手本プロンプト）
2. ネットワーク環境を整える
3. SSH の準備（キーペア＆セキュリティグループ）
4. EC2インスタンス作成（自力で挑戦！）
5. SSH接続確認

**学ぶこと**: AI と対話しながらの設計（Plan モード）、Agent開発の基本、効果的なプロンプトの4要素

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

---

### セッション3：EC2 を count でスケールアウト（任意・45min）

Terraform の `count` パラメータでEC2を2台に増やし、「コード1行でサーバーの台数を増減できる」IaC の威力を体験します。`terraform destroy -target` で1台だけの選択的削除も学びます。

**構築ステップ**:
1. `count = 2` でEC2を2台に増加
2. 2台のnginxにブラウザでアクセス確認
3. `terraform destroy -target` で2台目だけ削除 → 1台に戻す

**学ぶこと**: `count` によるスケールアウト、`terraform destroy -target` による選択的削除、コードとインフラの整合性

---

### セッション4：Ansible によるサーバー運用自動化（必須・2h）

セッション1のEC2に対して、Ansibleでサーバー運用を自動化します。後半では **ランダム障害対応シミュレーション** を通じて、Claude Code と協力してトラブルシューティングする実践力を身につけます。

**構築ステップ**:
1. Ansible接続設定（inventory + config）
2. 接続テスト
3. サーバー状態確認Playbook
4. サーバー再起動Playbook
5. サービス管理Playbook
6. 🔧 障害対応シミュレーション（ランダム障害発生→原因調査→復旧→Playbook化）

**学ぶこと**: TerraformとAnsibleの役割の違い、**AIと協力するトラブルシューティングパターン**

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

---

### セッション6：サーバー情報取得・運用レポート（任意・1h）

Ansibleでサーバー情報を自動収集し、Jinja2テンプレートで運用レポートを生成します。

**構築ステップ**:
1. サーバー情報収集Playbook
2. Jinja2レポートテンプレート
3. レポート自動生成

**学ぶこと**: Ansible の情報収集（facts, command）、Jinja2 テンプレート、`delegate_to: localhost` によるローカルファイル生成

---

### セッション7：応用 — Web アプリケーションの構築とデプロイ（任意・2h）

「上司からの依頼」シナリオで、EC2 上に Web アプリケーションを構築・デプロイします。手順書はなく、要件だけが与えられます。

**学ぶこと**: AI と協力したアーキテクチャ設計（Plan モード）、要件から実装までの自律的な問題解決

---

### セッション8：応用 — インフラの冗長化（任意・2h）

「上司からの依頼」シナリオで、1台が落ちてもサービスが継続する冗長構成を構築します。手順書はなく、要件だけが与えられます。

**学ぶこと**: ロードバランサーを使った冗長構成の設計・実装、障害時の動作確認

---

### セッション9：応用 — インフラ監視と通知の自動化（任意・2h）

「上司からの依頼」シナリオで、サーバー監視とアラート通知の仕組みを構築します。手順書はなく、要件だけが与えられます。

**学ぶこと**: CloudWatch + SNS を活用した監視・通知基盤の設計・実装

---

## セッション間のつながり

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
    ↓
Session 7〜9: 応用チャレンジ（任意・各セッション独立）
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
