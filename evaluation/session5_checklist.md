# セッション5：サーバー情報取得・運用レポート作成 評価チェックリスト（任意・発展）

## Step 1: サーバー情報収集
- [ ] gather_info.yml を作成・実行した
- [ ] サーバー情報がJSON形式で保存された

## Step 2: レポートテンプレート
- [ ] server_report.md.j2 を作成した
- [ ] アラート条件（メモリ80%超等）が含まれている

## Step 3: レポート生成
- [ ] generate_report.yml を作成・実行した
- [ ] レポートファイルが reports/ フォルダに生成された

## 成果物
- [ ] `ansible/playbooks/` に情報収集・レポート生成Playbookが存在する
- [ ] `ansible/templates/` にJinja2テンプレートが存在する
- [ ] `ansible/reports/` にレポートが生成されている
