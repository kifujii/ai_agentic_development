# Claude Code セットアップガイド

## 概要

このワークショップでは、Claude Code（CLIベースのAIコーディングエージェント）を使用します。Claude CodeはAWS Bedrockをモデルプロバイダーとして使用し、Claude Sonnet 4.6 でコード生成・ファイル操作・ターミナル実行などを自律的に行います。

## Claude Codeとは

Claude Codeは、ターミナルから直接利用できる自律型AIコーディングエージェントです。ファイルの作成・編集、ターミナルコマンドの実行など、開発に必要な操作をAIが自動で行います。各操作の実行前に承認を求めるため、安全に利用できます。

- **公式ドキュメント**: https://docs.anthropic.com/en/docs/claude-code

## セットアップ手順

### 1. Claude Codeのインストール

**重要**: DevSpacesワークスペースでは、セットアップスクリプト（`./scripts/setup_devspaces.sh`）を実行するとClaude Codeが自動インストールされます。

#### DevSpacesワークスペースを使用する場合（推奨）

1. ワークスペース起動後、セットアップスクリプトを実行：
   ```bash
   ./scripts/setup_devspaces.sh
   ```

2. このスクリプトでClaude Codeが自動インストールされます。

**手動インストールが必要な場合**:

```bash
npm config set prefix "$HOME/.local"
npm install -g @anthropic-ai/claude-code
```

### 2. AWS Bedrockの設定

Claude CodeはAWS Bedrockを経由してClaude Sonnet 4.6を使用します。

#### 2.1 環境変数の設定

`.env` ファイルに以下の環境変数を設定してください（`.env.template` を参考に）：

```bash
# AWS認証情報
AWS_ACCESS_KEY_ID=your-access-key-here
AWS_SECRET_ACCESS_KEY=your-secret-key-here
AWS_DEFAULT_REGION=ap-northeast-1

# Claude Code（AWS Bedrock経由）
CLAUDE_CODE_USE_BEDROCK=1
AWS_REGION=ap-northeast-1
ANTHROPIC_MODEL=anthropic.claude-sonnet-4-6-20250514-v1:0
```

| 環境変数 | 説明 |
|---------|------|
| `CLAUDE_CODE_USE_BEDROCK` | `1` に設定するとBedrock経由で動作 |
| `AWS_REGION` | Bedrockのリージョン |
| `ANTHROPIC_MODEL` | 使用するモデルID |

#### 2.2 AWS認証情報の確認

AWS Bedrockを使用するには、AWS認証情報が設定済みである必要があります。

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
        "bedrock:InvokeModelWithResponseStream",
        "bedrock:ListFoundationModels"
      ],
      "Resource": "*"
    }
  ]
}
```

### 3. Claude Codeの起動

ターミナルで以下のコマンドを実行します：

```bash
claude
```

対話型セッションが開始されます。プロンプトに指示を入力してEnterキーで実行します。

**便利なオプション**:

| コマンド | 説明 |
|---------|------|
| `claude` | 対話型セッションを開始 |
| `claude "指示内容"` | 初期プロンプト付きで起動 |
| `claude -c` | 前回のセッションを続行 |

### 4. 動作確認

Claude Codeが正しく動作しているか確認します：

1. ターミナルで Claude Code を起動：
   ```bash
   claude
   ```
2. 以下のプロンプトを入力：
   ```
   testフォルダに「hello.txt」というファイルを作成して、その中に「Hello, Claude Code!」と書き込んでください
   ```
3. Claude Codeがファイル作成の承認を求めてくるので確認して承認
4. `test/hello.txt` が作成されれば設定は成功です

## Claude Codeの使い方

### 基本的な使い方

Claude Codeはターミナルに指示を入力するだけで、必要な操作を自動的に行います：

1. **コード生成**: 「〜のコードを作成してください」
2. **ファイル操作**: ファイルの作成・編集・削除を自動実行
3. **ターミナル操作**: コマンドの実行（terraform apply、ssh接続など）

### ワークショップでの使い方

このワークショップでは、Claude Codeに以下のような指示を出します：

- Terraform コードの生成と実行（`terraform init` → `plan` → `apply`）
- EC2 への SSH 接続とソフトウェアインストール
- Ansible Playbook の作成と実行

### 承認ワークフロー

Claude Codeは操作を実行する前に承認を求めます：

- **ファイル作成・編集**: 変更内容が表示されます → 内容を確認して承認
- **ターミナルコマンド**: 実行するコマンドが表示されます → コマンドを確認して承認

> **重要**: 特に `terraform apply` や `ssh` コマンドなど、実際のインフラに影響するコマンドは内容をよく確認してから承認してください。

## トラブルシューティング

### 問題1: Claude Codeが起動しない

**解決方法**:
1. Node.js / npm がインストールされているか確認（`node --version`）
2. Claude Codeがインストールされているか確認（`which claude`）
3. npm prefix が正しいか確認（`npm config get prefix` → `~/.local` であること）
4. 再インストール:
   ```bash
   npm config set prefix "$HOME/.local"
   npm install -g @anthropic-ai/claude-code
   ```

### 問題2: AWS Bedrockへの接続エラー

**解決方法**:
1. 環境変数が正しく設定されているか確認（`echo $CLAUDE_CODE_USE_BEDROCK`）
2. AWS認証情報が正しく設定されているか確認（`aws sts get-caller-identity`）
3. IAMポリシーに `bedrock:InvokeModel` 権限があるか確認
4. リージョンが正しいか確認（`echo $AWS_REGION`）

### 問題3: モデルが応答しない

**解決方法**:
1. `ANTHROPIC_MODEL` 環境変数が正しいか確認
2. ネットワーク接続を確認
3. AWS Bedrockのサービス状態を確認

### 問題4: 環境変数が読み込まれない

**解決方法**:
1. `.env` ファイルが作成済みか確認
2. セットアップスクリプトを再実行して自動読み込み設定を反映:
   ```bash
   ./scripts/setup_devspaces.sh
   ```
3. 新しいターミナルを開くか `source ~/.bashrc` を実行

## 参考リンク

- [Claude Code 公式ドキュメント](https://docs.anthropic.com/en/docs/claude-code)
- [AWS Bedrock公式ドキュメント](https://docs.aws.amazon.com/bedrock/)
- [AWS Bedrock利用可能モデル](https://docs.aws.amazon.com/bedrock/latest/userguide/model-ids.html)
