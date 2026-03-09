#!/bin/bash

# ハンズオン環境セットアップスクリプト
# ツール類（Terraform, Ansible, AWS CLI, Claude Code）はプリインストール済みの前提です。
# このスクリプトは .env の PREFIX を読み取って環境変数を設定し、動作確認を行います。

set +e

echo "=========================================="
echo "ハンズオン環境セットアップ開始"
echo "=========================================="

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

PROJECT_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ==============================================================
# 1. .envファイルの確認と PREFIX の設定
# ==============================================================
log_info ".envファイルの確認中..."

ENV_FILE="${PROJECT_ROOT_DIR}/.env"
ENV_TEMPLATE="${PROJECT_ROOT_DIR}/.env.template"

if [ ! -f "$ENV_FILE" ]; then
    if [ -f "$ENV_TEMPLATE" ]; then
        log_warn ".envファイルが見つかりません。テンプレートからコピーします..."
        cp "$ENV_TEMPLATE" "$ENV_FILE"
        log_info "✓ .env ファイルを作成しました。PREFIX を自分のユーザー名に変更してください。"
        log_info "  コマンド: vi .env"
    else
        log_error ".env.template が見つかりません。"
        exit 1
    fi
fi

PREFIX_ENV=$(grep "^PREFIX=" "$ENV_FILE" 2>/dev/null | grep -v '^#' | cut -d'=' -f2 | sed "s/^['\"]//;s/['\"]$//" | head -1)

if [ -n "$PREFIX_ENV" ]; then
    export PREFIX="$PREFIX_ENV"
    export TF_VAR_prefix="$PREFIX_ENV"
    if [ "$PREFIX_ENV" = "user01" ]; then
        log_warn "PREFIX がデフォルト値（user01）のままです。他の受講者と区別するために変更してください。"
    else
        log_info "✓ PREFIX が設定されました: $PREFIX_ENV"
    fi
else
    log_warn "PREFIX が設定されていません。.env ファイルに PREFIX を設定してください。"
fi

# .env の自動読み込み設定を ~/.bashrc に追加
log_info ".env ファイルの自動読み込み設定を確認中..."
ENV_AUTO_LOAD="# .envファイルを自動的に読み込む
if [ -f \"${PROJECT_ROOT_DIR}/.env\" ]; then
    set -a
    source \"${PROJECT_ROOT_DIR}/.env\"
    set +a
    [ -n \"\${PREFIX:-}\" ] && export TF_VAR_prefix=\"\$PREFIX\"
fi"

if ! grep -q "# .envファイルを自動的に読み込む" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    echo "$ENV_AUTO_LOAD" >> ~/.bashrc
    log_info "✓ .env ファイルの自動読み込み設定を ~/.bashrc に追加しました"
else
    log_info "✓ .env ファイルの自動読み込み設定は既に存在します"
fi

# ==============================================================
# 2. 作業ディレクトリの作成
# ==============================================================
log_info "作業ディレクトリの作成中..."
mkdir -p "${PROJECT_ROOT_DIR}/terraform"
mkdir -p "${PROJECT_ROOT_DIR}/ansible"
mkdir -p "${PROJECT_ROOT_DIR}/keys"
log_info "✓ 作業ディレクトリを作成しました"

# ==============================================================
# 3. 動作確認
# ==============================================================
echo ""
log_info "=========================================="
log_info "インストール済みツールの確認"
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

if command -v claude &> /dev/null; then
    log_info "✓ Claude Code: インストール済み"
else
    log_error "✗ Claude Code: インストールされていません"
fi

if command -v git &> /dev/null; then
    log_info "✓ Git: $(git --version)"
else
    log_error "✗ Git: インストールされていません"
fi

# AWS 認証確認
log_info "AWS 認証情報の確認中..."
CALLER_IDENTITY=$(aws sts get-caller-identity 2>/dev/null)
if [ $? -eq 0 ]; then
    ACCOUNT_ID=$(echo "$CALLER_IDENTITY" | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
    ARN=$(echo "$CALLER_IDENTITY" | grep -o '"Arn": "[^"]*"' | cut -d'"' -f4)
    log_info "✓ AWS 認証OK (Account: $ACCOUNT_ID, Arn: $ARN)"
else
    log_error "✗ AWS 認証が通りません。講師に確認してください。"
fi

# Claude Code Bedrock 設定の確認
CLAUDE_SETTINGS_FILE="${PROJECT_ROOT_DIR}/.claude/settings.local.json"
if [ -f "$CLAUDE_SETTINGS_FILE" ]; then
    log_info "✓ Claude Code Bedrock 設定: ${CLAUDE_SETTINGS_FILE}"
else
    log_warn "✗ Claude Code Bedrock 設定が見つかりません: ${CLAUDE_SETTINGS_FILE}"
    log_warn "  講師に確認してください。"
fi

if [ -n "${PREFIX:-}" ]; then
    log_info "✓ PREFIX: $PREFIX（TF_VAR_prefix=$PREFIX）"
else
    log_warn "✗ PREFIX: 未設定（.env ファイルに PREFIX を設定してください）"
fi

echo ""
log_info "=========================================="
log_info "セットアップ完了！"
log_info "=========================================="

if [ "${PREFIX_ENV:-user01}" = "user01" ]; then
    echo ""
    log_info "【次のステップ】"
    log_info "  1. .env を編集して PREFIX を自分のユーザー名に変更"
    log_info "  2. source ~/.bashrc を実行して環境変数を反映"
fi
