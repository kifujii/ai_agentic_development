# セッション7：未知の技術を AI で攻略する（1.5時間）

## 学習目標

- 従来とは異なる構成（サーバーレス）でも AI Agent を使うことで解を導き出してみる

## シナリオ

あなたのチームリーダーから Slack でメッセージが届きました。

> 「社内ハッカソンのデモ用に、**メッセージボード API** を作ってほしい。
> メッセージを投稿して、一覧を取得できるシンプルなやつでいい。
> サーバーを立てるほどでもないので、**サーバーレス**でやってほしい。
> Lambda と API Gateway を使えばすぐできるらしい。よろしく。」

あなたは Lambda も API Gateway も DynamoDB も使ったことがありません。
しかし、Terraform と AI が使えれば恐れることはありません。

---

## 🎯 ゴール

以下の状態になっていれば完了です：

- `POST /messages` でメッセージを投稿できる
- `GET /messages` で投稿されたメッセージ一覧を取得できる
- データが永続化されている（API を再起動してもデータが残る）
- すべて Terraform で管理されている
- `curl` でエンドポイントを叩いて動作確認ができる

### 要件

- **POST** `/messages` — `name` と `message` を受け取って保存する
- **GET** `/messages` — 保存されたメッセージ一覧を JSON で返す
- レスポンス例:

```json
[
  {"name": "田中", "message": "ハッカソン楽しい！", "timestamp": "2026-03-09T10:00:00Z"},
  {"name": "鈴木", "message": "API できた！", "timestamp": "2026-03-09T10:05:00Z"}
]
```

- Lambda のランタイムは Python
- Terraform で `terraform apply` / `terraform destroy` が正常に動作する

---

## 進め方

### Phase 1: 設計（20分）

まず **Plan モード**（対話中に `Shift + Tab` または `/plan` で切り替え）で、何が必要かを AI と一緒に整理してください。

あなたが知らないことを AI に聞いて構いません。例えば：

- Lambda とは何か、EC2 と何が違うのか
- API Gateway は何をするものか
- データを保存するにはどうすればいいか
- Lambda を動かすために必要な AWS リソースは何か
- Terraform でどういうファイル構成にすべきか

**自分が納得できるまで設計を詰めてから**、Phase 2 に進んでください。

### Phase 2: 構築（45分）

Plan モードを解除して、設計した内容を Terraform で実装してください。

一度にすべて作る必要はありません。おすすめの進め方：

1. まず Lambda + API Gateway だけで GET が動くことを確認
2. データストアを追加して POST → GET の流れを実装
3. 動作確認しながら少しずつ拡張

### Phase 3: 動作確認と理解（25分）

- `curl` で POST してメッセージを投稿し、GET で一覧が返ることを確認
- 複数回 POST して、データが蓄積されることを確認
- AI に「今作った構成を図にして説明して」と聞いてみる

---

## ヒント

<details>
<summary>💡 最低限必要な AWS リソース</summary>

- Lambda 関数（Python）
- IAM ロール（Lambda 用）
- API Gateway（POST と GET のルート）
- データストア（DynamoDB がサーバーレスと相性が良い）
- Lambda からデータストアにアクセスするための IAM 権限

</details>

<details>
<summary>💡 Terraform のファイル構成</summary>

`terraform/` の下に新しいディレクトリを作ることを推奨します。VPC/EC2 とは独立した構成です。

</details>

<details>
<summary>💡 うまくいかないとき</summary>

- Lambda の実行ログは CloudWatch Logs で確認できます
- API Gateway のエンドポイント URL は Terraform の output で取得できます
- 権限まわりのエラーが出やすいので、IAM ロールの設定を確認してください
- POST でデータが保存されない場合、Lambda のログを確認しましょう

</details>

---

## 📚 事前準備

> ⚠️ **環境変数が未設定の場合**: `echo $TF_VAR_prefix` で値が表示されない場合は講師に確認してください。

- これまでのセッションで Terraform の基本操作に慣れていること
- Lambda や API Gateway の事前知識は不要（AI と一緒に学びます）

---

## ⚠️ リソースの削除

> **ワークショップ期間中はリソースを削除しないでください。** ここで作ったメッセージボード API はセッション8で拡張します。
>
> 全セッション終了後の削除手順は [README](../../README.md#注意事項) を参照してください。

---

## ➡️ 次のステップ

[セッション8：本番リリースの設計判断](session8_guide.md) に進んでください。
