# セッション4：Ansible自動化エージェント 詳細ガイド

## 📋 目的

このセッションでは、Continue AIを活用して、Ansible Playbook生成・実行を自動化するエージェントの実装方法を学びます。

### 学習目標

- Continue AIを活用したAnsible Playbook生成の実装方法を理解する
- Playbook検証機能の実装方法を理解する
- Ansible実行自動化の実装方法を理解する
- エラーハンドリングとリトライ機能の実装方法を理解する

## 🎯 目指すべき構成

このセッション終了時点で、以下の構成が完成していることを目指します：

```
workspace/
└── agents/
    └── ansible_agent/
        ├── agent.py           # メインのエージェントコード
        ├── playbook_generator.py # Playbook生成モジュール
        ├── validator.py       # Playbook検証モジュール
        └── executor.py        # Ansible実行モジュール
```

**エージェントの機能**:
- Continue AIを活用したAnsible Playbook生成
- Playbook検証
- Ansible実行の自動化
- エラーハンドリングとリトライ

## 📚 事前準備

- [セッション3](session3_guide.md) が完了していること
- Ansibleの基本理解
- Continue AIが正しく設定されていること

## 🚀 手順

### 1. Continue AIを活用したPlaybook生成（30分）

#### 1.1 Continue AIでのPlaybook生成

Continue AIを起動（`Ctrl+L` / `Cmd+L`）して、以下のプロンプトを入力します：

```
Ansible Playbookを生成してください。

要件:
- パッケージ（htop, git, curl）をインストールする
- 設定ファイルをコピーする
- サービス（nginx）を開始する
- 冪等性を確保する
- エラーハンドリングを含める

出力形式:
- YAML形式のAnsible Playbook
- 適切なモジュールを使用
- コメントを追加
- ベストプラクティスに従う
```

<details>
<summary>📝 生成Playbook例（クリックで展開）</summary>

```yaml
---
- name: パッケージインストールとサービス設定
  hosts: webservers
  become: yes
  
  tasks:
    - name: 必要なパッケージをインストール
      yum:
        name:
          - htop
          - git
          - curl
        state: present
      register: package_result
      failed_when: false
    
    - name: パッケージインストール結果の確認
      debug:
        msg: "パッケージインストール結果: {{ package_result }}"
      when: package_result.failed
    
    - name: 設定ファイルをコピー
      copy:
        src: config/nginx.conf
        dest: /etc/nginx/nginx.conf
        owner: root
        group: root
        mode: '0644'
      notify: restart nginx
    
    - name: nginxサービスを開始
      systemd:
        name: nginx
        state: started
        enabled: yes
  
  handlers:
    - name: restart nginx
      systemd:
        name: nginx
        state: restarted
```

</details>

#### 1.2 プロンプトテンプレートの作成

再利用可能なプロンプトテンプレートを作成します。

<details>
<summary>📝 プロンプトテンプレート例（クリックで展開）</summary>

```python
# prompt_templates.py
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

</details>

### 2. Playbook検証機能（20分）

#### 2.1 YAML検証の実装

```python
# validator.py
import yaml
import subprocess
import tempfile
import os

class AnsiblePlaybookValidator:
    """Ansible Playbook検証クラス"""
    
    def validate(self, playbook):
        """
        Playbookの検証
        
        Args:
            playbook: Ansible Playbook（YAML文字列）
        
        Returns:
            検証結果（valid, errors, warnings）
        """
        result = {
            'valid': True,
            'errors': [],
            'warnings': []
        }
        
        # 1. YAML構文チェック
        yaml_check = self.check_yaml_syntax(playbook)
        if not yaml_check['valid']:
            result['valid'] = False
            result['errors'].extend(yaml_check['errors'])
        
        # 2. ansible-lint（利用可能な場合）
        lint_check = self.run_ansible_lint(playbook)
        if lint_check['errors']:
            result['warnings'].extend(lint_check['errors'])
        
        return result
    
    def check_yaml_syntax(self, playbook):
        """YAML構文チェック"""
        try:
            yaml.safe_load(playbook)
            return {'valid': True, 'errors': []}
        except yaml.YAMLError as e:
            return {
                'valid': False,
                'errors': [f"YAML syntax error: {str(e)}"]
            }
    
    def run_ansible_lint(self, playbook):
        """ansible-lintの実行"""
        work_dir = tempfile.mkdtemp()
        
        try:
            # Playbookをファイルに保存
            playbook_file = os.path.join(work_dir, 'playbook.yml')
            with open(playbook_file, 'w') as f:
                f.write(playbook)
            
            # ansible-lint実行
            lint_result = subprocess.run(
                ['ansible-lint', playbook_file],
                capture_output=True,
                text=True
            )
            
            if lint_result.returncode != 0:
                return {'errors': lint_result.stderr.split('\n')}
            
            return {'errors': []}
        except FileNotFoundError:
            # ansible-lintがインストールされていない場合
            return {'errors': []}
        finally:
            import shutil
            shutil.rmtree(work_dir)
```

<details>
<summary>📝 使用例（クリックで展開）</summary>

```python
from validator import AnsiblePlaybookValidator

validator = AnsiblePlaybookValidator()

playbook = """
---
- name: Test playbook
  hosts: webservers
  tasks:
    - name: Test task
      debug:
        msg: "Hello"
"""

result = validator.validate(playbook)
print(f"Valid: {result['valid']}")
if result['errors']:
    print(f"Errors: {result['errors']}")
```

</details>

### 3. Ansible実行自動化（20分）

#### 3.1 自動実行パイプライン

```python
# executor.py
import subprocess
import tempfile
import os
import shutil

class AnsibleExecutor:
    """Ansible実行クラス"""
    
    def execute(self, playbook, inventory, extra_vars=None):
        """
        Ansible Playbookの自動実行
        
        Args:
            playbook: Ansible Playbook（YAML文字列）
            inventory: インベントリファイルのパス
            extra_vars: 追加変数（辞書）
        
        Returns:
            実行結果
        """
        work_dir = tempfile.mkdtemp()
        
        try:
            # Playbookをファイルに保存
            playbook_file = os.path.join(work_dir, 'playbook.yml')
            with open(playbook_file, 'w') as f:
                f.write(playbook)
            
            # ansible-playbookコマンドの構築
            cmd = ['ansible-playbook', '-i', inventory, playbook_file]
            
            # 追加変数の設定
            if extra_vars:
                vars_str = ' '.join([f"{k}={v}" for k, v in extra_vars.items()])
                cmd.extend(['--extra-vars', vars_str])
            
            # 実行
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True
            )
            
            return {
                'success': result.returncode == 0,
                'stdout': result.stdout,
                'stderr': result.stderr,
                'returncode': result.returncode
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
from executor import AnsibleExecutor

executor = AnsibleExecutor()

playbook = """
---
- name: Test playbook
  hosts: webservers
  tasks:
    - name: Test task
      debug:
        msg: "Hello"
"""

result = executor.execute(
    playbook,
    inventory='inventory.ini',
    extra_vars={'var1': 'value1'}
)

if result['success']:
    print("Playbook executed successfully!")
    print(result['stdout'])
else:
    print(f"Error: {result['stderr']}")
```

</details>

### 4. エージェントの統合（10分）

#### 4.1 エージェントクラスの実装

```python
# agent.py
from validator import AnsiblePlaybookValidator
from executor import AnsibleExecutor

class AnsibleAgent:
    """Ansible Playbook生成・実行自動化エージェント"""
    
    def __init__(self, inventory):
        self.inventory = inventory
        self.validator = AnsiblePlaybookValidator()
        self.executor = AnsibleExecutor()
    
    def process(self, instruction):
        """
        メイン処理フロー
        
        Args:
            instruction: 自然言語の指示
        
        Returns:
            処理結果
        """
        # 1. Continue AIでPlaybook生成（手動）
        # Continue AIを起動して、instructionを入力
        # 生成されたPlaybookを取得
        
        # 2. 検証
        validation_result = self.validator.validate(playbook)
        if not validation_result['valid']:
            # エラーがあれば修正を試みる
            # Continue AIに修正を依頼
            playbook = self.fix_playbook(playbook, validation_result['errors'])
        
        # 3. 実行（オプション）
        if self.should_execute():
            execution_result = self.executor.execute(playbook, self.inventory)
            return execution_result
        
        return {'playbook': playbook, 'validation': validation_result}
```

## ✅ チェックリスト

- [ ] Continue AIを活用したPlaybook生成を実践した
- [ ] Playbook検証機能を実装した
- [ ] Ansible実行自動化を実装した
- [ ] エラーハンドリングを実装した
- [ ] リトライ機能を実装した
- [ ] 基本的な動作確認を行った
- [ ] 生成Playbookの品質を確認した

## 🆘 トラブルシューティング

### Continue AIが応答しない

- Continueの設定を確認（`.continue/config.json`）
- ネットワーク接続を確認

### Ansible実行エラー

- インベントリファイルの設定を確認
- SSH接続を確認
- 権限を確認

## 📚 参考資料

- [Continue公式ドキュメント](https://continue.dev/docs)
- [Ansible公式ドキュメント](https://docs.ansible.com/)
- [サンプルコード](../../sample_code/ansible/)
- [テンプレート](../../templates/ai_agents/ansible_agent_template.py)

## ➡️ 次のステップ

セッション4が完了したら、[セッション5：統合管理エージェント](session5_guide.md) に進んでください。
