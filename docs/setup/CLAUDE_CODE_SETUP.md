# Claude Code セットアップガイド

## 概要

このワークショップでは、Claude Code（CLIベースの AI コーディング Agent）を使用します。Claude Code は AWS Bedrock をモデルプロバイダーとして使用し、Claude Sonnet 4.6 でコード生成・ファイル操作・ターミナル実行などを自律的に行います。

## Claude Codeとは

Claude Code は、ターミナルから直接利用できる自律型 AI コーディング Agent です。ファイルの作成・編集、ターミナルコマンドの実行など、開発に必要な操作を AI Agent が自動で行います。各操作の実行前に承認を求めるため、安全に利用できます。

- **公式ドキュメント**: https://docs.anthropic.com/en/docs/claude-code

## セットアップ状況

### ハンズオン環境（ブラウザ版 VSCode）の場合

ハンズオン環境では、以下がすべて**事前設定済み**です：

- Claude Code のインストール
- AWS Bedrock の認証情報（IAM ユーザーのクレデンシャル）
- Claude Code の設定ファイル（`.claude/settings.local.json`）

受講者が追加で設定する必要はありません。

### 設定ファイルの内容

Claude Code は `.claude/settings.local.json` で Bedrock 接続を管理しています。ハンズオン環境には以下の設定が配置済みです：

```json
{
    "env": {
        "CLAUDE_CODE_ENABLE_TELEMETRY": "false",
        "CLAUDE_CODE_USE_BEDROCK": "true",
        "AWS_REGION": "ap-northeast-1",
        "ANTHROPIC_MODEL": "arn:aws:bedrock:ap-northeast-1:<ACCOUNT_ID>:inference-profile/jp.anthropic.claude-sonnet-4-6"
    }
}
```

| 設定項目 | 説明 |
|---------|------|
| `CLAUDE_CODE_ENABLE_TELEMETRY` | テレメトリを無効化（企業環境向け） |
| `CLAUDE_CODE_USE_BEDROCK` | `"true"` に設定するとBedrock経由で動作 |
| `AWS_REGION` | Bedrockのリージョン |
| `ANTHROPIC_MODEL` | Bedrock inference profile の ARN（アカウントID含む） |

> **注意**: `.claude/settings.local.json` は `.gitignore` で無視されるため、Git 管理対象外です。ハンズオン環境では環境構築時に自動配置されています。

## Claude Codeの起動

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

## 動作確認

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

> 💡 Claude Code の操作方法は **[セッション0：Claude Code に慣れよう](../session_guides/session0_guide.md)** でハンズオン形式で学びます。以下はリファレンスとしてご利用ください。

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
1. Claude Code がインストールされているか確認（`which claude`）
2. 見つからない場合は講師に確認してください

### 問題2: ログイン画面が表示される（Bedrockに接続できない）

**原因**: `.claude/settings.local.json` が存在しないか、設定が不正です。

**解決方法**:
1. 設定ファイルが存在するか確認：
   ```bash
   cat .claude/settings.local.json
   ```
2. 存在しない場合はハンズオン資材のクローン手順を再実行してください
3. それでも解決しない場合は講師に確認してください

### 問題3: AWS Bedrockへの接続エラー

**解決方法**:
1. AWS認証情報が正しく設定されているか確認（`aws sts get-caller-identity`）
2. `.claude/settings.local.json` の `AWS_REGION` が `ap-northeast-1` になっているか確認
3. 上記に問題がない場合は講師に確認してください

### 問題4: モデルが応答しない

**解決方法**:
1. `.claude/settings.local.json` の `ANTHROPIC_MODEL` が正しいARN形式か確認
2. ネットワーク接続を確認
3. 講師に確認してください

## 参考リンク

- [Claude Code 公式ドキュメント](https://docs.anthropic.com/en/docs/claude-code)
- [AWS Bedrock公式ドキュメント](https://docs.aws.amazon.com/bedrock/)
- [AWS Bedrock利用可能モデル](https://docs.aws.amazon.com/bedrock/latest/userguide/model-ids.html)
