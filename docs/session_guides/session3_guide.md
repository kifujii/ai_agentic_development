# セッション3：システム運用基礎とAnsible Playbook作成 詳細ガイド

## 目標
Ansibleを使った基本的な運用タスクの自動化を実践する。

## 事前準備
- Ansibleのインストール確認
- EC2インスタンスへのSSH接続設定
- 作業ディレクトリの作成

## 手順

### 1. Ansibleインベントリの設定（15分）

#### 1.1 インベントリファイルの作成
`inventory.ini`を作成:
```ini
[webservers]
web1 ansible_host=<ec2-public-ip> ansible_user=ec2-user ansible_ssh_private_key_file=training-key.pem

[webservers:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

#### 1.2 SSH鍵の設定
```bash
# キーペアファイルの権限確認
chmod 400 training-key.pem

# SSH接続テスト
ssh -i training-key.pem ec2-user@<ec2-public-ip>
```

#### 1.3 接続テスト
```bash
# Ansible接続テスト
ansible all -i inventory.ini -m ping

# システム情報の取得
ansible all -i inventory.ini -m setup
```

### 2. サーバー再起動の自動化（30分）

#### 2.1 Playbookの作成
`restart_server.yml`を作成:
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

#### 2.2 Playbookの実行
```bash
# ドライラン（実際には実行しない）
ansible-playbook -i inventory.ini restart_server.yml --check

# 実行
ansible-playbook -i inventory.ini restart_server.yml

# 詳細な出力
ansible-playbook -i inventory.ini restart_server.yml -v
```

#### 2.3 エラーハンドリング
```yaml
tasks:
  - name: サーバーを再起動
    reboot:
      reboot_timeout: 300
    register: reboot_result
    ignore_errors: yes
  
  - name: 再起動結果の確認
    debug:
      msg: "再起動結果: {{ reboot_result }}"
    when: reboot_result.failed
```

### 3. その他の基本タスク（15分）

#### 3.1 パッケージのインストール
```yaml
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
        state: present
```

#### 3.2 ファイルのコピー
```yaml
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
```

#### 3.3 サービスの管理
```yaml
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

## チェックリスト

- [ ] Ansibleインベントリファイルを作成した
- [ ] SSH接続テストが成功した
- [ ] Ansible接続テストが成功した
- [ ] サーバー再起動のPlaybookを作成した
- [ ] Playbookの実行が成功した
- [ ] 再起動前後の状態確認を行った
- [ ] エラーハンドリングを実装した
- [ ] その他の基本タスクを実装した

## トラブルシューティング

### SSH接続エラー
- セキュリティグループでSSH（ポート22）が許可されているか確認
- キーペアファイルの権限を確認（chmod 400）
- ホストキーの確認を無効化（StrictHostKeyChecking=no）

### 権限エラー
- `become: yes`を使用してsudo権限を取得
- 適切なユーザーで実行しているか確認

### タイムアウトエラー
- `reboot_timeout`を増やす
- ネットワーク接続を確認

## 参考資料
- `sample_code/ansible/basic_playbook/`
