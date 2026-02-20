# 生成AI活用トレーニングメニュー詳細ドキュメント

## トレーニング概要

### 基本情報
- **期間**: 2日間（合計8時間、1日4時間）
- **形式**: ハンズオン形式のバイブコーディング
- **環境**: OpenShift DevSpaces + AWS
- **技術スタック**: Terraform, Ansible, Continue（AWS Bedrock）
- **前提条件**: 事前勉強会で生成AIとIaC（Terraform/Ansible）の基礎を学習済み

### 学習目標
- **Prompt Engineering**: 良いプロンプトと悪いプロンプトの違いを理解し、効果的なプロンプトを作成できる
- **Context Engineering**: コンテキスト情報を適切に活用して、品質の高いコードを生成できる
- **フィードバックループ**: human in the loopの重要性を理解し、エラー修正、反復的改善、承認ワークフローを実践できる
- **Agent形式での開発の理解**: Agent形式での開発の本質を理解し、開発体験の改善を実感できる
- Terraformを使ったAWSインフラの構築・検証を実践
- Ansibleを使ったシステム運用の自動化を実践

---

## セッション構成一覧

| セッション | 内容 | 時間 | 必須/任意 | ツール | 達成すること |
|-----------|------|------|-----------|--------|-------------|
| 1 | AI x IaC基礎実践とAgent開発の理解 | 1.5h | 必須 | Continue | Prompt/Context Engineering、Chat vs Agent理解 |
| 2 | VPC/Subnet/EC2の設計・構築・検証 | 1.5h | 必須 | Terraform | 基本AWSネットワーク+EC2が動作する環境 |
| 3 | Webシステム構築 (ALB/ECS/ECR/RDS) | 1h | 任意 | Terraform | Webアプリケーションインフラ一式 |
| 4 | サーバー再起動の自動化 | 1.5h | 必須 | Ansible | サーバー再起動Playbook+基本運用タスク |
| 5 | エージェントインストール・セットアップ | 1.5h | 必須 | Terraform+Ansible | CloudWatch Agent導入済み環境 |
| 6 | サーバー情報取得・運用レポート作成 | 1h | 任意 | Ansible | サーバー情報収集+運用レポート生成 |

### 時間配分

```
Day 1 (4h): インフラ構築 (Terraform)
├── Session 1: AI x IaC基礎実践とAgent開発の理解 (1.5h) [必須]
├── Session 2: VPC/Subnet/EC2の設計・構築・検証 (1.5h)  [必須]
└── Session 3: Webシステム構築 (1h)                      [任意]

Day 2 (4h): システム運用 (Ansible)
├── Session 4: サーバー再起動の自動化 (1.5h)              [必須]
├── Session 5: エージェントインストール・セットアップ (1.5h) [必須]
└── Session 6: サーバー情報取得・運用レポート作成 (1h)     [任意]
```

- Day 1: 必須(3h) + 任意(1h) = 4h
- Day 2: 必須(3h) + 任意(1h) = 4h
- 必須合計: 6h / 任意合計: 2h / 全体: 8h

---

## 1日目：インフラ構築（Terraform）（4時間）

### セッション1：AI x IaC基礎実践とAgent開発の理解（必須）（1.5時間）

#### 目標
Prompt Engineering、Context Engineering、フィードバックループ、開発方式比較を通じて、Agent形式での開発の本質を理解し、AI x IaCの基礎を習得する。

#### 学習内容

**1. 環境セットアップ（10分）**
- 環境セットアップガイドの実行・確認

**2. Prompt Engineering実践（30分）**
- 悪いプロンプトでの体験（曖昧な指示でのコード生成）
- フィードバックループでのプロンプト改善
- 良いプロンプトの確認（折りたたみで提示）

**3. Context Engineering実践（15分）**
- コンテキストなしでの生成
- コンテキストありでの生成

**4. Agent形式での開発の理解（20分）**
- Agent形式での実践（EC2インスタンス作成）
- フィードバックループの3つのパターンの体験

**5. チャット形式 vs Agent形式の比較（15分）**
- 既に作成したファイルを活用した比較・振り返り

#### 成果物
- Prompt Engineeringの実践成果
- Context Engineeringの実践成果
- チャット形式とAgent形式の比較体験
- Agent形式での開発の理解と実践成果

#### 参考資料
- `docs/session_guides/session1_guide.md`

---

### セッション2：VPC/Subnet/EC2の設計・構築・検証（必須）（1.5時間）

#### 目標
Agent形式でVPC/Subnet/EC2を構築し、構築結果を検証する。セッション4以降でAnsibleから操作するためのEC2環境を完成させる。

#### 学習内容
- Prompt Engineeringの実践（複雑な要件への対応）
- Context Engineeringの実践（既存AWSリソース情報の活用）
- Agent形式でのインフラ構築とフィードバックループ
- SSH鍵ペアの設定（セッション4以降のAnsible操作のため）
- 構築結果の検証（terraform plan/apply、SSH接続テスト）

#### 成果物
- VPC、Subnet、EC2インスタンスが構築されたAWS環境
- SSH接続が可能な状態
- 振り返りレポート

#### 参考資料
- `docs/session_guides/session2_guide.md`

---

### セッション3：Webシステム構築（任意・発展）（1時間）

#### 目標
セッション2で構築したVPC/Subnetを活用し、ALB、ECS/ECR、RDSを含む実践的なWebアプリケーションインフラをAgent開発で構築する。

#### 学習内容
- 複雑なインフラ構成のAgent開発
- セッション2のリソースを活用した拡張構築
- 依存関係を考慮した段階的な構築アプローチ
- 統合的なワークフローでのAgent開発

#### 成果物
- ALB、ECS、RDSを含むWebアプリケーションインフラ

#### 参考資料
- `docs/session_guides/session3_guide.md`

---

## 2日目：システム運用（Ansible）（4時間）

### セッション4：サーバー再起動の自動化（必須）（1.5時間）

#### 目標
セッション2で構築したEC2インスタンスに対して、Ansibleを使ったサーバー再起動の自動化をAgent開発で実現する。

#### 学習内容
- Ansibleの基本概念（インベントリ、Playbook、タスク、ハンドラー）
- Prompt Engineering（Ansible用）の実践
- Context Engineering（サーバー情報）の実践
- Agent形式でのPlaybook作成（再起動、状態確認、サービス管理）
- 段階的な構築アプローチ（接続テスト → 状態確認 → 再起動 → サービス管理）

#### 成果物
- Ansibleインベントリファイル
- サーバー再起動Playbook
- サーバー状態確認Playbook
- サービス管理Playbook

#### 参考資料
- `docs/session_guides/session4_guide.md`

---

### セッション5：エージェントインストール・セットアップ（必須）（1.5時間）

#### 目標
TerraformとAnsibleを組み合わせたAgent開発で、CloudWatch Agentのインストール・設定を実現する。

#### 学習内容
- TerraformとAnsibleの組み合わせによるAgent開発
- IAMロール/インスタンスプロファイルの設定（Terraform）
- CloudWatch Agentのインストール・設定（Ansible）
- ツール横断的なAgent開発の実践

#### 成果物
- IAMロール・インスタンスプロファイル（Terraform）
- CloudWatch Agentインストール用Playbook
- CloudWatch Agent設定用Playbook
- CloudWatch Agentが動作する環境

#### 参考資料
- `docs/session_guides/session5_guide.md`

---

### セッション6：サーバー情報取得・運用レポート作成（任意・発展）（1時間）

#### 目標
Ansible factsとJinja2テンプレートを活用して、サーバー情報の自動収集と運用レポートの生成をAgent開発で実現する。

#### 学習内容
- Ansible factsを活用したサーバー情報収集
- Jinja2テンプレートを使ったレポート生成
- 運用で活用できるレベルの自動化

#### 成果物
- サーバー情報収集Playbook
- 運用レポート生成Playbook
- Jinja2テンプレート
- 生成された運用レポート

#### 参考資料
- `docs/session_guides/session6_guide.md`

---

## トレーニング設計のポイント

### Agent開発体験の5つの要素

1. **Prompt Engineering**（全セッション）
   - 良いプロンプトと悪いプロンプトの比較体験
   - 不足パラメータの聞き返し機能の体験
   - 段階的なプロンプト改善の実践

2. **Context Engineering**（全セッション）
   - コンテキスト情報の構造化と管理
   - AWSリソース情報のコンテキスト化
   - 既存コードのコンテキスト活用

3. **フィードバックループ**（全セッション）
   - エラー修正プロセス: AIがエラー検出→修正提案→人間が承認
   - 反復的改善: 人間のフィードバック→AIが改善→再検証
   - 承認ワークフロー: AIが計画提示→人間が承認→実行

4. **開発方式比較**（セッション1）
   - チャット形式（コードコピー方式）vs Agent形式の比較体験
   - 開発体験の改善を実感

5. **Agent形式での開発の理解**（全セッション）
   - Agent形式の本質的理解
   - Agent形式のメリットと適用場面
   - 実践的なAgent開発スキルの習得

### セッション間のつながり

```
Session 1: 基礎理解
    ↓
Session 2: VPC/Subnet/EC2構築 ──→ Session 3: Webシステム構築（任意）
    ↓（EC2をAnsibleの操作対象として使用）
Session 4: サーバー再起動の自動化
    ↓
Session 5: CloudWatch Agentインストール
    ↓
Session 6: サーバー情報取得・レポート作成（任意）
```

- セッション2で構築したEC2がセッション4以降のAnsible操作の対象になる
- セッション3（任意）はセッション2の発展として独立して実施可能
- セッション6（任意）はセッション4・5の発展として独立して実施可能

---

## 前提条件と準備

### 事前勉強会で学習済みの内容

- **生成AIの基礎**
  - LLMの基本概念
  - Prompt Engineeringの基礎

- **IaC（Infrastructure as Code）の基礎**
  - Terraformの基本概念とコマンド（init, plan, apply）
  - Ansibleの基本概念とPlaybook構造

### 必要な環境とスキル

- **環境**
  - AWSアカウント（トレーニング用）
  - AWSアクセスキーとシークレットキー（事前に用意）
  - OpenShift DevSpacesへのアクセス
  - Continue（AWS Bedrock使用）

- **スキル**
  - 基本的なLinuxコマンドの知識
  - Gitの基本操作
  - YAML/JSONの基本的な理解

---

## 成果物と評価

### 各セッションの成果物

- **セッション1**: Prompt Engineering、Context Engineering、AI Agentの実践成果
- **セッション2**: VPC、Subnet、EC2インスタンスが構築されたAWS環境（SSH接続可能）
- **セッション3（任意）**: ALB、ECS、RDSを含むWebアプリケーションインフラ
- **セッション4**: サーバー再起動を自動化するAnsible Playbook
- **セッション5**: CloudWatch Agent導入済みの環境（Terraform + Ansible統合）
- **セッション6（任意）**: サーバー情報収集・運用レポート生成の仕組み

### 評価方法

- **構築結果の確認**: 各セッションで指定されたリソースが正しく構築されているか
- **Agent開発の活用度**: Agent機能をどの程度活用できたか
- **振り返りの質**: 学んだことをどの程度言語化できたか

詳細な評価チェックリストは `evaluation/` ディレクトリを参照してください。

---

## 参考資料とリソース

### ドキュメント
- セッションガイド: `docs/session_guides/`
- セットアップ手順: `docs/setup/`
- 評価チェックリスト: `evaluation/`

### 外部リソース
- [Terraform公式ドキュメント](https://www.terraform.io/docs)
- [Ansible公式ドキュメント](https://docs.ansible.com/)
- [AWS公式ドキュメント](https://docs.aws.amazon.com/)
- [OpenShift DevSpacesドキュメント](https://access.redhat.com/documentation/en-us/red_hat_openshift_dev_spaces/)

---

## トレーニング後のフォローアップ

### 推奨事項
- 実務での活用計画の作成
- 継続的な学習とスキル向上
- コミュニティへの参加（Terraform、Ansible、AI関連）

### 追加学習リソース
- セキュリティベストプラクティス
- CI/CDパイプライン統合
- コスト最適化
- 運用・監視の高度化
