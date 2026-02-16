# Continue AI セットアップガイド

## 概要

このワークショップでは、Continue AI（VS Code/Cursor拡張機能）を使用してAIアシスタントを活用します。Continueは、OpenShiftAIをモデルプロバイダーとして使用します。

## Continueとは

Continueは、VS CodeやCursorエディタで動作するAIコーディングアシスタントです。コード生成、レビュー、リファクタリングなどの開発タスクを支援します。

- **公式サイト**: https://continue.dev/
- **GitHub**: https://github.com/continue-dev/continue

## セットアップ手順

### 1. Continue拡張機能のインストール

#### VS Codeを使用する場合
1. VS Codeを開く
2. 拡張機能パネルを開く（`Ctrl+Shift+X` / `Cmd+Shift+X`）
3. "Continue"を検索
4. "Continue"をインストール

#### Cursorを使用する場合
1. Cursorを開く
2. 拡張機能パネルを開く（`Ctrl+Shift+X` / `Cmd+Shift+X`）
3. "Continue"を検索
4. "Continue"をインストール

### 2. OpenShiftAIの設定

#### 2.1 OpenShiftAIエンドポイントの取得

OpenShiftAIの管理者から以下を取得してください：
- **エンドポイントURL**: `https://your-openshiftai-endpoint/v1`
- **APIキー**: OpenShiftAIのAPIキー

#### 2.2 Continue設定ファイルの編集

プロジェクトルートの `.continue/config.json` を編集します：

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

**設定項目の説明**:
- `apiBase`: OpenShiftAIのエンドポイントURL（`/v1`で終わる）
- `apiKey`: OpenShiftAIのAPIキー
- `model`: 使用するモデル名（OpenShiftAIで利用可能なモデル名を指定）

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

### 問題2: OpenShiftAIへの接続エラー

**解決方法**:
1. エンドポイントURLが正しいか確認（`/v1`で終わっているか）
2. APIキーが正しいか確認
3. ネットワーク接続を確認
4. OpenShiftAIの管理者に問い合わせ

### 問題3: モデルが応答しない

**解決方法**:
1. 使用しているモデル名がOpenShiftAIで利用可能か確認
2. エンドポイントURLとAPIキーを再確認
3. OpenShiftAIのサービス状態を確認

## 参考リンク

- [Continue公式ドキュメント](https://continue.dev/docs)
- [Continue GitHub](https://github.com/continue-dev/continue)
- [OpenShiftAI公式ドキュメント](https://www.redhat.com/en/technologies/cloud-computing/openshift/openshift-ai)
