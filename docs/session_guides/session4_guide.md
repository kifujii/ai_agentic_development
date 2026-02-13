# セッション4：Ansible Playbook生成・実行自動化エージェント開発 詳細ガイド

## 目標
生成AIエージェントによるAnsible Playbook生成と自動実行の実装を行う。

## 事前準備
- セッション3の完了
- Ansibleの基本理解
- Python開発環境の準備

## 手順

### 1. Ansible Playbook生成エージェントの実装（40分）

#### 1.1 プロンプトエンジニアリング（Ansible Playbook生成用）
```python
class AnsiblePromptBuilder:
    def build_prompt(self, instruction, context=None):
        """Ansible Playbook生成用のプロンプト構築"""
        prompt = f"""
以下の要件でAnsible Playbookを生成してください。

要件:
{instruction}

既存のインフラ情報:
{context if context else "なし"}

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
```

#### 1.2 自然言語からPlaybookへの変換ロジック
```python
class AnsiblePlaybookGenerator:
    def __init__(self, api_key):
        self.api_key = api_key
        self.prompt_builder = AnsiblePromptBuilder()
    
    def generate(self, instruction, context=None):
        """自然言語からPlaybookを生成"""
        prompt = self.prompt_builder.build_prompt(instruction, context)
        
        # LLM API呼び出し
        response = self.call_llm(prompt)
        
        # YAML抽出と検証
        playbook = self.extract_yaml(response)
        playbook = self.validate_yaml(playbook)
        
        return playbook
    
    def extract_yaml(self, response):
        """レスポンスからYAMLを抽出"""
        import re
        
        # YAMLブロックを抽出
        yaml_pattern = r'```yaml\s*\n(.*?)\n```'
        match = re.search(yaml_pattern, response, re.DOTALL)
        
        if match:
            return match.group(1)
        
        # YAMLブロックがない場合は全体を返す
        return response
```

#### 1.3 タスク構造の最適化
```python
class PlaybookOptimizer:
    def optimize(self, playbook):
        """Playbookの最適化"""
        # 1. 冪等性の確保
        playbook = self.ensure_idempotency(playbook)
        
        # 2. エラーハンドリングの追加
        playbook = self.add_error_handling(playbook)
        
        # 3. ハンドラーの最適化
        playbook = self.optimize_handlers(playbook)
        
        return playbook
    
    def ensure_idempotency(self, playbook):
        """冪等性の確保"""
        # shell/commandモジュールを可能な限りyum/systemdなどに置き換え
        # changed_whenを適切に設定
        return playbook
```

### 2. Ansible実行自動化の実装（30分）

#### 2.1 ansible-playbookの自動実行
```python
class AnsibleExecutor:
    def __init__(self, inventory_file):
        self.inventory_file = inventory_file
    
    def execute(self, playbook_file, extra_vars=None, check_mode=False):
        """ansible-playbookの自動実行"""
        import subprocess
        import tempfile
        
        # Playbookを一時ファイルに保存
        with tempfile.NamedTemporaryFile(mode='w', suffix='.yml', delete=False) as f:
            f.write(playbook_file)
            temp_playbook = f.name
        
        try:
            # ansible-playbookコマンドの構築
            cmd = ['ansible-playbook', '-i', self.inventory_file, temp_playbook]
            
            if check_mode:
                cmd.append('--check')
            
            if extra_vars:
                cmd.extend(['--extra-vars', json.dumps(extra_vars)])
            
            # 実行
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
```

#### 2.2 実行結果の検証とレポート生成
```python
class AnsibleResultValidator:
    def validate(self, execution_result):
        """実行結果の検証"""
        result = {
            'success': execution_result['success'],
            'tasks': [],
            'errors': [],
            'warnings': []
        }
        
        # stdoutを解析
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
    
    def generate_report(self, validation_result):
        """レポートの生成"""
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
```

### 3. エージェントの動作確認とテスト（20分）

#### 3.1 エージェントの統合
```python
class AnsibleAgent:
    def __init__(self, api_key, inventory_file):
        self.generator = AnsiblePlaybookGenerator(api_key)
        self.optimizer = PlaybookOptimizer()
        self.executor = AnsibleExecutor(inventory_file)
        self.validator = AnsibleResultValidator()
    
    def process(self, instruction, execute=False):
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
```

#### 3.2 動作確認
```python
# エージェントの初期化
agent = AnsibleAgent(
    api_key=os.getenv('OPENAI_API_KEY'),
    inventory_file='inventory.ini'
)

# 監視エージェントのインストール
result = agent.process(
    "監視エージェント（Prometheus node_exporter）をインストールして起動してください。",
    execute=True
)

print(result['playbook'])
print(result['report'])

# サーバ情報の取得
result = agent.process(
    "サーバのCPU、メモリ、ディスク使用率を取得してください。",
    execute=True
)
```

## チェックリスト

- [ ] Ansible Playbook生成エージェントを実装した
- [ ] プロンプトエンジニアリングを実装した
- [ ] 自然言語からPlaybookへの変換ロジックを実装した
- [ ] タスク構造の最適化機能を実装した
- [ ] Ansible実行自動化を実装した
- [ ] 実行結果の検証機能を実装した
- [ ] レポート生成機能を実装した
- [ ] エラーハンドリングを実装した
- [ ] 基本的な動作確認を行った
- [ ] 複数のタスクで動作確認を行った

## トラブルシューティング

### YAML構文エラー
- 生成されたYAMLの構文を確認
- YAMLバリデーターを使用

### Ansible実行エラー
- インベントリファイルが正しいか確認
- SSH接続が可能か確認
- モジュールが正しく使用されているか確認

## 参考資料
- `templates/ai_agents/ansible_agent_template.py`
- `sample_code/ansible/`
