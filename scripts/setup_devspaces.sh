#!/bin/bash

# OpenShift DevSpaces環境セットアップスクリプト
# このスクリプトは、トレーニングに必要なツールを自動的にインストールします。
# DevSpaces環境ではsudo権限がないため、ユーザー権限でインストールします。

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

# sudo権限のチェック
check_sudo() {
    if sudo -n true 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# ローカルbinディレクトリの設定
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

# PATHにローカルbinを追加（まだ追加されていない場合）
if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
    export PATH="$LOCAL_BIN:$PATH"
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    log_info "PATHに ~/.local/bin を追加しました"
fi

# 1. システムパッケージの更新（sudoが使える場合のみ）
if check_sudo; then
    log_info "システムパッケージの更新中..."
    sudo apt-get update -qq || log_warn "システムパッケージの更新をスキップしました"
else
    log_warn "sudo権限がないため、システムパッケージの更新をスキップします"
fi

# 2. Terraformのインストール（ユーザー権限）
log_info "Terraformのインストール中..."
if ! command -v terraform &> /dev/null; then
    TERRAFORM_VERSION="1.6.0"
    TERRAFORM_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    
    log_info "Terraform ${TERRAFORM_VERSION}をダウンロード中..."
    wget -q "${TERRAFORM_URL}" -O /tmp/terraform.zip || {
        log_error "Terraformのダウンロードに失敗しました"
        exit 1
    }
    unzip -q /tmp/terraform.zip -d /tmp
    mkdir -p "$LOCAL_BIN"
    mv /tmp/terraform "$LOCAL_BIN/"
    chmod +x "$LOCAL_BIN/terraform"
    rm /tmp/terraform.zip
    
    log_info "Terraformインストール完了: $($LOCAL_BIN/terraform version | head -n 1)"
else
    log_warn "Terraformは既にインストールされています: $(terraform version | head -n 1)"
fi

# 3. Ansibleのインストール（pipでユーザー権限）
log_info "Ansibleのインストール中..."
if ! command -v ansible &> /dev/null; then
    # pipでインストール（ユーザー権限）
    pip3 install --user ansible -q || {
        log_error "Ansibleのインストールに失敗しました"
        exit 1
    }
    log_info "Ansibleインストール完了: $(ansible --version | head -n 1)"
else
    log_warn "Ansibleは既にインストールされています: $(ansible --version | head -n 1)"
fi

# 4. AWS CLIのインストール（ユーザー権限）
log_info "AWS CLIのインストール中..."
if ! command -v aws &> /dev/null; then
    log_info "AWS CLI v2をダウンロード中..."
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" || {
        log_error "AWS CLIのダウンロードに失敗しました"
        exit 1
    }
    unzip -q /tmp/awscliv2.zip -d /tmp
    
    # ユーザー権限でインストール
    /tmp/aws/install --install-dir "$HOME/.local/aws-cli" --bin-dir "$LOCAL_BIN" || {
        log_error "AWS CLIのインストールに失敗しました"
        exit 1
    }
    rm -rf /tmp/awscliv2.zip /tmp/aws
    
    log_info "AWS CLIインストール完了: $(aws --version)"
else
    log_warn "AWS CLIは既にインストールされています: $(aws --version)"
fi

# 5. Pythonパッケージのインストール
log_info "Pythonパッケージのインストール中..."
if [ -f "requirements.txt" ]; then
    pip3 install --user --upgrade pip -q
    pip3 install --user -r requirements.txt -q
    log_info "Pythonパッケージのインストール完了"
else
    log_warn "requirements.txtが見つかりません。基本的なパッケージをインストールします..."
    pip3 install --user --upgrade pip -q
    pip3 install --user openai anthropic python-dotenv boto3 pyyaml jinja2 -q
    log_info "基本的なPythonパッケージのインストール完了"
fi

# 6. Gitの確認（通常は既にインストールされている）
log_info "Gitの確認中..."
if ! command -v git &> /dev/null; then
    if check_sudo; then
        sudo apt-get install -y git
        log_info "Gitインストール完了: $(git --version)"
    else
        log_warn "Gitがインストールされていません。"
        log_info "Gitのバイナリをダウンロード中..."
        # Gitの静的バイナリをダウンロード（GitHub Releasesから）
        GIT_VERSION="2.42.0"
        GIT_URL="https://github.com/git/git/releases/download/v${GIT_VERSION}/git-${GIT_VERSION}.tar.gz"
        
        # 注意: Gitのバイナリビルドは複雑なため、通常はDevSpaces環境に既にインストールされている
        # ここでは警告のみを出し、ユーザーに手動インストールを促す
        log_error "Gitの自動インストールは複雑なため、DevSpaces管理者に依頼するか、"
        log_error "DevSpaces環境にGitが含まれるスタックを使用してください。"
        log_info "一時的な代替: pip3 install --user gitpython (Python用のGitライブラリ)"
    fi
else
    log_info "✓ Gitは既にインストールされています: $(git --version)"
fi

# 7. jqのインストール（ユーザー権限）
log_info "jqのインストール中..."
if ! command -v jq &> /dev/null; then
    if check_sudo; then
        sudo apt-get install -y jq
        log_info "jqインストール完了"
    else
        log_info "jqをユーザー権限でインストール中..."
        # jqの静的バイナリをダウンロード
        JQ_VERSION="1.7"
        # アーキテクチャの検出
        ARCH=$(uname -m)
        if [ "$ARCH" = "x86_64" ]; then
            JQ_ARCH="amd64"
        elif [ "$ARCH" = "aarch64" ]; then
            JQ_ARCH="arm64"
        else
            JQ_ARCH="amd64"  # デフォルト
        fi
        
        JQ_URL="https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-${JQ_ARCH}"
        
        if wget -q "${JQ_URL}" -O /tmp/jq 2>/dev/null; then
            chmod +x /tmp/jq
            mv /tmp/jq "$LOCAL_BIN/jq"
            log_info "jqインストール完了: $(jq --version 2>/dev/null || echo 'jq ${JQ_VERSION}')"
        else
            log_warn "jqのダウンロードに失敗しました（オプショナル）。"
            log_info "jqなしでもトレーニングは可能です。"
            log_info "手動インストール: wget ${JQ_URL} -O ~/.local/bin/jq && chmod +x ~/.local/bin/jq"
        fi
    fi
else
    log_info "✓ jqは既にインストールされています: $(jq --version)"
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
log_info ""
log_info "1. PATHの更新"
log_info "   新しいターミナルを開くか、以下のコマンドを実行してください:"
log_info "   source ~/.bashrc"
log_info ""
log_info "2. 認証情報の設定"
log_info "   .envファイルを作成して認証情報を設定してください:"
log_info "   cat > .env << 'EOF'"
log_info "   AWS_ACCESS_KEY_ID=your-access-key-here"
log_info "   AWS_SECRET_ACCESS_KEY=your-secret-key-here"
log_info "   AWS_DEFAULT_REGION=ap-northeast-1"
log_info "   OPENAI_API_KEY=your-openai-api-key-here"
log_info "   ANTHROPIC_API_KEY=your-anthropic-api-key-here"
log_info "   EOF"
log_info ""
log_info "   または、aws configureを使用:"
log_info "   aws configure"
log_info ""
log_info "3. インストール確認"
log_info "   以下のコマンドでツールが正しくインストールされているか確認してください:"
log_info "   terraform version"
log_info "   ansible --version"
log_info "   aws --version"
log_info ""
log_info "4. トレーニングの開始"
log_info "   docs/session_guides/session0_guide.mdを参照してトレーニングを開始してください"
log_info ""
log_info "詳細な手順は README.md または docs/setup/DEVSPACES_SETUP.md を参照してください。"
