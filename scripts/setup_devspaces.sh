#!/bin/bash

# OpenShift DevSpaces環境セットアップスクリプト
# このスクリプトは、トレーニングに必要なツールを自動的にインストールします。

set -e  # エラー時に停止

echo "=========================================="
echo "OpenShift DevSpaces環境セットアップ開始"
echo "=========================================="

# カラー出力の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 1. システムの更新
log_info "システムパッケージの更新中..."
sudo apt-get update -qq

# 2. Terraformのインストール
log_info "Terraformのインストール中..."
if ! command -v terraform &> /dev/null; then
    TERRAFORM_VERSION="1.6.0"
    TERRAFORM_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    
    log_info "Terraform ${TERRAFORM_VERSION}をダウンロード中..."
    wget -q "${TERRAFORM_URL}" -O /tmp/terraform.zip
    unzip -q /tmp/terraform.zip -d /tmp
    sudo mv /tmp/terraform /usr/local/bin/
    sudo chmod +x /usr/local/bin/terraform
    rm /tmp/terraform.zip
    
    log_info "Terraformインストール完了: $(terraform version | head -n 1)"
else
    log_warn "Terraformは既にインストールされています: $(terraform version | head -n 1)"
fi

# 3. Ansibleのインストール
log_info "Ansibleのインストール中..."
if ! command -v ansible &> /dev/null; then
    sudo apt-get install -y ansible
    log_info "Ansibleインストール完了: $(ansible --version | head -n 1)"
else
    log_warn "Ansibleは既にインストールされています: $(ansible --version | head -n 1)"
fi

# 4. AWS CLIのインストール
log_info "AWS CLIのインストール中..."
if ! command -v aws &> /dev/null; then
    log_info "AWS CLI v2をダウンロード中..."
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    unzip -q /tmp/awscliv2.zip -d /tmp
    sudo /tmp/aws/install
    rm -rf /tmp/awscliv2.zip /tmp/aws
    
    log_info "AWS CLIインストール完了: $(aws --version)"
else
    log_warn "AWS CLIは既にインストールされています: $(aws --version)"
fi

# 5. Pythonパッケージのインストール
log_info "Pythonパッケージのインストール中..."
if [ -f "requirements.txt" ]; then
    pip3 install --upgrade pip -q
    pip3 install -r requirements.txt -q
    log_info "Pythonパッケージのインストール完了"
else
    log_warn "requirements.txtが見つかりません。基本的なパッケージをインストールします..."
    pip3 install --upgrade pip -q
    pip3 install openai anthropic python-dotenv boto3 pyyaml jinja2 -q
    log_info "基本的なPythonパッケージのインストール完了"
fi

# 6. Gitのインストール（必要に応じて）
log_info "Gitの確認中..."
if ! command -v git &> /dev/null; then
    sudo apt-get install -y git
    log_info "Gitインストール完了: $(git --version)"
else
    log_warn "Gitは既にインストールされています: $(git --version)"
fi

# 7. jqのインストール（JSON処理用）
log_info "jqのインストール中..."
if ! command -v jq &> /dev/null; then
    sudo apt-get install -y jq
    log_info "jqインストール完了"
else
    log_warn "jqは既にインストールされています"
fi

# 8. 作業ディレクトリの作成
log_info "作業ディレクトリの作成中..."
mkdir -p ~/workspace/terraform
mkdir -p ~/workspace/ansible
mkdir -p ~/workspace/agents
log_info "作業ディレクトリの作成完了"

# 9. .envファイルのテンプレート作成
log_info ".envファイルのテンプレート作成中..."
if [ ! -f ".env" ]; then
    cat > .env.template << EOF
# AWS認証情報
AWS_ACCESS_KEY_ID=your-access-key-here
AWS_SECRET_ACCESS_KEY=your-secret-key-here
AWS_DEFAULT_REGION=ap-northeast-1

# 生成AI APIキー
OPENAI_API_KEY=your-openai-api-key-here
ANTHROPIC_API_KEY=your-anthropic-api-key-here
EOF
    log_info ".env.templateファイルを作成しました。.envファイルを作成して認証情報を設定してください。"
else
    log_warn ".envファイルは既に存在します"
fi

# 10. 動作確認
echo ""
log_info "=========================================="
log_info "インストールされたツールの確認"
log_info "=========================================="

if command -v terraform &> /dev/null; then
    log_info "✓ Terraform: $(terraform version | head -n 1)"
else
    log_error "✗ Terraform: インストールされていません"
fi

if command -v ansible &> /dev/null; then
    log_info "✓ Ansible: $(ansible --version | head -n 1)"
else
    log_error "✗ Ansible: インストールされていません"
fi

if command -v aws &> /dev/null; then
    log_info "✓ AWS CLI: $(aws --version)"
else
    log_error "✗ AWS CLI: インストールされていません"
fi

if command -v python3 &> /dev/null; then
    log_info "✓ Python: $(python3 --version)"
else
    log_error "✗ Python: インストールされていません"
fi

if command -v git &> /dev/null; then
    log_info "✓ Git: $(git --version)"
else
    log_error "✗ Git: インストールされていません"
fi

echo ""
log_info "=========================================="
log_info "セットアップ完了！"
log_info "=========================================="
log_info "次のステップ:"
log_info "1. .envファイルを作成して認証情報を設定してください"
log_info "2. 'aws configure'を実行してAWS認証情報を設定してください"
log_info "3. 'source venv/bin/activate'で仮想環境を有効化してください（作成済みの場合）"
log_info "4. docs/session_guides/session0_guide.mdを参照してトレーニングを開始してください"
