# セッション0：AI x IaC基礎実践 詳細ガイド

## 目標
Prompt Engineering、Context Engineering、AI Agentの実践を通じて、AI x IaCの基礎を習得する。

## 事前準備
- OpenShift DevSpaces環境へのアクセス
- AWS認証情報（アクセスキー、シークレットキー）
- 生成AI APIキー（OpenAI、Anthropicなど）
- 必要なツールのインストール確認

## 手順

### 1. 環境セットアップ（15分）

#### 1.1 OpenShift DevSpaces環境の確認
```bash
# 現在のディレクトリ確認
pwd

# 環境変数の確認
env | grep -E "AWS|OPENAI|ANTHROPIC"

# Python/Node.jsのバージョン確認
python3 --version
node --version
```

#### 1.2 AWS CLI/認証情報の設定
```bash
# AWS CLIのインストール確認
aws --version

# AWS認証情報の設定
aws configure
# AWS Access Key ID: [入力]
# AWS Secret Access Key: [入力]
# Default region name: ap-northeast-1
# Default output format: json

# 認証情報の確認
aws sts get-caller-identity
```

#### 1.3 生成AI APIキーの設定確認
```bash
# 環境変数の設定（例：OpenAI）
export OPENAI_API_KEY="your-api-key-here"

# または .envファイルの作成
cat > .env << EOF
OPENAI_API_KEY=your-api-key-here
ANTHROPIC_API_KEY=your-api-key-here
EOF

# .envファイルの読み込み（Pythonの場合）
# pip install python-dotenv
```

#### 1.4 必要なツールのインストール確認
```bash
# Terraformのインストール確認
terraform version

# Ansibleのインストール確認
ansible --version

# Pythonパッケージのインストール
pip install openai anthropic python-dotenv boto3
```

### 2. Prompt Engineering実践（30分）

#### 2.1 基本的なプロンプトの作成
**タスク**: EC2インスタンスを作成するTerraformコードを生成する

**悪い例**:
```
EC2を作成して
```

**良い例**:
```
以下の要件でEC2インスタンスを作成するTerraformコードを生成してください。

要件:
- リージョン: ap-northeast-1
- インスタンスタイプ: t3.micro
- AMI: Amazon Linux 2023
- セキュリティグループ: SSH（ポート22）のみ許可
- タグ: Name = "training-ec2", Environment = "training"

出力形式:
- HCL形式のTerraformコード
- 変数定義を含める
- コメントを適切に追加
```

#### 2.2 プロンプトテンプレートの作成
`templates/prompts/terraform_ec2_template.txt`を作成:

```
以下の要件で{resource_type}を作成するTerraformコードを生成してください。

要件:
- リージョン: {region}
- {specific_requirements}

出力形式:
- HCL形式のTerraformコード
- 変数定義を含める
- コメントを適切に追加
- ベストプラクティスに従う
```

#### 2.3 段階的なプロンプト最適化
1. **第1段階**: 基本的な要件を記述
2. **第2段階**: エラーフィードバックを反映
3. **第3段階**: ベストプラクティスを追加
4. **第4段階**: 再利用可能なテンプレート化

### 3. Context Engineering実践（20分）

#### 3.1 AWSリソース情報のコンテキスト化
```python
import boto3

def get_aws_context():
    """AWSリソース情報を取得してコンテキスト化"""
    ec2 = boto3.client('ec2')
    
    # 利用可能なAMIの取得
    amis = ec2.describe_images(
        Owners=['amazon'],
        Filters=[
            {'Name': 'name', 'Values': ['amzn2-ami-hvm-*']},
            {'Name': 'state', 'Values': ['available']}
        ]
    )
    
    # リージョン情報の取得
    regions = ec2.describe_regions()
    
    context = {
        'available_amis': amis['Images'][:5],
        'regions': [r['RegionName'] for r in regions['Regions']],
        'current_region': ec2.meta.region_name
    }
    
    return context
```

#### 3.2 既存コードのコンテキスト活用
```python
def load_existing_terraform_code(directory):
    """既存のTerraformコードを読み込んでコンテキスト化"""
    import os
    
    context = {
        'existing_resources': [],
        'variables': [],
        'outputs': []
    }
    
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.tf'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r') as f:
                    content = f.read()
                    # リソース名の抽出など
                    # ...
    
    return context
```

### 4. AI Agent実践（25分）

#### 4.1 シンプルなAIエージェントの実装
`templates/ai_agents/simple_agent_template.py`を参照して実装。

基本的な流れ:
1. プロンプトの作成
2. LLM APIの呼び出し
3. コード生成
4. コードの検証
5. 実行（オプション）

#### 4.2 エージェントの動作確認
```python
# エージェントのテスト
from simple_agent import SimpleTerraformAgent

agent = SimpleTerraformAgent(api_key=os.getenv('OPENAI_API_KEY'))

result = agent.generate_code(
    prompt="EC2インスタンスを作成するTerraformコードを生成してください。"
)

print(result['code'])
print(result['validation'])
```

### 5. AI x IaCを使ったEC2の設計・構築・検証（20分）

#### 5.1 自然言語指示による設計
指示例:
```
ap-northeast-1リージョンに、t3.microインスタンスタイプのEC2インスタンスを作成してください。
セキュリティグループはSSH（ポート22）のみ許可し、Nameタグに"training-ec2"を設定してください。
```

#### 5.2 AIを活用したTerraformコード生成
エージェントを使用してコード生成:
```python
code = agent.generate_code(
    prompt=instruction,
    context=get_aws_context()
)
```

#### 5.3 生成コードの検証と修正
```bash
# Terraformフォーマット
terraform fmt

# Terraform検証
terraform validate

# 実行計画の確認
terraform plan
```

#### 5.4 EC2インスタンスの構築と動作確認
```bash
# リソースの作成
terraform apply

# AWSコンソールでの確認
aws ec2 describe-instances --filters "Name=tag:Name,Values=training-ec2"

# SSH接続テスト（可能な場合）
ssh -i your-key.pem ec2-user@<public-ip>
```

## チェックリスト

- [ ] 環境セットアップが完了した
- [ ] AWS認証情報が正しく設定されている
- [ ] 生成AI APIキーが設定されている
- [ ] 基本的なプロンプトを作成した
- [ ] プロンプトテンプレートを作成した
- [ ] Context Engineeringの実践を行った
- [ ] シンプルなAIエージェントを実装した
- [ ] EC2インスタンスをAIを活用して構築した
- [ ] 構築結果を検証した

## トラブルシューティング

### AWS認証エラー
- 認証情報が正しく設定されているか確認
- IAM権限が適切か確認

### APIキーエラー
- 環境変数が正しく設定されているか確認
- APIキーが有効か確認

### Terraformエラー
- プロバイダーのバージョンを確認
- リソース名の重複を確認

## 参考資料
- `templates/ai_agents/simple_agent_template.py`
- `sample_code/terraform/basic_ec2/`
