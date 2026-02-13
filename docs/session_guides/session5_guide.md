# セッション5：インフラ管理タスク自動化エージェント開発 詳細ガイド

## 目標
統合的なインフラ管理タスクを自動化するエージェントの開発を行う。

## 事前準備
- セッション2、4の完了
- Terraform/Ansibleエージェントの理解
- Python開発環境の準備

## 手順

### 1. インフラ管理タスクの定義と分類（20分）

#### 1.1 タスクの分類
```python
class TaskClassifier:
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
    
    def classify(self, instruction):
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
```

#### 1.2 タスクの優先順位付け
```python
class TaskPrioritizer:
    PRIORITY_MAP = {
        '削除': 1,  # 最優先（慎重に）
        '作成': 2,
        '更新': 3,
        '確認': 4,
        '取得': 5
    }
    
    def prioritize(self, tasks):
        """タスクの優先順位付け"""
        return sorted(tasks, key=lambda t: self.PRIORITY_MAP.get(t['type'], 99))
```

### 2. 統合エージェントの実装（50分）

#### 2.1 Terraform/Ansibleの統合実行
```python
class IntegratedInfrastructureAgent:
    def __init__(self, api_key, aws_context=None, inventory_file=None):
        self.api_key = api_key
        self.aws_context = aws_context
        self.inventory_file = inventory_file
        
        self.terraform_agent = TerraformAgent(api_key, aws_context)
        self.ansible_agent = AnsibleAgent(api_key, inventory_file)
        self.classifier = TaskClassifier()
        self.prioritizer = TaskPrioritizer()
    
    def process(self, instruction, execute=False):
        """統合処理"""
        # 1. タスクタイプの判定
        task_type = self.classifier.classify(instruction)
        
        # 2. タスクの分解（複合タスクの場合）
        tasks = self.decompose_task(instruction, task_type)
        
        # 3. 優先順位付け
        tasks = self.prioritizer.prioritize(tasks)
        
        # 4. 依存関係の解決
        execution_plan = self.resolve_dependencies(tasks)
        
        # 5. 実行
        results = []
        for task in execution_plan:
            if task['type'] == 'terraform':
                result = self.terraform_agent.process(task['instruction'], execute)
            elif task['type'] == 'ansible':
                result = self.ansible_agent.process(task['instruction'], execute)
            else:
                result = self.process_hybrid(task, execute)
            
            results.append({
                'task': task,
                'result': result
            })
        
        return {
            'tasks': tasks,
            'execution_plan': execution_plan,
            'results': results
        }
```

#### 2.2 タスクの分解と依存関係管理
```python
def decompose_task(self, instruction, task_type):
    """複合タスクの分解"""
    if task_type == 'hybrid':
        # LLMを使ってタスクを分解
        decomposition_prompt = f"""
以下のタスクを、TerraformタスクとAnsibleタスクに分解してください。

タスク: {instruction}

出力形式:
- Terraformタスク: [リスト]
- Ansibleタスク: [リスト]
- 依存関係: [リスト]
"""
        decomposition = self.call_llm(decomposition_prompt)
        return self.parse_decomposition(decomposition)
    
    return [{'type': task_type, 'instruction': instruction}]

def resolve_dependencies(self, tasks):
    """依存関係の解決"""
    # 依存関係グラフの構築
    graph = self.build_dependency_graph(tasks)
    
    # トポロジカルソート
    execution_order = self.topological_sort(graph)
    
    return execution_order
```

#### 2.3 ワークフロー自動化
```python
class WorkflowAutomator:
    def automate_workflow(self, workflow_description):
        """ワークフローの自動化"""
        # 例: 新規サーバ追加→設定→監視開始
        
        steps = [
            {
                'name': 'サーバ作成',
                'type': 'terraform',
                'instruction': workflow_description['server_creation']
            },
            {
                'name': 'サーバ設定',
                'type': 'ansible',
                'instruction': workflow_description['server_config'],
                'depends_on': ['サーバ作成']
            },
            {
                'name': '監視開始',
                'type': 'ansible',
                'instruction': workflow_description['monitoring_setup'],
                'depends_on': ['サーバ設定']
            }
        ]
        
        return self.execute_workflow(steps)
```

### 3. 実践的なシナリオ演習（20分）

#### 3.1 Agentインストールセットアップの自動化
```python
# シナリオ1: 監視エージェントのセットアップ
scenario1 = """
EC2インスタンスにPrometheus node_exporterをインストールして起動してください。
設定ファイルは/etc/prometheus/node_exporter.confに配置し、
systemdサービスとして登録してください。
"""

result = agent.process(scenario1, execute=True)
```

#### 3.2 サーバ情報取得の自動化
```python
# シナリオ2: サーバ情報の取得
scenario2 = """
すべてのEC2インスタンスの以下の情報を取得してください:
- インスタンスID
- インスタンスタイプ
- パブリックIP
- プライベートIP
- 稼働時間
- CPU/メモリ使用率
"""

result = agent.process(scenario2, execute=True)
```

#### 3.3 複数リソースの一括管理
```python
# シナリオ3: 複数リソースの一括管理
scenario3 = """
以下のリソースを作成してください:
1. VPC (10.0.0.0/16)
2. パブリックサブネット (10.0.1.0/24)
3. EC2インスタンス (t3.micro)
4. セキュリティグループ (SSH許可)
5. EC2インスタンスに監視エージェントをインストール
"""

result = agent.process(scenario3, execute=True)
```

### 4. エージェントの動作確認とテスト（10分）

#### 4.1 統合テスト
```python
def test_integrated_agent():
    """統合テスト"""
    agent = IntegratedInfrastructureAgent(
        api_key=os.getenv('OPENAI_API_KEY'),
        aws_context=get_aws_context(),
        inventory_file='inventory.ini'
    )
    
    # テストケース1: Terraformタスク
    result1 = agent.process("S3バケットを作成してください", execute=False)
    assert result1['tasks'][0]['type'] == 'terraform'
    
    # テストケース2: Ansibleタスク
    result2 = agent.process("パッケージをインストールしてください", execute=False)
    assert result2['tasks'][0]['type'] == 'ansible'
    
    # テストケース3: 複合タスク
    result3 = agent.process("サーバを作成して設定してください", execute=False)
    assert len(result3['tasks']) > 1
    
    print("すべてのテストが成功しました")
```

## チェックリスト

- [ ] タスク分類機能を実装した
- [ ] 優先順位付け機能を実装した
- [ ] 統合エージェントを実装した
- [ ] Terraform/Ansibleの統合実行を実装した
- [ ] タスク分解機能を実装した
- [ ] 依存関係解決機能を実装した
- [ ] ワークフロー自動化を実装した
- [ ] Agentインストールセットアップの自動化を実装した
- [ ] サーバ情報取得の自動化を実装した
- [ ] 複数リソースの一括管理を実装した
- [ ] 統合テストを実施した

## トラブルシューティング

### タスク分類エラー
- キーワードマッチングの精度を向上
- LLMを使った分類の導入

### 依存関係エラー
- 依存関係グラフの可視化
- 循環依存の検出

### 実行順序エラー
- 実行前のプレビュー機能
- ロールバック機能

## 参考資料
- `templates/ai_agents/integrated_agent_template.py`
- `sample_code/terraform/`
- `sample_code/ansible/`
