# Continue AI セットアップガイド

## 概要

このワークショップでは、Continue AI（VS Code/Cursor拡張機能）を使用してAIアシスタントを活用します。Continueは、AWS Bedrockをモデルプロバイダーとして使用します。

## Continueとは

Continueは、VS CodeやCursorエディタで動作するAIコーディングアシスタントです。コード生成、レビュー、リファクタリングなどの開発タスクを支援します。

- **公式サイト**: https://continue.dev/
- **GitHub**: https://github.com/continue-dev/continue

## セットアップ手順

### 1. Continue拡張機能のインストール

**重要**: DevSpacesワークスペースでは、セットアップスクリプト（`./scripts/setup_devspaces.sh`）を実行すると、Continue拡張機能がCLI経由で自動インストールされます。

#### DevSpacesワークスペースを使用する場合（推奨）

1. ワークスペース起動後、セットアップスクリプトを実行：
   ```bash
   ./scripts/setup_devspaces.sh
   ```
   
2. このスクリプトでContinue拡張機能が自動インストールされます。

**手動インストールが必要な場合**（セットアップスクリプトでインストールに失敗した場合など）:

##### VS Codeを使用する場合
1. VS Codeを開く
2. 拡張機能パネルを開く（`Ctrl+Shift+X` / `Cmd+Shift+X`）
3. "Continue"を検索
4. "Continue"をインストール

##### Cursorを使用する場合
1. Cursorを開く
2. 拡張機能パネルを開く（`Ctrl+Shift+X` / `Cmd+Shift+X`）
3. "Continue"を検索
4. "Continue"をインストール

### 2. AWS Bedrockの設定

#### 2.1 AWS認証情報の確認

AWS Bedrockを使用するには、AWS認証情報（アクセスキー、シークレットキー）が必要です。これらは`.env`ファイルに設定されているはずです。

```bash
# AWS認証情報の確認
echo $AWS_ACCESS_KEY_ID
echo $AWS_SECRET_ACCESS_KEY
echo $AWS_DEFAULT_REGION
```

**重要**: AWS Bedrockを使用するには、IAMユーザーにBedrockへのアクセス権限が必要です。以下のIAMポリシーをアタッチしてください：

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

#### 2.2 Continue設定ファイルの編集

**重要**: セットアップスクリプトは自動的に`.continue/config.json`を作成します。

プロジェクトルートの `.continue/config.json` を編集します：

```json
{
  "models": [
    {
      "title": "Llama 3.1 70B (Bedrock - Agent用)",
      "provider": "bedrock",
      "model": "meta.llama3-1-70b-instruct-v1:0",
      "region": "us-east-1"
    },
    {
      "title": "Claude 3.5 Sonnet v2 (Bedrock - 要申請)",
      "provider": "bedrock",
      "model": "us.anthropic.claude-3-5-sonnet-20241022-v2:0",
      "region": "us-east-1"
    }
  ],
  "tabAutocompleteModel": {
    "title": "Llama 3.2 1B (Autocomplete)",
    "provider": "bedrock",
    "model": "meta.llama3-2-1b-instruct-v1:0",
    "region": "us-east-1"
  },
  "allowAnonymousTelemetry": false,
  "disableIndexing": true,
  "disableFormatting": true
}
```

**設定項目の説明**:
- `models`: チャットで使用するモデルのリスト（複数指定可能）
- `tabAutocompleteModel`: タブ補完で使用するモデル（軽量モデルを推奨）
- `provider`: `bedrock`を指定
- `region`: AWSリージョン（例: `us-east-1`）
- `model`: 使用するモデルID（AWS Bedrockで利用可能なモデルIDを指定）
- `allowAnonymousTelemetry`: 匿名テレメトリの送信を無効化
- `disableIndexing`: インデックス作成を無効化（パフォーマンス向上）
- `disableFormatting`: 自動フォーマットを無効化

**利用可能なモデル（on-demand対応）**:
- `meta.llama3-1-70b-instruct-v1:0` (Meta Llama 3.1 70B Instruct) - 推奨
- `meta.llama3-2-1b-instruct-v1:0` (Meta Llama 3.2 1B Instruct) - タブ補完用
- `us.anthropic.claude-3-5-sonnet-20241022-v2:0` (Claude 3.5 Sonnet v2) - 要申請

**注意**: 
- モデルIDはリージョンやアカウント設定によって利用可能なものが異なります
- **モデルIDが無効なエラーが発生する場合**: 以下のコマンドで実際に利用可能なモデルIDを確認してください：
  ```bash
  aws bedrock list-foundation-models --region us-east-1 --query 'modelSummaries[?inferenceTypesSupported==`ON_DEMAND`].modelId' --output table
  ```
- 表示されたモデルIDを使用して、`.continue/config.json`の`model`フィールドを更新してください

**注意**: Amazon Titanモデル（`amazon.titan-text-express-v1`、`amazon.titan-text-lite-v1`）はライフサイクルが終了しています。

**注意**: 
- 使用するモデルは、選択したリージョンでon-demand throughputが利用可能である必要があります
- モデルの利用可能性は、AWSコンソールのBedrockセクションで確認できます
- 一部のモデル（Anthropic Claudeなど）は、追加の設定やinference profileが必要な場合があります

### 3. Continueの起動

#### 方法1: ショートカットキー
- **Windows/Linux**: `Ctrl + L`
- **Mac**: `Cmd + L`

#### 方法2: サイドバーから
1. Continueアイコンをクリック（サイドバー左側）
2. チャットパネルが開きます

### 4. 動作確認

Continueが正しく動作しているか確認します：

1. Continueを起動（`Ctrl+L` / `Cmd+L`）
2. チャットに以下を入力：
   ```
   Hello! Can you generate a simple Terraform code to create an S3 bucket?
   ```
3. AIからの応答が表示されれば、設定は成功です

## Continueの使い方

### 基本的な使い方

1. **コード生成**: 自然言語で指示を入力
   ```
   「VPC、パブリック/プライベートサブネット、NAT Gatewayを含む
   AWS ネットワーク構成の Terraform コードを生成してください」
   ```

2. **コードレビュー**: コードを選択してレビューを依頼
   ```
   「このTerraformコードのセキュリティ上の問題点を指摘してください」
   ```

3. **リファクタリング**: コードの改善を依頼
   ```
   「このAnsible Playbookをより冪等性が高く、
   再利用可能な形にリファクタリングしてください」
   ```

### 便利な機能

- **コード選択**: コードを選択してからContinueに質問すると、選択したコードをコンテキストとして使用します
- **ファイル全体**: ファイルを開いた状態で質問すると、ファイル全体がコンテキストとして使用されます
- **複数ファイル**: 複数のファイルを開いて質問すると、すべてのファイルがコンテキストとして使用されます

## トラブルシューティング

### 問題1: Continueが起動しない

**解決方法**:
1. 拡張機能が正しくインストールされているか確認
2. VS Code/Cursorを再起動
3. Continueの設定ファイル（`.continue/config.json`）が正しいか確認

### 問題2: AWS Bedrockへの接続エラー

**解決方法**:
1. AWS認証情報が正しく設定されているか確認（`echo $AWS_ACCESS_KEY_ID`）
2. AWSリージョンが正しいか確認（`.continue/config.json`の`region`設定）
3. AWS Bedrockへのアクセス権限があるか確認（IAMポリシー）
4. ネットワーク接続を確認
5. AWS Bedrockが選択したリージョンで利用可能か確認

### 問題3: モデルが応答しない

**解決方法**:
1. 使用しているモデルIDがAWS Bedrockで利用可能か確認
2. モデルが選択したリージョンで利用可能か確認（AWSコンソールで確認）
3. AWS認証情報とリージョンを再確認
4. AWS Bedrockのサービス状態を確認
5. IAMポリシーに`bedrock:InvokeModel`権限があるか確認

## 参考リンク

- [Continue公式ドキュメント](https://continue.dev/docs)
- [Continue GitHub](https://github.com/continue-dev/continue)
- [AWS Bedrock公式ドキュメント](https://docs.aws.amazon.com/bedrock/)
- [AWS Bedrock利用可能モデル](https://docs.aws.amazon.com/bedrock/latest/userguide/model-ids.html)
