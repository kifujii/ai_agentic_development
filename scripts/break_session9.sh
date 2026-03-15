#!/usr/bin/env bash
# =============================================================================
# セッション9：複合障害シミュレーション
#
# インフラレベル（AWS リソース設定変更）とサーバーレベル（OS 内部の障害）を
# 組み合わせた複合障害を発生させます。
#
# インフラ障害（5件・固定）:
#   - セキュリティグループの HTTP/SSH ルール削除
#   - ルートテーブルの IGW ルート削除
#   - EC2 の Name タグ改ざん
#   - EC2 インスタンスの停止
#
# サーバー障害（2件・ランダム）:
#   - break_session.sh と同じ6パターンからランダムに2つ選択
#
# 使い方:
#   ./scripts/break_session9.sh
#
# 前提:
#   - terraform/vpc-ec2 に Terraform の state が存在すること（または PREFIX タグ付きリソースが存在）
#   - keys/training-key で EC2 に SSH 接続できること
#   - AWS CLI が設定済みであること
#   - Python 3 がインストールされていること（count=2 対応に使用）
# =============================================================================

set -uo pipefail
export AWS_PAGER=""

echo "========================================="
echo " セッション9：複合障害シミュレーション"
echo "========================================="
echo ""

# --- Terraform output からリソース情報を取得 ---
TF_DIR="terraform/vpc-ec2"

if [ ! -d "$TF_DIR" ]; then
  echo "[ERROR] $TF_DIR が見つかりません。セッション1-2が完了している必要があります。"
  exit 1
fi

echo "[1/4] Terraform output からリソース情報を取得中..."

# Terraform output を取得（スカラー値・リスト型の両方に対応）
tf_output_scalar() {
  local key="$1"
  local val
  val=$(terraform -chdir="$TF_DIR" output -raw "$key" 2>/dev/null)
  if [ $? -ne 0 ] || [ -z "$val" ]; then
    val=$(terraform -chdir="$TF_DIR" output -json "$key" 2>/dev/null \
          | python3 -c "import sys,json; v=json.load(sys.stdin); print(v[0] if isinstance(v,list) else v)" 2>/dev/null)
  fi
  echo "$val"
}

# 複数の output 名を順に試す
tf_output_try() {
  local val
  for name in "$@"; do
    val=$(tf_output_scalar "$name")
    if [ -n "$val" ]; then echo "$val"; return; fi
  done
  echo ""
}

TF_VAR_prefix="${TF_VAR_prefix:-training}"

# --- Security Group ID ---
SG_ID=$(tf_output_try security_group_id sg_id)
if [ -z "$SG_ID" ]; then
  # フォールバック: PREFIX タグで VPC → SG を検索
  _vpc=$(aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=*${TF_VAR_prefix}*" "Name=state,Values=available" \
    --query 'Vpcs[0].VpcId' --output text 2>/dev/null | grep -v "^None$" || echo "")
  if [ -n "$_vpc" ]; then
    SG_ID=$(aws ec2 describe-security-groups \
      --filters "Name=vpc-id,Values=$_vpc" "Name=tag:Name,Values=*${TF_VAR_prefix}*" \
      --query 'SecurityGroups[?GroupName!=`default`] | [0].GroupId' --output text 2>/dev/null | grep -v "^None$" || echo "")
  fi
fi
if [ -z "$SG_ID" ]; then
  echo "[ERROR] security_group_id の取得に失敗しました"
  exit 1
fi

# --- Instance ID ---
INSTANCE_ID=$(tf_output_try instance_id ec2_instance_id)
if [ -z "$INSTANCE_ID" ]; then
  # フォールバック: PREFIX タグで検索
  INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=*${TF_VAR_prefix}*" "Name=instance-state-name,Values=running,stopped" \
    --query 'Reservations[].Instances[0].InstanceId' --output text 2>/dev/null | head -1 | grep -v "^None$" || echo "")
fi
if [ -z "$INSTANCE_ID" ]; then
  echo "[ERROR] instance_id の取得に失敗しました"
  exit 1
fi

# --- Instance Public IP ---
INSTANCE_IP=$(tf_output_try instance_public_ip public_ip ec2_public_ip)
if [ -z "$INSTANCE_IP" ]; then
  # フォールバック: インスタンスIDから取得
  INSTANCE_IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' --output text 2>/dev/null | grep -v "^None$" || echo "")
fi
if [ -z "$INSTANCE_IP" ]; then
  echo "[ERROR] instance_public_ip の取得に失敗しました"
  exit 1
fi

# セッション3未解消（count=2）の場合は警告を表示
INSTANCE_COUNT=$(terraform -chdir="$TF_DIR" output -json instance_id 2>/dev/null \
  | python3 -c "import sys,json; v=json.load(sys.stdin); print(len(v) if isinstance(v,list) else 1)" 2>/dev/null || echo "1")
if [ "${INSTANCE_COUNT}" -gt 1 ] 2>/dev/null; then
  echo "  ⚠️  EC2 が ${INSTANCE_COUNT} 台起動しています（セッション3の count が残っている可能性があります）"
  echo "  ⚠️  1台目（$INSTANCE_IP）を対象にします"
fi

echo "  Security Group: $SG_ID"
echo "  Instance ID:    $INSTANCE_ID"
echo "  Instance IP:    $INSTANCE_IP"

# VPC ID とルートテーブル ID を AWS CLI で取得
VPC_ID=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].VpcId' --output text 2>/dev/null) || {
  echo "[ERROR] VPC ID の取得に失敗しました。EC2 が起動しているか確認してください。"
  exit 1
}

RTB_ID=$(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[?Associations[?!Main]].RouteTableId | [0]' \
  --output text 2>/dev/null)

if [ -z "$RTB_ID" ] || [ "$RTB_ID" = "None" ]; then
  RTB_ID=$(aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'RouteTables[0].RouteTableId' \
    --output text 2>/dev/null)
fi

echo "  VPC:            $VPC_ID"
echo "  Route Table:    $RTB_ID"
echo ""

# =============================================================
# Phase 1: サーバー内部の障害を仕込む（SSH 経由）
# ※ インフラ変更で SSH が遮断される前に実施
# =============================================================

KEY_PATH="keys/training-key"
SSH_USER="ec2-user"
SSH_OPTS="-i $KEY_PATH -o StrictHostKeyChecking=no -o ConnectTimeout=10"

echo "[2/4] サーバー内部に障害を仕込んでいます..."

if ! ssh $SSH_OPTS "$SSH_USER@$INSTANCE_IP" "echo ok" &>/dev/null; then
  echo "[ERROR] EC2 ($INSTANCE_IP) に SSH 接続できません。"
  echo "  EC2 が起動しており、SSH 鍵が正しいか確認してください。"
  exit 1
fi

# --- サーバー障害パターン（break_session.sh と同一） ---

issue_stop_nginx() {
  ssh $SSH_OPTS "$SSH_USER@$INSTANCE_IP" bash -c "'
    sudo systemctl stop nginx 2>/dev/null
  '" 2>/dev/null
}

issue_log_permissions() {
  ssh $SSH_OPTS "$SSH_USER@$INSTANCE_IP" bash -c "'
    sudo chmod 000 /var/log/messages 2>/dev/null
  '" 2>/dev/null
}

issue_hosts_corrupt() {
  ssh $SSH_OPTS "$SSH_USER@$INSTANCE_IP" bash -c "'
    sudo cp /etc/hosts /etc/hosts.bak.break 2>/dev/null
    echo \"999.999.999.999 important-service.internal api.internal\" | sudo tee -a /etc/hosts >/dev/null
  '" 2>/dev/null
}

issue_stop_chronyd() {
  ssh $SSH_OPTS "$SSH_USER@$INSTANCE_IP" bash -c "'
    sudo systemctl stop chronyd 2>/dev/null
    sudo cp /etc/chrony.conf /etc/chrony.conf.bak.break 2>/dev/null
    echo \"INVALID_CHRONY_CONFIG\" | sudo tee /etc/chrony.conf >/dev/null
  '" 2>/dev/null
}

issue_fill_tmp() {
  ssh $SSH_OPTS "$SSH_USER@$INSTANCE_IP" bash -c "'
    dd if=/dev/zero of=/tmp/.break_large_file_a bs=1M count=80 2>/dev/null
    dd if=/dev/zero of=/tmp/.break_large_file_b bs=1M count=80 2>/dev/null
    dd if=/dev/zero of=/tmp/.break_large_file_c bs=1M count=80 2>/dev/null
  '" 2>/dev/null
}

issue_broken_cronjob() {
  ssh $SSH_OPTS "$SSH_USER@$INSTANCE_IP" bash -c "'
    echo \"* * * * * root /usr/bin/nonexistent_break_command 2>&1 | logger -t BROKEN_SERVICE\" | sudo tee /etc/cron.d/break_simulation >/dev/null
    sudo chmod 644 /etc/cron.d/break_simulation
  '" 2>/dev/null
}

SERVER_FUNCS=(
  issue_stop_nginx
  issue_log_permissions
  issue_hosts_corrupt
  issue_stop_chronyd
  issue_fill_tmp
  issue_broken_cronjob
)
SERVER_COUNT=${#SERVER_FUNCS[@]}

declare -a SELECTED_INDICES=()
while [ ${#SELECTED_INDICES[@]} -lt 2 ]; do
  CANDIDATE=$((RANDOM % SERVER_COUNT))
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

for idx in "${SELECTED_INDICES[@]}"; do
  ${SERVER_FUNCS[$idx]} || true
done

echo "  サーバー障害: 2件 仕込み完了 ✓"
echo ""

# =============================================================
# Phase 2: インフラレベルの障害を仕込む（AWS CLI）
# =============================================================

echo "[3/4] AWS インフラ設定を変更しています..."

# 1. セキュリティグループ: HTTP (port 80) ルール削除
aws ec2 revoke-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol tcp --port 80 --cidr 0.0.0.0/0 2>/dev/null && \
  echo "  ✓ SG: HTTP (port 80) インバウンドルール削除" || \
  echo "  - SG: HTTP ルールは既に存在しません（スキップ）"

# 2. セキュリティグループ: SSH (port 22) ルール削除
aws ec2 revoke-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol tcp --port 22 --cidr 0.0.0.0/0 2>/dev/null && \
  echo "  ✓ SG: SSH (port 22) インバウンドルール削除" || \
  echo "  - SG: SSH ルールは既に存在しません（スキップ）"

# 3. ルートテーブル: インターネットゲートウェイへのルート削除
aws ec2 delete-route \
  --route-table-id "$RTB_ID" \
  --destination-cidr-block 0.0.0.0/0 2>/dev/null && \
  echo "  ✓ ルートテーブル: IGW ルート (0.0.0.0/0) 削除" || \
  echo "  - ルートテーブル: IGW ルートは既に存在しません（スキップ）"

# 4. EC2: Name タグ改ざん
ORIGINAL_NAME="${TF_VAR_prefix:-unknown}-training-ec2"
aws ec2 create-tags \
  --resources "$INSTANCE_ID" \
  --tags "Key=Name,Value=MODIFIED-unknown-instance" 2>/dev/null && \
  echo "  ✓ EC2: Name タグを改ざん（${ORIGINAL_NAME} → MODIFIED-unknown-instance）" || \
  echo "  - EC2: タグ変更に失敗（スキップ）"

echo ""
echo "[4/4] EC2 インスタンスを停止しています..."

# 5. EC2: インスタンス停止
aws ec2 stop-instances \
  --instance-ids "$INSTANCE_ID" > /dev/null 2>&1 && \
  echo "  ✓ EC2: インスタンス停止を開始しました" || \
  echo "  - EC2: 停止に失敗（スキップ）"

echo "  ※ 停止完了まで 1〜2 分かかります"

echo ""
echo "========================================="
echo " 障害の仕込みが完了しました"
echo "========================================="
echo ""
echo "  セッション1-2 で作成した EC2 環境に以下の障害を発生させました："
echo ""
echo "  インフラ障害: 5件（固定）"
echo "    - SG: HTTP (port 80) インバウンドルール削除"
echo "    - SG: SSH (port 22) インバウンドルール削除"
echo "    - ルートテーブル: IGW ルート削除"
echo "    - EC2: Name タグ改ざん"
echo "    - EC2: インスタンス停止"
echo ""
echo "  サーバー障害: 2件（ランダム）"
echo "    - 何が壊れたかはあなたにも分かりません"
echo ""
echo "==========================================="
echo " セッション9を開始してください"
echo "==========================================="
echo ""
echo "このスクリプトを実行したことは忘れて、以下のシナリオで進めてください："
echo ""
echo "――――――――――――――――――――――――――――――――――――――"
echo "月曜朝、出社するとチームの Slack チャンネルが騒がしい。"
echo ""
echo " > 「Web サイトにアクセスできない」"
echo " > 「SSH も繋がらない」"
echo " > 「サーバーが応答しない」"
echo ""
echo "週末当番だった先輩のメモ："
echo "「セキュリティの問題があったので対応した。"
echo "  サーバーの設定も少しいじった。詳細は月曜に共有する」"
echo ""
echo "しかし先輩は体調不良で休み。"
echo "AI と一緒に状況を把握し、すべて復旧してください。"
echo "――――――――――――――――――――――――――――――――――――――"
echo ""
echo "💡 復旧のヒント:"
echo "  - インフラ障害は terraform plan で検出できます"
echo "  - EC2 停止は terraform apply では復旧しません（別途起動が必要）"
echo "  - EC2 起動後は IP が変わるため terraform output で再取得してください"
echo "  - インフラを直してもサーバー内部の問題がまだ残っています"
