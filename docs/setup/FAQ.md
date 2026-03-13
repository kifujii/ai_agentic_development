# セットアップFAQ

## Q: ハンズオン環境にはどうやってアクセスしますか？

**A: ブラウザから配布された URL にアクセスしてください。**

AWS EC2 上にブラウザ版 VSCode（code-server）が構築されています。講師から配布された URL とパスワードを使ってブラウザからアクセスします。

### 手順
1. 配布された URL（`https://<IP>:<ポート>/`）をブラウザで開く
2. 自己署名証明書の警告が出たら「詳細設定」→「安全でないサイトへ進む」を選択
3. 配布されたパスワードを入力
4. VSCode がブラウザ上で表示されます

## Q: どのツールがプリインストールされていますか？

**A: Terraform, Ansible, AWS CLI, Claude Code, Git がすべてインストール済みです。**

受講者がツールを追加インストールする必要はありません。

## Q: AWS認証情報の設定は必要ですか？

**A: 不要です。環境構築時に設定済みです。**

各参加者の環境には、Bedrock を含む必要な権限が付与された IAM ユーザーの認証情報が事前に設定されています。

確認コマンド:
```bash
aws sts get-caller-identity
```

## Q: PREFIX とは何ですか？

**A: AWS リソース名の接頭辞です。複数人が同じ AWS 環境を使用するため、リソース名の衝突を防ぎます。**

PREFIX は環境構築時に自動設定されています。Terraform では `var.prefix`、AWS CLI では `$PREFIX`（または `$TF_VAR_prefix`）として利用されます。

確認コマンド:
```bash
echo $TF_VAR_prefix
```

値が表示されない場合は講師に確認してください。

## Q: ブラウザで VSCode にアクセスできません

**A: 以下を確認してください。**

1. URL とポート番号が正しいか確認
2. `https://` で始まるURLでアクセスしているか確認（`http://` ではアクセスできません）
3. 自己署名証明書の警告を受け入れたか確認
4. 別のブラウザで試す
5. 解決しない場合は講師に確認

## Q: Claude Code 起動時に「terminal setup」の選択が表示されます

**A: 「Yes, use recommended settings」を選択してください。**

初回起動時に以下のようなプロンプトが表示される場合があります：

```
Use Claude Code's terminal setup?
❯ 1. Yes, use recommended settings
  2. No, maybe later with /terminal-setup
```

「**1. Yes, use recommended settings**」を選択してください。これは Shift+Enter で改行入力ができるようになる設定で、長いプロンプトの入力に便利です。

## Q: セットアップ完了後、どのようにトレーニングを開始すればいいですか？

**A: セッション0のガイドから開始してください。**

[環境セットアップガイド](ENVIRONMENT_SETUP.md) の手順が完了したら、[セッション0：Claude Code に慣れよう](../session_guides/session0_guide.md) に進んでください。

## Q: 環境が正しく設定されているか確認する方法は？

**A: 以下のコマンドで確認できます。**

```bash
terraform version && ansible --version && aws sts get-caller-identity && echo "TF_VAR_prefix=$TF_VAR_prefix"
```

ツールのバージョン、AWS 認証、PREFIX が表示されれば正常です。問題がある場合は講師に確認してください。

## Q: check.sh はどこで実行すればいいですか？

**A: Claude Code の外（bash）で実行してください。**

`check.sh` は Claude Code のセッション内ではなく、通常の bash ターミナルで実行します。

1. Claude Code のセッション中であれば `/exit` で bash に戻る
2. `./scripts/check.sh session0` などを実行
3. `claude -c` で Claude Code のセッションを再開

別のターミナルタブで実行しても OK です。
