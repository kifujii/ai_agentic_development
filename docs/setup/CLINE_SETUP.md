# Cline セットアップガイド

## 概要

このワークショップでは、Cline（VS Code/Cursor拡張機能）を使用してAIコーディングエージェントを活用します。ClineはAWS Bedrockをモデルプロバイダーとして使用し、Claude 4.6 Sonnet でコード生成・ファイル操作・ターミナル実行などを自律的に行います。

## Clineとは

Clineは、VS CodeやCursorエディタで動作する自律型AIコーディングエージェントです。ファイルの作成・編集、ターミナルコマンドの実行、ブラウザ操作など、開発に必要な操作をAIが自動で行います。各操作の実行前に承認を求めるため、安全に利用できます。

- **公式サイト**: https://github.com/cline/cline
- **VS Code Marketplace**: https://marketplace.visualstudio.com/items?itemName=saoudrizwan.claude-dev

## セットアップ手順

### 1. Cline拡張機能のインストール

**重要**: DevSpacesワークスペースでは、セットアップスクリプト（`./scripts/setup_devspaces.sh`）を実行するとCline拡張機能がCLI経由で自動インストールされます。

#### DevSpacesワークスペースを使用する場合（推奨）

1. ワークスペース起動後、セットアップスクリプトを実行：
   ```bash
   ./scripts/setup_devspaces.sh
   ```

2. このスクリプトでCline拡張機能が自動インストールされます。

**手動インストールが必要な場合**:

##### VS Codeを使用する場合
1. VS Codeを開く
2. 拡張機能パネルを開く（`Ctrl+Shift+X` / `Cmd+Shift+X`）
3. "Cline" を検索
4. "Cline" (saoudrizwan.claude-dev) をインストール

##### Cursorを使用する場合
1. Cursorを開く
2. 拡張機能パネルを開く（`Ctrl+Shift+X` / `Cmd+Shift+X`）
3. "Cline" を検索
4. "Cline" (saoudrizwan.claude-dev) をインストール

### 2. AWS Bedrockの設定

#### 2.1 AWS認証情報の確認

AWS Bedrockを使用するには、AWS認証情報（アクセスキー、シークレットキー）が設定済みである必要があります。

```bash
aws sts get-caller-identity
```

**重要**: AWS Bedrockを使用するには、IAMユーザーに以下のポリシーが必要です：

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

#### 2.2 ClineでAWS Bedrockを設定

1. サイドバーのClineアイコンをクリック（またはコマンドパレットから `Cline: Open` を実行）
2. 初回起動時にAPIプロバイダーの設定画面が表示されます
3. 以下を設定：
   - **API Provider**: `AWS Bedrock`
   - **Region**: `ap-northeast-1`
   - **Model**: `anthropic.claude-sonnet-4-6`

> **注意**: Cline は `~/.aws/credentials` または環境変数（`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`）からAWS認証情報を読み取ります。セットアップスクリプトで `.env` を設定済みであれば追加の認証設定は不要です。

#### 2.3 設定の変更

設定を変更したい場合は、Clineパネル上部の歯車アイコンをクリックするか、コマンドパレットから `Cline: Open Settings` を実行してください。

**利用可能なモデル（Bedrock on-demand対応）**:
- `anthropic.claude-sonnet-4-6` (Claude Sonnet 4.6) — **ワークショップ標準**
- `anthropic.claude-sonnet-4-5-20250514` (Claude Sonnet 4.5)
- `us.meta.llama3-1-70b-instruct-v1:0` (Meta Llama 3.1 70B Instruct)

**注意**:
- モデルIDはリージョンやアカウント設定によって利用可能なものが異なります
- **モデルが見つからない場合**: 以下のコマンドで利用可能なモデルを確認してください：
  ```bash
  aws bedrock list-foundation-models --region ap-northeast-1 --query 'modelSummaries[?inferenceTypesSupported[?contains(@,`ON_DEMAND`)]].modelId' --output table
  ```

### 3. Clineの起動

#### 方法1: サイドバーから
1. 左側のサイドバーでClineアイコンをクリック
2. チャットパネルが開きます

#### 方法2: コマンドパレット
- `Ctrl+Shift+P` / `Cmd+Shift+P` → "Cline: Open" と入力

### 4. 動作確認

Clineが正しく動作しているか確認します：

1. Clineを起動
2. チャットに以下を入力：
   ```
   testフォルダに「hello.txt」というファイルを作成して、その中に「Hello, Cline!」と書き込んでください
   ```
3. Clineがファイル作成の承認を求めてくるので「Accept」をクリック
4. `test/hello.txt` が作成されれば設定は成功です

## Clineの使い方

### 基本的な使い方

Clineはチャットに指示を入力するだけで、必要な操作を自動的に行います：

1. **コード生成**: 「〜のコードを作成してください」
2. **ファイル操作**: ファイルの作成・編集・削除を自動実行
3. **ターミナル操作**: コマンドの実行（terraform apply、ssh接続など）

### ワークショップでの使い方

このワークショップでは、Clineに以下のような指示を出します：

- Terraform コードの生成と実行（`terraform init` → `plan` → `apply`）
- EC2 への SSH 接続とソフトウェアインストール
- Ansible Playbook の作成と実行

### 承認ワークフロー

Clineは操作を実行する前に必ず承認を求めます：

- **ファイル作成・編集**: 変更内容のdiffが表示されます → 内容を確認して「Accept」
- **ターミナルコマンド**: 実行するコマンドが表示されます → コマンドを確認して「Accept」

> **重要**: 特に `terraform apply` や `ssh` コマンドなど、実際のインフラに影響するコマンドは内容をよく確認してから承認してください。

## トラブルシューティング

### 問題1: Clineが起動しない

**解決方法**:
1. 拡張機能が正しくインストールされているか確認
2. VS Code/Cursorを再起動
3. 拡張機能パネルでClineが有効になっているか確認

### 問題2: AWS Bedrockへの接続エラー

**解決方法**:
1. AWS認証情報が正しく設定されているか確認（`aws sts get-caller-identity`）
2. リージョンが `ap-northeast-1` になっているか確認
3. IAMポリシーに `bedrock:InvokeModel` 権限があるか確認
4. モデル `anthropic.claude-sonnet-4-6` が利用可能か確認

### 問題3: モデルが応答しない

**解決方法**:
1. Clineの設定画面でAPI Provider、Region、Modelが正しいか確認
2. ネットワーク接続を確認
3. AWS Bedrockのサービス状態を確認

## 参考リンク

- [Cline GitHub](https://github.com/cline/cline)
- [Cline VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=saoudrizwan.claude-dev)
- [AWS Bedrock公式ドキュメント](https://docs.aws.amazon.com/bedrock/)
- [AWS Bedrock利用可能モデル](https://docs.aws.amazon.com/bedrock/latest/userguide/model-ids.html)
