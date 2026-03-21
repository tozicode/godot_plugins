#!/bin/bash
# godot_plugins の各プラグインを subtree split して個別リポジトリへ push するスクリプト。
# 使い方: bash split_and_push.sh
#
# 前提:
#   - git remote に utility, localization, cartoon が登録済み
#   - モノレポの main ブランチで実行すること

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# 対象プラグインの定義: "プレフィックス ブランチ名 リモート名"
PLUGINS=(
    "addons/utility split/utility utility"
    "addons/localization split/localization localization"
    "addons/cartoon split/cartoon cartoon"
)

echo "=== godot_plugins subtree split & push ==="
echo ""

for plugin in "${PLUGINS[@]}"; do
    read -r prefix branch remote <<< "$plugin"
    plugin_name="${prefix#addons/}"

    echo "--- ${plugin_name} ---"

    # 既存の split ブランチを削除（再生成のため）
    if git show-ref --verify --quiet "refs/heads/${branch}"; then
        git branch -D "$branch"
    fi

    # subtree split
    echo "  splitting ${prefix} -> ${branch}"
    git subtree split --prefix="$prefix" -b "$branch"

    # push
    echo "  pushing ${branch} -> ${remote}/main"
    git push "$remote" "${branch}:main" --force

    echo "  done."
    echo ""
done

echo "=== 完了 ==="
