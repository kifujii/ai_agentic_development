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
    # Terraform 1.6.0: ワークショップで使用する機能（VPC, EC2, ALB, ECS, RDS, IAM）に十分な安定バージョン
    # バージョン更新時はプロバイダ互換性を確認してください
    TERRAFORM_VERSION="1.14.6"
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

# 6. Node.js / npm の確認
log_info "Node.js / npm の確認中..."
if command -v node &> /dev/null && command -v npm &> /dev/null; then
    log_info "✓ Node.js は既にインストールされています: $(node --version)"
    log_info "✓ npm は既にインストールされています: $(npm --version)"
else
    log_warn "Node.js / npm がインストールされていません。"
    log_info "Node.js のインストールを試みます..."
    # nvm経由でインストール
    if [ ! -d "$HOME/.nvm" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    fi
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm install --lts || {
        log_error "Node.js のインストールに失敗しました"
        log_error "手動でインストールしてください: https://nodejs.org/"
        exit 1
    }
    log_info "Node.js インストール完了: $(node --version)"
fi

# 6-1. Claude Code のインストール（npm グローバル）
log_info "Claude Code のインストール中..."
if command -v claude &> /dev/null; then
    log_info "✓ Claude Code は既にインストールされています: $(claude --version 2>/dev/null || echo '(バージョン取得不可)')"
else
    npm install -g @anthropic-ai/claude-code || {
        log_error "Claude Code のインストールに失敗しました"
        log_error "手動でインストールしてください: npm install -g @anthropic-ai/claude-code"
        exit 1
    }
    log_info "✓ Claude Code インストール完了"
fi

# 6-2. Claude Code の Bedrock 設定案内
log_info "Claude Code の設定について:"
log_info "  Claude Code は AWS Bedrock 経由で Claude Sonnet 4.6 を使用します。"
log_info "  .env ファイルに以下の環境変数が設定されていることを確認してください:"
log_info "    - CLAUDE_CODE_USE_BEDROCK=1"
log_info "    - AWS_REGION=ap-northeast-1"
log_info "    - ANTHROPIC_MODEL=anthropic.claude-sonnet-4-6-20250514-v1:0"
log_info "  詳細は docs/setup/CLAUDE_CODE_SETUP.md を参照してください。"

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

# 9. 作業ディレクトリの作成（プロジェクトルート配下）
log_info "作業ディレクトリの作成中..."
PROJECT_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "${PROJECT_ROOT_DIR}/terraform"
mkdir -p "${PROJECT_ROOT_DIR}/ansible"
log_info "作業ディレクトリの作成完了（${PROJECT_ROOT_DIR}/terraform, ${PROJECT_ROOT_DIR}/ansible）"

# 10. .envファイルの確認
log_info ".envファイルの確認中..."
if [ ! -f ".env" ]; then
    if [ -f ".env.template" ]; then
        log_info ".env.templateファイルが見つかりました。"
        log_info "次のステップ: .env.templateをコピーして.envファイルを作成し、AWS認証情報を設定してください。"
        log_info "  コマンド: cp .env.template .env"
    else
        log_warn ".env.templateファイルが見つかりません。"
        log_info ".envファイルを手動で作成し、AWS認証情報を設定してください。"
    fi
else
    log_info ".envファイルは既に存在します"
fi

# 10-1. .envファイルの自動読み込み設定を~/.bashrcに追加
log_info ".envファイルの自動読み込み設定を追加中..."
ENV_AUTO_LOAD="# .envファイルを自動的に読み込む（プロジェクトディレクトリの場合のみ）
if [ -f \"${PROJECT_ROOT_DIR}/.env\" ]; then
    set -a
    source \"${PROJECT_ROOT_DIR}/.env\"
    set +a
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


# 10-3. AWS CLI設定ファイルを作成（Claude CodeとAWS CLI用）
log_info "AWS CLI設定ファイルを作成中（.envファイルから自動設定）..."
if [ -f ".env" ]; then
    # .envファイルからAWS認証情報を抽出
    AWS_ACCESS_KEY=$(grep "^AWS_ACCESS_KEY_ID=" .env | grep -v '^#' | cut -d'=' -f2 | sed "s/^['\"]//;s/['\"]$//" | head -1)
    AWS_SECRET_KEY=$(grep "^AWS_SECRET_ACCESS_KEY=" .env | grep -v '^#' | cut -d'=' -f2 | sed "s/^['\"]//;s/['\"]$//" | head -1)
    AWS_REGION=$(grep "^AWS_DEFAULT_REGION=" .env | grep -v '^#' | cut -d'=' -f2 | sed "s/^['\"]//;s/['\"]$//" | head -1)
    
    if [ -n "$AWS_ACCESS_KEY" ] && [ -n "$AWS_SECRET_KEY" ] && [ "$AWS_ACCESS_KEY" != "your-access-key-here" ] && [ "$AWS_SECRET_KEY" != "your-secret-key-here" ]; then
        # ~/.awsディレクトリを作成
        mkdir -p ~/.aws
        
        # credentialsファイルを作成または更新
        if [ ! -f ~/.aws/credentials ] || ! grep -q "\[default\]" ~/.aws/credentials 2>/dev/null; then
            cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = ${AWS_ACCESS_KEY}
aws_secret_access_key = ${AWS_SECRET_KEY}
EOF
            log_info "✓ AWS認証情報ファイルを作成しました: ~/.aws/credentials"
        else
            # 既存の[default]セクションを更新
            if grep -q "\[default\]" ~/.aws/credentials; then
                # 一時ファイルに書き込んでから置き換え
                awk -v access_key="$AWS_ACCESS_KEY" -v secret_key="$AWS_SECRET_KEY" '
                    /\[default\]/ { in_default=1; print; next }
                    in_default && /^\[/ { in_default=0 }
                    in_default && /^aws_access_key_id/ { print "aws_access_key_id = " access_key; next }
                    in_default && /^aws_secret_access_key/ { print "aws_secret_access_key = " secret_key; next }
                    { print }
                ' ~/.aws/credentials > ~/.aws/credentials.tmp && mv ~/.aws/credentials.tmp ~/.aws/credentials
                log_info "✓ AWS認証情報ファイルを更新しました: ~/.aws/credentials"
            fi
        fi
        
        # configファイルを作成または更新
        if [ -n "$AWS_REGION" ]; then
            if [ ! -f ~/.aws/config ]; then
                cat > ~/.aws/config << EOF
[default]
region = ${AWS_REGION}
EOF
                log_info "✓ AWS設定ファイルを作成しました: ~/.aws/config"
            else
                if ! grep -q "\[default\]" ~/.aws/config; then
                    echo "" >> ~/.aws/config
                    echo "[default]" >> ~/.aws/config
                    echo "region = ${AWS_REGION}" >> ~/.aws/config
                    log_info "✓ AWS設定ファイルにリージョンを追加しました: ~/.aws/config"
                fi
            fi
        fi
    else
        log_warn ".envファイルに有効なAWS認証情報が設定されていません（テンプレートのままの可能性があります）"
    fi
else
    log_warn ".envファイルが存在しないため、AWS CLI設定ファイルの作成をスキップします"
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

if command -v claude &> /dev/null; then
    log_info "✓ Claude Code: インストール済み"
else
    log_error "✗ Claude Code: インストールされていません"
fi

echo ""
log_info "=========================================="
log_info "セットアップ完了！"
log_info "=========================================="
