"""
インフラ管理タスク自動化エージェントテンプレート
セッション5で使用する統合エージェント実装
"""

import os
from typing import Dict, Optional, List
from dotenv import load_dotenv

# TerraformAgentとAnsibleAgentをインポート
# 実際の実装では、これらのクラスを別ファイルからインポート
# from terraform_agent_template import TerraformAgent
# from ansible_agent_template import AnsibleAgent

load_dotenv()


class TaskClassifier:
    """タスク分類クラス"""
    
    TASK_TYPES = {
        'terraform': [
            '作成', '構築', 'デプロイ', 'リソース作成',
            'VPC', 'EC2', 'S3', 'RDS', 'インフラ'
        ],
        'ansible': [
            '設定', 'インストール', '起動', '停止',
            '再起動', 'パッケージ', 'サービス', 'ファイル'
        ],
        'hybrid': [
            'セットアップ', '環境構築', 'デプロイ',
            '監視開始', 'バックアップ'
        ]
    }
    
    def classify(self, instruction: str) -> str:
        """タスクタイプの分類"""
        instruction_lower = instruction.lower()
        
        terraform_score = sum(1 for keyword in self.TASK_TYPES['terraform'] 
                             if keyword in instruction_lower)
        ansible_score = sum(1 for keyword in self.TASK_TYPES['ansible'] 
                           if keyword in instruction_lower)
        
        if terraform_score > ansible_score:
            return 'terraform'
        elif ansible_score > terraform_score:
            return 'ansible'
        else:
            return 'hybrid'


class TaskPrioritizer:
    """タスク優先順位付けクラス"""
    
    PRIORITY_MAP = {
        '削除': 1,
        '作成': 2,
        '更新': 3,
        '確認': 4,
        '取得': 5
    }
    
    def prioritize(self, tasks: List[Dict]) -> List[Dict]:
        """タスクの優先順位付け"""
        return sorted(tasks, key=lambda t: self.PRIORITY_MAP.get(t.get('type', ''), 99))


class IntegratedInfrastructureAgent:
    """統合インフラ管理エージェント"""
    
    def __init__(self, api_key: Optional[str] = None, aws_context: Optional[Dict] = None, 
                 inventory_file: Optional[str] = None):
        self.api_key = api_key or os.getenv('OPENAI_API_KEY')
        if not self.api_key:
            raise ValueError("APIキーが設定されていません")
        
        self.aws_context = aws_context
        self.inventory_file = inventory_file or "inventory.ini"
        
        # 実際の実装では、これらのエージェントを初期化
        # self.terraform_agent = TerraformAgent(api_key, aws_context)
        # self.ansible_agent = AnsibleAgent(api_key, inventory_file)
        
        self.classifier = TaskClassifier()
        self.prioritizer = TaskPrioritizer()
    
    def process(self, instruction: str, execute: bool = False) -> Dict:
        """統合処理"""
        # 1. タスクタイプの判定
        task_type = self.classifier.classify(instruction)
        
        # 2. タスクの分解（複合タスクの場合）
        tasks = self._decompose_task(instruction, task_type)
        
        # 3. 優先順位付け
        tasks = self.prioritizer.prioritize(tasks)
        
        # 4. 依存関係の解決
        execution_plan = self._resolve_dependencies(tasks)
        
        # 5. 実行
        results = []
        for task in execution_plan:
            # 実際の実装では、適切なエージェントを呼び出す
            if task['type'] == 'terraform':
                # result = self.terraform_agent.process(task['instruction'], execute)
                result = {'type': 'terraform', 'instruction': task['instruction'], 'status': 'pending'}
            elif task['type'] == 'ansible':
                # result = self.ansible_agent.process(task['instruction'], execute)
                result = {'type': 'ansible', 'instruction': task['instruction'], 'status': 'pending'}
            else:
                result = self._process_hybrid(task, execute)
            
            results.append({
                'task': task,
                'result': result
            })
        
        return {
            'tasks': tasks,
            'execution_plan': execution_plan,
            'results': results
        }
    
    def _decompose_task(self, instruction: str, task_type: str) -> List[Dict]:
        """複合タスクの分解"""
        if task_type == 'hybrid':
            # LLMを使ってタスクを分解
            # 簡易実装：実際にはLLMを使用
            return [
                {'type': 'terraform', 'instruction': f'{instruction} (インフラ部分)'},
                {'type': 'ansible', 'instruction': f'{instruction} (設定部分)'}
            ]
        
        return [{'type': task_type, 'instruction': instruction}]
    
    def _resolve_dependencies(self, tasks: List[Dict]) -> List[Dict]:
        """依存関係の解決"""
        # 簡易実装：実際には依存関係グラフを構築してトポロジカルソート
        return tasks
    
    def _process_hybrid(self, task: Dict, execute: bool) -> Dict:
        """ハイブリッドタスクの処理"""
        # TerraformとAnsibleを順次実行
        return {'type': 'hybrid', 'status': 'pending'}


class WorkflowAutomator:
    """ワークフロー自動化クラス"""
    
    def __init__(self, agent: IntegratedInfrastructureAgent):
        self.agent = agent
    
    def automate_workflow(self, workflow_description: Dict) -> Dict:
        """ワークフローの自動化"""
        steps = [
            {
                'name': 'サーバ作成',
                'type': 'terraform',
                'instruction': workflow_description.get('server_creation', '')
            },
            {
                'name': 'サーバ設定',
                'type': 'ansible',
                'instruction': workflow_description.get('server_config', ''),
                'depends_on': ['サーバ作成']
            },
            {
                'name': '監視開始',
                'type': 'ansible',
                'instruction': workflow_description.get('monitoring_setup', ''),
                'depends_on': ['サーバ設定']
            }
        ]
        
        return self._execute_workflow(steps)
    
    def _execute_workflow(self, steps: List[Dict]) -> Dict:
        """ワークフローの実行"""
        results = []
        for step in steps:
            result = self.agent.process(step['instruction'], execute=True)
            results.append({
                'step': step['name'],
                'result': result
            })
        return {'workflow_results': results}


def main():
    """使用例"""
    agent = IntegratedInfrastructureAgent()
    
    # テストケース1: Terraformタスク
    result1 = agent.process("S3バケットを作成してください", execute=False)
    print("Terraformタスク:", result1['tasks'][0]['type'])
    
    # テストケース2: Ansibleタスク
    result2 = agent.process("パッケージをインストールしてください", execute=False)
    print("Ansibleタスク:", result2['tasks'][0]['type'])
    
    # テストケース3: 複合タスク
    result3 = agent.process("サーバを作成して設定してください", execute=False)
    print("複合タスク数:", len(result3['tasks']))


if __name__ == "__main__":
    main()
