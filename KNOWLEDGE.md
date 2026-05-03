# KNOWLEDGE.md — 過去の失敗を繰り返さないための注意事項

## subtree split 用リモート

| リモート名 | リポジトリ |
|---|---|
| `utility` | `git@github.com:tozicode/godot-plugin-utility.git` |
| `localization` | `git@github.com:tozicode/godot-plugin-localization.git` |
| `cartoon` | `git@github.com:tozicode/godot-plugin-cartoon.git` |

## プラグイン同期ワークフロー

複数プロジェクトで同じ submodule を編集すると、個別リポジトリ未 push の独自系統が
各プロジェクトに溜まり、後から手動で集約する羽目になる。これを防ぐためのルール。

### 同期構造

個別リポジトリ (`tozicode/godot-plugin-*`) がハブとなる:

```
[各プロジェクト] ←submodule── [個別リポジトリ (GitHub)] ←pull── [godot_plugins モノレポ]
                                       ↑                    ↓
                                       └── split & push ────┘
```

- **各プロジェクト → 個別リポジトリ**: 編集後にプロジェクト側から push（下記ルール 2）
- **個別リポジトリ → godot_plugins**: `pull_from_splits.sh` で定期的に取り込み
- **godot_plugins → 個別リポジトリ**: `split_and_push.sh` で配布

### ルール 1: submodule で編集する前に最新化

`git submodule update` 直後の submodule は detached HEAD のままなので、
そこで commit するとブランチに記録されない。編集前に必ずブランチを当てる。

```bash
cd <project>/addons/<plugin>
git checkout main
git pull origin main
```

### ルール 2: submodule で commit したら即座に個別リポジトリへ push

push を後回しにすると、他プロジェクトと独自系統が衝突して解消が複雑化する。

```bash
cd <project>/addons/<plugin>
git add .
git commit -m "..."
git push origin main      # ← 必ず即 push
cd ../..
git add addons/<plugin>
git commit -m "chore: <plugin> を更新"
```

### ルール 3: monorepo は定期的に個別リポジトリの更新を取り込む

godot_plugins モノレポで `pull_from_splits.sh` を月 1 回程度実行し、
各個別リポジトリの最新を `addons/` 配下に取り込む。

### ルール 4: プロジェクト固有の設定は submodule に commit しない

例: `addons/cartoon/editor/debug_target.tres` は各プロジェクトで参照シーンが
異なるため `.gitignore` で除外し、`debug_target.tres.example` をテンプレートとして
配布する。各プロジェクトでは初回利用時に example を複製してローカル設定する。

### ルール 5: 大きな変更は monorepo 側で行う

機能追加レベルの変更は godot_plugins モノレポで行い `split_and_push.sh` で配布する。
バグ修正など小さい変更は submodule 内で直接編集して即 push でも良いが、
他プロジェクトへの影響が大きいものは monorepo を起点にする。
