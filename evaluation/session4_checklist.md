# セッション4：サーバー再起動の自動化 評価チェックリスト

## Step 1: Ansible接続設定
- [ ] ansible.cfg を作成した
- [ ] inventory.ini を作成した（実際のIPアドレスを使用）

## Step 2: 接続テスト
- [ ] `ansible all -m ping` で SUCCESS が返った

## Step 3: サーバー状態確認
- [ ] check_status.yml を作成した
- [ ] OS情報・メモリ・ディスク情報が表示された

## Step 4: サーバー再起動
- [ ] restart_server.yml を作成した
- [ ] 再起動前後の状態が表示された
- [ ] サーバーが正常に再起動した

## Step 5: サービス管理
- [ ] manage_services.yml を作成した
- [ ] サービスの状態変更が確認できた

## Step 6: nginx管理
- [ ] maintain_nginx.yml を作成した
- [ ] 設定テスト・再起動・ヘルスチェックが成功した
- [ ] ブラウザでWebページが表示された

## 成果物
- [ ] `ansible/` ディレクトリに設定ファイルとPlaybookが作成されている
