# GitHub連携コマンド集

このファイルには、GitHubリポジトリに連携するためのコマンドが記載されています。
ターミナルで順番に実行してください。

## 初回セットアップ

```bash
# 1. プロジェクトディレクトリに移動
cd /home/kifujii/Desktop/projects/NIT/ai_agentic

# 2. Gitリポジトリの状態を確認
git status

# 3. ブランチ名をmainに変更（必要に応じて）
git branch -m main

# 4. すべてのファイルをステージング
git add .

# 5. 初回コミット
git commit -m "Initial commit: 生成AI活用トレーニングメニュー資材の追加

- トレーニングメニュー詳細ドキュメント
- セッションガイド（0-6）
- DevSpaces環境セットアップ手順
- Terraform/Ansibleサンプルコード
- AIエージェントテンプレート
- 評価チェックリスト"

# 6. GitHubリポジトリのURLを追加（YOUR_USERNAMEとリポジトリ名を置き換えてください）
# HTTPSの場合:
git remote add origin https://github.com/YOUR_USERNAME/ai-agentic-training.git

# またはSSHの場合:
# git remote add origin git@github.com:YOUR_USERNAME/ai-agentic-training.git

# 7. リモートリポジトリの確認
git remote -v

# 8. GitHubにプッシュ
git push -u origin main
```

## 今後の更新手順

```bash
# 1. 変更を確認
git status

# 2. 変更をステージング
git add .

# 3. コミット
git commit -m "変更内容の説明"

# 4. プッシュ
git push
```

## 注意事項

- `.env`ファイルは自動的に除外されます（機密情報を含むため）
- `.env.example`ファイルは含まれます（テンプレートとして）
- Terraform状態ファイル（`*.tfstate`）も自動的に除外されます

詳細は `docs/GITHUB_SETUP.md` を参照してください。
