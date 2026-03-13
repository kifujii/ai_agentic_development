# セッション7：未知の技術を AI で攻略する（1.5時間）

## シナリオ

あなたのチームリーダーから Slack でメッセージが届きました。

> 「来週のデモ用に、簡単な API が必要になった。
> サーバーを立てるほどでもないので、**サーバーレス**でやってほしい。
> Lambda と API Gateway を使えばすぐできるらしい。よろしく。」

あなたは Lambda も API Gateway も使ったことがありません。
しかし、Terraform と AI があります。

---

## 🎯 ゴール

以下の状態になっていれば完了です：

- API Gateway にリクエストを送ると、Lambda 関数が実行されてレスポンスが返る
- すべて Terraform で管理されている
- `curl` でエンドポイントを叩いて動作確認ができる

### 要件

- **GET リクエスト**で JSON レスポンスを返す API
- レスポンスには少なくとも `message` と `timestamp` を含める
- Lambda のランタイムは Python
- Terraform で `terraform apply` / `terraform destroy` が正常に動作する

---

## 進め方

### Phase 1: 設計（20分）

まず **Plan モード**（`claude --plan` で起動、または対話中に `Shift + Tab` で切り替え）で、何が必要かを AI と一緒に整理してください。

あなたが知らないことを AI に聞いて構いません。例えば：
- Lambda とは何か、EC2 と何が違うのか
- API Gateway は何をするものか
- Lambda を動かすために必要な AWS リソースは何か
- Terraform でどういうファイル構成にすべきか

**自分が納得できるまで設計を詰めてから**、Phase 2 に進んでください。

### Phase 2: 構築（45分）

Plan モードを解除して、設計した内容を Terraform で実装してください。

一度にすべて作る必要はありません。小さく作って動かし、少しずつ拡張していくのがおすすめです。

### Phase 3: 動作確認と理解（25分）

- `curl` でエンドポイントを叩いて、期待通りのレスポンスが返ることを確認
- 作成されたリソースを把握する
- AI に「今作った構成を図にして説明して」と聞いてみる

---

## ヒント

<details>
<summary>💡 最低限必要な AWS リソース</summary>

- Lambda 関数
- IAM ロール（Lambda 用）
- API Gateway
- Lambda と API Gateway の連携設定

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

</details>

---

## 📚 事前準備

> ⚠️ **環境変数が未設定の場合**: `echo $TF_VAR_prefix` で値が表示されない場合は講師に確認してください。

- これまでのセッションで Terraform の基本操作に慣れていること
- Lambda や API Gateway の事前知識は不要（AI と一緒に学びます）

---

## ⚠️ リソースの削除

このセッションで作成したリソースは、完了後に削除してください：

```bash
terraform -chdir=terraform/<作成したディレクトリ> destroy
```

> 💡 ディレクトリ名は AI に任せた場合 `lambda-api` や `serverless` などになっている可能性があります。`ls terraform/` で確認してください。

---

## ➡️ 次のステップ

[セッション8：本番リリースの設計判断](session8_guide.md) に進んでください。
