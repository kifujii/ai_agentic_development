# セッション3：サーバー再起動の自動化 評価チェックリスト

## Step 1: 接続設定
- [ ] inventory.ini を作成した
- [ ] ansible.cfg を作成した

## Step 2: 接続テスト
- [ ] `ansible all -m ping` が成功した

## Step 3: サーバー状態確認
- [ ] check_status.yml を作成・実行した
- [ ] OS情報・メモリ・ディスク情報が表示された

## Step 4: サーバー再起動
- [ ] restart_server.yml を作成・実行した
- [ ] 再起動前後のチェックが行われた
- [ ] 再起動が正常に完了した

## Step 5: サービス管理
- [ ] manage_services.yml を作成・実行した
- [ ] サービスの状態変更が確認できた

## 成果物
- [ ] `ansible/` にインベントリ・設定・Playbookが存在する
