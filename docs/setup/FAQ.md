# セットアップFAQ

## Q: セットアップスクリプトはどの環境で実行する想定ですか？

**A: OpenShift DevSpaces環境内で実行する想定です。**

セットアップスクリプト（`scripts/setup_devspaces.sh`）は、OpenShift DevSpacesのワークスペース内で実行することを前提としています。このスクリプトは以下のツールをインストールします：

- Terraform
- Ansible
- AWS CLI
- Pythonパッケージ
- Git
- jq

これらのツールは、DevSpaces環境内でトレーニングを実施するために必要です。

## Q: DevSpacesで実行する想定であれば、どのようにして資材をDevSpacesの環境下に持ち込みますか？

**A: Gitリポジトリからクローンして持ち込みます。**

以下の手順で資材をDevSpaces環境に持ち込んでください：

### 手順1: DevSpacesワークスペースの作成
1. OpenShift DevSpacesのURLにアクセス
2. ログイン
3. 新しいワークスペースを作成（スタック: Python 3.11 または Node.js 18）

### 手順2: Gitリポジトリのクローン
DevSpaces環境内のターミナルで以下のコマンドを実行：

```bash
# リポジトリをクローン
git clone https://github.com/kifujii/ai_agentic_development.git
cd ai_agentic_development

# trainingブランチに切り替え
git checkout training

# プロジェクトディレクトリに移動
cd ai_agentic
```

### 手順3: セットアップスクリプトの実行
```bash
# セットアップスクリプトを実行
chmod +x scripts/setup_devspaces.sh
./scripts/setup_devspaces.sh
```

## Q: ローカル環境（自分のPC）で実行することはできますか？

**A: 可能ですが、推奨されません。**

セットアップスクリプトはDevSpaces環境を前提としていますが、ローカル環境でも実行可能です。ただし、以下の点に注意してください：

- ローカル環境のOS（Linux、macOS、Windows）によって動作が異なる可能性があります
- `sudo`権限が必要な場合があります
- DevSpaces環境と異なる動作をする可能性があります

ローカル環境で実行する場合は、手動インストール手順（`docs/setup/DEVSPACES_SETUP.md`の「手動インストール」セクション）を参照してください。

## Q: DevSpaces環境でGitが使えない場合はどうすればいいですか？

**A: 以下の代替方法があります：**

### 方法1: ファイルのアップロード
1. ローカルでリポジトリをクローン
2. ファイルをZIPに圧縮
3. DevSpaces環境にZIPファイルをアップロード
4. 解凍

### 方法2: 手動でのコピー
1. ローカルでリポジトリをクローン
2. 必要なファイルをDevSpaces環境に手動でコピー

### 方法3: DevSpacesのGit統合機能を使用
DevSpacesにはGit統合機能がある場合があります。DevSpacesのドキュメントを参照してください。

## Q: セットアップスクリプトの実行にsudo権限が必要ですが、DevSpaces環境でsudoが使えない場合はどうすればいいですか？

**A: 手動インストール手順を参照してください。**

DevSpaces環境によっては、`sudo`権限が制限されている場合があります。その場合は、以下の手順を参照してください：

1. `docs/setup/DEVSPACES_SETUP.md`の「手動インストール」セクションを参照
2. ユーザー権限でインストール可能な方法を選択
3. 必要に応じて、DevSpaces管理者に権限の付与を依頼

## Q: セットアップスクリプトの実行中にエラーが発生した場合はどうすればいいですか？

**A: トラブルシューティングセクションを参照してください。**

`docs/setup/DEVSPACES_SETUP.md`の「トラブルシューティング」セクションに、よくある問題と解決方法が記載されています。

よくある問題：
- 権限エラー
- パッケージインストールエラー
- AWS認証エラー
- APIキーエラー

## Q: セットアップ完了後、どのようにトレーニングを開始すればいいですか？

**A: セッション0のガイドから開始してください。**

1. `docs/session_guides/session0_guide.md`を開く
2. 手順に従って進める
3. 各セッションのガイドを順番に参照

詳細は `docs/TRAINING_MENU.md` を参照してください。
