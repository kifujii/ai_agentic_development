# セッション2：Terraformコード生成・実行自動化エージェント開発 詳細ガイド

## 目標
セッション0で学んだ基礎を活用し、本格的なTerraformコード生成・実行自動化エージェントを実装する。

## 事前準備
- セッション0の完了
- セッション1で構築したインフラの理解
- Python開発環境の準備

## 手順

### 1. エージェントの高度化（30分）

#### 1.1 シンプルなエージェントの拡張
セッション0で作成したシンプルなエージェントをベースに拡張。

#### 1.2 エージェントアーキテクチャの改善
```python
class TerraformAgent:
    def __init__(self, api_key, aws_context=None):
        self.api_key = api_key
        self.aws_context = aws_context
        self.code_generator = CodeGenerator(api_key)
        self.validator = TerraformValidator()
        self.executor = TerraformExecutor()
        self.logger = AgentLogger()
    
    def process(self, instruction):
        """メイン処理フロー"""
        try:
            # 1. コード生成
            code = self.code_generator.generate(instruction, self.aws_context)
            self.logger.log("Code generated", code)
            
            # 2. 検証
            validation_result = self.validator.validate(code)
            if not validation_result['valid']:
                # エラーがあれば修正を試みる
                code = self.code_generator.fix(code, validation_result['errors'])
            
            # 3. 実行（オプション）
            if self.should_execute():
                execution_result = self.executor.execute(code)
                return execution_result
            
            return {'code': code, 'validation': validation_result}
        except Exception as e:
            self.logger.log_error(e)
            raise
```

#### 1.3 Context Engineeringの活用
```python
def get_aws_context():
    """既存インフラ情報を取得"""
    import boto3
    
    ec2 = boto3.client('ec2')
    
    context = {
        'existing_vpcs': get_vpcs(ec2),
        'existing_subnets': get_subnets(ec2),
        'available_amis': get_available_amis(ec2),
        'security_groups': get_security_groups(ec2)
    }
    
    return context
```

### 2. Terraformコード生成機能の強化（30分）

#### 2.1 複雑なリソース構成のコード生成
```python
class CodeGenerator:
    def generate(self, instruction, context=None):
        """複雑なリソース構成のコード生成"""
        prompt = self.build_prompt(instruction, context)
        
        # LLM API呼び出し
        response = self.call_llm(prompt)
        
        # コード抽出と整形
        code = self.extract_code(response)
        code = self.format_code(code)
        
        return code
    
    def build_prompt(self, instruction, context):
        """プロンプトの構築"""
        prompt_template = """
以下の要件でTerraformコードを生成してください。

要件:
{instruction}

既存のインフラ情報:
{context}

出力形式:
- HCL形式のTerraformコード
- 変数定義を含める
- 依存関係を適切に記述
- コメントを追加
- ベストプラクティスに従う
"""
        return prompt_template.format(
            instruction=instruction,
            context=json.dumps(context, indent=2) if context else "なし"
        )
```

#### 2.2 コード検証とフォーマット機能
```python
class TerraformValidator:
    def validate(self, code):
        """コードの検証"""
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
        import subprocess
        import tempfile
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.tf', delete=False) as f:
            f.write(code)
            temp_file = f.name
        
        try:
            subprocess.run(['terraform', 'fmt', temp_file], check=True)
            with open(temp_file, 'r') as f:
                return f.read()
        finally:
            os.unlink(temp_file)
```

### 3. Terraform実行自動化の実装（20分）

#### 3.1 自動実行パイプライン
```python
class TerraformExecutor:
    def execute(self, code, auto_approve=False):
        """Terraformの自動実行"""
        work_dir = self.create_work_directory()
        
        try:
            # コードをファイルに保存
            self.save_code(work_dir, code)
            
            # terraform init
            init_result = self.run_command(work_dir, ['terraform', 'init'])
            if not init_result['success']:
                return {'success': False, 'error': 'init failed', 'details': init_result}
            
            # terraform plan
            plan_result = self.run_command(work_dir, ['terraform', 'plan', '-out=tfplan'])
            if not plan_result['success']:
                return {'success': False, 'error': 'plan failed', 'details': plan_result}
            
            # プレビュー表示
            self.show_plan_preview(plan_result['output'])
            
            # terraform apply（承認が必要な場合）
            if auto_approve or self.should_auto_approve():
                apply_result = self.run_command(work_dir, ['terraform', 'apply', 'tfplan'])
                return apply_result
            else:
                return {'success': True, 'pending_approval': True, 'plan': plan_result}
        
        except Exception as e:
            return {'success': False, 'error': str(e)}
        finally:
            # クリーンアップ（必要に応じて）
            pass
```

#### 3.2 エラーハンドリングとリトライ
```python
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

### 4. エージェントの動作確認とテスト（10分）

#### 4.1 基本的な動作確認
```python
# エージェントの初期化
agent = TerraformAgent(
    api_key=os.getenv('GOOGLE_API_KEY'),
    aws_context=get_aws_context()
)

# シンプルな指示
result = agent.process("S3バケットを作成してください。バケット名はtraining-bucketです。")
print(result['code'])

# 複合的な指示
result = agent.process("VPCとSubnetを作成してください。VPC CIDRは10.0.0.0/16、サブネットは10.0.1.0/24です。")
print(result['code'])
```

#### 4.2 品質確認
- 生成されたコードが正しく動作するか
- ベストプラクティスに従っているか
- エラーハンドリングが適切か

## チェックリスト

- [ ] エージェントアーキテクチャを改善した
- [ ] コード生成機能を強化した
- [ ] コード検証機能を実装した
- [ ] Terraform実行自動化を実装した
- [ ] エラーハンドリングを実装した
- [ ] リトライ機能を実装した
- [ ] 基本的な動作確認を行った
- [ ] 複合的な指示への対応を確認した
- [ ] 生成コードの品質を確認した

## トラブルシューティング

### LLM APIエラー
- APIキーが正しく設定されているか確認
- レート制限に達していないか確認
- プロンプトサイズが制限内か確認

### Terraform実行エラー
- IAM権限を確認
- リソース制限を確認
- 状態ファイルの競合を確認

## 参考資料
- `templates/ai_agents/terraform_agent_template.py`
- `sample_code/terraform/`
