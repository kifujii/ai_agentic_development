# 生成AI活用トレーニングメニュー

## 基本情報

| 項目 | 内容 |
|------|------|
| 期間 | 2日間（必須10h + 任意2h15min） |
| 形式 | ハンズオン形式のバイブコーディング |
| 環境 | ブラウザ版 VSCode（code-server on AWS EC2）+ AWS |
| 技術 | Terraform, Ansible, Claude Code（AWS Bedrock） |
| 前提 | 事前勉強会で生成AIとIaCの基礎を学習済み |

---

## セッション構成

| # | 内容 | 時間 | 必須/任意 | ツール |
|---|------|------|-----------|--------|
| 0 | Claude Code に慣れよう | 30min | 必須 | Claude Code |
| 1 | VPC + EC2 を段階的に構築 | 1.5h | 必須 | Terraform |
| 2 | Terraform でインフラを構築・変更・再構築 | 1h | 必須 | Terraform |
| 3 | Web サーバーを冗長構成にしよう | 30min | 任意 | Terraform |
| 4 | Ansible によるサーバー運用自動化 | 1.5h | 必須 | Ansible |
| 5 | SSM Agent & CloudWatch Agent 導入 | 1.5h | 必須 | Ansible + AWS CLI |
| 6 | 運用レポートの自動生成 | 45min | 任意 | Ansible |
| 7 | 未知の技術を AI で攻略する | 1.5h | 必須 | Terraform |
| 8 | 本番リリースの設計判断 | 1.5h | 必須 | Terraform |
| 9 | インシデント対応とポストモーテム | 1h | 必須 | Ansible + SSH |
| 10 | ゼロからシステム構築チャレンジ | 1.5h | 任意 | 全ツール |

### 時間配分

```
Day 1 (6h + 任意30min): Claude Code 入門 → Terraform → Ansible → 監視基盤
├── Session 0: Claude Code に慣れよう (30min)                [必須]
├── Session 1: VPC + EC2 を段階的に構築 (1.5h)              [必須]
├── Session 2: Terraform でインフラを構築・変更・再構築 (1h)  [必須]
├── Session 3: Web サーバーを冗長構成にしよう (30min)         [任意]
├── Session 4: Ansible によるサーバー運用自動化 (1.5h)       [必須]
└── Session 5: SSM Agent & CloudWatch Agent 導入 (1.5h)     [必須]

Day 2 (4h + 任意2h15min): 応用・実践（シナリオ型）
├── Session 6: 運用レポートの自動生成 (45min)                [任意]
├── Session 7: 未知の技術を AI で攻略する (1.5h)            [必須]
├── Session 8: 本番リリースの設計判断 (1.5h)                [必須]
├── Session 9: インシデント対応とポストモーテム (1h)         [必須]
└── Session 10: ゼロからシステム構築チャレンジ (1.5h)       [任意]
```

- 必須合計: 10h / 任意合計: 2h15min / 全体: 12h15min（任意含む）
- ⏱️ 各セッションの時間にはバッファを含んでいます。環境トラブルやAgent応答待ちに充ててください。
- 💡 Day 2 の Session 7-9 は各セッション独立しています。順番を入れ替えても問題ありません。

---

## 各セッションの概要

### セッション0：Claude Code に慣れよう（必須・30min）

Session 1 以降で使う Claude Code（AI コーディング Agent）の基本操作を体験します。AWS リソースは使わず、安全な環境で自由に試せます。

**体験すること**:
1. Claude Code の起動と基本操作
2. 承認ワークフロー（ファイル作成・コマンド実行）
3. スラッシュコマンド（`/help`, `/exit`, `/compact`）
4. プロンプトの書き方を自由に試す
5. ワークショップ環境の確認

**学ぶこと**: AI Agent との協業の基本（指示の出し方、承認フロー、エラー対処）

---

### セッション1：VPC + EC2 を段階的に構築（必須・1.5h）

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

### セッション2：Terraform でインフラを構築・変更・再構築（必須・1h）

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

### セッション3：Web サーバーを冗長構成にしよう（任意・30min）

Terraform の `count` パラメータでEC2を2台に増やし、「コード1行でサーバーの台数を増減できる」IaC の威力を体験します。`terraform destroy -target` で1台だけの選択的削除も学びます。

**構築ステップ**:
1. `count = 2` でEC2を2台に増加
2. 2台のnginxにブラウザでアクセス確認
3. `terraform destroy -target` で2台目だけ削除 → 1台に戻す

**学ぶこと**: `count` によるスケールアウト、`terraform destroy -target` による選択的削除、コードとインフラの整合性

---

### セッション4：Ansible によるサーバー運用自動化（必須・1.5h）

セッション1・2で構築したEC2に対して、Ansibleでサーバー運用を自動化します。後半では **ランダム障害対応シミュレーション** を通じて、Claude Code と協力してトラブルシューティングする実践力を身につけます。

**構築ステップ**:
1. Ansible接続設定（inventory + config）
2. 接続テスト
3. サーバー状態確認Playbook
4. サーバー再起動Playbook
5. サービス管理Playbook
6. 🔧 障害対応シミュレーション（ランダム障害発生→原因調査→復旧→Playbook化）

**学ぶこと**: TerraformとAnsibleの役割の違い、**AIと協力するトラブルシューティングパターン**

---

### セッション5：SSM Agent & CloudWatch Agent 導入（必須・1.5h）

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

### セッション6：運用レポートの自動生成（任意・45min）

Ansibleでサーバー情報を自動収集し、Jinja2テンプレートで運用レポートを生成します。

**構築ステップ**:
1. サーバー情報収集Playbook
2. Jinja2レポートテンプレート
3. レポート自動生成

**学ぶこと**: Ansible の情報収集（facts, command）、Jinja2 テンプレート、`delegate_to: localhost` によるローカルファイル生成

---

### セッション7：未知の技術を AI で攻略する（必須・1.5h）

Lambda も API Gateway も使ったことがない状態から、AI と協力してサーバーレス API を構築します。「自分ができないことでも AI を使えばできる」を体験するセッションです。

**学ぶこと**: 未知の技術への取り組み方、AI との対話による技術学習、Lambda + API Gateway + Terraform

---

### セッション8：本番リリースの設計判断（必須・1.5h）

「月額3万円以内で可用性 99.9%」という制約の中で、EC2 1台構成から高可用性構成への移行を設計・実装します。コスト見積もりと設計判断のドキュメントも作成します。

**学ぶこと**: アーキテクチャの設計判断、コスト最適化、可用性の設計、ALB + Multi-AZ

---

### セッション9：インシデント対応とポストモーテム（必須・1h）

金曜夕方に複数のアラートが発報。障害復旧からポストモーテム（障害報告書）の作成、再発防止策の実装まで一連のインシデント対応を体験します。

**学ぶこと**: 障害調査・復旧の手順、ポストモーテムの書き方、再発防止策の IaC 化

---

### セッション10：ゼロからシステム構築チャレンジ（任意・1.5h）

社内ハッカソン形式で、3つのお題（ステータスページ / デプロイパイプライン / 複数環境管理）から1つを選んで1.5時間で動くものを作ります。

**学ぶこと**: ゼロからの設計・実装力、時間制約下での優先順位判断

---

## セッション間のつながり

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
