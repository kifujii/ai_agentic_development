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

#### 3.1 .envファイルの作成

セットアップスクリプトが`.env.template`ファイルを作成します。このテンプレートから`.env`ファイルを作成します：

```bash
cp .env.template .env
```

#### 3.2 .envファイルの編集

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

#### 3.3 環境変数の読み込み

`.env`ファイルを環境変数として読み込みます：

```bash
export $(cat .env | grep -v '^#' | xargs)
```

AWS認証情報が正しく設定されているか確認します：

```bash
aws sts get-caller-identity
```

**注意**: `aws configure`は不要です。`.env`ファイルを環境変数としてエクスポートすれば、AWS CLIとTerraformの両方が環境変数から認証情報を読み取ります。

### ステップ4: Continue AIのセットアップ

Continue AIはVS Code/Cursorの拡張機能です。AWS Bedrockをモデルプロバイダーとして使用します。

**重要**: セットアップスクリプト（`./scripts/setup_devspaces.sh`）を実行すると、Continue拡張機能が自動的にインストールされます。

#### 4.1 AWS Bedrockの設定

1. AWS認証情報が`.env`ファイルに設定されていることを確認します：

```bash
echo $AWS_ACCESS_KEY_ID
```

```bash
echo $AWS_SECRET_ACCESS_KEY
```

```bash
echo $AWS_DEFAULT_REGION
```

2. **重要**: AWS Bedrockを使用するには、IAMユーザーにBedrockへのアクセス権限が必要です。以下のIAMポリシーをアタッチしてください：
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

3. プロジェクトルートの `.continue/config.json` を編集：

```json
{
  "models": [
    {
      "title": "AWS Bedrock",
      "provider": "bedrock",
      "region": "ap-northeast-1",
      "model": "anthropic.claude-3-sonnet-20240229-v1:0",
      "credentialsProvider": "default"
    }
  ],
  "defaultModel": "AWS Bedrock",
  "allowAnonymousTelemetry": false
}
```

**設定項目の説明**:
- `provider`: `bedrock`を指定
- `region`: AWSリージョン（`.env`ファイルの`AWS_DEFAULT_REGION`と一致させる）
- `model`: 使用するモデルID（例: `anthropic.claude-3-sonnet-20240229-v1:0`）
- `credentialsProvider`: AWS認証情報の取得方法（`default`は環境変数やAWS CLI設定から自動取得）

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
