#!/usr/bin/env bash
# =============================================================================
# セッション完了チェックスクリプト
# 使い方:
#   ./scripts/check.sh session1          # セッション1全体をチェック
#   ./scripts/check.sh session1 step3    # セッション1のStep3だけチェック
#   ./scripts/check.sh session2          # セッション2全体をチェック
# =============================================================================

set -euo pipefail

# --- プレフィックス取得 ---
if [ -z "${TF_VAR_prefix:-}" ]; then
  if [ -f ".env" ]; then
    PREFIX_VAL=$(grep '^PREFIX=' .env 2>/dev/null | cut -d'=' -f2 | tr -d '[:space:]' || echo "")
    if [ -n "$PREFIX_VAL" ]; then
      TF_VAR_prefix="$PREFIX_VAL"
    fi
  fi
fi
TF_VAR_prefix="${TF_VAR_prefix:-training}"

# --- 色定義 ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

# --- カウンタ ---
PASS=0
FAIL=0

# --- ユーティリティ ---
pass() {
  echo -e "  ${GREEN}✅ $1${NC}"
  PASS=$((PASS + 1))
}

fail() {
  echo -e "  ${RED}❌ $1${NC}"
  if [ -n "${2:-}" ]; then
    echo -e "     ${YELLOW}💡 $2${NC}"
  fi
  FAIL=$((FAIL + 1))
}

summary() {
  local total=$((PASS + FAIL))
  echo ""
  echo "=============================="
  if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}結果: ${PASS}/${total} 完了 🎉${NC}"
  else
    echo -e "${YELLOW}結果: ${PASS}/${total} 完了${NC}"
  fi
  echo "=============================="
  return $FAIL
}

# --- Terraform output ヘルパー ---
tf_output() {
  local key="$1"
  terraform -chdir=terraform/vpc-ec2 output -raw "$key" 2>/dev/null || echo ""
}

tf_output_exists() {
  local val
  val=$(tf_output "$1")
  [ -n "$val" ]
}

# --- SSH ヘルパー ---
ssh_check_cmd() {
  local ip="$1"
  local cmd="$2"
  local key="keys/training-key"
  if [ ! -f "$key" ]; then
    key="$HOME/.ssh/training-key"
  fi
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes \
    -i "$key" ec2-user@"$ip" "$cmd" 2>/dev/null
}

# =============================================================================
# セッション0: Claude Code に慣れよう
# =============================================================================
check_session0() {
  local step="${1:-all}"
  echo ""
  echo "🔍 セッション0: Claude Code に慣れよう"
  echo "------------------------------"

  # Step 1-3: practice/ フォルダの確認
  if [ "$step" = "all" ] || [ "$step" = "step1" ] || [ "$step" = "step2" ] || [ "$step" = "step3" ]; then
    echo ""
    echo "📦 Step 1-3: Claude Code でのファイル作成"
    if [ -d "practice" ]; then
      local file_count
      file_count=$(find practice -type f 2>/dev/null | wc -l | tr -d ' ')
      if [ "$file_count" -gt 0 ]; then
        pass "practice/ フォルダにファイルが存在する ($file_count ファイル)"
      else
        fail "practice/ フォルダは存在するがファイルがありません" "Claude Code にファイル作成を依頼してください"
      fi
    else
      fail "practice/ フォルダがありません" "Step 2 のプロンプトを実行してください"
    fi
  fi

  # Step 4: 環境確認
  if [ "$step" = "all" ] || [ "$step" = "step4" ]; then
    echo ""
    echo "📦 Step 4: ワークショップ環境"

    if command -v terraform &> /dev/null; then
      local tf_ver
      tf_ver=$(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*"' | head -1 || terraform version 2>/dev/null | head -1)
      pass "terraform がインストールされている ($tf_ver)"
    else
      fail "terraform がインストールされていません" "講師に確認してください"
    fi

    if command -v ansible &> /dev/null; then
      pass "ansible がインストールされている"
    else
      fail "ansible がインストールされていません" "講師に確認してください"
    fi

    if command -v aws &> /dev/null; then
      pass "aws cli がインストールされている"
    else
      fail "aws cli がインストールされていません" "講師に確認してください"
    fi

    local caller
    caller=$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null || echo "")
    if [ -n "$caller" ]; then
      pass "AWS認証が通っている (Account: $caller)"
    else
      fail "AWS認証が通りません" "講師に確認してください"
    fi
  fi

  summary
}

# =============================================================================
# セッション1: VPC + EC2 を段階的に構築
# =============================================================================
check_session1() {
  local step="${1:-all}"
  echo ""
  echo "🔍 セッション1: VPC + EC2 を段階的に構築"
  echo "------------------------------"

  # Step 1: VPC
  if [ "$step" = "all" ] || [ "$step" = "step1" ]; then
    echo ""
    echo "📦 Step 1: VPC作成"
    local vpc_id
    vpc_id=$(tf_output "vpc_id")
    if [ -n "$vpc_id" ]; then
      pass "VPC が作成されている ($vpc_id)"
    else
      fail "VPC が見つかりません" "terraform -chdir=terraform/vpc-ec2 apply を実行してください"
    fi
  fi

  # Step 2: サブネット＆インターネット接続
  if [ "$step" = "all" ] || [ "$step" = "step2" ]; then
    echo ""
    echo "📦 Step 2: サブネット＆インターネット接続"
    local subnet_id
    subnet_id=$(tf_output "subnet_id")
    if [ -n "$subnet_id" ]; then
      pass "サブネットが作成されている ($subnet_id)"
    else
      fail "サブネットが見つかりません" "Step 2のプロンプトを実行してください"
    fi
  fi

  # Step 3: キーペア＆セキュリティグループ
  if [ "$step" = "all" ] || [ "$step" = "step3" ]; then
    echo ""
    echo "📦 Step 3: キーペア＆セキュリティグループ"
    local sg_id
    sg_id=$(tf_output "security_group_id")
    if [ -n "$sg_id" ]; then
      pass "セキュリティグループが作成されている ($sg_id)"
      # SSH(22) ルールの確認
      local ssh_rule
      ssh_rule=$(aws ec2 describe-security-groups --group-ids "$sg_id" \
        --query 'SecurityGroups[0].IpPermissions[?FromPort==`22`]' \
        --output text 2>/dev/null || echo "")
      if [ -n "$ssh_rule" ]; then
        pass "SSH(22) のインバウンドルールが設定されている"
      else
        fail "SSH(22) のインバウンドルールがありません" "セキュリティグループにSSHルールを追加してください"
      fi
    else
      fail "セキュリティグループが見つかりません（output名: security_group_id）" "output名が security_group_id になっているか確認してください"
    fi
  fi

  # Step 4: EC2インスタンス
  if [ "$step" = "all" ] || [ "$step" = "step4" ]; then
    echo ""
    echo "📦 Step 4: EC2インスタンス"
    local ip
    ip=$(tf_output "instance_public_ip")
    local inst_id
    inst_id=$(tf_output "instance_id")
    if [ -n "$ip" ] && [ -n "$inst_id" ]; then
      pass "EC2 インスタンスが作成されている ($inst_id)"
      pass "パブリックIPが割り当てられている ($ip)"
      # running 状態の確認
      local state
      state=$(aws ec2 describe-instances --instance-ids "$inst_id" \
        --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null || echo "")
      if [ "$state" = "running" ]; then
        pass "インスタンスが running 状態"
      else
        fail "インスタンスの状態: ${state:-不明}" "AWSコンソールでインスタンスの状態を確認してください"
      fi
    else
      if [ -z "$ip" ]; then
        fail "パブリックIPが見つかりません（output名: instance_public_ip）" "output名が instance_public_ip になっているか確認してください"
      fi
      if [ -z "$inst_id" ]; then
        fail "インスタンスIDが見つかりません（output名: instance_id）" "output名が instance_id になっているか確認してください"
      fi
    fi
  fi

  # Step 5: SSH接続確認
  if [ "$step" = "all" ] || [ "$step" = "step5" ]; then
    echo ""
    echo "📦 Step 5: SSH接続確認"
    local ip
    ip=$(tf_output "instance_public_ip")
    if [ -n "$ip" ]; then
      local result
      result=$(ssh_check_cmd "$ip" "echo ok" 2>/dev/null || echo "")
      if [ "$result" = "ok" ]; then
        pass "SSH接続に成功 ($ip)"
      else
        fail "SSH接続できません ($ip)" "鍵の権限を確認してください: chmod 400 keys/training-key"
      fi
    else
      fail "IPアドレスが取得できないため SSH チェックをスキップしました"
    fi
  fi

  summary
}

# =============================================================================
# セッション2: Terraform でインフラを構築・変更・再構築
# =============================================================================
check_session2() {
  local step="${1:-all}"
  echo ""
  echo "🔍 セッション2: Terraform でインフラを構築・変更・再構築"
  echo "------------------------------"

  local ip
  ip=$(tf_output "instance_public_ip")
  if [ -z "$ip" ]; then
    fail "EC2のIPが取得できません" "セッション1を完了してください（またはStep 5の再構築を実行してください）"
    summary
    return
  fi

  # Step 1: SG に HTTP(80)
  if [ "$step" = "all" ] || [ "$step" = "step1" ]; then
    echo ""
    echo "📦 Step 1: セキュリティグループにHTTP追加"
    local sg_id
    sg_id=$(tf_output "security_group_id")
    if [ -n "$sg_id" ]; then
      local http_rule
      http_rule=$(aws ec2 describe-security-groups --group-ids "$sg_id" \
        --query 'SecurityGroups[0].IpPermissions[?FromPort==`80`]' \
        --output text 2>/dev/null || echo "")
      if [ -n "$http_rule" ]; then
        pass "HTTP(80) のインバウンドルールがある ($sg_id)"
      else
        fail "HTTP(80) のインバウンドルールがありません" "Agentに「SGにHTTP(80)を追加して」と指示してください"
      fi
    else
      fail "セキュリティグループIDが取得できません"
    fi
  fi

  # Step 2: nginx 起動確認
  if [ "$step" = "all" ] || [ "$step" = "step2" ]; then
    echo ""
    echo "📦 Step 2: nginx起動確認"
    local nginx_status
    nginx_status=$(ssh_check_cmd "$ip" "systemctl is-active nginx" 2>/dev/null || echo "")
    if [ "$nginx_status" = "active" ]; then
      pass "nginx が起動している"
    else
      fail "nginx が起動していません" "Agentに「EC2にSSH接続してnginxをインストール・起動して」と指示してください"
    fi
  fi

  # Step 3: タグ追加確認
  if [ "$step" = "all" ] || [ "$step" = "step3" ]; then
    echo ""
    echo "📦 Step 3: インフラ変更（タグ追加）"
    local inst_id
    inst_id=$(tf_output "instance_id")
    if [ -n "$inst_id" ]; then
      local env_tag
      env_tag=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$inst_id" "Name=key,Values=Environment" \
        --query 'Tags[0].Value' --output text 2>/dev/null || echo "")
      if [ -n "$env_tag" ] && [ "$env_tag" != "None" ]; then
        pass "EC2 に Environment タグが設定されている ($env_tag)"
      else
        fail "EC2 に Environment タグがありません" "Step 3のプロンプトでタグ追加を実行してください"
      fi
    else
      fail "インスタンスIDが取得できないためスキップ"
    fi
  fi

  # Step 5: user_data による再構築確認
  if [ "$step" = "all" ] || [ "$step" = "step5" ]; then
    echo ""
    echo "📦 Step 5: user_data による再構築"
    # user_data が設定されているか確認
    local inst_id
    inst_id=$(tf_output "instance_id")
    if [ -n "$inst_id" ]; then
      local user_data
      user_data=$(aws ec2 describe-instance-attribute --instance-id "$inst_id" --attribute userData \
        --query 'UserData.Value' --output text 2>/dev/null || echo "")
      if [ -n "$user_data" ] && [ "$user_data" != "None" ]; then
        pass "EC2 に user_data が設定されている"
      else
        fail "EC2 に user_data がありません" "Step 5のプロンプトでuser_dataを追加して再構築してください"
      fi
    else
      fail "インスタンスIDが取得できないためスキップ"
    fi
  fi

  # Step 6: HTTP アクセス + カスタムページ
  if [ "$step" = "all" ] || [ "$step" = "step6" ]; then
    echo ""
    echo "📦 Step 6: HTTPアクセス + カスタムページ"
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://$ip" 2>/dev/null || echo "000")
    if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
      pass "HTTP でアクセス可能 (ステータス: $http_code)"
    else
      fail "HTTP でアクセスできません (ステータス: $http_code)" "SGのHTTPルールとnginxの起動状態を確認してください"
    fi
  fi

  summary
}

# =============================================================================
# セッション3: Web サーバーを冗長構成にしよう
# =============================================================================
check_session3() {
  local step="${1:-all}"
  echo ""
  echo "🔍 セッション3: Web サーバーを冗長構成にしよう"
  echo "------------------------------"

  local ip
  ip=$(tf_output "instance_public_ip")
  if [ -z "$ip" ]; then
    fail "EC2のIPが取得できません" "セッション2を完了してください"
    summary
    return
  fi

  # セッション3は最終的に1台構成に戻すため、完了後は以下を確認:
  # - EC2が1台で running
  # - nginx が動作中
  # - terraform plan で差分なし

  # Step 1-2: EC2の状態確認（最終状態は1台）
  if [ "$step" = "all" ] || [ "$step" = "step1" ] || [ "$step" = "step2" ]; then
    echo ""
    echo "📦 Step 1-2: EC2 状態確認"
    local inst_id
    inst_id=$(tf_output "instance_id")
    if [ -n "$inst_id" ]; then
      local state
      state=$(aws ec2 describe-instances --instance-ids "$inst_id" \
        --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null || echo "")
      if [ "$state" = "running" ]; then
        pass "EC2 インスタンスが running 状態 ($inst_id)"
      else
        fail "EC2 の状態: ${state:-不明}" "terraform apply を実行してください"
      fi
    else
      fail "インスタンスIDが取得できません"
    fi

    # nginx アクセス確認
    local http_code
    http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://$ip" 2>/dev/null || echo "000")
    if [ "$http_code" = "200" ] || [ "$http_code" = "301" ] || [ "$http_code" = "302" ]; then
      pass "HTTP でアクセス可能 (ステータス: $http_code)"
    else
      fail "HTTP でアクセスできません (ステータス: $http_code)"
    fi
  fi

  # Step 3: コードの整合性確認（terraform plan で差分なし）
  if [ "$step" = "all" ] || [ "$step" = "step3" ]; then
    echo ""
    echo "📦 Step 3: Terraform コードの整合性"
    local plan_output
    plan_output=$(terraform -chdir=terraform/vpc-ec2 plan -no-color 2>&1 || echo "ERROR")
    if echo "$plan_output" | grep -q "No changes\|0 to add, 0 to change, 0 to destroy"; then
      pass "terraform plan で差分なし（コードとインフラが一致）"
    elif echo "$plan_output" | grep -q "ERROR"; then
      fail "terraform plan の実行に失敗しました" "terraform init を実行してください"
    else
      fail "terraform plan に差分があります" "countを1に戻してterraform applyを実行してください"
    fi
  fi

  summary
}

# =============================================================================
# セッション4: Ansible によるサーバー運用自動化
# =============================================================================
check_session4() {
  local step="${1:-all}"
  echo ""
  echo "🔍 セッション4: Ansible によるサーバー運用自動化"
  echo "------------------------------"

  # Step 1: Ansible設定ファイル
  if [ "$step" = "all" ] || [ "$step" = "step1" ]; then
    echo ""
    echo "📦 Step 1: Ansible接続設定"
    if [ -f "ansible/ansible.cfg" ]; then
      pass "ansible.cfg が存在する"
    else
      fail "ansible/ansible.cfg がありません" "Agentにansible.cfgの作成を指示してください"
    fi
    if [ -f "ansible/inventory.ini" ]; then
      pass "inventory.ini が存在する"
      # IP がプレースホルダでないか確認
      if grep -q '<EC2' "ansible/inventory.ini" 2>/dev/null; then
        fail "inventory.ini に <EC2のIP> のプレースホルダが残っています" "実際のIPアドレスに置き換えてください"
      else
        pass "inventory.ini に実際のIPアドレスが設定されている"
      fi
    else
      fail "ansible/inventory.ini がありません" "Agentにinventory.iniの作成を指示してください"
    fi
  fi

  # Step 2: 接続テスト
  if [ "$step" = "all" ] || [ "$step" = "step2" ]; then
    echo ""
    echo "📦 Step 2: 接続テスト"
    local ping_result
    ping_result=$(ANSIBLE_CONFIG=ansible/ansible.cfg ansible -i ansible/inventory.ini all -m ping 2>/dev/null | grep -c "SUCCESS" || echo "0")
    if [ "$ping_result" -gt 0 ]; then
      pass "ansible ping 成功"
    else
      fail "ansible ping 失敗" "inventory.ini のIPアドレスとSSH鍵のパスを確認してください"
    fi
  fi

  # Step 3-6: Playbook 存在チェック
  if [ "$step" = "all" ] || [ "$step" = "step3" ]; then
    echo ""
    echo "📦 Step 3: サーバー状態確認"
    local pb="ansible/playbooks/check_status.yml"
    if [ -f "$pb" ] || compgen -G "ansible/playbooks/*check*status*" > /dev/null 2>&1; then
      pass "check_status Playbook が存在する"
    else
      fail "check_status Playbook がありません"
    fi
  fi

  if [ "$step" = "all" ] || [ "$step" = "step4" ]; then
    echo ""
    echo "📦 Step 4: サーバー再起動"
    local pb="ansible/playbooks/restart_server.yml"
    if [ -f "$pb" ] || compgen -G "ansible/playbooks/*restart*" > /dev/null 2>&1; then
      pass "restart_server Playbook が存在する"
    else
      fail "restart_server Playbook がありません"
    fi
  fi

  if [ "$step" = "all" ] || [ "$step" = "step5" ]; then
    echo ""
    echo "📦 Step 5: サービス管理"
    local pb="ansible/playbooks/manage_services.yml"
    if [ -f "$pb" ] || compgen -G "ansible/playbooks/*manage*service*" > /dev/null 2>&1; then
      pass "manage_services Playbook が存在する"
    else
      fail "manage_services Playbook がありません"
    fi
  fi

  if [ "$step" = "all" ] || [ "$step" = "step6" ]; then
    echo ""
    echo "📦 Step 6: 🔧 障害対応シミュレーション"
    local pb="ansible/playbooks/server_health_check.yml"
    if [ -f "$pb" ] || compgen -G "ansible/playbooks/*health*check*" > /dev/null 2>&1; then
      pass "server_health_check（診断・復旧）Playbook が存在する"
    else
      fail "server_health_check Playbook がありません" "Step 6の障害対応シミュレーションを実行してください"
    fi
  fi

  summary
}

# =============================================================================
# セッション5: EC2 のリモート管理と監視基盤
# =============================================================================
check_session5() {
  local step="${1:-all}"
  echo ""
  echo "🔍 セッション5: EC2 のリモート管理と監視基盤"
  echo "------------------------------"

  local ip
  ip=$(tf_output "instance_public_ip")
  local inst_id
  inst_id=$(tf_output "instance_id")

  # 前半: SSM Agent（IAMロール + SSM Agent + フリートマネージャー）
  if [ "$step" = "all" ] || [ "$step" = "step1" ]; then
    echo ""
    echo "📦 前半: SSH なしでサーバーを管理できるようにしよう"

    # IAMロール
    local role_name="${TF_VAR_prefix}-ec2-agent-role"
    local profile_name="${TF_VAR_prefix}-ec2-agent-profile"
    local role
    role=$(aws iam get-role --role-name "$role_name" --query 'Role.RoleName' --output text 2>/dev/null || echo "")
    if [ "$role" = "$role_name" ]; then
      pass "IAMロール $role_name が存在する"
    else
      fail "IAMロール $role_name がありません" "Claude Code に IAM ロールの作成を相談してください"
    fi

    local profile
    profile=$(aws iam get-instance-profile --instance-profile-name "$profile_name" \
      --query 'InstanceProfile.InstanceProfileName' --output text 2>/dev/null || echo "")
    if [ "$profile" = "$profile_name" ]; then
      pass "インスタンスプロファイル $profile_name が存在する"
    else
      fail "インスタンスプロファイル $profile_name がありません"
    fi

    # SSM Agent
    if [ -n "$ip" ]; then
      local ssm_status
      ssm_status=$(ssh_check_cmd "$ip" "systemctl is-active amazon-ssm-agent" 2>/dev/null || echo "")
      if [ "$ssm_status" = "active" ]; then
        pass "SSM Agent が active (running)"
      else
        fail "SSM Agent が起動していません" "Ansible Playbook で SSM Agent をインストールしてください"
      fi
    else
      fail "EC2のIPが取得できないためスキップ"
    fi

    # フリートマネージャー確認
    if [ -n "$inst_id" ]; then
      local ssm_info
      ssm_info=$(aws ssm describe-instance-information \
        --filters "Key=InstanceIds,Values=$inst_id" \
        --query 'InstanceInformationList[0].PingStatus' --output text 2>/dev/null || echo "")
      if [ "$ssm_info" = "Online" ]; then
        pass "Systems Manager でインスタンスが Online"
      else
        fail "Systems Manager にインスタンスが登録されていません（${ssm_info:-不明}）" "IAMロールの関連付けとSSM Agentの再起動を確認してください"
      fi
    else
      fail "インスタンスIDが取得できないためスキップ"
    fi
  fi

  # 後半: CloudWatch Agent（Agent + メトリクス + Alarm）
  if [ "$step" = "all" ] || [ "$step" = "step2" ]; then
    echo ""
    echo "📦 後半: サーバーの監視基盤を構築しよう"

    if [ -n "$ip" ]; then
      local cw_status
      cw_status=$(ssh_check_cmd "$ip" "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status 2>/dev/null | grep -o 'running'" 2>/dev/null || echo "")
      if [ "$cw_status" = "running" ]; then
        pass "CloudWatch Agent が running"
      else
        fail "CloudWatch Agent が起動していません" "Ansible Playbook で CloudWatch Agent をインストール・設定してください"
      fi
    else
      fail "EC2のIPが取得できないためスキップ"
    fi

    # メトリクス確認
    local cw_namespace="${TF_VAR_prefix}/EC2"
    local metrics
    metrics=$(aws cloudwatch list-metrics --namespace "$cw_namespace" \
      --query 'Metrics | length(@)' --output text 2>/dev/null || echo "0")
    if [ "$metrics" -gt 0 ] 2>/dev/null; then
      pass "$cw_namespace 名前空間にメトリクスが存在する ($metrics 個)"
    else
      fail "$cw_namespace 名前空間にメトリクスがありません" "数分待ってから再確認してください"
    fi

    # CloudWatch Alarm
    local alarm_prefix="${TF_VAR_prefix}"
    local alarm_count
    alarm_count=$(aws cloudwatch describe-alarms --alarm-name-prefix "$alarm_prefix" \
      --query 'MetricAlarms | length(@)' --output text 2>/dev/null || echo "0")
    if [ "$alarm_count" -gt 0 ] 2>/dev/null; then
      pass "CloudWatch Alarm が存在する ($alarm_count 個)"
    else
      fail "CloudWatch Alarm が見つかりません" "CPU 使用率のアラームを作成してください"
    fi
  fi

  summary
}

# =============================================================================
# セッション6: 運用レポートの自動生成
# =============================================================================
check_session6() {
  local step="${1:-all}"
  echo ""
  echo "🔍 セッション6: 運用レポートの自動生成"
  echo "------------------------------"

  # Step 1: 情報収集 Playbook
  if [ "$step" = "all" ] || [ "$step" = "step1" ]; then
    echo ""
    echo "📦 Step 1: サーバー情報収集"
    if [ -f "ansible/playbooks/gather_info.yml" ] || compgen -G "ansible/playbooks/*gather*" > /dev/null 2>&1; then
      pass "gather_info Playbook が存在する"
    else
      fail "gather_info Playbook がありません"
    fi
  fi

  # Step 2: テンプレート
  if [ "$step" = "all" ] || [ "$step" = "step2" ]; then
    echo ""
    echo "📦 Step 2: レポートテンプレート"
    if [ -f "ansible/templates/server_report.md.j2" ] || compgen -G "ansible/templates/*.j2" > /dev/null 2>&1; then
      pass "Jinja2 テンプレートが存在する"
    else
      fail "ansible/templates/ にテンプレートがありません"
    fi
  fi

  # Step 3: レポート生成
  if [ "$step" = "all" ] || [ "$step" = "step3" ]; then
    echo ""
    echo "📦 Step 3: レポート自動生成"
    if [ -f "ansible/playbooks/generate_report.yml" ] || compgen -G "ansible/playbooks/*report*" > /dev/null 2>&1; then
      pass "generate_report Playbook が存在する"
    else
      fail "generate_report Playbook がありません"
    fi
    local report_count
    report_count=$(compgen -G "ansible/reports/*.md" 2>/dev/null | wc -l || echo "0")
    if [ "$report_count" -gt 0 ]; then
      pass "レポートが生成されている ($report_count ファイル)"
    else
      fail "ansible/reports/ にレポートがありません" "generate_report.yml を実行してください"
    fi
  fi

  summary
}

# =============================================================================
# メイン
# =============================================================================
usage() {
  echo "使い方: $0 <session> [step]"
  echo ""
  echo "セッション:"
  echo "  session0   Claude Code に慣れよう"
  echo "  session1   VPC + EC2 を段階的に構築"
  echo "  session2   Terraform でインフラを構築・変更・再構築"
  echo "  session3   EC2 を count でスケールアウト"
  echo "  session4   Ansible によるサーバー運用自動化"
  echo "  session5   EC2 のリモート管理と監視基盤"
  echo "  session6   サーバー情報取得・運用レポート"
  echo ""
  echo "ステップ（任意）:"
  echo "  step1, step2, ... stepN"
  echo ""
  echo "例:"
  echo "  $0 session1          # セッション1全体をチェック"
  echo "  $0 session1 step3    # セッション1の Step3 だけチェック"
}

main() {
  if [ $# -lt 1 ]; then
    usage
    exit 1
  fi

  local session="$1"
  local step="${2:-all}"

  local result=0
  case "$session" in
    session0) check_session0 "$step" || result=$? ;;
    session1) check_session1 "$step" || result=$? ;;
    session2) check_session2 "$step" || result=$? ;;
    session3) check_session3 "$step" || result=$? ;;
    session4) check_session4 "$step" || result=$? ;;
    session5) check_session5 "$step" || result=$? ;;
    session6) check_session6 "$step" || result=$? ;;
    *)
      echo "エラー: 不明なセッション '$session'"
      usage
      exit 1
      ;;
  esac

  if [ "$result" -gt 0 ]; then
    exit 1
  fi
}

main "$@"
