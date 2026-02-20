"""
Terraformコード生成・実行自動化エージェントテンプレート
セッション3で使用する本格的なエージェント実装
"""

import os
import json
import subprocess
import tempfile
import shutil
from typing import Dict, Optional, List
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

try:
    from openai import OpenAI
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False


class CodeGenerator:
    """Terraformコード生成クラス"""
    
    def __init__(self, api_key: str, model: str = "gpt-4"):
        self.api_key = api_key
        self.model = model
        if OPENAI_AVAILABLE:
            self.client = OpenAI(api_key=api_key)
        else:
            raise ImportError("OpenAI library is required")
    
    def generate(self, instruction: str, context: Optional[Dict] = None) -> str:
        """コード生成"""
        prompt = self._build_prompt(instruction, context)
        response = self._call_llm(prompt)
        code = self._extract_code(response)
        return self._format_code(code)
    
    def _build_prompt(self, instruction: str, context: Optional[Dict] = None) -> str:
        """プロンプトの構築"""
        prompt = f"""
以下の要件でTerraformコードを生成してください。

要件:
{instruction}
"""
        if context:
            prompt += f"\n既存のインフラ情報:\n{json.dumps(context, indent=2, ensure_ascii=False)}\n"
        
        prompt += """
出力形式:
- HCL形式のTerraformコード
- 変数定義を含める
- 依存関係を適切に記述
- コメントを追加
- ベストプラクティスに従う
"""
        return prompt
    
    def _call_llm(self, prompt: str) -> str:
        """LLM API呼び出し"""
        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": "あなたはTerraformコード生成の専門家です。"},
                {"role": "user", "content": prompt}
            ],
            temperature=0.3,
            max_tokens=3000
        )
        return response.choices[0].message.content
    
    def _extract_code(self, response: str) -> str:
        """コード抽出"""
        import re
        pattern = r'```(?:terraform|hcl)?\s*\n(.*?)\n```'
        match = re.search(pattern, response, re.DOTALL)
        return match.group(1).strip() if match else response.strip()
    
    def _format_code(self, code: str) -> str:
        """コードフォーマット（terraform fmt相当の処理）"""
        # 実際の実装では terraform fmt を使用
        return code


class TerraformValidator:
    """Terraformコード検証クラス"""
    
    def validate(self, code: str) -> Dict:
        """コード検証"""
        result = {
            'valid': True,
            'errors': [],
            'warnings': []
        }
        
        # 構文チェック
        syntax_check = self._check_syntax(code)
        if not syntax_check['valid']:
            result['valid'] = False
            result['errors'].extend(syntax_check['errors'])
        
        # terraform fmt
        formatted_code = self._format(code)
        
        # terraform validate（一時ファイルに保存して実行）
        validation = self._run_terraform_validate(formatted_code)
        if not validation['valid']:
            result['valid'] = False
            result['errors'].extend(validation['errors'])
        
        return result
    
    def _check_syntax(self, code: str) -> Dict:
        """構文チェック"""
        if not code:
            return {'valid': False, 'errors': ['コードが空です']}
        return {'valid': True, 'errors': []}
    
    def _format(self, code: str) -> str:
        """terraform fmtの実行"""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.tf', delete=False) as f:
            f.write(code)
            temp_file = f.name
        
        try:
            subprocess.run(['terraform', 'fmt', temp_file], check=True, capture_output=True)
            with open(temp_file, 'r') as f:
                return f.read()
        except subprocess.CalledProcessError:
            return code
        finally:
            os.unlink(temp_file)
    
    def _run_terraform_validate(self, code: str) -> Dict:
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
                    'errors': [f'terraform init failed: {init_result.stderr}']
                }
            
            # terraform validate
            validate_result = subprocess.run(
                ['terraform', 'validate'],
                cwd=work_dir,
                capture_output=True,
                text=True
            )
            
            return {
                'valid': validate_result.returncode == 0,
                'errors': [validate_result.stderr] if validate_result.returncode != 0 else []
            }
        finally:
            shutil.rmtree(work_dir)


class TerraformExecutor:
    """Terraform実行クラス"""
    
    def __init__(self, work_dir: Optional[str] = None):
        self.work_dir = work_dir or tempfile.mkdtemp()
    
    def execute(self, code: str, auto_approve: bool = False) -> Dict:
        """Terraformの自動実行"""
        try:
            # コードをファイルに保存
            os.makedirs(self.work_dir, exist_ok=True)
            with open(os.path.join(self.work_dir, 'main.tf'), 'w') as f:
                f.write(code)
            
            # terraform init
            init_result = self._run_command(['terraform', 'init'])
            if not init_result['success']:
                return {'success': False, 'error': 'init failed', 'details': init_result}
            
            # terraform plan
            plan_result = self._run_command(['terraform', 'plan', '-out=tfplan'])
            if not plan_result['success']:
                return {'success': False, 'error': 'plan failed', 'details': plan_result}
            
            # プレビュー表示
            print("実行計画:")
            print(plan_result['output'])
            
            # terraform apply
            if auto_approve:
                apply_result = self._run_command(['terraform', 'apply', '-auto-approve', 'tfplan'])
                return apply_result
            else:
                return {'success': True, 'pending_approval': True, 'plan': plan_result}
        
        except Exception as e:
            return {'success': False, 'error': str(e)}
    
    def _run_command(self, cmd: List[str]) -> Dict:
        """コマンド実行"""
        try:
            result = subprocess.run(
                cmd,
                cwd=self.work_dir,
                capture_output=True,
                text=True,
                timeout=300
            )
            return {
                'success': result.returncode == 0,
                'output': result.stdout,
                'error': result.stderr,
                'returncode': result.returncode
            }
        except subprocess.TimeoutExpired:
            return {'success': False, 'error': 'Command timeout'}
        except Exception as e:
            return {'success': False, 'error': str(e)}


class TerraformAgent:
    """Terraformコード生成・実行自動化エージェント"""
    
    def __init__(self, api_key: Optional[str] = None, aws_context: Optional[Dict] = None):
        self.api_key = api_key or os.getenv('OPENAI_API_KEY')
        if not self.api_key:
            raise ValueError("APIキーが設定されていません")
        
        self.aws_context = aws_context
        self.code_generator = CodeGenerator(self.api_key)
        self.validator = TerraformValidator()
        self.executor = TerraformExecutor()
    
    def process(self, instruction: str, execute: bool = False, auto_approve: bool = False) -> Dict:
        """メイン処理"""
        try:
            # 1. コード生成
            code = self.code_generator.generate(instruction, self.aws_context)
            print("コード生成完了")
            
            # 2. 検証
            validation_result = self.validator.validate(code)
            if not validation_result['valid']:
                print("検証エラー:", validation_result['errors'])
                # エラーがあれば修正を試みる
                code = self._fix_code(code, validation_result['errors'])
            
            # 3. 実行（オプション）
            if execute:
                execution_result = self.executor.execute(code, auto_approve)
                return {
                    'code': code,
                    'validation': validation_result,
                    'execution': execution_result
                }
            
            return {
                'code': code,
                'validation': validation_result
            }
        except Exception as e:
            return {
                'error': str(e),
                'code': None
            }
    
    def _fix_code(self, code: str, errors: List[str]) -> str:
        """コード修正（簡易実装）"""
        # 実際の実装では、エラーをLLMに送って修正を依頼
        return code


def main():
    """使用例"""
    agent = TerraformAgent()
    
    result = agent.process(
        "S3バケットを作成してください。バケット名はtraining-bucketです。",
        execute=False
    )
    
    print("生成されたコード:")
    print(result['code'])


if __name__ == "__main__":
    main()
