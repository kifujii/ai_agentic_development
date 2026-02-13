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

### 2. トレーニング資材の取得

**重要**: セットアップスクリプトは **DevSpaces環境内** で実行する必要があります。まず、Gitリポジトリから資材をクローンしてください。

#### 2.1 Gitリポジトリのクローン
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

**注意**: リポジトリURLは実際のリポジトリに合わせて変更してください。

#### 2.2 プロジェクト構造の確認
```bash
# ディレクトリ構造の確認
ls -la

# 期待される構造:
# .
# ├── docs/
# ├── sample_code/
# ├── templates/
# ├── scripts/
# └── evaluation/
```

### 3. 必要なツールのインストール

#### 3.1 自動インストールスクリプトの実行
**重要**: このスクリプトは **DevSpaces環境内** で実行してください。

**注意**: DevSpaces環境ではsudo権限が制限されているため、スクリプトはユーザー権限でインストールを行います。

```bash
# プロジェクトディレクトリにいることを確認
pwd
# 出力例: /projects/ai_agentic_development/ai_agentic

# セットアップスクリプトを実行
chmod +x scripts/setup_devspaces.sh
./scripts/setup_devspaces.sh
```

このスクリプトは以下のツールを自動的にインストールします（ユーザー権限）：
- Terraform（~/.local/binにインストール）
- Ansible（pipでユーザー権限インストール）
- AWS CLI（~/.local/binにインストール）
- Pythonパッケージ（requirements.txtから、--userオプションでインストール）
- Git（既にインストールされている場合が多い）
- jq（sudoが使える場合のみ）

**インストール後の注意**:
- スクリプト実行後、新しいターミナルを開くか、`source ~/.bashrc`を実行してPATHを更新してください
- ツールは`~/.local/bin`にインストールされ、自動的にPATHに追加されます

#### 3.2 手動インストール（必要な場合）

スクリプトが失敗した場合や、特定のツールのみをインストールしたい場合は、以下の手順を参照してください。

**Terraformのインストール（ユーザー権限）**
```bash
# ローカルbinディレクトリの作成
mkdir -p ~/.local/bin

# PATHに追加（まだ追加されていない場合）
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Terraformのダウンロードとインストール
TERRAFORM_VERSION="1.6.0"
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
mv terraform ~/.local/bin/
chmod +x ~/.local/bin/terraform
rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# 新しいターミナルを開くか、PATHを再読み込み
source ~/.bashrc
terraform version
```

**Ansibleのインストール（ユーザー権限）**
```bash
# pipでユーザー権限でインストール
pip3 install --user ansible

# PATHを確認（pipのbinディレクトリが含まれているか）
echo $PATH

# インストール確認
ansible --version
```

**AWS CLIのインストール（ユーザー権限）**
```bash
# ローカルbinディレクトリの作成
mkdir -p ~/.local/bin

# AWS CLI v2のダウンロード
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip

# ユーザー権限でインストール
./aws/install --install-dir ~/.local/aws-cli --bin-dir ~/.local/bin

# クリーンアップ
rm -rf awscliv2.zip aws

# PATHを確認
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# 新しいターミナルを開くか、PATHを再読み込み
source ~/.bashrc
aws --version
```

**注意**: 手動インストール後は、新しいターミナルを開くか、`source ~/.bashrc`を実行してPATHを更新してください。

### 4. 認証情報の設定

#### 4.1 AWS認証情報の設定
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

#### 4.2 生成AI APIキーの設定
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

### 5. Python環境のセットアップ

#### 5.1 仮想環境の作成
```bash
# 仮想環境の作成
python3 -m venv venv
source venv/bin/activate
```

#### 5.2 必要なパッケージのインストール
```bash
# requirements.txtからインストール
pip install -r requirements.txt

# または個別にインストール
pip install openai anthropic python-dotenv boto3 pyyaml jinja2
```

### 6. プロジェクト構造の確認

#### 6.1 ディレクトリ構造の確認
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

#### 6.2 Git設定（オプション）
```bash
# Gitの初期化（必要に応じて）
git init
git config user.name "Your Name"
git config user.email "your.email@example.com"
```

### 7. 動作確認

#### 7.1 ツールの動作確認
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

#### 7.2 接続テスト
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
