# セッション2：Terraform自動化エージェント 詳細ガイド

## 📋 目的

このセッションでは、Continue AIを活用して、Terraformコード生成・実行を自動化するエージェントの実装方法を学びます。

### 学習目標

- Continue AIを活用したTerraformコード生成の実装方法を理解する
- コード検証とフォーマット機能の実装方法を理解する
- Terraform実行自動化の実装方法を理解する
- エラーハンドリングとリトライ機能の実装方法を理解する

## 🎯 目指すべき構成

このセッション終了時点で、以下の構成が完成していることを目指します：

```
workspace/
└── agents/
    └── terraform_agent/
        ├── agent.py           # メインのエージェントコード
        ├── code_generator.py # コード生成モジュール
        ├── validator.py      # コード検証モジュール
        └── executor.py       # Terraform実行モジュール
```

**エージェントの機能**:
- Continue AIを活用したTerraformコード生成
- コード検証とフォーマット
- Terraform実行の自動化
- エラーハンドリングとリトライ

## 📚 事前準備

- [セッション0](session0_guide.md) が完了していること
- [セッション1](session1_guide.md) で構築したインフラの理解
- Continue AIが正しく設定されていること

## 🚀 手順

### 1. エージェントアーキテクチャの設計（20分）

#### 1.1 エージェントの基本構造

Continue AIを活用したエージェントの基本構造を理解します。

<details>
<summary>📝 エージェントアーキテクチャ例（クリックで展開）</summary>

```python
# agent.py
class TerraformAgent:
    """
    Terraformコード生成・実行自動化エージェント
    
    このエージェントは、Continue AIを活用してTerraformコードを生成し、
    検証・実行まで自動化します。
    """
    
    def __init__(self, aws_context=None):
        self.aws_context = aws_context
        self.validator = TerraformValidator()
        self.executor = TerraformExecutor()
        self.logger = AgentLogger()
    
    def process(self, instruction):
        """
        メイン処理フロー
        
        Args:
            instruction: 自然言語の指示
        
        Returns:
            処理結果（コード、検証結果、実行結果など）
        """
        try:
            # 1. Continue AIでコード生成（手動）
            # Continue AIを起動して、instructionを入力
            # 生成されたコードを取得
            
            # 2. 検証
            validation_result = self.validator.validate(code)
            if not validation_result['valid']:
                # エラーがあれば修正を試みる
                # Continue AIに修正を依頼
                code = self.fix_code(code, validation_result['errors'])
            
            # 3. 実行（オプション）
            if self.should_execute():
                execution_result = self.executor.execute(code)
                return execution_result
            
            return {'code': code, 'validation': validation_result}
        except Exception as e:
            self.logger.log_error(e)
            raise
```

</details>

#### 1.2 モジュール化の設計

エージェントを以下のモジュールに分割します：

- **CodeGenerator**: コード生成（Continue AIを使用）
- **Validator**: コード検証
- **Executor**: Terraform実行
- **Logger**: ログ機能

### 2. Continue AIを活用したコード生成（30分）

#### 2.1 Continue AIでのコード生成

Continue AIを起動（`Ctrl+L` / `Cmd+L`）して、以下のプロンプトを入力します：

```
以下の要件でTerraformコードを生成してください。

要件:
- S3バケットを作成
- バケット名: training-bucket
- バージョニングを有効化
- 暗号化を有効化（AES256）

出力形式:
- HCL形式のTerraformコード
- 変数定義を含める
- コメントを適切に追加
- ベストプラクティスに従う
```

<details>
<summary>📝 生成コード例（クリックで展開）</summary>

```hcl
# variables.tf
variable "bucket_name" {
  description = "S3バケット名"
  type        = string
  default     = "training-bucket"
}

# main.tf
resource "aws_s3_bucket" "training_bucket" {
  bucket = var.bucket_name

  tags = {
    Name = var.bucket_name
  }
}

resource "aws_s3_bucket_versioning" "training_bucket_versioning" {
  bucket = aws_s3_bucket.training_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "training_bucket_encryption" {
  bucket = aws_s3_bucket.training_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

</details>

#### 2.2 コード生成の自動化（参考）

Continue AIはエディタ拡張機能なので、完全な自動化は難しいですが、以下のようなワークフローを実装できます：

1. Continue AIでコード生成
2. 生成されたコードをファイルに保存
3. 検証とフォーマットを自動実行

### 3. コード検証とフォーマット機能（20分）

#### 3.1 Terraform検証の実装

```python
# validator.py
import subprocess
import tempfile
import os

class TerraformValidator:
    """Terraformコードの検証クラス"""
    
    def validate(self, code):
        """
        コードの検証
        
        Args:
            code: Terraformコード（文字列）
        
        Returns:
            検証結果（valid, errors, warnings）
        """
        result = {
            'valid': True,
            'errors': [],
            'warnings': []
        }
        
        # 1. 構文チェック
        syntax_check = self.check_syntax(code)
        if not syntax_check['valid']:
            result['valid'] = False
            result['errors'].extend(syntax_check['errors'])
        
        # 2. terraform fmt
        formatted_code = self.format(code)
        
        # 3. terraform validate（一時ファイルに保存して実行）
        validation = self.run_terraform_validate(formatted_code)
        if not validation['valid']:
            result['valid'] = False
            result['errors'].extend(validation['errors'])
        
        return result
    
    def format(self, code):
        """terraform fmtの実行"""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.tf', delete=False) as f:
            f.write(code)
            temp_file = f.name
        
        try:
            subprocess.run(['terraform', 'fmt', temp_file], check=True, capture_output=True)
            with open(temp_file, 'r') as f:
                return f.read()
        finally:
            os.unlink(temp_file)
    
    def run_terraform_validate(self, code):
        """terraform validateの実行"""
        work_dir = tempfile.mkdtemp()
        
        try:
            # コードをファイルに保存
            with open(os.path.join(work_dir, 'main.tf'), 'w') as f:
                f.write(code)
            
            # terraform init
            init_result = subprocess.run(
                ['terraform', 'init'],
                cwd=work_dir,
                capture_output=True,
                text=True
            )
            
            if init_result.returncode != 0:
                return {
                    'valid': False,
                    'errors': [f"terraform init failed: {init_result.stderr}"]
                }
            
            # terraform validate
            validate_result = subprocess.run(
                ['terraform', 'validate'],
                cwd=work_dir,
                capture_output=True,
                text=True
            )
            
            if validate_result.returncode != 0:
                return {
                    'valid': False,
                    'errors': [f"terraform validate failed: {validate_result.stderr}"]
                }
            
            return {'valid': True, 'errors': []}
        finally:
            import shutil
            shutil.rmtree(work_dir)
```

<details>
<summary>📝 使用例（クリックで展開）</summary>

```python
from validator import TerraformValidator

validator = TerraformValidator()

code = """
resource "aws_s3_bucket" "test" {
  bucket = "test-bucket"
}
"""

result = validator.validate(code)
print(f"Valid: {result['valid']}")
if result['errors']:
    print(f"Errors: {result['errors']}")
```

</details>

### 4. Terraform実行自動化（20分）

#### 4.1 自動実行パイプライン

```python
# executor.py
import subprocess
import tempfile
import os
import shutil

class TerraformExecutor:
    """Terraform実行クラス"""
    
    def execute(self, code, auto_approve=False):
        """
        Terraformの自動実行
        
        Args:
            code: Terraformコード（文字列）
            auto_approve: 自動承認するか
        
        Returns:
            実行結果
        """
        work_dir = tempfile.mkdtemp()
        
        try:
            # コードをファイルに保存
            with open(os.path.join(work_dir, 'main.tf'), 'w') as f:
                f.write(code)
            
            # terraform init
            init_result = subprocess.run(
                ['terraform', 'init'],
                cwd=work_dir,
                capture_output=True,
                text=True
            )
            
            if init_result.returncode != 0:
                return {
                    'success': False,
                    'error': 'init failed',
                    'details': init_result.stderr
                }
            
            # terraform plan
            plan_result = subprocess.run(
                ['terraform', 'plan', '-out=tfplan'],
                cwd=work_dir,
                capture_output=True,
                text=True
            )
            
            if plan_result.returncode != 0:
                return {
                    'success': False,
                    'error': 'plan failed',
                    'details': plan_result.stderr
                }
            
            # プレビュー表示
            print(plan_result.stdout)
            
            # terraform apply（承認が必要な場合）
            if auto_approve:
                apply_result = subprocess.run(
                    ['terraform', 'apply', '-auto-approve', 'tfplan'],
                    cwd=work_dir,
                    capture_output=True,
                    text=True
                )
                return {
                    'success': apply_result.returncode == 0,
                    'output': apply_result.stdout,
                    'error': apply_result.stderr if apply_result.returncode != 0 else None
                }
            else:
                return {
                    'success': True,
                    'pending_approval': True,
                    'plan': plan_result.stdout
                }
        
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
        finally:
            # クリーンアップ（必要に応じて）
            # shutil.rmtree(work_dir)  # デバッグ時はコメントアウト
            pass
```

<details>
<summary>📝 使用例（クリックで展開）</summary>

```python
from executor import TerraformExecutor

executor = TerraformExecutor()

code = """
resource "aws_s3_bucket" "test" {
  bucket = "test-bucket"
}
"""

result = executor.execute(code, auto_approve=False)
if result['success']:
    if result.get('pending_approval'):
        print("Plan created. Review and approve manually.")
    else:
        print("Resources created successfully!")
else:
    print(f"Error: {result['error']}")
```

</details>

#### 4.2 エラーハンドリングとリトライ

```python
import time

def execute_with_retry(self, code, max_retries=3):
    """リトライ機能付き実行"""
    for attempt in range(max_retries):
        try:
            result = self.execute(code)
            if result['success']:
                return result
        except Exception as e:
            if attempt == max_retries - 1:
                raise
            time.sleep(2 ** attempt)  # 指数バックオフ
```

### 5. エージェントの動作確認とテスト（10分）

#### 5.1 基本的な動作確認

1. Continue AIでコード生成
2. 生成されたコードを検証
3. 必要に応じて実行

<details>
<summary>📝 テスト例（クリックで展開）</summary>

```python
# test_agent.py
from validator import TerraformValidator
from executor import TerraformExecutor

# 検証のテスト
validator = TerraformValidator()
code = """
resource "aws_s3_bucket" "test" {
  bucket = "test-bucket"
}
"""

result = validator.validate(code)
print(f"Validation result: {result}")

# 実行のテスト（実際には実行しない）
executor = TerraformExecutor()
# result = executor.execute(code, auto_approve=False)
```

</details>

## ✅ チェックリスト

- [ ] エージェントアーキテクチャを設計した
- [ ] Continue AIを活用したコード生成を実践した
- [ ] コード検証機能を実装した
- [ ] Terraform実行自動化を実装した
- [ ] エラーハンドリングを実装した
- [ ] リトライ機能を実装した
- [ ] 基本的な動作確認を行った
- [ ] 生成コードの品質を確認した

## 🆘 トラブルシューティング

### Continue AIが応答しない

- Continueの設定を確認（`.continue/config.json`）
- ネットワーク接続を確認
- AWS Bedrockのサービス状態を確認（AWSコンソールで確認）

### Terraform実行エラー

- IAM権限を確認
- リソース制限を確認
- 状態ファイルの競合を確認

## 📚 参考資料

- [Continue公式ドキュメント](https://continue.dev/docs)
- [Terraform公式ドキュメント](https://developer.hashicorp.com/terraform/docs)
- [サンプルコード](../../sample_code/terraform/)
- [テンプレート](../../templates/ai_agents/terraform_agent_template.py)

## ➡️ 次のステップ

セッション2が完了したら、[セッション3：Ansible運用基礎](session3_guide.md) に進んでください。
