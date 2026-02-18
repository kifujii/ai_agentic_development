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

# 6-1. VS Code拡張機能のインストール（CLI経由）
log_info "VS Code拡張機能のインストール中..."

# code-ossコマンドのパスを探す（複数のパスを試す）
CODE_CMD=""
for CODE_PATH in "/usr/bin/code-oss" "/usr/local/bin/code-oss" "$HOME/.local/bin/code-oss" "code-oss" "/usr/bin/code" "/usr/local/bin/code" "$HOME/.local/bin/code" "code"; do
    if command -v "$CODE_PATH" &> /dev/null; then
        CODE_CMD="$CODE_PATH"
        break
    fi
done

if [ -n "$CODE_CMD" ]; then
    log_info "VS Code CLIが見つかりました: $CODE_CMD"
    
    # 必要な拡張機能のリスト（Continueのみ）
    EXTENSIONS=(
        "continue.continue"
    )
    
    INSTALLED_COUNT=0
    FAILED_EXTENSIONS=()
    
    for EXT in "${EXTENSIONS[@]}"; do
        # 既にインストールされているか確認
        if "$CODE_CMD" --list-extensions 2>/dev/null | grep -q "^${EXT}$"; then
            log_info "✓ 拡張機能 ${EXT} は既にインストールされています"
            ((INSTALLED_COUNT++))
        else
            log_info "拡張機能 ${EXT} をインストール中..."
            # リトライ処理（最大3回）
            RETRY_COUNT=0
            MAX_RETRIES=3
            INSTALL_SUCCESS=false
            
            while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
                if "$CODE_CMD" --install-extension "${EXT}" --force 2>/dev/null; then
                    log_info "✓ 拡張機能 ${EXT} のインストールに成功しました"
                    ((INSTALLED_COUNT++))
                    INSTALL_SUCCESS=true
                    break
                else
                    ((RETRY_COUNT++))
                    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                        log_warn "拡張機能 ${EXT} のインストールに失敗しました（リトライ ${RETRY_COUNT}/${MAX_RETRIES}）"
                        sleep 2
                    fi
                fi
            done
            
            if [ "$INSTALL_SUCCESS" = false ]; then
                log_warn "拡張機能 ${EXT} のインストールに失敗しました（最大リトライ回数に達しました）"
                FAILED_EXTENSIONS+=("${EXT}")
            fi
        fi
    done
    
    # 結果のサマリー
    if [ $INSTALLED_COUNT -eq ${#EXTENSIONS[@]} ]; then
        log_info "✓ すべての拡張機能がインストールされています"
    else
        log_warn "一部の拡張機能のインストールに失敗しました（${INSTALLED_COUNT}/${#EXTENSIONS[@]} 成功）"
        if [ ${#FAILED_EXTENSIONS[@]} -gt 0 ]; then
            log_info "失敗した拡張機能: ${FAILED_EXTENSIONS[*]}"
            log_info "手動でインストールする場合:"
            for EXT in "${FAILED_EXTENSIONS[@]}"; do
                log_info "  $CODE_CMD --install-extension ${EXT} --force"
            done
        fi
    fi
else
    log_warn "VS Code CLI (code-oss/code) が見つかりません。拡張機能は手動でインストールしてください。"
    log_info "以下のコマンドでContinue拡張機能をインストールできます:"
    log_info "  code-oss --install-extension continue.continue --force"
fi

# 6-2. Continue設定ファイルの確認と作成
log_info "Continue設定ファイルの確認中..."
CONTINUE_CONFIG_DIR=".continue"
CONTINUE_CONFIG_FILE="${CONTINUE_CONFIG_DIR}/config.json"

# プロジェクトルートのパスを取得（スクリプトがどこから実行されても正しく動作）
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_CONTINUE_CONFIG="${PROJECT_ROOT}/${CONTINUE_CONFIG_FILE}"

# .continueディレクトリが存在しない場合は作成
if [ ! -d "$CONTINUE_CONFIG_DIR" ]; then
    mkdir -p "$CONTINUE_CONFIG_DIR"
    log_info "✓ .continueディレクトリを作成しました"
fi

# config.jsonが存在しない、または内容が正しくない場合は作成/更新
if [ ! -f "$CONTINUE_CONFIG_FILE" ] || ! grep -q '"provider": "bedrock"' "$CONTINUE_CONFIG_FILE" 2>/dev/null; then
    log_info "Continue設定ファイルを作成/更新中..."
    cat > "$CONTINUE_CONFIG_FILE" << 'EOF'
{
  "models": [
    {
      "title": "AWS Bedrock",
      "provider": "bedrock",
      "region": "ap-northeast-1",
      "model": "cohere.command-text-v14",
      "credentialsProvider": "default"
    }
  ],
  "defaultModel": "AWS Bedrock",
  "allowAnonymousTelemetry": false
}
EOF
    log_info "✓ Continue設定ファイルを作成/更新しました: ${CONTINUE_CONFIG_FILE}"
else
    log_info "✓ Continue設定ファイルは既に存在し、正しく設定されています"
fi

# 6-3. Continue設定ファイルを/home/user/.continueにシンボリックリンクで反映
log_info "Continue設定ファイルを/home/user/.continueにリンク中..."
USER_CONTINUE_DIR="/home/user/.continue"
USER_CONTINUE_CONFIG="${USER_CONTINUE_DIR}/config.json"

# プロジェクトルートのconfig.jsonが存在することを確認
if [ ! -f "$PROJECT_CONTINUE_CONFIG" ]; then
    log_warn "プロジェクトルートの設定ファイルが見つかりません: ${PROJECT_CONTINUE_CONFIG}"
    log_warn "シンボリックリンクの作成をスキップします"
else
    # /home/user/.continueディレクトリを作成（既に存在する場合は何もしない）
    if [ ! -d "$USER_CONTINUE_DIR" ]; then
        mkdir -p "$USER_CONTINUE_DIR"
        log_info "✓ /home/user/.continueディレクトリを作成しました"
    else
        log_info "✓ /home/user/.continueディレクトリは既に存在しています"
    fi

    # シンボリックリンクを作成または更新
    if [ -L "$USER_CONTINUE_CONFIG" ]; then
        # 既存のシンボリックリンクを確認
        LINK_TARGET="$(readlink -f "$USER_CONTINUE_CONFIG" 2>/dev/null || readlink "$USER_CONTINUE_CONFIG")"
        if [ "$LINK_TARGET" != "$PROJECT_CONTINUE_CONFIG" ]; then
            log_info "既存のシンボリックリンクを更新中..."
            rm "$USER_CONTINUE_CONFIG"
            if ln -s "$PROJECT_CONTINUE_CONFIG" "$USER_CONTINUE_CONFIG" 2>/dev/null; then
                log_info "✓ シンボリックリンクを更新しました: ${USER_CONTINUE_CONFIG} -> ${PROJECT_CONTINUE_CONFIG}"
            else
                log_warn "シンボリックリンクの作成に失敗しました"
            fi
        else
            log_info "✓ シンボリックリンクは既に正しく設定されています"
        fi
    elif [ -f "$USER_CONTINUE_CONFIG" ]; then
        # 通常のファイルが存在する場合はバックアップしてからシンボリックリンクに置き換え
        log_info "既存の設定ファイルをバックアップ中..."
        mv "$USER_CONTINUE_CONFIG" "${USER_CONTINUE_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
        if ln -s "$PROJECT_CONTINUE_CONFIG" "$USER_CONTINUE_CONFIG" 2>/dev/null; then
            log_info "✓ 既存の設定ファイルをバックアップし、シンボリックリンクを作成しました"
        else
            log_warn "シンボリックリンクの作成に失敗しました"
        fi
    else
        # シンボリックリンクが存在しない場合は作成
        if ln -s "$PROJECT_CONTINUE_CONFIG" "$USER_CONTINUE_CONFIG" 2>/dev/null; then
            log_info "✓ シンボリックリンクを作成しました: ${USER_CONTINUE_CONFIG} -> ${PROJECT_CONTINUE_CONFIG}"
        else
            log_warn "シンボリックリンクの作成に失敗しました"
        fi
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

# 10-2. .envファイルから環境変数を~/.profileに追加（VS Codeプロセス用）
log_info ".envファイルから環境変数を~/.profileに追加中..."
if [ -f ".env" ]; then
    # .envファイルからAWS認証情報を抽出（コメント行を除外）
    ENV_VARS=$(grep -v '^#' .env | grep -v '^$' | grep -E '^(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|AWS_DEFAULT_REGION)=' || true)
    
    if [ -n "$ENV_VARS" ]; then
        # ~/.profileに環境変数エクスポートを追加（既に存在しない場合のみ）
        PROFILE_ENV_MARKER="# AWS認証情報（.envファイルから自動設定）"
        if ! grep -q "$PROFILE_ENV_MARKER" ~/.profile 2>/dev/null; then
            echo "" >> ~/.profile
            echo "$PROFILE_ENV_MARKER" >> ~/.profile
            while IFS='=' read -r key value; do
                # 値から引用符を除去
                value=$(echo "$value" | sed "s/^['\"]//;s/['\"]$//")
                echo "export ${key}=\"${value}\"" >> ~/.profile
            done <<< "$ENV_VARS"
            log_info "✓ ~/.profileに環境変数を追加しました"
            log_info "  注意: VS Codeを再起動すると、Continue拡張機能が環境変数にアクセスできるようになります"
        else
            log_warn "~/.profileに既に環境変数の設定が存在します"
        fi
    else
        log_warn ".envファイルにAWS認証情報が設定されていません"
    fi
else
    log_warn ".envファイルが存在しないため、環境変数の追加をスキップします"
fi

# 10-3. AWS CLI設定ファイルを作成（Continue拡張機能とAWS CLI用）
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

echo ""
log_info "=========================================="
log_info "セットアップ完了！"
log_info "=========================================="
log_info "次のステップは README.md を参照してください。"
