#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0
FAIL=0
TOTAL=0

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${PROJECT_ROOT}/terraform/vpc-ec2"
ANSIBLE_DIR="${PROJECT_ROOT}/ansible"
KEYS_DIR="${PROJECT_ROOT}/keys"

print_result() {
    local status="$1" step="$2" message="$3"
    TOTAL=$((TOTAL + 1))
    if [ "$status" = "pass" ]; then
        PASS=$((PASS + 1))
        echo -e "  ${GREEN}✅ ${step}: ${message}${NC}"
    else
        FAIL=$((FAIL + 1))
        echo -e "  ${RED}❌ ${step}: ${message}${NC}"
        if [ -n "${4:-}" ]; then
            echo -e "     ${YELLOW}→ ${4}${NC}"
        fi
    fi
}

print_summary() {
    echo ""
    echo -e "${BOLD}結果: ${PASS}/${TOTAL} 完了${NC}"
    if [ "$FAIL" -eq 0 ]; then
        echo -e "${GREEN}すべてのチェックに合格しました！${NC}"
    else
        echo -e "${RED}${FAIL} 件のチェックが未完了です${NC}"
    fi
}

tf_output() {
    terraform -chdir="$TF_DIR" output -raw "$1" 2>/dev/null
}

get_ec2_ip() {
    tf_output instance_public_ip 2>/dev/null || echo ""
}

get_ssh_key() {
    if [ -f "${KEYS_DIR}/training-key" ]; then
        echo "${KEYS_DIR}/training-key"
    else
        echo ""
    fi
}

ssh_cmd() {
    local ip key
    ip=$(get_ec2_ip)
    key=$(get_ssh_key)
    if [ -z "$ip" ] || [ -z "$key" ]; then
        return 1
    fi
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -o BatchMode=yes \
        -i "$key" ec2-user@"$ip" "$@" 2>/dev/null
}

# -------------------------------------------------------------------

check_session1() {
    local session_name="session1" step_filter="${1:-}"
    echo -e "${BOLD}Session 1: VPC + EC2 を段階的に構築${NC}"
    echo ""

    if ! [ -d "$TF_DIR" ]; then
        echo -e "  ${RED}terraform/vpc-ec2/ ディレクトリが見つかりません${NC}"
        echo -e "  ${YELLOW}→ セッション1をまだ開始していない場合は、ガイドに従って開始してください${NC}"
        return
    fi

    if ! terraform -chdir="$TF_DIR" output -json >/dev/null 2>&1; then
        echo -e "  ${RED}terraform output を実行できません（terraform init が必要かもしれません）${NC}"
        return
    fi

    # Step 1: VPC
    if [ -z "$step_filter" ] || [ "$step_filter" = "step1" ]; then
        local vpc_id
        vpc_id=$(tf_output vpc_id 2>/dev/null || echo "")
        if [ -n "$vpc_id" ] && [[ "$vpc_id" == vpc-* ]]; then
            print_result pass "Step 1" "VPC が作成されている (${vpc_id})"
        else
            print_result fail "Step 1" "VPC が見つかりません" "terraform apply を実行してください"
        fi
    fi

    # Step 2: Subnet & IGW
    if [ -z "$step_filter" ] || [ "$step_filter" = "step2" ]; then
        local subnet_id
        subnet_id=$(tf_output subnet_id 2>/dev/null || echo "")
        if [ -n "$subnet_id" ] && [[ "$subnet_id" == subnet-* ]]; then
            print_result pass "Step 2" "サブネットが作成されている (${subnet_id})"
        else
            print_result fail "Step 2" "サブネットが見つかりません" "Step 2 の terraform apply を実行してください"
        fi
    fi

    # Step 3: SG with SSH
    if [ -z "$step_filter" ] || [ "$step_filter" = "step3" ]; then
        local sg_id
        sg_id=$(tf_output security_group_id 2>/dev/null || echo "")
        if [ -n "$sg_id" ] && [[ "$sg_id" == sg-* ]]; then
            local ssh_rule
            ssh_rule=$(aws ec2 describe-security-groups --group-ids "$sg_id" \
                --query 'SecurityGroups[0].IpPermissions[?FromPort==`22` && ToPort==`22`]' \
                --output text 2>/dev/null || echo "")
            if [ -n "$ssh_rule" ]; then
                print_result pass "Step 3" "セキュリティグループが SSH(22) を許可している (${sg_id})"
            else
                print_result fail "Step 3" "セキュリティグループに SSH ルールがありません" "SSH(22) のインバウンドルールを追加してください"
            fi
        else
            print_result fail "Step 3" "セキュリティグループが見つかりません (output名: security_group_id)" "Step 3 の terraform apply を実行してください"
        fi
    fi

    # Step 4: EC2
    if [ -z "$step_filter" ] || [ "$step_filter" = "step4" ]; then
        local instance_ip instance_id
        instance_ip=$(get_ec2_ip)
        instance_id=$(tf_output instance_id 2>/dev/null || echo "")
        if [ -n "$instance_ip" ] && [ -n "$instance_id" ]; then
            local state
            state=$(aws ec2 describe-instances --instance-ids "$instance_id" \
                --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null || echo "")
            if [ "$state" = "running" ]; then
                print_result pass "Step 4" "EC2 インスタンスが running (${instance_id}, ${instance_ip})"
            else
                print_result fail "Step 4" "EC2 インスタンスの状態: ${state:-不明}" "インスタンスが running 状態か確認してください"
            fi
        else
            print_result fail "Step 4" "EC2 インスタンスが見つかりません" "Step 4 の terraform apply を実行してください"
        fi
    fi

    # Step 5: SSH
    if [ -z "$step_filter" ] || [ "$step_filter" = "step5" ]; then
        local key
        key=$(get_ssh_key)
        if [ -z "$key" ]; then
            print_result fail "Step 5" "SSH鍵が見つかりません" "keys/training-key を作成してください"
        else
            if ssh_cmd "echo ok" >/dev/null 2>&1; then
                print_result pass "Step 5" "SSH 接続に成功"
            else
                print_result fail "Step 5" "SSH 接続に失敗" "キーの権限 (chmod 400) やセキュリティグループを確認してください"
            fi
        fi
    fi

    print_summary
}

check_session2() {
    local session_name="session2" step_filter="${1:-}"
    echo -e "${BOLD}Session 2: Webアプリケーションを公開${NC}"
    echo ""

    if ! [ -d "$TF_DIR" ]; then
        echo -e "  ${RED}terraform/vpc-ec2/ ディレクトリが見つかりません${NC}"
        return
    fi

    # Step 1: SG HTTP rule
    if [ -z "$step_filter" ] || [ "$step_filter" = "step1" ]; then
        local sg_id
        sg_id=$(tf_output security_group_id 2>/dev/null || echo "")
        if [ -n "$sg_id" ] && [[ "$sg_id" == sg-* ]]; then
            local http_rule
            http_rule=$(aws ec2 describe-security-groups --group-ids "$sg_id" \
                --query 'SecurityGroups[0].IpPermissions[?FromPort==`80` && ToPort==`80`]' \
                --output text 2>/dev/null || echo "")
            if [ -n "$http_rule" ]; then
                print_result pass "Step 1" "セキュリティグループに HTTP(80) ルールあり"
            else
                print_result fail "Step 1" "HTTP(80) のインバウンドルールがありません" "セキュリティグループに HTTP ルールを追加してください"
            fi
        else
            print_result fail "Step 1" "セキュリティグループが見つかりません" "Session 1 を先に完了してください"
        fi
    fi

    # Step 2: nginx running
    if [ -z "$step_filter" ] || [ "$step_filter" = "step2" ]; then
        local nginx_status
        nginx_status=$(ssh_cmd "systemctl is-active nginx" 2>/dev/null || echo "")
        if [ "$nginx_status" = "active" ]; then
            print_result pass "Step 2" "nginx が起動している"
        else
            print_result fail "Step 2" "nginx が起動していません (状態: ${nginx_status:-接続不可})" "EC2 に SSH で接続して nginx をインストール・起動してください"
        fi
    fi

    # Step 3: HTTP access
    if [ -z "$step_filter" ] || [ "$step_filter" = "step3" ]; then
        local ip http_code
        ip=$(get_ec2_ip)
        if [ -n "$ip" ]; then
            http_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "http://${ip}/" 2>/dev/null || echo "000")
            if [ "$http_code" = "200" ]; then
                print_result pass "Step 3" "HTTP でアクセス可能 (http://${ip}/)"
            else
                print_result fail "Step 3" "HTTP アクセス失敗 (HTTP ${http_code})" "セキュリティグループと nginx の状態を確認してください"
            fi
        else
            print_result fail "Step 3" "EC2 の IP アドレスが取得できません" "Session 1 を先に完了してください"
        fi
    fi

    # Step 4-5: Custom page
    if [ -z "$step_filter" ] || [ "$step_filter" = "step4" ] || [ "$step_filter" = "step5" ]; then
        local ip body
        ip=$(get_ec2_ip)
        if [ -n "$ip" ]; then
            body=$(curl -s --connect-timeout 5 "http://${ip}/" 2>/dev/null || echo "")
            if [ -n "$body" ] && ! echo "$body" | grep -qi "Welcome to nginx" >/dev/null 2>&1; then
                print_result pass "Step 4-5" "カスタムページがデプロイされている"
            elif [ -n "$body" ]; then
                print_result fail "Step 4-5" "デフォルトの nginx ページが表示されています" "カスタム HTML を作成して EC2 にデプロイしてください"
            else
                print_result fail "Step 4-5" "ページの取得に失敗しました" "HTTP アクセスが可能か確認してください"
            fi
        else
            print_result fail "Step 4-5" "EC2 の IP アドレスが取得できません" "Session 1 を先に完了してください"
        fi
    fi

    print_summary
}

check_session3() {
    local step_filter="${1:-}"
    echo -e "${BOLD}Session 3: HTTPS 対応${NC}"
    echo ""
    echo -e "  ${YELLOW}(未実装 — 今後のアップデートで追加予定)${NC}"
}

check_session4() {
    local step_filter="${1:-}"
    echo -e "${BOLD}Session 4: サーバー再起動の自動化${NC}"
    echo ""

    # Step 1: config files exist
    if [ -z "$step_filter" ] || [ "$step_filter" = "step1" ]; then
        if [ -f "${ANSIBLE_DIR}/ansible.cfg" ] && [ -f "${ANSIBLE_DIR}/inventory.ini" ]; then
            print_result pass "Step 1" "ansible.cfg と inventory.ini が存在する"
        else
            local missing=""
            [ ! -f "${ANSIBLE_DIR}/ansible.cfg" ] && missing="ansible.cfg "
            [ ! -f "${ANSIBLE_DIR}/inventory.ini" ] && missing="${missing}inventory.ini"
            print_result fail "Step 1" "${missing} が見つかりません" "ansible/ フォルダに設定ファイルを作成してください"
        fi
    fi

    # Step 2: Ansible ping
    if [ -z "$step_filter" ] || [ "$step_filter" = "step2" ]; then
        local ping_result
        ping_result=$(cd "$ANSIBLE_DIR" && ansible all -m ping --one-line 2>/dev/null || echo "FAIL")
        if echo "$ping_result" | grep -q "SUCCESS"; then
            print_result pass "Step 2" "Ansible ping 成功"
        else
            print_result fail "Step 2" "Ansible ping 失敗" "接続設定 (inventory, SSH鍵) を確認してください"
        fi
    fi

    # Steps 3-6: Playbook existence + syntax
    local playbooks=("check_status.yml:Step 3" "restart_server.yml:Step 4" "manage_services.yml:Step 5" "maintain_nginx.yml:Step 6")
    for entry in "${playbooks[@]}"; do
        local file="${entry%%:*}" step="${entry##*:}"
        if [ -n "$step_filter" ] && [ "$step_filter" != "$(echo "$step" | tr '[:upper:]' '[:lower:]' | tr ' ' '')" ]; then
            continue
        fi
        local path="${ANSIBLE_DIR}/playbooks/${file}"
        if [ -f "$path" ]; then
            local syntax
            syntax=$(cd "$ANSIBLE_DIR" && ansible-playbook --syntax-check "playbooks/${file}" 2>&1 || echo "ERROR")
            if echo "$syntax" | grep -q "ERROR"; then
                print_result fail "$step" "${file} に構文エラーがあります" "ansible-playbook --syntax-check で確認してください"
            else
                print_result pass "$step" "${file} が存在し構文も正しい"
            fi
        else
            print_result fail "$step" "${file} が見つかりません" "Playbook を作成してください"
        fi
    done

    print_summary
}

check_session5() {
    local step_filter="${1:-}"
    echo -e "${BOLD}Session 5: SSM Agent & CloudWatch Agent 導入${NC}"
    echo ""

    # Step 1: IAM role
    if [ -z "$step_filter" ] || [ "$step_filter" = "step1" ]; then
        local role
        role=$(aws iam get-role --role-name training-ec2-agent-role --query 'Role.RoleName' --output text 2>/dev/null || echo "")
        if [ "$role" = "training-ec2-agent-role" ]; then
            print_result pass "Step 1" "IAM ロール training-ec2-agent-role が存在する"
        else
            print_result fail "Step 1" "IAM ロールが見つかりません" "AWS CLI で IAM ロールを作成してください"
        fi
    fi

    # Step 2: SSM Agent
    if [ -z "$step_filter" ] || [ "$step_filter" = "step2" ]; then
        local ssm_status
        ssm_status=$(ssh_cmd "systemctl is-active amazon-ssm-agent" 2>/dev/null || echo "")
        if [ "$ssm_status" = "active" ]; then
            print_result pass "Step 2" "SSM Agent が稼働している"
        else
            print_result fail "Step 2" "SSM Agent が稼働していません (状態: ${ssm_status:-接続不可})" "install_ssm_agent.yml を実行してください"
        fi
    fi

    # Steps 5-6: CW Agent
    if [ -z "$step_filter" ] || [ "$step_filter" = "step5" ] || [ "$step_filter" = "step6" ]; then
        local cw_status
        cw_status=$(ssh_cmd "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status" 2>/dev/null || echo "")
        if echo "$cw_status" | grep -q '"status": "running"'; then
            print_result pass "Step 5-6" "CloudWatch Agent が running"
        else
            print_result fail "Step 5-6" "CloudWatch Agent が稼働していません" "install_cwagent.yml と configure_cwagent.yml を実行してください"
        fi
    fi

    # Step 8: CW Alarm
    if [ -z "$step_filter" ] || [ "$step_filter" = "step8" ]; then
        local alarm
        alarm=$(aws cloudwatch describe-alarms --alarm-name-prefix training-cpu \
            --query 'MetricAlarms[0].AlarmName' --output text 2>/dev/null || echo "None")
        if [ -n "$alarm" ] && [ "$alarm" != "None" ]; then
            print_result pass "Step 8" "CloudWatch Alarm が存在する (${alarm})"
        else
            print_result fail "Step 8" "CloudWatch Alarm が見つかりません" "AWS CLI で CloudWatch Alarm を作成してください"
        fi
    fi

    print_summary
}

check_session6() {
    local step_filter="${1:-}"
    echo -e "${BOLD}Session 6: サーバー情報取得・運用レポート${NC}"
    echo ""
    echo -e "  ${YELLOW}(未実装 — 今後のアップデートで追加予定)${NC}"
}

# -------------------------------------------------------------------

usage() {
    echo "使い方: $0 <session> [step]"
    echo ""
    echo "引数:"
    echo "  session   session1 | session2 | session3 | session4 | session5 | session6"
    echo "  step      (オプション) step1 | step2 | ... 特定のStepだけチェック"
    echo ""
    echo "例:"
    echo "  $0 session1          # セッション1の全Stepをチェック"
    echo "  $0 session1 step3    # セッション1のStep3だけチェック"
    echo "  $0 session2          # セッション2の全Stepをチェック"
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

SESSION="$1"
STEP="${2:-}"

case "$SESSION" in
    session1) check_session1 "$STEP" ;;
    session2) check_session2 "$STEP" ;;
    session3) check_session3 "$STEP" ;;
    session4) check_session4 "$STEP" ;;
    session5) check_session5 "$STEP" ;;
    session6) check_session6 "$STEP" ;;
    *)
        echo "エラー: 不明なセッション '$SESSION'"
        usage
        exit 1
        ;;
esac
