#!/bin/bash
# Continue認証情報の診断スクリプト

LOG_FILE="/home/kifujii/Desktop/projects/NIT/ai_agentic/.cursor/debug.log"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ログ関数
log_debug() {
    local hypothesis_id="$1"
    local location="$2"
    local message="$3"
    local data="$4"
    local timestamp=$(date +%s%3N)
    
    # NDJSON形式でログを書き込む
    echo "{\"id\":\"log_${timestamp}_${RANDOM}\",\"timestamp\":${timestamp},\"location\":\"${location}\",\"message\":\"${message}\",\"data\":${data},\"runId\":\"diagnosis\",\"hypothesisId\":\"${hypothesis_id}\"}" >> "$LOG_FILE"
}

# ログファイルをクリア
> "$LOG_FILE"

echo "=========================================="
echo "Continue認証情報の診断を開始します"
echo "=========================================="
echo ""

# 仮説A: .envファイルの存在と内容を確認
echo "[仮説A] .envファイルの存在と内容を確認中..."
ENV_FILE="${PROJECT_ROOT}/.env"
if [ -f "$ENV_FILE" ]; then
    echo "✓ .envファイルが存在します: $ENV_FILE"
    # 環境変数の存在を確認（値は表示しない）
    if grep -q "AWS_ACCESS_KEY_ID=" "$ENV_FILE" && ! grep -q "AWS_ACCESS_KEY_ID=your-access-key-here" "$ENV_FILE"; then
        echo "  ✓ AWS_ACCESS_KEY_IDが設定されています"
        HAS_ACCESS_KEY=true
    else
        echo "  ✗ AWS_ACCESS_KEY_IDが設定されていません（またはテンプレートのまま）"
        HAS_ACCESS_KEY=false
    fi
    
    if grep -q "AWS_SECRET_ACCESS_KEY=" "$ENV_FILE" && ! grep -q "AWS_SECRET_ACCESS_KEY=your-secret-key-here" "$ENV_FILE"; then
        echo "  ✓ AWS_SECRET_ACCESS_KEYが設定されています"
        HAS_SECRET_KEY=true
    else
        echo "  ✗ AWS_SECRET_ACCESS_KEYが設定されていません（またはテンプレートのまま）"
        HAS_SECRET_KEY=false
    fi
    
    if grep -q "AWS_DEFAULT_REGION=" "$ENV_FILE"; then
        REGION=$(grep "^AWS_DEFAULT_REGION=" "$ENV_FILE" | cut -d'=' -f2 | tr -d '"' | tr -d "'")
        echo "  ✓ AWS_DEFAULT_REGION: $REGION"
    else
        echo "  ✗ AWS_DEFAULT_REGIONが設定されていません"
        REGION=""
    fi
    
    log_debug "A" "debug_continue_credentials.sh:ENV_FILE_CHECK" ".envファイルの確認" "{\"exists\":true,\"hasAccessKey\":${HAS_ACCESS_KEY},\"hasSecretKey\":${HAS_SECRET_KEY},\"region\":\"${REGION}\"}"
else
    echo "✗ .envファイルが存在しません: $ENV_FILE"
    log_debug "A" "debug_continue_credentials.sh:ENV_FILE_CHECK" ".envファイルの確認" "{\"exists\":false}"
fi
echo ""

# 仮説B: 現在のシェル環境変数の状態を確認
echo "[仮説B] 現在のシェル環境変数の状態を確認中..."
if [ -n "${AWS_ACCESS_KEY_ID}" ]; then
    echo "  ✓ AWS_ACCESS_KEY_IDが設定されています（長さ: ${#AWS_ACCESS_KEY_ID}文字）"
    HAS_ENV_ACCESS_KEY=true
else
    echo "  ✗ AWS_ACCESS_KEY_IDが設定されていません"
    HAS_ENV_ACCESS_KEY=false
fi

if [ -n "${AWS_SECRET_ACCESS_KEY}" ]; then
    echo "  ✓ AWS_SECRET_ACCESS_KEYが設定されています（長さ: ${#AWS_SECRET_ACCESS_KEY}文字）"
    HAS_ENV_SECRET_KEY=true
else
    echo "  ✗ AWS_SECRET_ACCESS_KEYが設定されていません"
    HAS_ENV_SECRET_KEY=false
fi

if [ -n "${AWS_DEFAULT_REGION}" ]; then
    echo "  ✓ AWS_DEFAULT_REGION: ${AWS_DEFAULT_REGION}"
    ENV_REGION="${AWS_DEFAULT_REGION}"
else
    echo "  ✗ AWS_DEFAULT_REGIONが設定されていません"
    ENV_REGION=""
fi

log_debug "B" "debug_continue_credentials.sh:ENV_VARS_CHECK" "環境変数の確認" "{\"hasAccessKey\":${HAS_ENV_ACCESS_KEY},\"hasSecretKey\":${HAS_ENV_SECRET_KEY},\"region\":\"${ENV_REGION}\"}"
echo ""

# 仮説C: AWS CLI設定ファイルの確認
echo "[仮説C] AWS CLI設定ファイルの確認中..."
AWS_CREDENTIALS_FILE="${HOME}/.aws/credentials"
AWS_CONFIG_FILE="${HOME}/.aws/config"

if [ -f "$AWS_CREDENTIALS_FILE" ]; then
    echo "  ✓ AWS認証情報ファイルが存在します: $AWS_CREDENTIALS_FILE"
    if grep -q "aws_access_key_id" "$AWS_CREDENTIALS_FILE"; then
        echo "    ✓ aws_access_key_idが設定されています"
        HAS_AWS_CLI_CRED=true
    else
        echo "    ✗ aws_access_key_idが設定されていません"
        HAS_AWS_CLI_CRED=false
    fi
    log_debug "C" "debug_continue_credentials.sh:AWS_CLI_CHECK" "AWS CLI設定ファイルの確認" "{\"credentialsExists\":true,\"hasCredentials\":${HAS_AWS_CLI_CRED}}"
else
    echo "  ✗ AWS認証情報ファイルが存在しません: $AWS_CREDENTIALS_FILE"
    log_debug "C" "debug_continue_credentials.sh:AWS_CLI_CHECK" "AWS CLI設定ファイルの確認" "{\"credentialsExists\":false}"
fi

if [ -f "$AWS_CONFIG_FILE" ]; then
    echo "  ✓ AWS設定ファイルが存在します: $AWS_CONFIG_FILE"
    if grep -q "region" "$AWS_CONFIG_FILE"; then
        AWS_CLI_REGION=$(grep "^region" "$AWS_CONFIG_FILE" | head -1 | awk '{print $3}')
        echo "    ✓ region: $AWS_CLI_REGION"
    else
        echo "    ✗ regionが設定されていません"
        AWS_CLI_REGION=""
    fi
else
    echo "  ✗ AWS設定ファイルが存在しません: $AWS_CONFIG_FILE"
    AWS_CLI_REGION=""
fi
echo ""

# 仮説D: VS Code設定ファイルの確認
echo "[仮説D] VS Code設定ファイルの確認中..."
VSCODE_SETTINGS="${PROJECT_ROOT}/.vscode/settings.json"
if [ -f "$VSCODE_SETTINGS" ]; then
    echo "  ✓ .vscode/settings.jsonが存在します"
    if grep -q "AWS_ACCESS_KEY_ID" "$VSCODE_SETTINGS" || grep -q "env" "$VSCODE_SETTINGS"; then
        echo "    ✓ 環境変数の設定が含まれています"
        HAS_VSCODE_ENV=true
    else
        echo "    ✗ 環境変数の設定が含まれていません"
        HAS_VSCODE_ENV=false
    fi
    log_debug "D" "debug_continue_credentials.sh:VSCODE_SETTINGS_CHECK" "VS Code設定ファイルの確認" "{\"exists\":true,\"hasEnv\":${HAS_VSCODE_ENV}}"
else
    echo "  ✗ .vscode/settings.jsonが存在しません"
    log_debug "D" "debug_continue_credentials.sh:VSCODE_SETTINGS_CHECK" "VS Code設定ファイルの確認" "{\"exists\":false}"
fi
echo ""

# 仮説E: Continue設定ファイルの確認
echo "[仮説E] Continue設定ファイルの確認中..."
CONTINUE_CONFIG="${PROJECT_ROOT}/.continue/config.json"
USER_CONTINUE_CONFIG="${HOME}/.continue/config.json"

if [ -f "$CONTINUE_CONFIG" ]; then
    echo "  ✓ プロジェクトルートの設定ファイルが存在します: $CONTINUE_CONFIG"
    if grep -q '"provider": "bedrock"' "$CONTINUE_CONFIG"; then
        echo "    ✓ provider: bedrockが設定されています"
        if grep -q '"credentialsProvider": "default"' "$CONTINUE_CONFIG"; then
            echo "    ✓ credentialsProvider: defaultが設定されています"
        else
            echo "    ✗ credentialsProviderが設定されていません"
        fi
    else
        echo "    ✗ provider: bedrockが設定されていません"
    fi
    log_debug "E" "debug_continue_credentials.sh:CONTINUE_CONFIG_CHECK" "Continue設定ファイルの確認" "{\"projectConfigExists\":true}"
else
    echo "  ✗ プロジェクトルートの設定ファイルが存在しません: $CONTINUE_CONFIG"
    log_debug "E" "debug_continue_credentials.sh:CONTINUE_CONFIG_CHECK" "Continue設定ファイルの確認" "{\"projectConfigExists\":false}"
fi

if [ -L "$USER_CONTINUE_CONFIG" ]; then
    LINK_TARGET=$(readlink -f "$USER_CONTINUE_CONFIG" 2>/dev/null || readlink "$USER_CONTINUE_CONFIG")
    echo "  ✓ /home/user/.continue/config.jsonがシンボリックリンクです: -> $LINK_TARGET"
    if [ "$LINK_TARGET" = "$CONTINUE_CONFIG" ]; then
        echo "    ✓ リンク先が正しいです"
    else
        echo "    ✗ リンク先が正しくありません"
    fi
elif [ -f "$USER_CONTINUE_CONFIG" ]; then
    echo "  ✓ /home/user/.continue/config.jsonが通常のファイルです"
else
    echo "  ✗ /home/user/.continue/config.jsonが存在しません"
fi
echo ""

# 診断結果のサマリー
echo "=========================================="
echo "診断結果サマリー"
echo "=========================================="
echo "ログファイル: $LOG_FILE"
echo ""
echo "次のステップ:"
if [ "$HAS_ENV_ACCESS_KEY" = "false" ] || [ "$HAS_ENV_SECRET_KEY" = "false" ]; then
    echo "1. .envファイルを確認し、AWS認証情報を設定してください"
    echo "2. VS Code設定ファイル（.vscode/settings.json）に環境変数を追加する必要があります"
fi
if [ "$HAS_VSCODE_ENV" = "false" ]; then
    echo "3. VS Code設定ファイルに環境変数を追加してください"
fi
echo ""
