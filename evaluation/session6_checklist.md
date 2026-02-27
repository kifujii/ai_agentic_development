# セッション6：サーバー情報取得・運用レポート 評価チェックリスト

## Step 1: サーバー情報収集
- [ ] gather_info.yml を作成した
- [ ] サーバー情報が収集・表示された
- [ ] JSONファイルがローカルに取得された

## Step 2: レポートテンプレート
- [ ] server_report.md.j2 を作成した
- [ ] 条件分岐（アラート）やループが含まれている

## Step 3: レポート自動生成
- [ ] generate_report.yml を作成した
- [ ] reports/ フォルダにレポートが生成された
- [ ] レポートにサーバー情報が正しく含まれている

## 成果物
- [ ] `ansible/playbooks/` に情報収集・レポート生成 Playbook が作成されている
- [ ] `ansible/templates/` にJinja2テンプレートが作成されている
- [ ] `ansible/reports/` にレポートが生成されている
