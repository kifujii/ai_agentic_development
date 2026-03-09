# セッション3：EC2 を count でスケールアウト 評価チェックリスト

## 事前準備
- [ ] セッション2が完了していること（EC2にnginxがインストール済み）
- [ ] EC2のIPアドレスを確認した

## Step 1: count でEC2を2台に増加
- [ ] `aws_instance` に `count = 2` を追加した
- [ ] `outputs.tf` を複数台に対応させた（splat 式 `[*]`）
- [ ] `terraform plan` で「1台追加」の差分を確認した
- [ ] `terraform apply` が成功し、EC2が2台 running になった

## Step 2: 2台のEC2を確認
- [ ] `terraform output` で2台分のIPアドレスを確認した
- [ ] 2台ともブラウザで nginx にアクセスできた

## Step 3: targeted destroy で1台だけ削除
- [ ] `terraform destroy -target` で2台目だけを削除した
- [ ] 1台目が残っていることを確認した
- [ ] コードを1台構成に戻した（count 削除 or count = 1）
- [ ] `terraform plan` で差分がないことを確認した

## 成果物
- [ ] `terraform/vpc-ec2/` のEC2が1台構成に戻っている
- [ ] `terraform plan` で差分がない状態

---

## 理解度チェック（自分の言葉で書いてみましょう）

- [ ] Q: `count` を使うとどんなメリットがありますか？
  - A: _______________
- [ ] Q: `terraform destroy -target` はどんな場面で使いますか？注意点は？
  - A: _______________
- [ ] Q: targeted destroy 後にコードを修正する必要があるのはなぜですか？
  - A: _______________

## プロンプトの振り返り

- [ ] count 導入時の output 修正（splat 式）をAgentが正しく行えたか
  - 振り返り: _______________
