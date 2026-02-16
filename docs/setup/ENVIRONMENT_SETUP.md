# 環境セットアップガイド

このドキュメントでは、ワークショップに必要な環境のセットアップ手順を説明します。

## 📋 前提条件

- **GitHub アカウント**: リポジトリへのアクセス用
- **AWS アカウント**: トレーニング用（Admin権限のアクセスキー/シークレットキー）
- **OpenShift DevSpaces へのアクセス**: 開発環境
- **VS Code または Cursor エディタ**: Continue拡張機能を使用

## 🚀 セットアップ手順

### ステップ1: DevSpaces環境への資材の持ち込み

#### 1.1 DevSpacesワークスペースの作成

1. OpenShift DevSpacesのURLにアクセス
2. ログイン
3. 新しいワークスペースを作成
   - **スタック**: Python 3.11 または Node.js 18
   - **メモリ**: 4GB以上推奨

#### 1.2 Gitリポジトリのクローン

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

### ステップ2: 環境セットアップスクリプトの実行

**重要**: セットアップスクリプトは **OpenShift DevSpaces環境内** で実行する必要があります。

```bash
# セットアップスクリプトの実行
chmod +x scripts/setup_devspaces.sh
./scripts/setup_devspaces.sh

# スクリプト実行後、PATHを更新（新しいターミナルを開くか、以下を実行）
source ~/.bashrc
```

**インストールされるツール**:
- Terraform（~/.local/binにインストール）
- Ansible（pipでユーザー権限インストール）
- AWS CLI（~/.local/binにインストール）
- Pythonパッケージ（requirements.txtから、--userオプションでインストール）
- Git（既にインストールされている場合が多い）
- jq（sudoが使える場合のみ）

詳細は [`docs/setup/DEVSPACES_SETUP.md`](../setup/DEVSPACES_SETUP.md) を参照してください。

### ステップ3: AWS認証情報の設定

#### 3.1 .envファイルの作成

セットアップスクリプトが`.env.template`ファイルを作成します。このテンプレートから`.env`ファイルを作成し、AWS認証情報を設定してください：

```bash
# .env.templateをコピーして.envファイルを作成
cp .env.template .env

# .envファイルを編集して認証情報を設定
nano .env
# または
vi .env
```

#### 3.2 .envファイルの内容

`.env`ファイルの内容を以下のように設定してください：

```bash
# AWS認証情報
AWS_ACCESS_KEY_ID=your-access-key-here
AWS_SECRET_ACCESS_KEY=your-secret-key-here
AWS_DEFAULT_REGION=ap-northeast-1
```

**重要**: 
- AWS認証情報はIAMユーザーのアクセスキーとシークレットキーを使用してください
- Admin権限を持つアクセスキーが必要です
- `.env`ファイルはGitにコミットしないでください（`.gitignore`に含まれています）

#### 3.3 環境変数の読み込み

`.env`ファイルを環境変数として読み込めば、AWS CLIとTerraformの両方が認証情報を使用できます：

```bash
# .envファイルを環境変数として読み込む
export $(cat .env | grep -v '^#' | xargs)

# AWS認証情報の確認
aws sts get-caller-identity
```

**永続的な設定**: セットアップスクリプトが自動的に`~/.bashrc`に`.env`ファイルの自動読み込み設定を追加します。新しいターミナルを開くか、`source ~/.bashrc`を実行すると、プロジェクトディレクトリにいる場合に自動的に`.env`ファイルが読み込まれます。

**注意**: `aws configure`は不要です。`.env`ファイルを環境変数としてエクスポートすれば、AWS CLIとTerraformの両方が環境変数から認証情報を読み取ります。

### ステップ4: Continue AIのセットアップ

Continue AIはVS Code/Cursorの拡張機能です。OpenShiftAIをモデルプロバイダーとして使用します。

#### 4.1 Continue拡張機能のインストール

1. VS CodeまたはCursorを開く
2. 拡張機能パネルを開く（`Ctrl+Shift+X` / `Cmd+Shift+X`）
3. "Continue"を検索してインストール

#### 4.2 OpenShiftAIの設定

1. OpenShiftAIの管理者から以下を取得：
   - エンドポイントURL: `https://your-openshiftai-endpoint/v1`
   - APIキー: OpenShiftAIのAPIキー

2. プロジェクトルートの `.continue/config.json` を編集：

```json
{
  "models": [
    {
      "title": "OpenShiftAI",
      "provider": "openai",
      "model": "gpt-4",
      "apiBase": "https://YOUR_OPENSHIFTAI_ENDPOINT/v1",
      "apiKey": "YOUR_OPENSHIFTAI_API_KEY"
    }
  ],
  "defaultModel": "OpenShiftAI",
  "allowAnonymousTelemetry": false
}
```

詳細は [`docs/setup/CONTINUE_SETUP.md`](../setup/CONTINUE_SETUP.md) を参照してください。

### ステップ5: 動作確認

#### 5.1 ツールの確認

```bash
# Terraformの確認
terraform version

# Ansibleの確認
ansible --version

# AWS CLIの確認
aws --version

# AWS認証情報の確認
aws sts get-caller-identity
```

#### 5.2 Continue AIの確認

1. Continueを起動（`Ctrl+L` / `Cmd+L`）
2. チャットに以下を入力：
   ```
   Hello! Can you generate a simple Terraform code to create an S3 bucket?
   ```
3. AIからの応答が表示されれば、設定は成功です

## ✅ セットアップ完了チェックリスト

- [ ] DevSpacesワークスペースを作成した
- [ ] Gitリポジトリをクローンした
- [ ] セットアップスクリプトを実行した
- [ ] `.env`ファイルを作成し、AWS認証情報を設定した
- [ ] 環境変数を読み込んだ（`export $(cat .env | grep -v '^#' | xargs)`）
- [ ] AWS認証情報が正しく設定されていることを確認した（`aws sts get-caller-identity`）
- [ ] Continue拡張機能をインストールした
- [ ] OpenShiftAIの設定を完了した
- [ ] Continue AIが正常に動作することを確認した
- [ ] すべてのツールが正しくインストールされていることを確認した

## 🆘 トラブルシューティング

よくある問題と解決方法は [`docs/setup/FAQ.md`](../setup/FAQ.md) を参照してください。

## 📚 次のステップ

環境セットアップが完了したら、[README.md](../../README.md) に戻ってワークショップを開始してください。
