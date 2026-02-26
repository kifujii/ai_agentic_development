# アーキテクチャ画像の生成方法

各セッションの「最終的な目標構成」にはAWSアイコンを使った構成図画像を使用します。

## 方法1: draw.io（推奨）

1. [draw.io](https://app.diagrams.net/) を開く
2. 左メニューの **検索** で「AWS」と入力し、AWSアイコンライブラリを有効化
3. 各セッションの構成に合わせて図を作成
4. **ファイル → エクスポート → PNG** で書き出し
5. このディレクトリ（`docs/images/`）に保存

### ファイル名規則

| ファイル名 | 内容 |
|-----------|------|
| `session1_target.png` | Session 1: VPC + Subnet + EC2 構成 |
| `session2_target.png` | Session 2: ALB + ECS + RDS 構成 |
| `session3_target.png` | Session 3: Ansible ワークフロー |
| `session4_target.png` | Session 4: CloudWatch Agent 構成 |
| `session5_target.png` | Session 5: 情報収集ワークフロー |

## 方法2: Python `diagrams` ライブラリ

```bash
pip install diagrams
python scripts/generate_diagrams.py
```

> **注意**: `diagrams` ライブラリには [Graphviz](https://graphviz.org/download/) のインストールが必要です。
