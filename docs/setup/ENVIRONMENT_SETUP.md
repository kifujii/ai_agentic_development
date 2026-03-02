# 環境セットアップガイド

このドキュメントでは、ワークショップに必要な環境のセットアップ手順を説明します。

## 📋 前提条件

- **GitHub アカウント**: リポジトリへのアクセス用
- **AWS アカウント**: トレーニング用（アクセスキー/シークレットキー）
- **OpenShift DevSpaces へのアクセス**: 開発環境

## 🚀 セットアップ手順

### ステップ1: DevSpaces環境への資材の持ち込み

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

**インストールされるツール**:
- Terraform 1.14.6（~/.local/binにインストール）
- Ansible（pipでユーザー権限インストール）
- AWS CLI（~/.local/binにインストール）
- Claude Code（npm グローバルインストール）

**インストール後の注意**:
- スクリプト実行後、新しいターミナルを開くか、`source ~/.bashrc`を実行してPATHを更新してください

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

#### 3.2 セットアップスクリプトの再実行（AWS CLI設定 & Claude Code設定の自動作成）

**重要**: `.env`ファイルを編集した後、セットアップスクリプトを再実行してください。以下が自動的に作成されます：
- AWS CLI設定ファイル（`~/.aws/credentials` と `~/.aws/config`）
- Claude Code設定ファイル（`.claude/settings.local.json`）— AWSアカウントIDから自動生成

```bash
./scripts/setup_devspaces.sh
```

#### 3.3 AWS認証情報の確認

```bash
aws sts get-caller-identity
```

### ステップ4: 動作確認

#### 4.1 ツールの確認

```bash
terraform version
```

```bash
ansible --version
```

```bash
aws --version
```

#### 4.2 Claude Codeの確認

1. **Claude Codeを起動**
   ```bash
   claude
   ```

2. **動作確認**
   - 以下のプロンプトを入力：
     ```
     testフォルダに「hello.txt」というファイルを作成して、その中に「Hello, Claude Code!」と書き込んでください
     ```
   - Claude Codeがファイル作成の承認を求めてくるので確認して承認
   - `test/hello.txt` が作成されれば、設定は成功です

## ✅ セットアップ完了チェックリスト

- [ ] DevSpacesワークスペースを作成した
- [ ] セットアップスクリプトを実行した
- [ ] `.env`ファイルを作成し、AWS認証情報を入力した
- [ ] セットアップスクリプトを再実行してAWS CLI設定 & Claude Code設定ファイルを作成した
- [ ] AWS認証情報が正しく設定されていることを確認した（`aws sts get-caller-identity`）
- [ ] Claude Codeが正常に動作することを確認した（ファイル作成テスト）

## 🆘 トラブルシューティング

### 権限エラー
```bash
chmod +x scripts/*.sh
```

### AWS認証エラー
- 認証情報が正しく設定されているか確認
- IAM権限が適切か確認
- リージョンが正しいか確認

### Claude Codeが起動しない
1. Node.js / npm がインストールされているか確認（`node --version`）
2. Claude Codeがインストールされているか確認（`which claude`）
3. 再インストール:
   ```bash
   npm config set prefix "$HOME/.local"
   npm install -g @anthropic-ai/claude-code
   ```

### Claude Codeでログイン画面が表示される
1. `.claude/settings.local.json` が存在するか確認（`cat .claude/settings.local.json`）
2. 存在しない場合、セットアップスクリプトを再実行（`./scripts/setup_devspaces.sh`）
3. 詳細は [Claude Code セットアップガイド](CLAUDE_CODE_SETUP.md) を参照

### AWS Bedrockへの接続エラー
1. `.claude/settings.local.json` に正しいAWSアカウントIDが含まれているか確認
2. AWS認証情報が正しく設定されているか確認（`aws sts get-caller-identity`）
3. AWSリージョンが正しいか確認（`ap-northeast-1`）
4. AWS Bedrockへのアクセス権限があるか確認（IAMポリシー）

### 手動インストールが必要な場合

スクリプトが失敗した場合の手動インストール手順：

<details>
<summary>Terraformの手動インストール</summary>

```bash
mkdir -p ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"
TERRAFORM_VERSION="1.14.6"
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
mv terraform ~/.local/bin/
chmod +x ~/.local/bin/terraform
rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip
source ~/.bashrc
terraform version
```

</details>

<details>
<summary>Ansibleの手動インストール</summary>

```bash
python3 -m pip install --user ansible
ansible --version
```

</details>

<details>
<summary>AWS CLIの手動インストール</summary>

```bash
mkdir -p ~/.local/bin
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install --install-dir ~/.local/aws-cli --bin-dir ~/.local/bin
rm -rf awscliv2.zip aws
source ~/.bashrc
aws --version
```

</details>

<details>
<summary>Claude Codeの手動インストール</summary>

```bash
npm config set prefix "$HOME/.local"
npm install -g @anthropic-ai/claude-code
claude --version
```

</details>

よくある問題と解決方法は [`docs/setup/FAQ.md`](FAQ.md) を参照してください。

## 📚 参考資料

- [Claude Code セットアップガイド](CLAUDE_CODE_SETUP.md) — Claude Codeの詳細設定
- [Terraform公式ドキュメント](https://www.terraform.io/docs)
- [Ansible公式ドキュメント](https://docs.ansible.com/)

## ➡️ 次のステップ

環境セットアップが完了したら、[README.md](../../README.md) に戻ってワークショップを開始してください。
