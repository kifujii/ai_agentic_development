# OpenShift DevSpaces環境セットアップ手順書

## 概要
このドキュメントでは、OpenShift DevSpaces環境でのトレーニング準備手順を説明します。

## 前提条件
- OpenShift DevSpacesへのアクセス権限
- AWSアカウント（トレーニング用）
- 生成AI APIキー（OpenAI、Anthropicなど）

## セットアップ手順

### 1. DevSpacesワークスペースの作成

#### 1.1 ワークスペースへのアクセス
1. OpenShift DevSpacesのURLにアクセス
2. ログイン
3. 新しいワークスペースを作成または既存のワークスペースを開く

#### 1.2 ワークスペース設定
- **名前**: `ai-agentic-training`
- **スタック**: Python 3.11 または Node.js 18
- **メモリ**: 4GB以上推奨

### 2. 必要なツールのインストール

#### 2.1 自動インストールスクリプトの実行
```bash
# セットアップスクリプトを実行
chmod +x scripts/setup_devspaces.sh
./scripts/setup_devspaces.sh
```

#### 2.2 手動インストール（必要な場合）

**Terraformのインストール**
```bash
# Terraformのダウンロードとインストール
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform version
```

**Ansibleのインストール**
```bash
# Ansibleのインストール
pip3 install ansible

# または
sudo apt-get update
sudo apt-get install -y ansible

ansible --version
```

**AWS CLIのインストール**
```bash
# AWS CLI v2のインストール
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

### 3. 認証情報の設定

#### 3.1 AWS認証情報の設定
```bash
# AWS認証情報の設定
aws configure
# AWS Access Key ID: [入力]
# AWS Secret Access Key: [入力]
# Default region name: ap-northeast-1
# Default output format: json

# 認証情報の確認
aws sts get-caller-identity
```

#### 3.2 生成AI APIキーの設定
```bash
# 環境変数の設定
export OPENAI_API_KEY="your-api-key-here"
export ANTHROPIC_API_KEY="your-api-key-here"

# .envファイルの作成（推奨）
cat > .env << EOF
OPENAI_API_KEY=your-api-key-here
ANTHROPIC_API_KEY=your-api-key-here
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_DEFAULT_REGION=ap-northeast-1
EOF

# .envファイルを読み込む（.bashrcに追加）
echo 'export $(cat .env | xargs)' >> ~/.bashrc
source ~/.bashrc
```

### 4. Python環境のセットアップ

#### 4.1 仮想環境の作成
```bash
# 仮想環境の作成
python3 -m venv venv
source venv/bin/activate
```

#### 4.2 必要なパッケージのインストール
```bash
# requirements.txtからインストール
pip install -r requirements.txt

# または個別にインストール
pip install openai anthropic python-dotenv boto3 pyyaml jinja2
```

### 5. プロジェクト構造の確認

#### 5.1 ディレクトリ構造の確認
```bash
# プロジェクト構造の確認
tree -L 2

# 期待される構造:
# .
# ├── docs/
# ├── sample_code/
# ├── templates/
# ├── scripts/
# └── evaluation/
```

#### 5.2 Git設定（オプション）
```bash
# Gitの初期化（必要に応じて）
git init
git config user.name "Your Name"
git config user.email "your.email@example.com"
```

### 6. 動作確認

#### 6.1 ツールの動作確認
```bash
# Terraformの確認
terraform version

# Ansibleの確認
ansible --version

# AWS CLIの確認
aws --version

# Pythonの確認
python3 --version
pip3 list
```

#### 6.2 接続テスト
```bash
# AWS接続テスト
aws sts get-caller-identity

# APIキーの確認（環境変数）
echo $OPENAI_API_KEY
```

## トラブルシューティング

### 権限エラー
```bash
# 実行権限の付与
chmod +x scripts/*.sh
```

### パッケージインストールエラー
```bash
# pipのアップグレード
pip3 install --upgrade pip

# キャッシュのクリア
pip3 cache purge
```

### AWS認証エラー
- 認証情報が正しく設定されているか確認
- IAM権限が適切か確認
- リージョンが正しいか確認

### APIキーエラー
- 環境変数が正しく設定されているか確認
- .envファイルが正しく読み込まれているか確認
- APIキーが有効か確認

## 次のステップ
セットアップが完了したら、以下のセッションガイドを参照してください：
- `docs/session_guides/session0_guide.md`

## 参考資料
- [OpenShift DevSpaces公式ドキュメント](https://access.redhat.com/documentation/en-us/red_hat_openshift_dev_spaces/)
- [Terraform公式ドキュメント](https://www.terraform.io/docs)
- [Ansible公式ドキュメント](https://docs.ansible.com/)
