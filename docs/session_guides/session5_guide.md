# セッション5：統合管理エージェント 詳細ガイド

## 📋 目的

このセッションでは、Continue AIを活用して、TerraformとAnsibleを統合的に管理するエージェントの実装方法を学びます。

### 学習目標

- タスク分類と優先順位付けの実装方法を理解する
- TerraformとAnsibleの統合実行方法を理解する
- タスク分解と依存関係解決の実装方法を理解する
- ワークフロー自動化の実装方法を理解する

## 🎯 目指すべき構成

このセッション終了時点で、以下の構成が完成していることを目指します：

```
workspace/
└── agents/
    └── integrated_agent/
        ├── agent.py           # メインのエージェントコード
        ├── classifier.py      # タスク分類モジュール
        ├── prioritizer.py     # 優先順位付けモジュール
        └── workflow.py        # ワークフロー自動化モジュール
```

**エージェントの機能**:
- タスクの自動分類（Terraform/Ansible/Hybrid）
- 優先順位付け
- タスク分解と依存関係解決
- ワークフロー自動化

## 📚 事前準備

- [セッション2](session2_guide.md) が完了していること
- [セッション4](session4_guide.md) が完了していること
- Terraform/Ansibleエージェントの理解
- Continue AIが正しく設定されていること

## 🚀 手順

### 1. タスク分類と優先順位付け（20分）

#### 1.1 タスク分類の実装

Continue AIを活用して、タスクを自動的に分類する機能を実装します。

<details>
<summary>📝 タスク分類クラス例（クリックで展開）</summary>

```python
# classifier.py
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
    
    def classify(self, instruction):
        """
        タスクタイプの分類
        
        Args:
            instruction: 自然言語の指示
        
        Returns:
            タスクタイプ（terraform/ansible/hybrid）
        """
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

</details>

#### 1.2 優先順位付けの実装

<details>
<summary>📝 優先順位付けクラス例（クリックで展開）</summary>

```python
# prioritizer.py
class TaskPrioritizer:
    """タスク優先順位付けクラス"""
    
    PRIORITY_MAP = {
        '削除': 1,  # 最優先（慎重に）
        '作成': 2,
        '更新': 3,
        '確認': 4,
        '取得': 5
    }
    
    def prioritize(self, tasks):
        """
        タスクの優先順位付け
        
        Args:
            tasks: タスクのリスト
        
        Returns:
            優先順位付けされたタスクのリスト
        """
        return sorted(tasks, key=lambda t: self.PRIORITY_MAP.get(t.get('type', ''), 99))
```

</details>

### 2. 統合エージェントの実装（40分）

#### 2.1 統合エージェントクラス

Continue AIを活用して、TerraformとAnsibleを統合的に管理するエージェントを実装します。

<details>
<summary>📝 統合エージェントクラス例（クリックで展開）</summary>

```python
# agent.py
from classifier import TaskClassifier
from prioritizer import TaskPrioritizer
# Terraform/Ansibleエージェントはセッション2、4で実装済みと仮定

class IntegratedInfrastructureAgent:
    """統合インフラ管理エージェント"""
    
    def __init__(self, aws_context=None, inventory_file=None):
        self.aws_context = aws_context
        self.inventory_file = inventory_file
        
        # セッション2、4で実装したエージェントを使用
        # self.terraform_agent = TerraformAgent(aws_context)
        # self.ansible_agent = AnsibleAgent(inventory_file)
        
        self.classifier = TaskClassifier()
        self.prioritizer = TaskPrioritizer()
    
    def process(self, instruction, execute=False):
        """
        統合処理
        
        Args:
            instruction: 自然言語の指示
            execute: 実際に実行するか
        
        Returns:
            処理結果
        """
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
                # Continue AIでTerraformコード生成
                # セッション2の手順を参照
                result = self.process_terraform_task(task, execute)
            elif task['type'] == 'ansible':
                # Continue AIでAnsible Playbook生成
                # セッション4の手順を参照
                result = self.process_ansible_task(task, execute)
            else:
                result = self.process_hybrid_task(task, execute)
            
            results.append({
                'task': task,
                'result': result
            })
        
        return {
            'tasks': tasks,
            'execution_plan': execution_plan,
            'results': results
        }
    
    def decompose_task(self, instruction, task_type):
        """複合タスクの分解"""
        if task_type == 'hybrid':
            # Continue AIを使ってタスクを分解
            # Continue AIを起動して、以下のプロンプトを入力:
            """
            以下のタスクを、TerraformタスクとAnsibleタスクに分解してください。
            
            タスク: {instruction}
            
            出力形式:
            - Terraformタスク: [リスト]
            - Ansibleタスク: [リスト]
            - 依存関係: [リスト]
            """
            # 生成された分解結果をパース
            # 実際の実装では、Continue AIの応答をパースする必要がある
        
        return [{'type': task_type, 'instruction': instruction}]
    
    def resolve_dependencies(self, tasks):
        """依存関係の解決"""
        # 依存関係グラフの構築
        graph = self.build_dependency_graph(tasks)
        
        # トポロジカルソート
        execution_order = self.topological_sort(graph)
        
        return execution_order
```

</details>

### 3. 実践的なシナリオ演習（20分）

#### 3.1 シナリオ1: 監視エージェントのセットアップ

Continue AIを起動して、以下のプロンプトを入力します：

```
EC2インスタンスにPrometheus node_exporterをインストールして起動してください。
設定ファイルは/etc/prometheus/node_exporter.confに配置し、
systemdサービスとして登録してください。
```

<details>
<summary>📝 生成されるAnsible Playbook例（クリックで展開）</summary>

```yaml
---
- name: Prometheus node_exporterのインストールと設定
  hosts: webservers
  become: yes
  
  tasks:
    - name: node_exporterユーザーを作成
      user:
        name: node_exporter
        system: yes
        shell: /bin/false
        home: /var/lib/node_exporter
    
    - name: node_exporterをダウンロード
      get_url:
        url: https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
        dest: /tmp/node_exporter.tar.gz
    
    - name: node_exporterを展開
      unarchive:
        src: /tmp/node_exporter.tar.gz
        dest: /opt
        remote_src: yes
    
    - name: node_exporterバイナリをコピー
      copy:
        src: /opt/node_exporter-1.6.1.linux-amd64/node_exporter
        dest: /usr/local/bin/node_exporter
        owner: root
        group: root
        mode: '0755'
        remote_src: yes
    
    - name: 設定ファイルを作成
      copy:
        content: |
          # node_exporter configuration
        dest: /etc/prometheus/node_exporter.conf
        owner: node_exporter
        group: node_exporter
        mode: '0644'
    
    - name: systemdサービスファイルを作成
      copy:
        content: |
          [Unit]
          Description=Prometheus Node Exporter
          After=network.target
          
          [Service]
          User=node_exporter
          Group=node_exporter
          ExecStart=/usr/local/bin/node_exporter --config.file=/etc/prometheus/node_exporter.conf
          Restart=always
          
          [Install]
          WantedBy=multi-user.target
        dest: /etc/systemd/system/node_exporter.service
        owner: root
        group: root
        mode: '0644'
    
    - name: systemdをリロード
      systemd:
        daemon_reload: yes
    
    - name: node_exporterサービスを開始
      systemd:
        name: node_exporter
        state: started
        enabled: yes
```

</details>

#### 3.2 シナリオ2: 複数リソースの一括管理

Continue AIを起動して、以下のプロンプトを入力します：

```
以下のリソースを作成してください:
1. VPC (10.0.0.0/16)
2. パブリックサブネット (10.0.1.0/24)
3. EC2インスタンス (t3.micro)
4. セキュリティグループ (SSH許可)
5. EC2インスタンスに監視エージェントをインストール
```

このシナリオでは、TerraformタスクとAnsibleタスクが組み合わさった複合タスクになります。

### 4. ワークフロー自動化（10分）

#### 4.1 ワークフロー定義

<details>
<summary>📝 ワークフロー自動化クラス例（クリックで展開）</summary>

```python
# workflow.py
class WorkflowAutomator:
    """ワークフロー自動化クラス"""
    
    def automate_workflow(self, workflow_description):
        """
        ワークフローの自動化
        
        例: 新規サーバ追加→設定→監視開始
        """
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
    
    def execute_workflow(self, steps):
        """ワークフローの実行"""
        results = []
        
        for step in steps:
            # 依存関係の確認
            if step.get('depends_on'):
                for dep in step['depends_on']:
                    # 依存タスクが完了しているか確認
                    if not self.is_task_completed(dep):
                        raise Exception(f"Dependency {dep} not completed")
            
            # タスクの実行
            if step['type'] == 'terraform':
                result = self.execute_terraform_task(step)
            elif step['type'] == 'ansible':
                result = self.execute_ansible_task(step)
            
            results.append({
                'step': step,
                'result': result
            })
        
        return results
```

</details>

## ✅ チェックリスト

- [ ] タスク分類機能を実装した
- [ ] 優先順位付け機能を実装した
- [ ] 統合エージェントを実装した
- [ ] Terraform/Ansibleの統合実行を実装した
- [ ] タスク分解機能を実装した
- [ ] 依存関係解決機能を実装した
- [ ] ワークフロー自動化を実装した
- [ ] 監視エージェントセットアップの自動化を実践した
- [ ] 複数リソースの一括管理を実践した
- [ ] 統合テストを実施した

## 🆘 トラブルシューティング

### タスク分類エラー

- キーワードマッチングの精度を向上
- Continue AIを使った分類の導入

### 依存関係エラー

- 依存関係グラフの可視化
- 循環依存の検出

### 実行順序エラー

- 実行前のプレビュー機能
- ロールバック機能

## 📚 参考資料

- [Continue公式ドキュメント](https://continue.dev/docs)
- [テンプレート](../../templates/ai_agents/integrated_agent_template.py)
- [サンプルコード](../../sample_code/)

## ➡️ 次のステップ

セッション5が完了したら、[セッション6：Webシステム構築（任意）](session6_guide.md) に進むか、ワークショップを完了してください。
