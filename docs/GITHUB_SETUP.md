# GitHub連携手順書

このドキュメントでは、作成したトレーニング資材をGitHubリポジトリに連携する手順を説明します。

## 前提条件

- GitHubアカウントを持っていること
- Gitがインストールされていること
- SSH鍵が設定されているか、HTTPSでアクセスできること

## 手順

### 1. GitHubリポジトリの作成

1. GitHubにログインします
2. 右上の「+」ボタンをクリックし、「New repository」を選択します
3. リポジトリ情報を入力します：
   - **Repository name**: `ai-agentic-training`（または任意の名前）
   - **Description**: `生成AIを活用したIaCトレーニングメニュー`
   - **Visibility**: Public または Private（お好みで）
   - **Initialize this repository with**: チェックを外す（既存のファイルがあるため）
4. 「Create repository」をクリックします

### 2. ローカルリポジトリの準備

プロジェクトディレクトリで以下のコマンドを実行します：

```bash
# プロジェクトディレクトリに移動
cd /home/kifujii/Desktop/projects/NIT/ai_agentic

# Gitリポジトリが初期化されているか確認
git status

# ブランチ名をmainに変更（必要に応じて）
git branch -m main

# すべてのファイルをステージング
git add .

# 初回コミット
git commit -m "Initial commit: 生成AI活用トレーニングメニュー資材の追加"
```

### 3. GitHubリモートリポジトリの追加

GitHubで作成したリポジトリのURLを取得し、リモートリポジトリとして追加します：

**HTTPSの場合:**
```bash
git remote add origin https://github.com/YOUR_USERNAME/ai-agentic-training.git
```

**SSHの場合:**
```bash
git remote add origin git@github.com:YOUR_USERNAME/ai-agentic-training.git
```

**リモートリポジトリの確認:**
```bash
git remote -v
```

### 4. GitHubへのプッシュ

```bash
# メインブランチをプッシュ
git push -u origin main
```

初回プッシュ時は認証情報の入力が求められる場合があります。

### 5. 確認

GitHubのリポジトリページを開いて、ファイルが正しくアップロードされているか確認してください。

## 今後の作業フロー

### 変更をコミットしてプッシュする場合

```bash
# 変更されたファイルを確認
git status

# 変更をステージング
git add .

# コミット
git commit -m "変更内容の説明"

# プッシュ
git push
```

### ブランチを作成して作業する場合

```bash
# 新しいブランチを作成して切り替え
git checkout -b feature/new-feature

# 変更をコミット
git add .
git commit -m "新機能の追加"

# ブランチをプッシュ
git push -u origin feature/new-feature
```

## 注意事項

### .gitignoreについて

以下のファイルは`.gitignore`に含まれているため、GitHubにアップロードされません：

- `.env`ファイル（認証情報を含む）
- `*.tfstate`ファイル（Terraform状態ファイル）
- `*.pem`、`*.key`ファイル（秘密鍵）
- `venv/`、`env/`（仮想環境）
- その他の一時ファイルや機密情報

### 機密情報の管理

**絶対にGitHubにアップロードしてはいけないもの：**

- AWS認証情報（アクセスキー、シークレットキー）
- 生成AI APIキー
- SSH秘密鍵
- Terraform状態ファイル（機密情報を含む可能性がある）

**推奨される方法：**

1. `.env.example`ファイルを作成して、必要な環境変数のテンプレートを提供する
2. `.env`ファイルは`.gitignore`に含まれているため、ローカルのみに存在する
3. GitHub Secretsを使用してCI/CDで認証情報を管理する

### .env.exampleファイルの作成

```bash
# .env.exampleファイルを作成
cat > .env.example << EOF
# AWS認証情報
AWS_ACCESS_KEY_ID=your-access-key-here
AWS_SECRET_ACCESS_KEY=your-secret-key-here
AWS_DEFAULT_REGION=ap-northeast-1

# 生成AI APIキー
GOOGLE_API_KEY=your-google-api-key-here
EOF

# .env.exampleはコミットに含める
git add .env.example
git commit -m "Add .env.example template"
git push
```

## トラブルシューティング

### 認証エラーが発生する場合

**HTTPSの場合:**
- Personal Access Tokenを使用する必要がある場合があります
- GitHubの設定でPersonal Access Tokenを生成してください

**SSHの場合:**
- SSH鍵がGitHubに登録されているか確認してください
- `ssh -T git@github.com`で接続テストができます

### プッシュが拒否される場合

```bash
# リモートリポジトリの状態を確認
git fetch origin

# リモートの変更をマージ
git pull origin main --rebase

# 再度プッシュ
git push origin main
```

### 大きなファイルをアップロードする場合

GitHubは100MB以上のファイルを直接アップロードできません。必要に応じてGit LFSを使用してください。

## 参考資料

- [Git公式ドキュメント](https://git-scm.com/doc)
- [GitHub公式ドキュメント](https://docs.github.com/)
- [GitHub CLI](https://cli.github.com/)（コマンドラインからGitHubを操作する場合）
