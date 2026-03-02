# OpenShift DevSpaces環境セットアップ手順書

## 概要
このドキュメントは、OpenShift DevSpaces環境でのトレーニング準備手順の**詳細リファレンス**です。

> **⚠️ 重要**: このドキュメントは**手動インストールやトラブルシューティング**が必要な場合の参考資料です。
> **通常のセットアップは [環境セットアップガイド](ENVIRONMENT_SETUP.md) に従ってください。**
> 受講者は ENVIRONMENT_SETUP.md の手順のみで環境構築が完了します。

## 前提条件
- OpenShift DevSpacesへのアクセス権限
- AWSアカウント（トレーニング用、AWS Bedrock利用可能）

## セットアップ手順

### 1. DevSpacesワークスペースの作成

#### 1.1 ワークスペースへのアクセス
1. OpenShift DevSpacesのURLにアクセス
2. ログイン
3. 新しいワークスペースを作成または既存のワークスペースを開く

#### 1.2 ワークスペース設定
- **Import from Git**: このリポジトリのURLを指定

### 2. トレーニング資材の確認


#### 2.1 プロジェクト構造の確認
```bash
# ディレクトリ構造の確認
ls -la

# 期待される構造:
# .
# ├── docs/
# ├── scripts/
# ├── evaluation/
# ├── terraform/
# └── ansible/
```

### 3. 必要なツールのインストール

#### 3.1 自動インストールスクリプトの実行
**重要**: このスクリプトは **DevSpaces環境内** で実行してください。

**注意**: DevSpaces環境ではsudo権限が制限されているため、スクリプトはユーザー権限でインストールを行います。

1. **ターミナルを開く**
   - VS Codeのメニューから「ターミナル」→「新しいターミナル」を選択
   - または、ショートカットキー（`Ctrl+Shift+C` / `Cmd+Shift+C`）を使用

2. **セットアップスクリプトの実行**
   ```bash
   # プロジェクトディレクトリにいることを確認
   pwd
   # 出力例: /projects/ai_agentic_development/ai_agentic
   
   # セットアップスクリプトを実行
   ./scripts/setup_devspaces.sh
   ```

このスクリプトは以下のツールを自動的にインストールします（ユーザー権限）：
- Terraform（~/.local/binにインストール）
- Ansible（pipでユーザー権限インストール）
- AWS CLI（~/.local/binにインストール）
- Pythonパッケージ（scripts/requirements.txtから、--userオプションでインストール）
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
# python3 -m pipでユーザー権限でインストール
# 重要: python3 -m pipを使用することで、python3コマンドと同じPythonバージョンに確実にインストールされます
python3 -m pip install --user ansible

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

**jqのインストール（ユーザー権限、オプショナル）**
```bash
# ローカルbinディレクトリの作成
mkdir -p ~/.local/bin

# アーキテクチャの確認
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    JQ_ARCH="amd64"
elif [ "$ARCH" = "aarch64" ]; then
    JQ_ARCH="arm64"
else
    JQ_ARCH="amd64"
fi

# jqの静的バイナリをダウンロード
JQ_VERSION="1.7"
wget "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-${JQ_ARCH}" -O ~/.local/bin/jq
chmod +x ~/.local/bin/jq

# PATHを確認
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# インストール確認
source ~/.bashrc
jq --version
```

**Gitについて**:
DevSpaces環境には通常Gitが既にインストールされています。インストールされていない場合は、DevSpaces管理者に依頼するか、Gitが含まれるスタックを使用してください。

**注意**: 手動インストール後は、新しいターミナルを開くか、`source ~/.bashrc`を実行してPATHを更新してください。

### 4. 認証情報の設定

> **注意**: 通常は [環境セットアップガイド](ENVIRONMENT_SETUP.md) のステップ3に従ってください。以下は手動で設定する場合の手順です。

#### 4.1 .envファイルの作成と編集

```bash
# .env.templateから.envファイルを作成
cp .env.template .env
```

VS Codeで`.env`ファイルを開き、以下の値を実際のAWS認証情報に置き換えてください：

```bash
# AWS認証情報
AWS_ACCESS_KEY_ID=your-access-key-here
AWS_SECRET_ACCESS_KEY=your-secret-key-here
AWS_DEFAULT_REGION=ap-northeast-1
```

#### 4.2 セットアップスクリプトの再実行（AWS CLI設定ファイルの自動作成）

`.env`ファイルを編集した後、セットアップスクリプトを再実行すると、`.env`ファイルから自動的にAWS CLI設定ファイル（`~/.aws/credentials`と`~/.aws/config`）が作成されます。

```bash
./scripts/setup_devspaces.sh
```

#### 4.3 AWS認証情報の確認
```bash
aws sts get-caller-identity
```

### 5. Python環境のセットアップ

#### 5.1 必要なパッケージのインストール
```bash
# scripts/requirements.txtからインストール
# 重要: python3 -m pipを使用することで、python3コマンドと同じPythonバージョンに確実にインストールされます
python3 -m pip install --user -r scripts/requirements.txt

# または個別にインストール
python3 -m pip install --user python-dotenv boto3 pyyaml jinja2 requests colorama
```

### 6. プロジェクト構造の確認

#### 6.1 ディレクトリ構造の確認
```bash
# プロジェクト構造の確認
tree -L 2

# 期待される構造:
# .
# ├── .continue/          # Continue設定
# ├── docs/               # ドキュメント
# ├── scripts/            # セットアップスクリプト
# ├── evaluation/         # 評価チェックリスト
# ├── terraform/          # Terraformコード（セッション中に作成）
# └── ansible/            # Ansibleコード（セッション中に作成）
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
```

#### 7.2 AWS接続テスト
```bash
aws sts get-caller-identity
```

#### 7.3 Continueの動作確認

1. Continueを起動（`Ctrl+L` / `Cmd+L`）
2. Agentモードで以下を入力：
   ```
   testフォルダに「hello.txt」というファイルを作成して、その中に「Hello, Continue!」と書き込んでください
   ```
3. AIがファイルを作成できれば、設定は成功です

## トラブルシューティング

### 権限エラー
```bash
# 実行権限の付与
chmod +x scripts/*.sh
```

### パッケージインストールエラー
```bash
# pipのアップグレード
python3 -m pip install --user --upgrade pip

# キャッシュのクリア
python3 -m pip cache purge
```

### AWS認証エラー
- 認証情報が正しく設定されているか確認
- IAM権限が適切か確認
- リージョンが正しいか確認

### 環境変数エラー
- .envファイルが正しく作成されているか確認
- .envファイルが正しく読み込まれているか確認（`source ~/.bashrc` を実行）
- AWS認証情報が有効か確認（`aws sts get-caller-identity`）

## 次のステップ
セットアップが完了したら、以下のセッションガイドを参照してください：
- `docs/session_guides/session1_guide.md`

## 参考資料
- [OpenShift DevSpaces公式ドキュメント](https://access.redhat.com/documentation/en-us/red_hat_openshift_dev_spaces/)
- [Terraform公式ドキュメント](https://www.terraform.io/docs)
- [Ansible公式ドキュメント](https://docs.ansible.com/)
