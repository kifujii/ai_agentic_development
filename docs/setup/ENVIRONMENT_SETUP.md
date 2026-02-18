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
   - **Import from Git**: このリポジトリのURLを指定

**注意**: ワークスペース作成時にリポジトリを指定しているため、ファイル一式が既にワークスペース内に含まれています。追加のgit cloneは不要です。

### ステップ2: 環境セットアップスクリプトの実行

**重要**: セットアップスクリプトは **OpenShift DevSpaces環境内** で実行する必要があります。

1. **ターミナルを開く**
   - VS Codeのメニューから「ターミナル」→「新しいターミナル」を選択
   - または、ショートカットキー（`Ctrl+Shift+C` / `Cmd+Shift+C`）を使用

2. **セットアップスクリプトの実行**
   ```bash
   ./scripts/setup_devspaces.sh
   ```

3. **スクリプト実行後、PATHを更新**
   ```bash
   source ~/.bashrc
   ```

**インストールされるツールと拡張機能**:
- **ツール**:
  - Terraform（~/.local/binにインストール）
  - Ansible（pipでユーザー権限インストール）
  - AWS CLI（~/.local/binにインストール）
  - Pythonパッケージ（requirements.txtから、--userオプションでインストール）
  - Git（既にインストールされている場合が多い）
  - jq（sudoが使える場合のみ）
- **VS Code拡張機能**（CLI経由で自動インストール）:
  - Continue

詳細は [`docs/setup/DEVSPACES_SETUP.md`](../setup/DEVSPACES_SETUP.md) を参照してください。

### ステップ3: AWS認証情報の設定

#### 3.1 .envファイルの作成と編集

セットアップスクリプト（ステップ2）が`.env.template`ファイルを作成します。このテンプレートから`.env`ファイルを作成し、実際のAWS認証情報を設定します：

```bash
cp .env.template .env
```

VS Codeで`.env`ファイルを開き、以下の値を実際のAWS認証情報に置き換えてください：

```bash
# AWS認証情報
AWS_ACCESS_KEY_ID=your-access-key-here
AWS_SECRET_ACCESS_KEY=your-secret-key-here
AWS_DEFAULT_REGION=ap-northeast-1
```

**編集内容**:
- `your-access-key-here` → 実際のAWSアクセスキーID
- `your-secret-key-here` → 実際のAWSシークレットアクセスキー

**重要**: 
- AWS認証情報はIAMユーザーのアクセスキーとシークレットキーを使用してください
- Admin権限を持つアクセスキーが必要です
- `.env`ファイルはGitにコミットしないでください（`.gitignore`に含まれています）

#### 3.2 セットアップスクリプトの再実行（AWS CLI設定ファイルの自動作成）

**重要**: `.env`ファイルを編集した後、セットアップスクリプトを再実行すると、`.env`ファイルから自動的にAWS CLI設定ファイル（`~/.aws/credentials`と`~/.aws/config`）が作成されます。これにより、Continue拡張機能がAWS認証情報にアクセスできるようになります。

セットアップスクリプトを再実行します：

```bash
./scripts/setup_devspaces.sh
```

このスクリプトは以下の処理を自動的に実行します：
- `.env`ファイルからAWS認証情報を読み込み
- `~/.aws/credentials`ファイルを作成（既に存在する場合は更新）
- `~/.aws/config`ファイルを作成（リージョン設定）
- `~/.profile`に環境変数を追加（VS Code再起動時に読み込まれる）
- Continue設定ファイル（`.continue/config.json`）の作成

#### 3.3 環境変数の読み込み（現在のシェル用）

現在のターミナルセッションで環境変数を読み込みます：

```bash
export $(cat .env | grep -v '^#' | xargs)
```

#### 3.4 AWS認証情報の確認

AWS認証情報が正しく設定されているか確認します：

```bash
aws sts get-caller-identity
```

AWS CLI設定ファイルが正しく作成されているか確認します：

```bash
cat ~/.aws/credentials
```

```bash
cat ~/.aws/config
```

**注意**: 
- `aws configure`コマンドは不要です。セットアップスクリプトが自動的に設定ファイルを作成します。
- Continue拡張機能を使用するには、**VS Codeを再起動**する必要があります（`~/.profile`の変更を反映するため）。

### ステップ4: Continue AIのセットアップ

Continue AIはVS Code/Cursorの拡張機能です。AWS Bedrockをモデルプロバイダーとして使用します。

**重要**: セットアップスクリプト（`./scripts/setup_devspaces.sh`）を実行すると、Continue拡張機能が自動的にインストールされます。

#### 4.1 AWS Bedrockの設定

**重要**: セットアップスクリプト（`./scripts/setup_devspaces.sh`）を実行すると、以下の設定が自動的に行われます：
- AWS CLI設定ファイル（`~/.aws/credentials`と`~/.aws/config`）の作成
- Continue設定ファイル（`.continue/config.json`）の作成
- `~/.profile`への環境変数の追加

1. **VS Codeを再起動**します（ワークスペースを閉じて再度開く、またはブラウザをリフレッシュ）。
   - これにより、`~/.profile`の環境変数がVS Codeプロセスに読み込まれます。

2. AWS認証情報が正しく設定されているか確認します：

```bash
aws sts get-caller-identity
```

3. **重要**: AWS Bedrockを使用するには、IAMユーザーにBedrockへのアクセス権限が必要です。以下のIAMポリシーをアタッチしてください：
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "bedrock:InvokeModel",
           "bedrock:ListFoundationModels"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

3. Continue設定ファイルの確認：

セットアップスクリプトが自動的に `.continue/config.yaml` を作成します。内容を確認します：

```bash
cat .continue/config.yaml
```

設定ファイルの内容は以下の通りです：

```yaml
name: aws-bedrock-config
version: 1.0
models:
  - title: "AWS Bedrock"
    provider: bedrock
    region: ap-northeast-1
    model: cohere.command-light-text-v14
    credentialsProvider: default

defaultModel: "AWS Bedrock"
allowAnonymousTelemetry: false
```

**注意**: Continueは`config.json`から`config.yaml`への移行を推奨しています。セットアップスクリプトは自動的に`config.yaml`を作成します。

**設定項目の説明**:
- `provider`: `bedrock`を指定
- `region`: AWSリージョン（`.env`ファイルの`AWS_DEFAULT_REGION`と一致）
- `model`: 使用するモデルID（例: `cohere.command-light-text-v14`）

**モデルIDが無効なエラーが発生する場合**:
実際に利用可能なモデルIDを確認してください：

```bash
aws bedrock list-foundation-models --region ap-northeast-1 --query 'modelSummaries[?inferenceTypesSupported==`ON_DEMAND`].modelId' --output table
```

表示されたモデルIDを使用して、`.continue/config.yaml`の`model`フィールドを更新してください。
- `credentialsProvider`: `default`を指定すると、環境変数やAWS CLI設定ファイル（`~/.aws/credentials`）から自動的に認証情報を取得します

**注意**: セットアップスクリプトが自動的に設定ファイルを作成するため、手動での編集は通常不要です。

詳細は [`docs/setup/CONTINUE_SETUP.md`](../setup/CONTINUE_SETUP.md) を参照してください。

### ステップ5: 動作確認

#### 5.1 ツールの確認

Terraformのバージョンを確認します：

```bash
terraform version
```

Ansibleのバージョンを確認します：

```bash
ansible --version
```

AWS CLIのバージョンを確認します：

```bash
aws --version
```

AWS認証情報が正しく設定されているか確認します：

```bash
aws sts get-caller-identity
```

#### 5.2 Continue AIの確認

1. Continueを起動（`Ctrl+L` / `Cmd+L`）
2. チャットに以下を入力：
   ```
   S3バケットを作成するシンプルなTerraformコードを生成してください
   ```
3. AIからの応答が表示されれば、設定は成功です

## ✅ セットアップ完了チェックリスト

- [ ] DevSpacesワークスペースを作成した
- [ ] セットアップスクリプトを実行した
- [ ] `.env`ファイルを作成し、AWS認証情報を設定した
- [ ] 環境変数を読み込んだ（`export $(cat .env | grep -v '^#' | xargs)`）
- [ ] AWS認証情報が正しく設定されていることを確認した（`aws sts get-caller-identity`）
- [ ] AWS Bedrockへのアクセス権限をIAMユーザーに付与した
- [ ] AWS Bedrockの設定を完了した（`.continue/config.json`を編集）
- [ ] Continue AIが正常に動作することを確認した
- [ ] すべてのツールが正しくインストールされていることを確認した

## 🆘 トラブルシューティング

よくある問題と解決方法は [`docs/setup/FAQ.md`](../setup/FAQ.md) を参照してください。

## 📚 次のステップ

環境セットアップが完了したら、[README.md](../../README.md) に戻ってワークショップを開始してください。
