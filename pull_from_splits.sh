#!/bin/bash
# 各個別リポジトリの最新を godot_plugins モノレポへ取り込むスクリプト。
# 使い方: bash pull_from_splits.sh
#
# 前提:
#   - git remote に utility, localization, cartoon が登録済み
#   - モノレポの main ブランチで実行すること
#   - ワーキングツリーがクリーンであること（subtree pull は merge コミットを作るため）
#
# 注意:
#   各プロジェクトで submodule に直接 commit & push した内容を取り込むためのスクリプト。
#   月1回程度の定期実行を想定。詳細は KNOWLEDGE.md の「プラグイン同期ワークフロー」を参照。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# 対象プラグインの定義: "プレフィックス リモート名"
PLUGINS=(
    "addons/utility utility"
    "addons/localization localization"
    "addons/cartoon cartoon"
)

echo "=== godot_plugins subtree pull from splits ==="
echo ""

# ワーキングツリーがクリーンか確認
if ! git diff-index --quiet HEAD --; then
    echo "エラー: ワーキングツリーに未コミットの変更があります。" >&2
    echo "       subtree pull は merge コミットを作るため、クリーンな状態で実行してください。" >&2
    exit 1
fi

for plugin in "${PLUGINS[@]}"; do
    read -r prefix remote <<< "$plugin"
    plugin_name="${prefix#addons/}"

    echo "--- ${plugin_name} ---"

    # 個別リポジトリから fetch
    echo "  fetching ${remote}/main"
    git fetch "$remote" main

    # subtree pull (--squash で履歴を1コミットにまとめる)
    echo "  pulling ${remote}/main -> ${prefix}"
    if git subtree pull --prefix="$prefix" "$remote" main --squash -m "chore: ${plugin_name} を個別リポジトリから取り込み"; then
        echo "  done."
    else
        echo "  pull に失敗しました。コンフリクトを解消してから commit してください。" >&2
        exit 1
    fi
    echo ""
done

echo "=== 完了 ==="
echo "取り込んだ内容を確認の上、git push origin main で反映してください。"
