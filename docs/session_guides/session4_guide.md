# セッション4：Ansible運用基礎とAgent形式でのPlaybook生成 詳細ガイド

## 📋 目的

このセッションでは、ContinueのAgent機能を使って、Ansible Playbookを生成し、基本的な運用タスクを自動化します。セッション1、2、3で学んだPrompt EngineeringとContext EngineeringをAnsibleに適用します。

### 学習目標

- Prompt Engineering（Ansible用）の実践（良いプロンプトと悪いプロンプトの比較）
- Context Engineering（サーバー情報）の実践
- Agent形式でのPlaybook生成の体験
- Agent形式での開発の理解（Ansible）
- Ansibleの基本概念を理解する
- インベントリファイルの設定方法を習得する
- Playbookの作成と実行方法を習得する
- 基本的な運用タスクの自動化を実践する

## 🎯 最終的な目標構成

このセッション終了時点で、以下の構成が完成していることを目指します：

### ファイル構成

```
workspace/
└── ansible/
    ├── inventory.ini          # インベントリファイル
    ├── playbooks/
    │   ├── restart_server.yml # サーバー再起動Playbook
    │   └── install_packages.yml # パッケージインストールPlaybook
    └── group_vars/
        └── webservers.yml     # グループ変数（オプション）
```

### 自動化されるタスク

- サーバー再起動（再起動前後の状態確認、サービス再起動を含む）
- パッケージのインストール
- ファイルのコピー
- サービスの管理

## 📚 事前準備

- [セッション2](session2_guide.md) で構築したEC2インスタンスが起動していること
- Ansibleがインストールされていること
- EC2インスタンスへのSSH接続が可能なこと（キーペアファイルの準備）
- Continueが正しく設定されていること

## 🚀 Agent開発の進め方

### Agent開発のアドバイス

#### 1. Prompt Engineering（Ansible用）のヒント

**悪いプロンプト例**:
```
サーバーを再起動するAnsible Playbookを作成してください
```

**良いプロンプト例**:
```
ansible/playbooks/ フォルダに、下記条件を満たすサーバー再起動を自動化するAnsible Playbookを生成してください。

要件:
- 対象サーバー: インベントリファイルのwebserversグループ
- 再起動前: サービス状態の確認、ログのバックアップ（オプション）
- 再起動後: サービス状態の確認、ヘルスチェック
- エラーハンドリング: 失敗時の適切な処理

注意事項:
- 足りていないパラメータがある場合は、そのまま実行するのではなく一度聞き返してください
- 冪等性を確保してください
- ハンドラーを使用してください（サービス再起動など）
- コメントを適切に追加してください
- ベストプラクティスに従ってください

出力形式:
- YAML形式のAnsible Playbook
- 適切なコメントを含める
```

**プロンプト作成のポイント**:
- 対象サーバー（インベントリグループ）の明確な指定
- タスクの順序（再起動前、再起動、再起動後）
- 冪等性の確保（`changed_when: false`など）
- エラーハンドリングの要求
- ハンドラーの使用（サービス再起動など）

#### 2. Context Engineering（サーバー情報）のヒント

**既存サーバー情報の取得方法**:

Continueのチャット機能を使って、サーバー情報を取得できます：

```
セッション2で構築したEC2インスタンスのOS情報を教えてください。
また、Ansibleでサーバー情報を取得する方法も教えてください。
```

または、Ansibleコマンドを実行して情報を取得し、それをコンテキストとして提供：

```
既存のサーバー情報:
- OS: Amazon Linux 2023
- 利用可能なサービス: sshd, crond, など

上記の情報を考慮して、サーバー再起動を自動化するAnsible Playbookを生成してください。
既存のサービス状態を確認し、適切に再起動してください。
```

**インベントリ情報の活用**:

インベントリファイルの情報もコンテキストとして提供できます：

```
インベントリ情報:
- 対象サーバー: webserversグループ
- SSHユーザー: ec2-user
- 接続方法: SSH鍵認証

上記の情報を考慮して、Ansible Playbookを生成してください。
```

#### 3. フィードバックループの活用方法

**承認ワークフロー**:
- Agentが生成したPlaybookを確認してから承認
- 特に再起動などの重要な操作は必ず確認

**エラー修正プロセス**:
- Playbook実行時のエラーをコンテキストとして提供
- Agentに修正を依頼

**反復的改善**:
- 生成されたPlaybookを確認し、改善点があればフィードバックを提供
- 例：「エラーハンドリングをより詳細にしてください」「ログ出力を追加してください」

### 考えながら進めるポイント

1. **どのようなプロンプトが効果的か**
   - Ansible特有の概念（冪等性、ハンドラー、タスク構造）をどのように表現すべきか
   - 複数のタスクをどのように整理すべきか

2. **どのようなコンテキストが必要か**
   - サーバー情報（OS、サービス、パッケージなど）をどのように取得すべきか
   - インベントリ情報をどのように活用すべきか

3. **エラーが発生した場合の対処方法**
   - Ansibleのエラーメッセージをどのように解釈すべきか
   - どのような修正が必要か

4. **段階的な構築アプローチ**
   - まずインベントリファイルを作成
   - 次に簡単なPlaybookから始める
   - 徐々に複雑なタスクに挑戦

## 📝 振り返り

以下の点について振り返り、学んだことをまとめてください：

- **Prompt Engineering（Ansible用）の効果**: Ansible特有の要件をどのようにプロンプトに反映したか
- **Context Engineeringの重要性**: サーバー情報を活用することで、どのような問題を回避できたか
- **フィードバックループの体験**: エラー修正、反復的改善、承認ワークフローをどのように体験したか
- **Agent形式での開発体験**: Terraformと比較して、AnsibleでのAgent開発の特徴は何か

<details>
<summary>📝 解答例（クリックで展開）</summary>

### インベントリファイル例

#### inventory.ini

```ini
[webservers]
web1 ansible_host=<ec2-public-ip> ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/training-key.pem

[webservers:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

**設定項目の説明**:
- `ansible_host`: EC2インスタンスのパブリックIP（セッション2で構築したインスタンスのIP）
- `ansible_user`: SSH接続ユーザー（Amazon Linux 2023の場合は`ec2-user`）
- `ansible_ssh_private_key_file`: キーペアファイルのパス
- `ansible_ssh_common_args`: SSH接続オプション

### Playbook例

#### restart_server.yml

```yaml
---
- name: サーバー再起動の自動化
  hosts: webservers
  become: yes
  
  handlers:
    - name: restart services
      systemd:
        name: "{{ item }}"
        state: restarted
      loop:
        - sshd
        - crond
  
  tasks:
    - name: 再起動前の状態確認
      shell: uptime
      register: uptime_before
      changed_when: false
    
    - name: 再起動前の状態を表示
      debug:
        msg: "再起動前の稼働時間: {{ uptime_before.stdout }}"
    
    - name: サーバーを再起動
      reboot:
        reboot_timeout: 300
        pre_reboot_delay: 10
        post_reboot_delay: 30
      register: reboot_result
      ignore_errors: yes
    
    - name: 再起動結果の確認
      debug:
        msg: "再起動結果: {{ reboot_result }}"
      when: reboot_result.failed
    
    - name: 再起動後の状態確認
      shell: uptime
      register: uptime_after
      changed_when: false
    
    - name: 再起動後の状態を表示
      debug:
        msg: "再起動後の稼働時間: {{ uptime_after.stdout }}"
    
    - name: サービスの再起動
      notify: restart services
```

#### install_packages.yml

```yaml
---
- name: パッケージのインストール
  hosts: webservers
  become: yes
  
  tasks:
    - name: 必要なパッケージをインストール
      yum:
        name:
          - htop
          - git
          - curl
          - vim
        state: present
        update_cache: yes
```

#### copy_files.yml

```yaml
---
- name: ファイルのコピー
  hosts: webservers
  
  tasks:
    - name: 設定ファイルをコピー
      copy:
        src: config/app.conf
        dest: /etc/app/app.conf
        owner: root
        group: root
        mode: '0644'
      notify: restart app service
  
  handlers:
    - name: restart app service
      systemd:
        name: app
        state: restarted
```

#### manage_service.yml

```yaml
---
- name: サービスの管理
  hosts: webservers
  become: yes
  
  tasks:
    - name: サービスを開始
      systemd:
        name: nginx
        state: started
        enabled: yes
```

### プロンプト例

**パッケージインストール用プロンプト**:

```
ansible/playbooks/ フォルダに、下記条件を満たすパッケージインストールを自動化するAnsible Playbookを生成してください。

要件:
- 対象サーバー: インベントリファイルのwebserversグループ
- インストールするパッケージ: htop, git, curl, vim
- パッケージマネージャー: yum（Amazon Linux 2023）
- キャッシュの更新も実行

注意事項:
- 冪等性を確保してください
- コメントを適切に追加してください
- ベストプラクティスに従ってください
```

**ファイルコピー用プロンプト**:

```
ansible/playbooks/ フォルダに、下記条件を満たすファイルコピーを自動化するAnsible Playbookを生成してください。

要件:
- 対象サーバー: インベントリファイルのwebserversグループ
- コピー元: config/app.conf（ローカル）
- コピー先: /etc/app/app.conf（リモート）
- 所有者: root
- グループ: root
- パーミッション: 0644
- ファイル変更時にサービスを再起動

注意事項:
- 冪等性を確保してください
- ハンドラーを使用してください
- コメントを適切に追加してください
```

</details>

## ✅ チェックリスト

- [ ] 最終的な目標構成を理解した
- [ ] インベントリファイルを作成した
- [ ] SSH接続テストが成功した
- [ ] Ansible接続テストが成功した
- [ ] Prompt Engineering（Ansible用）を実践した
- [ ] Context Engineering（サーバー情報）を実践した
- [ ] Agent形式でPlaybookを生成した
- [ ] サーバー再起動のPlaybookを作成・実行した
- [ ] その他の基本タスク（パッケージインストール、ファイルコピー、サービス管理）を実装した
- [ ] Agent形式での開発の振り返りを行った

## 🆘 トラブルシューティング

### SSH接続エラー

- セキュリティグループでSSH（ポート22）が許可されているか確認
- キーペアファイルの権限を確認（`chmod 400`）
- ホストキーの確認を無効化（`StrictHostKeyChecking=no`）

### 権限エラー

- `become: yes`を使用してsudo権限を取得
- 適切なユーザーで実行しているか確認

### タイムアウトエラー

- `reboot_timeout`を増やす
- ネットワーク接続を確認

### Playbook実行エラー

- エラーメッセージを詳しく確認
- Agentにエラーメッセージをコンテキストとして提供し、修正を依頼

## 📚 参考資料

- [Ansible公式ドキュメント](https://docs.ansible.com/)
- [セッション1ガイド](session1_guide.md)
- [セッション2ガイド](session2_guide.md)
- [セッション3ガイド](session3_guide.md)

## ➡️ 次のステップ

セッション4が完了したら、[セッション5：Ansible自動化エージェント開発](session5_guide.md) に進んでください。
