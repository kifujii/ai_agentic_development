# 生成AI活用トレーニングメニュー設計

このリポジトリには、生成AIを活用したIaC（Infrastructure as Code）トレーニングのための資料とサンプルコードが含まれています。

## ディレクトリ構造

```
.
├── docs/                          # ドキュメント
│   ├── TRAINING_MENU.md          # トレーニングメニュー詳細
│   ├── session_guides/           # セッションガイド
│   │   ├── session0_guide.md     # AI x IaC基礎実践
│   │   ├── session1_guide.md     # VPC/Subnet/EC2構築
│   │   ├── session2_guide.md     # Terraform自動化エージェント
│   │   ├── session3_guide.md     # Ansible運用基礎
│   │   ├── session4_guide.md     # Ansible自動化エージェント
│   │   ├── session5_guide.md     # 統合管理エージェント
│   │   └── session6_guide.md     # Webシステム構築（任意）
│   └── setup/                     # セットアップ手順
│       └── DEVSPACES_SETUP.md    # DevSpaces環境セットアップ
├── sample_code/                  # サンプルコード
│   ├── terraform/                 # Terraformサンプル
│   │   ├── basic_ec2/            # 基本的なEC2
│   │   ├── vpc_subnet_ec2/       # VPC/Subnet/EC2
│   │   └── s3_bucket/            # S3バケット
│   └── ansible/                   # Ansibleサンプル
│       ├── basic_playbook/       # 基本Playbook
│       └── monitoring_setup/      # 監視セットアップ
├── templates/                     # テンプレート
│   └── ai_agents/                 # AIエージェントテンプレート
│       ├── simple_agent_template.py
│       ├── terraform_agent_template.py
│       ├── ansible_agent_template.py
│       └── integrated_agent_template.py
├── evaluation/                    # 評価チェックリスト
│   ├── session0_checklist.md
│   ├── session1_checklist.md
│   ├── session2_checklist.md
│   ├── session3_checklist.md
│   ├── session4_checklist.md
│   ├── session5_checklist.md
│   ├── session6_checklist.md
│   └── README.md
├── scripts/                       # スクリプト
│   └── setup_devspaces.sh        # DevSpacesセットアップスクリプト
├── requirements.txt               # Python依存関係
└── README.md                     # このファイル
```

## クイックスタート

### 1. DevSpaces環境への資材の持ち込み

**重要**: セットアップスクリプトは **OpenShift DevSpaces環境内** で実行する想定です。

#### 1.1 DevSpacesワークスペースの作成
1. OpenShift DevSpacesのURLにアクセス
2. ログイン
3. 新しいワークスペースを作成（スタック: Python 3.11 または Node.js 18）

#### 1.2 Gitリポジトリのクローン
DevSpaces環境内のターミナルで以下のコマンドを実行：

```bash
# リポジトリをクローン
git clone https://github.com/kifujii/ai_agentic_development.git
cd ai_agentic_development

# trainingブランチに切り替え
git checkout training

# プロジェクトディレクトリに移動
cd ai_agentic
```

### 2. 環境セットアップ

**DevSpaces環境内**で以下のコマンドを実行：

```bash
# セットアップスクリプトの実行
chmod +x scripts/setup_devspaces.sh
./scripts/setup_devspaces.sh

# スクリプト実行後、PATHを更新（新しいターミナルを開くか、以下を実行）
source ~/.bashrc
```

**注意**: セットアップスクリプトは自動的にPythonパッケージもインストールします（`pip3 install --user`を使用）。

詳細は `docs/setup/DEVSPACES_SETUP.md` を参照してください。

**よくある質問**: セットアップに関する質問は `docs/setup/FAQ.md` を参照してください。

### 3. Groq APIのセットアップ

トレーニングでは、生成AIエージェント開発のためにGroq APIを使用します。以下の手順でセットアップしてください。

#### 3.1 Groqアカウントの作成

1. **Groq公式サイトにアクセス**
   - URL: https://console.groq.com/
   - 「Sign Up」または「Get Started」をクリック

2. **アカウント登録**
   - メールアドレスを入力
   - パスワードを設定
   - メール認証を完了（メールボックスを確認）
   - **注意**: クレジットカード情報は不要

3. **ログイン**
   - 登録したメールアドレスとパスワードでログイン

#### 3.2 APIキーの取得

1. **API Keysページにアクセス**
   - ログイン後、左側メニューから「API Keys」を選択
   - または、URL: https://console.groq.com/keys に直接アクセス

2. **APIキーの作成**
   - 「Create API Key」ボタンをクリック
   - APIキー名を入力（例: "training-handson"）
   - 「Create」をクリック

3. **APIキーのコピー**
   - 表示されたAPIキーをコピー（`gsk_`で始まる文字列）
   - **重要**: この画面を閉じると再度確認できないため、必ずコピーして安全な場所に保存
   - 例: `gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

#### 3.3 環境変数への設定

DevSpaces環境内で、Groq APIキーを環境変数に設定します：

```bash
# 一時的な設定（現在のセッションのみ）
export GROQ_API_KEY="gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# 永続的な設定（推奨）
echo 'export GROQ_API_KEY="gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"' >> ~/.bashrc
source ~/.bashrc

# 設定の確認
echo $GROQ_API_KEY
# APIキーが表示されればOK
```

#### 3.4 接続テスト

Groq APIが正しく設定されているか確認します：

```bash
# 必要なPythonパッケージのインストール（初回のみ）
# セットアップスクリプトを実行済みの場合は、既にインストールされています
pip3 install --user -r requirements.txt

# 接続テストスクリプトの実行
python3 scripts/test_groq.py
```

**期待される結果**: 「✅ 接続成功!」と表示され、Terraformコードが生成されればOKです。

**注意**: 接続テストスクリプト（`scripts/test_groq.py`）は事前に作成されています。コマンドラインでスクリプトを作成する必要はありません。

#### トラブルシューティング

**問題1: `ModuleNotFoundError: No module named 'groq'`**
```bash
# groqモジュールをインストール
pip3 install --user groq

# または、requirements.txtからすべてのパッケージをインストール
pip3 install --user -r requirements.txt
```

**問題2: APIキーが認識されない**
```bash
# 環境変数が正しく設定されているか確認
echo $GROQ_API_KEY

# 設定されていない場合は再設定
export GROQ_API_KEY="gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# 永続的に設定する場合
echo 'export GROQ_API_KEY="gsk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"' >> ~/.bashrc
source ~/.bashrc
```

**問題3: 接続エラーが発生する**
- インターネット接続を確認
- APIキーが正しくコピーされているか確認（先頭の`gsk_`を含む）
- GroqコンソールでAPIキーが有効か確認

**問題4: レート制限エラー**
- 無料枠は非常に大きいが、短時間に大量のリクエストを送ると制限される場合がある
- リクエスト間に少し待機時間を入れる

**問題5: モデルが見つからないエラー**
- 利用可能なモデル名を確認:
  - `llama3-8b-8192`（推奨）
  - `llama3-70b-8192`
  - `mixtral-8x7b-32768`
  - `gemma-7b-it`

### 4. 認証情報の設定

セットアップスクリプトが`.env.template`ファイルを作成します。`.env`ファイルを作成して認証情報を設定してください：

```bash
# .envファイルを作成（.env.templateを参考に）
cat > .env << EOF
AWS_ACCESS_KEY_ID=your-access-key-here
AWS_SECRET_ACCESS_KEY=your-secret-key-here
AWS_DEFAULT_REGION=ap-northeast-1
GROQ_API_KEY=your-groq-api-key-here
EOF

# .envファイルを環境変数として読み込む
# これにより、AWS CLIとTerraformの両方が環境変数から認証情報を読み取れます
export $(cat .env | grep -v '^#' | xargs)

# 認証情報の確認（AWS CLI）
aws sts get-caller-identity
```

**重要**: `.env`ファイルにAWS認証情報を設定し、環境変数としてエクスポートすれば、AWS CLIとTerraformの両方が使用できます。`aws configure`は不要です。

**理由**:
- Terraformは環境変数（`AWS_ACCESS_KEY_ID`、`AWS_SECRET_ACCESS_KEY`）から認証情報を読み取ります
- AWS CLIも環境変数から認証情報を読み取ることができます
- `.env`ファイルを環境変数としてエクスポートすることで、両方のツールが同じ認証情報を使用できます

### 4. トレーニングの開始

セットアップが完了したら、各セッションのガイドを参照してください：

- **セッション0**: `docs/session_guides/session0_guide.md`
- **セッション1**: `docs/session_guides/session1_guide.md`
- 以降も同様

**セットアップ完了後の確認事項**:
- [ ] Groqアカウントを作成し、APIキーを取得した
- [ ] Groq APIキーを環境変数に設定した（`export GROQ_API_KEY="..."`）
- [ ] Groq APIの接続テストが成功した（`python3 test_groq.py`）
- [ ] 新しいターミナルを開くか、`source ~/.bashrc`を実行してPATHを更新した
- [ ] `.env`ファイルを作成して認証情報を設定した
- [ ] `.env`ファイルを環境変数としてエクスポートした（`export $(cat .env | grep -v '^#' | xargs)`）
- [ ] AWS認証情報が正しく設定されていることを確認した（`aws sts get-caller-identity`）
- [ ] すべてのツールが正しくインストールされていることを確認した（`terraform version`、`ansible --version`など）

## トレーニング概要

- **期間**: 2日間（合計8時間、1日4時間）
- **形式**: ハンズオン形式のバイブコーディング
- **環境**: OpenShift DevSpaces + AWS
- **技術スタック**: Terraform, Ansible, 生成AIエージェント開発

詳細は `docs/TRAINING_MENU.md` を参照してください。

## 前提条件

- AWSアカウント（トレーニング用）
- AWS Admin権限を持つアクセスキーとシークレットキー
- OpenShift DevSpacesへのアクセス
- Groq APIキー（無料、クレジットカード不要）
  - アカウント作成: https://console.groq.com/
  - セットアップ手順は上記の「3. Groq APIのセットアップ」を参照

## 成果物

各セッションで以下の成果物を作成します：

- **セッション0**: Prompt Engineering、Context Engineering、AI Agentの実践成果
- **セッション1**: VPC、Subnet、EC2インスタンスが構築されたAWS環境
- **セッション2**: Terraformコード生成・実行を自動化する生成AIエージェント
- **セッション3**: サーバー再起動を自動化するAnsible Playbook
- **セッション4**: Ansible Playbook生成・実行を自動化する生成AIエージェント
- **セッション5**: インフラ管理タスクを統合的に自動化する生成AIエージェント
- **セッション6（任意）**: Webアプリケーションが動作するインフラ環境

## 評価

各セッションの評価チェックリストは `evaluation/` ディレクトリを参照してください。

## 参考資料

- [Terraform公式ドキュメント](https://www.terraform.io/docs)
- [Ansible公式ドキュメント](https://docs.ansible.com/)
- [AWS公式ドキュメント](https://docs.aws.amazon.com/)
- [OpenShift DevSpacesドキュメント](https://access.redhat.com/documentation/en-us/red_hat_openshift_dev_spaces/)

## ライセンス

このプロジェクトはトレーニング目的で作成されています。
