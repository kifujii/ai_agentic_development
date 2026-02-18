# 環境セットアップガイド

このドキュメントでは、ワークショップに必要な環境のセットアップ手順を説明します。

## 📋 前提条件

- **GitHub アカウント**: リポジトリへのアクセス用
- **AWS アカウント**: トレーニング用（アクセスキー/シークレットキー）
- **OpenShift DevSpaces へのアクセス**: 開発環境
- **VS Code または Cursor エディタ**: Continue拡張機能を使用

## 🚀 セットアップ手順

### ステップ1: DevSpaces環境への資材の持ち込み

#### 1.1 DevSpacesワークスペースの作成

1. OpenShift DevSpacesのURLにアクセス
2. ログイン
3. 新しいワークスペースを作成
   - **Import from Git**: このリポジトリのURLを指定

### ステップ2: 環境セットアップスクリプトの実行

**重要**: セットアップスクリプトは **OpenShift DevSpaces環境内** で実行する必要があります。

1. **ターミナルを開く**
   - VS Codeのメニューから「ターミナル」→「新しいターミナル」を選択
   - または、ショートカットキー（`Ctrl+Shift+C` / `Cmd+Shift+C`）を使用

2. **セットアップスクリプトの実行**
   ```bash
   ./scripts/setup_devspaces.sh
   ```

**インストールされるツールと拡張機能**:
- **ツール**:
  - Terraform（~/.local/binにインストール）
  - Ansible（pipでユーザー権限インストール）
  - AWS CLI（~/.local/binにインストール）
  - Pythonパッケージ（scripts/requirements.txtから、--userオプションでインストール）
  - Git（既にインストールされている場合が多い）
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
- `your-access-key-here` → AWSアクセスキーID
- `your-secret-key-here` → AWSシークレットアクセスキー

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
- Continue設定ファイル（`.continue/config.json`）の作成

#### 3.3 AWS認証情報の確認

AWS認証情報が正しく設定されているか確認します：

```bash
aws sts get-caller-identity
```

### ステップ4: 動作確認

#### 4.1 Continue AIの確認

1. **Continueを起動**
   - 方法1: 左側のサイドバーからContinueアイコンをクリック
   - 方法2: ショートカットキー（`Ctrl+L` / `Cmd+L`）を使用

2. **Agentモードで動作確認**
   - Continueのチャット画面で、Agentモードを有効化
   - チャットに以下を入力：
     ```
     testフォルダに「hello.txt」というファイルを作成して、その中に「Hello, Continue!」と書き込んでください
     ```
   - AIが`test`フォルダを作成し、`hello.txt`ファイルを作成して内容を書き込めば、設定は成功です

## ✅ セットアップ完了チェックリスト

- [ ] DevSpacesワークスペースを作成した
- [ ] セットアップスクリプトを実行した
- [ ] `.env`ファイルを作成し、AWS認証情報を設定した
- [ ] セットアップスクリプトを再実行してAWS CLI設定ファイルを作成した
- [ ] AWS認証情報が正しく設定されていることを確認した（`aws sts get-caller-identity`）
- [ ] Continue AIが正常に動作することを確認した（Agentモードでファイル作成テスト）

## 🆘 トラブルシューティング

よくある問題と解決方法は [`docs/setup/FAQ.md`](../setup/FAQ.md) を参照してください。

## 📚 次のステップ

環境セットアップが完了したら、[README.md](../../README.md) に戻ってワークショップを開始してください。
