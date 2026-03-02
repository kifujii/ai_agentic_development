#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# Dev Spaces メモリチューニング 適用スクリプト
#
# 実施内容:
#   Step 1 … CheCluster にデフォルトリソース制限 / NODE_OPTIONS / アイドルタイムアウトを設定
#   Step 2 … 現在稼働中の DevWorkspace CR に memoryLimit と NODE_OPTIONS を直接追加
#   Step 3 … 変更を即時反映させるためワークスペース Pod を再起動
#
# 前提:
#   - oc login 済み (admin 権限)
#   - このスクリプトは dev-spaces-manifest/ のルートから実行する
#     例: bash patch/apply.sh
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHE_NAMESPACE="openshift-devspaces"
CHE_CLUSTER="devspaces"
WS_NAMESPACE="admin-devspaces"

# ── 色付きログ ──────────────────────────────────────────────────────────────
info()    { echo -e "\e[34m[INFO]\e[0m  $*"; }
success() { echo -e "\e[32m[OK]\e[0m    $*"; }
warn()    { echo -e "\e[33m[WARN]\e[0m  $*"; }
die()     { echo -e "\e[31m[ERROR]\e[0m $*" >&2; exit 1; }

# ── 権限確認 ────────────────────────────────────────────────────────────────
info "接続ユーザー: $(oc whoami)"
oc get checluster "$CHE_CLUSTER" -n "$CHE_NAMESPACE" > /dev/null 2>&1 \
  || die "CheCluster '$CHE_CLUSTER' が $CHE_NAMESPACE に見つかりません。oc login と namespace を確認してください。"

# ────────────────────────────────────────────────────────────────────────────
# Step 1: CheCluster パッチ適用
# ────────────────────────────────────────────────────────────────────────────
echo ""
info "=== Step 1: CheCluster のデフォルトリソース制限・NODE_OPTIONS・アイドルタイムアウトを設定 ==="

oc patch checluster "$CHE_CLUSTER" \
  -n "$CHE_NAMESPACE" \
  --type=merge \
  --patch-file "$SCRIPT_DIR/checluster-patch.yaml"

success "CheCluster にパッチを適用しました。"

# ────────────────────────────────────────────────────────────────────────────
# Step 2: 既存 DevWorkspace CR に memoryLimit と NODE_OPTIONS を追加
# ────────────────────────────────────────────────────────────────────────────
echo ""
info "=== Step 2: 既存 DevWorkspace に memoryLimit / NODE_OPTIONS を追加 ==="

WORKSPACES=$(oc get devworkspace -n "$WS_NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || true)

if [ -z "$WORKSPACES" ]; then
  warn "稼働中の DevWorkspace が見つかりませんでした。Step 2 をスキップします。"
else
  for ws in $WORKSPACES; do
    info "  Patching DevWorkspace: $ws"

    # pipe と heredoc が stdin を取り合う問題を避けるため一時ファイル経由で渡す
    TMP_JSON=$(mktemp /tmp/devworkspace_XXXXXX.json)
    oc get devworkspace "$ws" -n "$WS_NAMESPACE" -o json > "$TMP_JSON"

    # python3 - FILE の形で呼ぶと stdin=heredoc(スクリプト), argv[1]=FILE(JSON)になる
    PATCHED=$(python3 - "$TMP_JSON" <<'PYEOF'
import json, sys

with open(sys.argv[1]) as f:
    dw = json.load(f)

components = dw.get("spec", {}).get("template", {}).get("components", [])
updated = False

for comp in components:
    if comp.get("name") == "universal-developer-image" and "container" in comp:
        c = comp["container"]

        # リソース制限を上書き (Devfile 形式: memoryLimit/cpuLimit)
        c["memoryLimit"]   = "6Gi"
        c["memoryRequest"] = "2Gi"
        c["cpuLimit"]      = "2"
        c["cpuRequest"]    = "500m"

        # NODE_OPTIONS を追加 (既存のエントリは除去してから追加)
        env = [e for e in c.get("env", []) if e.get("name") != "NODE_OPTIONS"]
        env.append({"name": "NODE_OPTIONS", "value": "--max-old-space-size=4096"})
        c["env"] = env

        updated = True

if not updated:
    sys.stderr.write("[WARN] universal-developer-image component not found, skipping.\n")

print(json.dumps(dw))
PYEOF
)
    rm -f "$TMP_JSON"

    echo "$PATCHED" | oc apply -f - > /dev/null
    success "    $ws にパッチを適用しました。"
  done
fi

# ────────────────────────────────────────────────────────────────────────────
# Step 3: ワークスペース Pod を再起動して設定を即時反映
# ────────────────────────────────────────────────────────────────────────────
echo ""
info "=== Step 3: ワークスペース Pod を再起動 ==="

# DevWorkspace Operator が DeploymentSpec を更新するまで少し待つ
sleep 3

WS_IDS=$(oc get devworkspace -n "$WS_NAMESPACE" \
  -o jsonpath='{.items[*].status.devworkspaceId}' 2>/dev/null || true)

if [ -z "$WS_IDS" ]; then
  warn "再起動対象 Pod が見つかりませんでした。"
else
  for ws_id in $WS_IDS; do
    POD=$(oc get pod -n "$WS_NAMESPACE" \
      -l "controller.devfile.io/devworkspace-id=$ws_id" \
      -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)

    if [ -n "$POD" ]; then
      info "  Pod を再起動: $POD"
      oc delete pod "$POD" -n "$WS_NAMESPACE" --grace-period=15
      success "    削除しました (Deployment が自動的に再作成します)"
    else
      warn "  Pod が見つかりません (workspace_id=$ws_id)、スキップ"
    fi
  done
fi

# ────────────────────────────────────────────────────────────────────────────
# 完了メッセージ
# ────────────────────────────────────────────────────────────────────────────
echo ""
success "=== すべての処理が完了しました ==="
echo ""
echo "  新しい Pod の起動状況を確認:"
echo "    oc get pods -n $WS_NAMESPACE -w"
echo ""
echo "  Pod の起動後、リソース上限が反映されているか確認:"
echo "    oc get pod -n $WS_NAMESPACE -o json | python3 -c \\"
echo "      \"import json,sys; [print(c['name'],c.get('resources',{})) for p in json.load(sys.stdin)['items'] for c in p['spec']['containers']]\""
echo ""
echo "  アイドルタイムアウト設定の確認:"
echo "    oc get checluster devspaces -n openshift-devspaces \\"
echo "      -o jsonpath='{.spec.devEnvironments.secondsOfInactivityBeforeIdling}'"
