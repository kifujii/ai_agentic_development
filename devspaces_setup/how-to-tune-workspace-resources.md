# Dev Spaces ワークスペース リソースチューニング ガイド

OpenShift Dev Spaces のワークスペースがメモリ不足でクラッシュする場合に、
コンテナのメモリ上限を引き上げるための手順書です。

---

## 前提条件

| 項目 | 内容 |
|------|------|
| 必要な権限 | `openshift-devspaces` namespace への patch 権限 (cluster-admin 推奨) |
| 必要なコマンド | `oc`、`python3` |
| 確認方法 | `oc whoami` でログイン済みか確認 |

---

## ステップ 0：スクリプトに必要な値を調べる

スクリプト `patch/apply.sh` の冒頭には以下の3変数があります。
他のクラスター環境で使う場合はこれらを調べて書き換えてください。

```bash
CHE_NAMESPACE="openshift-devspaces"  # CheCluster がある namespace
CHE_CLUSTER="devspaces"              # CheCluster リソースの名前
WS_NAMESPACE="admin-devspaces"       # ワークスペース Pod が起動する namespace
```

### CHE_NAMESPACE / CHE_CLUSTER の調べ方

```bash
oc get checluster --all-namespaces
```

出力例：
```
NAMESPACE               NAME        AGE
openshift-devspaces     devspaces   21d
```

`NAMESPACE` 列 → `CHE_NAMESPACE`、`NAME` 列 → `CHE_CLUSTER`

### WS_NAMESPACE の調べ方

**方法 A：CheCluster の設定テンプレートから推測する（事前に確認）**

```bash
oc get checluster -A \
  -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}: {.spec.devEnvironments.defaultNamespace.template}{"\n"}{end}'
```

出力例：
```
openshift-devspaces/devspaces: <username>-devspaces
```

`<username>` を自分のユーザー名に置き換えたものが `WS_NAMESPACE` になります。

```bash
echo "$(oc whoami)-devspaces"  # → admin-devspaces
```

**方法 B：実際に稼働中の DevWorkspace を確認する（確実）**

```bash
oc get devworkspace --all-namespaces
```

出力例：
```
NAMESPACE            NAME                           DEVWORKSPACEID     PHASE     AGE
admin-devspaces      ai-agentic-development-09pc    workspace84279...  Running   50m
```

DevWorkspace が存在する `NAMESPACE` 列が `WS_NAMESPACE` です。

### ワンライナーで自動取得する（推奨）

スクリプト冒頭の固定値を以下に差し替えれば、どのクラスターでも自動的に値が設定されます。

```bash
CHE_NAMESPACE=$(oc get checluster -A -o jsonpath='{.items[0].metadata.namespace}')
CHE_CLUSTER=$(oc get checluster -A -o jsonpath='{.items[0].metadata.name}')
WS_NAMESPACE="$(oc whoami)-devspaces"
```

---

## ステップ 1：スクリプトを実行する

```bash
# リポジトリのルートで実行
bash patch/apply.sh
```

スクリプトは以下の3つを順番に行います。

| Step | 対象 | 内容 |
|------|------|------|
| 1 | CheCluster | デフォルトリソース上限・アイドルタイムアウト・NODE_OPTIONS を設定 |
| 2 | 既存 DevWorkspace CR | 稼働中のワークスペースに直接リソース上限と NODE_OPTIONS を追記 |
| 3 | Pod | ワークスペース Pod を再起動して設定を即時反映 |

---

## ステップ 2：適用後の確認

### Pod のメモリ上限が 6Gi になっているか確認

```bash
oc get pods -n admin-devspaces -o json | python3 -c "
import json, sys
data = json.load(sys.stdin)
for pod in data['items']:
    print('POD:', pod['metadata']['name'])
    for c in pod['spec']['containers']:
        print(f'  {c[\"name\"]}: {c.get(\"resources\", {})}')
"
```

期待する出力：
```
POD: workspace84279dbc85674f21-...
  universal-developer-image: {'limits': {'memory': '6Gi', 'cpu': '2'}, ...}
  che-gateway: {'limits': {'memory': '256Mi'}, ...}
```

### NODE_OPTIONS が設定されているか確認

```bash
oc get pods -n admin-devspaces -o json | python3 -c "
import json, sys
for pod in json.load(sys.stdin)['items']:
    for c in pod['spec']['containers']:
        for e in c.get('env', []):
            if e['name'] == 'NODE_OPTIONS':
                print(pod['metadata']['name'], c['name'], e['value'])
"
```

### アイドルタイムアウトが 1800 秒になっているか確認

```bash
oc get checluster devspaces -n openshift-devspaces \
  -o jsonpath='{.spec.devEnvironments.secondsOfInactivityBeforeIdling}'
# → 1800 が返ればOK
```

---

## 適用内容の詳細

### CheCluster へのパッチ (`patch/checluster-patch.yaml`)

```yaml
spec:
  devEnvironments:
    defaultContainerResources:   # リソース未指定コンテナへのデフォルト上限
      limits:
        memory: "6Gi"
        cpu: "2"
      requests:
        memory: "2Gi"
        cpu: "500m"
    defaultComponents:           # devfile が空の bootstrap ワークスペース向け
      - name: universal-developer-image
        container:
          env:
            - name: NODE_OPTIONS
              value: "--max-old-space-size=4096"
    secondsOfInactivityBeforeIdling: 1800   # 30分アイドルで自動停止
```

### NODE_OPTIONS の意味

```
--max-old-space-size=4096
```

VS Code のサーバープロセスは Node.js で動いています。
このオプションを指定しないと Node.js はコンテナのメモリ上限を認識せず、
際限なくヒープを確保しようとして OOM Kill されます。
コンテナ上限の約 67% をヒープに割り当て、残りをシステム・拡張・言語サーバーに確保します。

| コンテナ上限 | NODE_OPTIONS 推奨値 |
|------------|-------------------|
| 2Gi        | `--max-old-space-size=1024` |
| 4Gi        | `--max-old-space-size=2560` |
| 6Gi        | `--max-old-space-size=4096` |
| 8Gi        | `--max-old-space-size=5632` |

---

## リポジトリのファイル構成

```
dev-spaces-manifest/
├── patch/
│   ├── checluster-patch.yaml   クラスター全体に適用する CheCluster パッチ
│   └── apply.sh                上記を含む一括適用スクリプト
├── devfile.yaml                新規ワークスペースをリポジトリから作成する際の devfile
│                               → プロジェクトの .devfile.yaml として配置して使う
├── devworkspace.yaml           oc apply で直接ワークスペースを作成する場合の CR
│                               → YOUR_NAMESPACE を書き換えて使う
└── .vscode/settings.json       VS Code のパフォーマンス最適化設定
                                → プロジェクトのリポジトリに含めると自動適用される
```

---

## よくある問題

### `checluster not found` が出る場合

```bash
# CRD が入っているか確認
oc get crd | grep che
# → checlusters.org.eclipse.che が存在すればOK
```

存在しない場合は Dev Spaces オペレータがインストールされていません。
OperatorHub から "Red Hat OpenShift Dev Spaces" をインストールしてください。

### パッチ適用後もリソースが変わらない場合

CheCluster の設定変更は**新規起動のワークスペース**に反映されます。
`apply.sh` の Step 2・3 は既存ワークスペースへの直接適用のためのものです。
Step 2・3 が失敗している場合は、ワークスペースを一度停止して再起動してください。

```bash
# ワークスペースを停止
oc patch devworkspace <ワークスペース名> -n <WS_NAMESPACE> \
  --type=merge -p '{"spec":{"started":false}}'

# 少し待ってから再起動
sleep 10
oc patch devworkspace <ワークスペース名> -n <WS_NAMESPACE> \
  --type=merge -p '{"spec":{"started":true}}'
```
