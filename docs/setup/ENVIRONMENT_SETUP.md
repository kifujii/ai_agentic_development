# 環境セットアップガイド

このドキュメントでは、ワークショップに必要な環境のセットアップ手順を説明します。

## 📋 前提条件

- **講師から配布された接続情報**: URL とパスワード
- ブラウザ（Chrome / Edge / Firefox 推奨）

## 🖥️ ハンズオン環境について

本ワークショップでは、AWS EC2 上に構築されたブラウザ版 VSCode（code-server）を使用します。参加者ごとに独立した環境が用意されており、以下のツールがプリインストールされています：

| ツール | 用途 |
|--------|------|
| Terraform | AWSインフラの構築・管理 |
| Ansible | サーバーの設定・運用自動化 |
| AWS CLI | AWSリソースの操作 |
| Claude Code | AI Agent によるコード生成・実行 |
| Git | バージョン管理 |

また、AWS 認証情報（IAM ユーザーの AccessKey / SecretKey）と Claude Code の Bedrock 設定は**環境構築時に設定済み**です。

## 🚀 セットアップ手順

### ステップ1: ブラウザから VSCode にアクセス

1. 講師から配布された **URL**（`https://<IP>:<ポート>/`）をブラウザで開く
2. 自己署名証明書の警告が表示されるため「**詳細設定**」→「**安全でないサイトへ進む**」を選択
3. 配布された **パスワード** を入力してログイン
4. ブラウザ上に VSCode が表示されます

### ステップ2: ハンズオン資材の取得

1. **ターミナルを開く**
   - VSCode のメニューから「ターミナル」→「新しいターミナル」を選択
   - またはショートカットキー `Ctrl+Shift+@`（バッククォート）を使用

2. **ハンズオン資材をクローン**
   ```bash
   git clone --depth 1 https://github.com/kifujii/ai_agentic_development.git tmp && cp -rn tmp/. . && rm -rf tmp
   ```

   > 💡 このコマンドは、GitHub からハンズオン資材を取得し、現在のディレクトリ（Claude Code の設定が既にある場所）にコピーします。

### ステップ3: PREFIX の設定

複数の受講者が同じ AWS 環境を使用するため、リソース名の衝突を防ぐ **PREFIX** を設定します。

1. **`.env.template` から `.env` ファイルを作成**
   ```bash
   cp .env.template .env
   ```

2. **`.env` ファイルを編集して PREFIX を自分のユーザー名に変更**

   VSCode で `.env` ファイルを開き、`PREFIX=` の値を講師から指示された自分のユーザー名に変更します：

   ```bash
   # 受講者固有の設定
   PREFIX=user01   ← ここを自分のユーザー名に変更（例: user03）
   ```

### ステップ4: セットアップスクリプトの実行

```bash
./scripts/setup.sh
```

**スクリプトが行うこと**:
- `.env` から PREFIX を読み取り、環境変数 `TF_VAR_prefix` として設定
- ターミナル起動時に `.env` を自動読み込みする設定を `~/.bashrc` に追加
- 作業ディレクトリ（`terraform/`, `ansible/`, `keys/`）の作成
- インストール済みツールと AWS 認証の動作確認

### ステップ5: 動作確認

#### 5.1 ツールの確認

```bash
terraform version
```

```bash
ansible --version
```

```bash
aws --version
```

#### 5.2 AWS 認証情報の確認

```bash
aws sts get-caller-identity
```

アカウントID と ARN が表示されれば OK です。

#### 5.3 Claude Code の確認

1. **Claude Code を起動**
   ```bash
   claude
   ```

2. **動作確認**
   - 以下のプロンプトを入力：
     ```
     testフォルダに「hello.txt」というファイルを作成して、その中に「Hello, Claude Code!」と書き込んでください
     ```
   - Claude Code がファイル作成の承認を求めてくるので確認して承認
   - `test/hello.txt` が作成されれば、設定は成功です

## ✅ セットアップ完了チェックリスト

- [ ] ブラウザから VSCode にアクセスできた
- [ ] ハンズオン資材をクローンした
- [ ] `.env` ファイルを作成し、PREFIX を自分のユーザー名に変更した
- [ ] セットアップスクリプトを実行した
- [ ] AWS 認証情報が正しく設定されていることを確認した（`aws sts get-caller-identity`）
- [ ] Claude Code が正常に動作することを確認した（ファイル作成テスト）

## 🆘 トラブルシューティング

### ブラウザで VSCode にアクセスできない
- URL とポート番号が正しいか確認してください
- 自己署名証明書の警告を受け入れたか確認してください
- 講師に確認してください

### AWS 認証エラー
- 環境には認証情報が事前設定されています。エラーが出る場合は講師に確認してください

### Claude Code が起動しない
1. Claude Code がインストールされているか確認（`which claude`）
2. `.claude/settings.local.json` が存在するか確認（`cat .claude/settings.local.json`）
3. 上記が見つからない場合は講師に確認してください

### Claude Code でログイン画面が表示される
1. `.claude/settings.local.json` が存在するか確認（`cat .claude/settings.local.json`）
2. 存在しない場合は、資材のクローン手順（ステップ2）を再実行してください
3. 詳細は [Claude Code セットアップガイド](CLAUDE_CODE_SETUP.md) を参照

### PREFIX が反映されない
```bash
source ~/.bashrc
echo $TF_VAR_prefix
```
PREFIX が表示されない場合は、`.env` ファイルの内容を確認してください。

よくある問題と解決方法は [`docs/setup/FAQ.md`](FAQ.md) を参照してください。

## 📚 参考資料

- [Claude Code セットアップガイド](CLAUDE_CODE_SETUP.md) — Claude Code の詳細設定
- [Terraform公式ドキュメント](https://www.terraform.io/docs)
- [Ansible公式ドキュメント](https://docs.ansible.com/)

## ➡️ 次のステップ

環境セットアップが完了したら、[README.md](../../README.md) に戻ってワークショップを開始してください。
