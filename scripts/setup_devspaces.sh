#!/bin/bash

# OpenShift DevSpaces環境セットアップスクリプト
# このスクリプトは、トレーニングに必要なツールを自動的にインストールします。
# DevSpaces環境ではsudo権限がないため、ユーザー権限でインストールします。

# エラー時に停止しない（postStartフックでエラーが発生するとワークスペースが起動しないため）
set +e

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

# 3. pipのインストール確認とインストール（Ansibleのインストール前に必要）
log_info "pipの確認中..."
log_info "使用するPythonバージョン: $(python3 --version)"
if python3 -m pip --version &>/dev/null; then
    log_info "✓ pipは既にインストールされています"
    python3 -m pip install --user --upgrade pip -q || log_warn "pipのアップグレードに失敗しましたが、続行します"
else
    log_warn "pipがインストールされていません。インストールします..."
    python3 -m ensurepip --user --upgrade || {
        log_error "pipのインストールに失敗しました"
        log_error "手動でインストールしてください: python3 -m ensurepip --user"
        exit 1
    }
    log_info "pipのインストール完了"
fi

# 4. Ansibleのインストール（python3 -m pipでユーザー権限）
log_info "Ansibleのインストール中..."
if ! command -v ansible &> /dev/null; then
    # python3 -m pipでインストール（ユーザー権限、python3と同じバージョンに確実にインストール）
    python3 -m pip install --user ansible -q || {
        log_error "Ansibleのインストールに失敗しました"
        log_error "pipが正しくインストールされているか確認してください: python3 -m pip --version"
        exit 1
    }
    log_info "Ansibleインストール完了: $(ansible --version | head -n 1)"
else
    log_warn "Ansibleは既にインストールされています: $(ansible --version | head -n 1)"
fi

# 5. AWS CLIのインストール（ユーザー権限）
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

# 6. Pythonパッケージのインストール
# 重要: python3 -m pipを使用することで、python3コマンドと同じPythonバージョンに確実にインストールされます
# 注意: pipは既にセクション3でインストール済みです
log_info "Pythonパッケージのインストール中..."

if [ -f "requirements.txt" ]; then
    python3 -m pip install --user -r requirements.txt -q || {
        log_error "requirements.txtからのインストールに失敗しました"
        log_info "基本的なパッケージを個別にインストールします..."
        python3 -m pip install --user python-dotenv boto3 pyyaml jinja2 requests colorama -q
    }
    log_info "Pythonパッケージのインストール完了"
else
    log_warn "requirements.txtが見つかりません。基本的なパッケージをインストールします..."
    python3 -m pip install --user python-dotenv boto3 pyyaml jinja2 requests colorama -q || {
        log_error "Pythonパッケージのインストールに失敗しました"
        exit 1
    }
    log_info "基本的なPythonパッケージのインストール完了"
fi

# 注意: Continue AIはエディタ拡張機能なので、Pythonパッケージのインストールは不要です
# Continueの設定は .continue/config.json を参照してください

# 6-1. VS Code拡張機能のインストール（フォールバック）
# 注意: .devfile.yamlや.devcontainer/devcontainer.jsonで拡張機能が自動インストールされない場合のフォールバック
log_info "VS Code拡張機能の確認中..."
if command -v code &> /dev/null; then
    log_info "VS Code CLIが利用可能です。拡張機能のインストールを試みます..."
    
    # 必要な拡張機能のリスト
    EXTENSIONS=(
        "continue.continue"
        "hashicorp.terraform"
        "redhat.ansible"
        "amazonwebservices.aws-toolkit-vscode"
        "ms-python.python"
        "redhat.vscode-yaml"
    )
    
    INSTALLED_COUNT=0
    for EXT in "${EXTENSIONS[@]}"; do
        if code --list-extensions 2>/dev/null | grep -q "^${EXT}$"; then
            log_info "✓ 拡張機能 ${EXT} は既にインストールされています"
            ((INSTALLED_COUNT++))
        else
            log_info "拡張機能 ${EXT} をインストール中..."
            if code --install-extension "${EXT}" --force 2>/dev/null; then
                log_info "✓ 拡張機能 ${EXT} のインストールに成功しました"
                ((INSTALLED_COUNT++))
            else
                log_warn "拡張機能 ${EXT} のインストールに失敗しました（手動インストールが必要な場合があります）"
            fi
        fi
    done
    
    if [ $INSTALLED_COUNT -eq ${#EXTENSIONS[@]} ]; then
        log_info "すべての拡張機能がインストールされています"
    else
        log_warn "一部の拡張機能のインストールに失敗しました。手動でインストールしてください。"
    fi
else
    log_warn "VS Code CLI (code) が利用できません。拡張機能は手動でインストールしてください。"
    log_info "拡張機能は通常、.devfile.yamlや.devcontainer/devcontainer.jsonで自動インストールされます。"
fi

# 7. Gitの確認（通常は既にインストールされている）
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
        log_info "一時的な代替: python3 -m pip install --user gitpython (Python用のGitライブラリ)"
    fi
else
    log_info "✓ Gitは既にインストールされています: $(git --version)"
fi

# 8. jqのインストール（ユーザー権限）
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

# 9. 作業ディレクトリの作成
log_info "作業ディレクトリの作成中..."
mkdir -p ~/workspace/terraform
mkdir -p ~/workspace/ansible
mkdir -p ~/workspace/agents
log_info "作業ディレクトリの作成完了"

# 10. .envファイルのテンプレート作成
log_info ".envファイルのテンプレート作成中..."
if [ ! -f ".env" ]; then
    cat > .env.template << EOF
# AWS認証情報
AWS_ACCESS_KEY_ID=your-access-key-here
AWS_SECRET_ACCESS_KEY=your-secret-key-here
AWS_DEFAULT_REGION=ap-northeast-1

# 注意: Continue AIはエディタ拡張機能です
# Continueの設定は .continue/config.json を参照してください
# AWS Bedrockを使用する場合、AWS認証情報が環境変数に設定されている必要があります
EOF
    log_info ".env.templateファイルを作成しました。"
    log_info "次のステップ: .env.templateをコピーして.envファイルを作成し、APIキーを設定してください。"
else
    log_warn ".envファイルは既に存在します"
fi

# 10-1. .envファイルの自動読み込み設定を~/.bashrcに追加
log_info ".envファイルの自動読み込み設定を追加中..."
ENV_AUTO_LOAD="# .envファイルを自動的に読み込む（プロジェクトディレクトリにいる場合）
if [ -f .env ]; then
    export \$(cat .env | grep -v '^#' | xargs)
fi"

# 既に設定が存在するかチェック
if ! grep -q "# .envファイルを自動的に読み込む" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    echo "$ENV_AUTO_LOAD" >> ~/.bashrc
    log_info "✓ .envファイルの自動読み込み設定を~/.bashrcに追加しました"
    log_info "  新しいターミナルを開くか、source ~/.bashrcを実行すると有効になります"
else
    log_warn ".envファイルの自動読み込み設定は既に存在します"
fi

# 11. 動作確認
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
log_info "次のステップは README.md を参照してください。"
