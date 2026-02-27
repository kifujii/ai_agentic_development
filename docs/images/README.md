# アーキテクチャ構成図

各セッションの「最終的な目標構成」にはAWS公式アイコンを使った構成図を使用しています。

## ファイル構成

| ソースファイル (.drawio) | 表示用ファイル (.svg) | 内容 |
|-------------------------|----------------------|------|
| `session1_target.drawio` | `session1_target.svg` | Session 1: VPC + EC2 構成 |
| `session2_target.drawio` | `session2_target.svg` | Session 2: ALB + ECS + RDS 構成 |
| `session3_target.drawio` | `session3_target.svg` | Session 3: Ansible ワークフロー |
| `session4_target.drawio` | `session4_target.svg` | Session 4: CloudWatch Agent 構成 |
| `session5_target.drawio` | `session5_target.svg` | Session 5: 情報収集・レポート生成 |

## 編集方法

1. `.drawio` ファイルを [draw.io](https://app.diagrams.net/) で開く
2. AWSアイコンライブラリを使って編集
3. SVGにエクスポート:

```bash
# CLI でエクスポート（drawio がインストール済みの場合）
drawio --no-sandbox -x -f svg --embed-svg-images -o session1_target.svg session1_target.drawio
```

> `.drawio` ファイルはダイアグラムのソースファイルです。SVGを再生成する際に必要なため、リポジトリに含めています。
