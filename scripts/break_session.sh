#!/usr/bin/env bash
# =============================================================================
# 障害対応シミュレーション — ランダム障害発生スクリプト
#
# EC2 にランダムな障害を発生させます。
# どの障害が選ばれるかは毎回異なるため、事前に予測できません。
#
# 使い方:
#   ./scripts/break_session.sh <EC2のIPアドレス>
#   例: ./scripts/break_session.sh 13.112.xxx.xxx
# =============================================================================

set -uo pipefail

# --- 引数チェック ---
if [ -z "${1:-}" ]; then
  echo "使い方: $0 <EC2のIPアドレス>"
  echo "例: $0 13.112.xxx.xxx"
  exit 1
fi

EC2_IP="$1"
KEY_PATH="keys/training-key"
SSH_USER="ec2-user"
SSH_OPTS="-i $KEY_PATH -o StrictHostKeyChecking=no -o ConnectTimeout=10"

# --- SSH接続チェック ---
echo "EC2 ($EC2_IP) への接続を確認中..."
if ! ssh $SSH_OPTS "$SSH_USER@$EC2_IP" "echo ok" &>/dev/null; then
  echo "[ERROR] EC2 ($EC2_IP) に接続できません。"
  echo "  - IPアドレスが正しいか確認してください"
  echo "  - SSH鍵（keys/training-key）が存在するか確認してください"
  echo "  - EC2 が起動しているか確認してください"
  exit 1
fi

# --- 障害パターン定義 ---
# 各関数は EC2 上で1つの障害を発生させる
# パターンはランダムに選択されるため、このスクリプトを読んでも
# 実際にどの障害が発生したかは分かりません

issue_stop_nginx() {
  ssh $SSH_OPTS "$SSH_USER@$EC2_IP" bash -c "'
    sudo systemctl stop nginx 2>/dev/null
  '" 2>/dev/null
}

issue_log_permissions() {
  ssh $SSH_OPTS "$SSH_USER@$EC2_IP" bash -c "'
    sudo chmod 000 /var/log/messages 2>/dev/null
  '" 2>/dev/null
}

issue_hosts_corrupt() {
  ssh $SSH_OPTS "$SSH_USER@$EC2_IP" bash -c "'
    sudo cp /etc/hosts /etc/hosts.bak.break 2>/dev/null
    echo \"999.999.999.999 important-service.internal api.internal\" | sudo tee -a /etc/hosts >/dev/null
  '" 2>/dev/null
}

issue_stop_chronyd() {
  ssh $SSH_OPTS "$SSH_USER@$EC2_IP" bash -c "'
    sudo systemctl stop chronyd 2>/dev/null
    sudo cp /etc/chrony.conf /etc/chrony.conf.bak.break 2>/dev/null
    echo \"INVALID_CHRONY_CONFIG\" | sudo tee /etc/chrony.conf >/dev/null
  '" 2>/dev/null
}

issue_fill_tmp() {
  ssh $SSH_OPTS "$SSH_USER@$EC2_IP" bash -c "'
    dd if=/dev/zero of=/tmp/.break_large_file_a bs=1M count=80 2>/dev/null
    dd if=/dev/zero of=/tmp/.break_large_file_b bs=1M count=80 2>/dev/null
    dd if=/dev/zero of=/tmp/.break_large_file_c bs=1M count=80 2>/dev/null
  '" 2>/dev/null
}

issue_broken_cronjob() {
  ssh $SSH_OPTS "$SSH_USER@$EC2_IP" bash -c "'
    echo \"* * * * * root /usr/bin/nonexistent_break_command 2>&1 | logger -t BROKEN_SERVICE\" | sudo tee /etc/cron.d/break_simulation >/dev/null
    sudo chmod 644 /etc/cron.d/break_simulation
  '" 2>/dev/null
}

# --- 障害パターンのプール ---
ISSUE_FUNCS=(
  issue_stop_nginx
  issue_log_permissions
  issue_hosts_corrupt
  issue_stop_chronyd
  issue_fill_tmp
  issue_broken_cronjob
)
ISSUE_COUNT=${#ISSUE_FUNCS[@]}

# --- ランダムに2つ選択（重複なし） ---
declare -a SELECTED_INDICES=()

while [ ${#SELECTED_INDICES[@]} -lt 2 ]; do
  CANDIDATE=$((RANDOM % ISSUE_COUNT))
  DUPLICATE=false
  for existing in "${SELECTED_INDICES[@]+"${SELECTED_INDICES[@]}"}"; do
    if [ "$existing" = "$CANDIDATE" ]; then
      DUPLICATE=true
      break
    fi
  done
  if [ "$DUPLICATE" = false ]; then
    SELECTED_INDICES+=("$CANDIDATE")
  fi
done

# --- 選択された障害を実行 ---
echo "障害を発生させています..."
for idx in "${SELECTED_INDICES[@]}"; do
  ${ISSUE_FUNCS[$idx]} || true
done

# --- メッセージ表示 ---
echo ""
echo "⚠️ ============================================="
echo "⚠️  EC2 に障害が発生しました（2件）"
echo "⚠️ ============================================="
echo ""
echo "Claude Code に以下のように伝えてください："
echo ""
echo "――――――――――――――――――――――――――――――――――――――"
echo "EC2（$EC2_IP）に何らかの問題が発生しています。"
echo "SSHで接続して、サーバーの状態を調査し、"
echo "見つかった問題をすべて修正してください。"
echo ""
echo "■ 接続情報"
echo "- IP: $EC2_IP"
echo "- SSH鍵: keys/training-key"
echo "- ユーザー: ec2-user"
echo ""
echo "■ 調査ポイント"
echo "- サービスの状態（systemctl で確認）"
echo "- 設定ファイルの整合性"
echo "- ログファイル"
echo "- ディスク使用量"
echo "- 不審なプロセスやジョブ"
echo "――――――――――――――――――――――――――――――――――――――"
echo ""
echo "💡 Claude Code の調査・修復プロセスをよく観察してください。"
