"""
Ansible Playbook生成・実行自動化エージェントテンプレート
セッション4で使用するエージェント実装
"""

import os
import json
import subprocess
import tempfile
import yaml
from typing import Dict, Optional, List
from dotenv import load_dotenv

load_dotenv()

try:
    from openai import OpenAI
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False


class AnsiblePromptBuilder:
    """Ansible Playbook生成用プロンプトビルダー"""
    
    def build_prompt(self, instruction: str, context: Optional[Dict] = None) -> str:
        """プロンプトの構築"""
        prompt = f"""
以下の要件でAnsible Playbookを生成してください。

要件:
{instruction}
"""
        if context:
            prompt += f"\n既存のインフラ情報:\n{json.dumps(context, indent=2, ensure_ascii=False)}\n"
        
        prompt += """
出力形式:
- YAML形式のAnsible Playbook
- 適切なモジュールを使用
- 冪等性を確保
- エラーハンドリングを含める
- ハンドラーを適切に使用
- コメントを追加
- ベストプラクティスに従う

Ansibleの主要モジュール:
- yum/apt: パッケージ管理
- systemd: サービス管理
- copy/template: ファイル操作
- shell/command: コマンド実行
- user/group: ユーザー管理
- file: ファイル・ディレクトリ操作
"""
        return prompt


class AnsiblePlaybookGenerator:
    """Ansible Playbook生成クラス"""
    
    def __init__(self, api_key: str, model: str = "gpt-4"):
        self.api_key = api_key
        self.model = model
        self.prompt_builder = AnsiblePromptBuilder()
        if OPENAI_AVAILABLE:
            self.client = OpenAI(api_key=api_key)
        else:
            raise ImportError("OpenAI library is required")
    
    def generate(self, instruction: str, context: Optional[Dict] = None) -> str:
        """Playbook生成"""
        prompt = self.prompt_builder.build_prompt(instruction, context)
        response = self._call_llm(prompt)
        playbook = self._extract_yaml(response)
        return self._validate_yaml(playbook)
    
    def _call_llm(self, prompt: str) -> str:
        """LLM API呼び出し"""
        response = self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": "あなたはAnsible Playbook生成の専門家です。"},
                {"role": "user", "content": prompt}
            ],
            temperature=0.3,
            max_tokens=3000
        )
        return response.choices[0].message.content
    
    def _extract_yaml(self, response: str) -> str:
        """YAML抽出"""
        import re
        yaml_pattern = r'```yaml\s*\n(.*?)\n```'
        match = re.search(yaml_pattern, response, re.DOTALL)
        if match:
            return match.group(1)
        return response
    
    def _validate_yaml(self, yaml_content: str) -> str:
        """YAML検証"""
        try:
            yaml.safe_load(yaml_content)
            return yaml_content
        except yaml.YAMLError as e:
            print(f"YAML検証エラー: {e}")
            return yaml_content


class PlaybookOptimizer:
    """Playbook最適化クラス"""
    
    def optimize(self, playbook: str) -> str:
        """Playbookの最適化"""
        # 1. 冪等性の確保
        playbook = self._ensure_idempotency(playbook)
        # 2. エラーハンドリングの追加
        playbook = self._add_error_handling(playbook)
        return playbook
    
    def _ensure_idempotency(self, playbook: str) -> str:
        """冪等性の確保"""
        # 簡易実装：実際にはより高度な処理が必要
        return playbook
    
    def _add_error_handling(self, playbook: str) -> str:
        """エラーハンドリングの追加"""
        # 簡易実装
        return playbook


class AnsibleExecutor:
    """Ansible実行クラス"""
    
    def __init__(self, inventory_file: str):
        self.inventory_file = inventory_file
    
    def execute(self, playbook_content: str, extra_vars: Optional[Dict] = None, check_mode: bool = False) -> Dict:
        """ansible-playbookの自動実行"""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.yml', delete=False) as f:
            f.write(playbook_content)
            temp_playbook = f.name
        
        try:
            cmd = ['ansible-playbook', '-i', self.inventory_file, temp_playbook]
            
            if check_mode:
                cmd.append('--check')
            
            if extra_vars:
                cmd.extend(['--extra-vars', json.dumps(extra_vars)])
            
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=600
            )
            
            return {
                'success': result.returncode == 0,
                'stdout': result.stdout,
                'stderr': result.stderr,
                'returncode': result.returncode
            }
        finally:
            os.unlink(temp_playbook)


class AnsibleResultValidator:
    """Ansible実行結果検証クラス"""
    
    def validate(self, execution_result: Dict) -> Dict:
        """実行結果の検証"""
        result = {
            'success': execution_result['success'],
            'tasks': [],
            'errors': [],
            'warnings': []
        }
        
        stdout = execution_result['stdout']
        
        # タスクの成功/失敗を抽出
        import re
        task_pattern = r'TASK \[(.*?)\].*?ok=(\d+).*?failed=(\d+)'
        matches = re.findall(task_pattern, stdout, re.DOTALL)
        
        for match in matches:
            task_name, ok, failed = match
            result['tasks'].append({
                'name': task_name,
                'ok': int(ok),
                'failed': int(failed)
            })
        
        # エラーの抽出
        if 'FAILED' in stdout:
            error_pattern = r'FAILED!.*?\n(.*?)(?=\nTASK|\Z)'
            errors = re.findall(error_pattern, stdout, re.DOTALL)
            result['errors'] = errors
        
        return result
    
    def generate_report(self, validation_result: Dict) -> str:
        """レポート生成"""
        report = f"""
実行結果レポート
================

成功: {validation_result['success']}

タスク詳細:
"""
        for task in validation_result['tasks']:
            report += f"- {task['name']}: ok={task['ok']}, failed={task['failed']}\n"
        
        if validation_result['errors']:
            report += "\nエラー:\n"
            for error in validation_result['errors']:
                report += f"{error}\n"
        
        return report


class AnsibleAgent:
    """Ansible Playbook生成・実行自動化エージェント"""
    
    def __init__(self, api_key: Optional[str] = None, inventory_file: str = "inventory.ini"):
        self.api_key = api_key or os.getenv('OPENAI_API_KEY')
        if not self.api_key:
            raise ValueError("APIキーが設定されていません")
        
        self.inventory_file = inventory_file
        self.generator = AnsiblePlaybookGenerator(self.api_key)
        self.optimizer = PlaybookOptimizer()
        self.executor = AnsibleExecutor(inventory_file)
        self.validator = AnsibleResultValidator()
    
    def process(self, instruction: str, execute: bool = False) -> Dict:
        """メイン処理"""
        # 1. Playbook生成
        playbook = self.generator.generate(instruction)
        
        # 2. 最適化
        playbook = self.optimizer.optimize(playbook)
        
        # 3. 実行（オプション）
        if execute:
            result = self.executor.execute(playbook)
            validation = self.validator.validate(result)
            report = self.validator.generate_report(validation)
            return {
                'playbook': playbook,
                'execution_result': result,
                'validation': validation,
                'report': report
            }
        
        return {'playbook': playbook}


def main():
    """使用例"""
    agent = AnsibleAgent(inventory_file='inventory.ini')
    
    result = agent.process(
        "監視エージェント（Prometheus node_exporter）をインストールして起動してください。",
        execute=False
    )
    
    print("生成されたPlaybook:")
    print(result['playbook'])


if __name__ == "__main__":
    main()
