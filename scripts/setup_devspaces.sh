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

# プロジェクトルートの取得
PROJECT_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ==============================================================
# 0. .envファイルの確認と AWS認証情報の早期セットアップ
# ==============================================================
# .envファイルが先に作成されていれば、ツールインストール後の
# Claude Code設定（AWSアカウントID取得）まで1回の実行で完結します。
log_info ".envファイルの確認中..."
AWS_CREDENTIALS_READY=false

ENV_FILE="${PROJECT_ROOT_DIR}/.env"
ENV_TEMPLATE="${PROJECT_ROOT_DIR}/.env.template"

if [ ! -f "$ENV_FILE" ]; then
    if [ -f "$ENV_TEMPLATE" ]; then
        log_warn ".envファイルが見つかりません。"
        log_info "先に .env ファイルを作成してからスクリプトを実行すると、1回で全セットアップが完了します。"
        log_info "  コマンド: cp .env.template .env"
        log_info "  その後、.env を編集してAWS認証情報を設定してください。"
    else
        log_warn ".env.templateファイルが見つかりません。"
        log_info ".envファイルを手動で作成し、AWS認証情報を設定してください。"
    fi
else
    log_info "✓ .envファイルが見つかりました。AWS認証情報を読み込みます..."

    # .envファイルからAWS認証情報を抽出
    AWS_ACCESS_KEY=$(grep "^AWS_ACCESS_KEY_ID=" "$ENV_FILE" | grep -v '^#' | cut -d'=' -f2 | sed "s/^['\"]//;s/['\"]$//" | head -1)
    AWS_SECRET_KEY=$(grep "^AWS_SECRET_ACCESS_KEY=" "$ENV_FILE" | grep -v '^#' | cut -d'=' -f2 | sed "s/^['\"]//;s/['\"]$//" | head -1)
    AWS_REGION_ENV=$(grep "^AWS_DEFAULT_REGION=" "$ENV_FILE" | grep -v '^#' | cut -d'=' -f2 | sed "s/^['\"]//;s/['\"]$//" | head -1)

    if [ -n "$AWS_ACCESS_KEY" ] && [ -n "$AWS_SECRET_KEY" ] && [ "$AWS_ACCESS_KEY" != "your-access-key-here" ] && [ "$AWS_SECRET_KEY" != "your-secret-key-here" ]; then
        # 環境変数にエクスポート（このスクリプト内で aws コマンドが使えるようにする）
        export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY"
        export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_KEY"
        [ -n "$AWS_REGION_ENV" ] && export AWS_DEFAULT_REGION="$AWS_REGION_ENV"

        # ~/.aws/credentials ファイルの作成・更新
        mkdir -p ~/.aws
        if [ ! -f ~/.aws/credentials ] || ! grep -q "\[default\]" ~/.aws/credentials 2>/dev/null; then
            cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = ${AWS_ACCESS_KEY}
aws_secret_access_key = ${AWS_SECRET_KEY}
EOF
            log_info "✓ AWS認証情報ファイルを作成しました: ~/.aws/credentials"
        else
            awk -v access_key="$AWS_ACCESS_KEY" -v secret_key="$AWS_SECRET_KEY" '
                /\[default\]/ { in_default=1; print; next }
                in_default && /^\[/ { in_default=0 }
                in_default && /^aws_access_key_id/ { print "aws_access_key_id = " access_key; next }
                in_default && /^aws_secret_access_key/ { print "aws_secret_access_key = " secret_key; next }
                { print }
            ' ~/.aws/credentials > ~/.aws/credentials.tmp && mv ~/.aws/credentials.tmp ~/.aws/credentials
            log_info "✓ AWS認証情報ファイルを更新しました: ~/.aws/credentials"
        fi

        # ~/.aws/config ファイルの作成・更新
        if [ -n "$AWS_REGION_ENV" ]; then
            if [ ! -f ~/.aws/config ]; then
                cat > ~/.aws/config << EOF
[default]
region = ${AWS_REGION_ENV}
EOF
                log_info "✓ AWS設定ファイルを作成しました: ~/.aws/config"
            else
                if ! grep -q "\[default\]" ~/.aws/config; then
                    echo "" >> ~/.aws/config
                    echo "[default]" >> ~/.aws/config
                    echo "region = ${AWS_REGION_ENV}" >> ~/.aws/config
                    log_info "✓ AWS設定ファイルにリージョンを追加しました: ~/.aws/config"
                fi
            fi
        fi

        AWS_CREDENTIALS_READY=true
        log_info "✓ AWS認証情報のセットアップが完了しました"
    else
        log_warn ".envファイルに有効なAWS認証情報が設定されていません（テンプレートのままの可能性があります）"
        log_info ".envファイルを編集してAWS認証情報を設定してください。"
    fi
fi

# .envファイルの自動読み込み設定を~/.bashrcに追加
log_info ".envファイルの自動読み込み設定を確認中..."
ENV_AUTO_LOAD="# .envファイルを自動的に読み込む（プロジェクトディレクトリの場合のみ）
if [ -f \"${PROJECT_ROOT_DIR}/.env\" ]; then
    set -a
    source \"${PROJECT_ROOT_DIR}/.env\"
    set +a
fi"

if ! grep -q "# .envファイルを自動的に読み込む" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    echo "$ENV_AUTO_LOAD" >> ~/.bashrc
    log_info "✓ .envファイルの自動読み込み設定を~/.bashrcに追加しました"
else
    log_info "✓ .envファイルの自動読み込み設定は既に存在します"
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

# 3. pipのインストール確認とアップグレード（Ansibleのインストール前に必要）
log_info "pipの確認中..."
log_info "使用するPythonバージョン: $(python3 --version)"
if python3 -m pip --version &>/dev/null; then
    log_info "✓ pipは既にインストールされています: $(python3 -m pip --version)"
    # pipをアップグレード（古いpipは依存解決が遅いため、先にアップグレードする）
    log_info "pipをアップグレード中..."
    python3 -m pip install --user --upgrade pip || log_warn "pipのアップグレードに失敗しましたが、続行します"
    # アップグレード後のバージョンを確認
    # --user でインストールしたpipを確実に使うため、ハッシュテーブルをリフレッシュ
    hash -r 2>/dev/null
    log_info "pipバージョン（アップグレード後）: $(python3 -m pip --version)"
else
    log_warn "pipがインストールされていません。インストールします..."
    python3 -m ensurepip --user --upgrade || {
        log_error "pipのインストールに失敗しました"
        log_error "手動でインストールしてください: python3 -m ensurepip --user"
        exit 1
    }
    # インストール直後にアップグレード
    python3 -m pip install --user --upgrade pip || log_warn "pipのアップグレードに失敗しましたが、続行します"
    hash -r 2>/dev/null
    log_info "pipのインストール完了: $(python3 -m pip --version)"
fi

# 4. Ansibleのインストール（python3 -m pipでユーザー権限）
log_info "Ansibleのインストール中..."
if ! command -v ansible &> /dev/null; then
    # python3 -m pipでインストール（ユーザー権限、python3と同じバージョンに確実にインストール）
    python3 -m pip install --user ansible || {
        log_error "Ansibleのインストールに失敗しました"
        log_error "pipが正しくインストールされているか確認してください: python3 -m pip --version"
        exit 1
    }
    hash -r 2>/dev/null
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

# 6-1. npm グローバルインストール先をユーザーディレクトリに設定
# DevSpaces環境ではsudo権限がなく /usr/local/lib/node_modules に書き込めないため、
# npm のグローバルインストール先を ~/.local に変更する
NPM_GLOBAL_PREFIX="$HOME/.local"
CURRENT_PREFIX="$(npm config get prefix 2>/dev/null)"
if [ "$CURRENT_PREFIX" != "$NPM_GLOBAL_PREFIX" ]; then
    log_info "npm のグローバルインストール先を ${NPM_GLOBAL_PREFIX} に設定中..."
    npm config set prefix "$NPM_GLOBAL_PREFIX"
    log_info "✓ npm prefix を ${NPM_GLOBAL_PREFIX} に設定しました"
fi

# 6-2. Claude Code のインストール（npm グローバル → ~/.local/bin）
log_info "Claude Code のインストール中..."
if command -v claude &> /dev/null; then
    log_info "✓ Claude Code は既にインストールされています: $(claude --version 2>/dev/null || echo '(バージョン取得不可)')"
else
    npm install -g @anthropic-ai/claude-code || {
        log_error "Claude Code のインストールに失敗しました"
        log_error "手動でインストールしてください:"
        log_error "  npm config set prefix \"\$HOME/.local\""
        log_error "  npm install -g @anthropic-ai/claude-code"
        exit 1
    }
    hash -r 2>/dev/null
    log_info "✓ Claude Code インストール完了"
fi

# 6-3. Claude Code の Bedrock 設定ファイル作成
log_info "Claude Code の Bedrock 設定ファイルを確認中..."
CLAUDE_SETTINGS_DIR="${PROJECT_ROOT_DIR}/.claude"
CLAUDE_SETTINGS_FILE="${CLAUDE_SETTINGS_DIR}/settings.local.json"

mkdir -p "$CLAUDE_SETTINGS_DIR"

if [ -f "$CLAUDE_SETTINGS_FILE" ]; then
    log_info "✓ Claude Code 設定ファイルは既に存在します: ${CLAUDE_SETTINGS_FILE}"
else
    # AWSアカウントIDを取得して設定ファイルを自動生成
    AWS_ACCOUNT_ID=""
    if [ "$AWS_CREDENTIALS_READY" = true ] && command -v aws &> /dev/null; then
        AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
    fi

    if [ -n "$AWS_ACCOUNT_ID" ]; then
        cat > "$CLAUDE_SETTINGS_FILE" << JSONEOF
{
    "env": {
        "CLAUDE_CODE_ENABLE_TELEMETRY": "false",
        "CLAUDE_CODE_USE_BEDROCK": "true",
        "AWS_REGION": "ap-northeast-1",
        "ANTHROPIC_MODEL": "arn:aws:bedrock:ap-northeast-1:${AWS_ACCOUNT_ID}:inference-profile/jp.anthropic.claude-sonnet-4-6"
    }
}
JSONEOF
        log_info "✓ Claude Code 設定ファイルを作成しました: ${CLAUDE_SETTINGS_FILE}"
        log_info "  モデル: Claude Sonnet 4.6（Bedrock inference profile）"
        log_info "  AWSアカウントID: ${AWS_ACCOUNT_ID}"
    else
        log_warn "AWSアカウントIDを取得できませんでした。"
        log_warn "AWS認証情報を設定後、セットアップスクリプトを再実行するか、"
        log_warn "手動で ${CLAUDE_SETTINGS_FILE} を作成してください。"
        log_info "  詳細は docs/setup/CLAUDE_CODE_SETUP.md を参照してください。"
    fi
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

# 8. 作業ディレクトリの作成（プロジェクトルート配下）
log_info "作業ディレクトリの作成中..."
mkdir -p "${PROJECT_ROOT_DIR}/terraform"
mkdir -p "${PROJECT_ROOT_DIR}/ansible"
log_info "作業ディレクトリの作成完了（${PROJECT_ROOT_DIR}/terraform, ${PROJECT_ROOT_DIR}/ansible）"

# 9. 動作確認
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

if [ -f "$CLAUDE_SETTINGS_FILE" ]; then
    log_info "✓ Claude Code Bedrock設定: ${CLAUDE_SETTINGS_FILE}"
else
    log_warn "✗ Claude Code Bedrock設定: 未作成（AWS認証情報を設定後、スクリプトを再実行してください）"
fi

if [ -f ~/.aws/credentials ]; then
    log_info "✓ AWS CLI設定: ~/.aws/credentials"
else
    log_warn "✗ AWS CLI設定: 未作成（.envファイルにAWS認証情報を設定後、スクリプトを再実行してください）"
fi

echo ""
log_info "=========================================="
log_info "セットアップ完了！"
log_info "=========================================="

if [ "$AWS_CREDENTIALS_READY" != true ]; then
    echo ""
    log_info "【次のステップ】"
    log_info "  1. cd ${PROJECT_ROOT_DIR} && cp .env.template .env"
    log_info "  2. .env を編集してAWS認証情報を設定"
    log_info "  3. ./scripts/setup_devspaces.sh を再実行"
    log_info "  → AWS CLI設定とClaude Code Bedrock設定が自動作成されます"
fi
