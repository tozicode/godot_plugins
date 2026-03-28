# SPEC.md — godot_plugins 仕様記録

## プロジェクト概要

Godot Engine でのゲーム開発に用いる各種共通機能をプラグインとして集約するプロジェクト。
他の Godot プロジェクトから `addons/` 以下のプラグインを git submodule として共有利用する。
`git subtree split` でプラグインごとに個別リポジトリへ分離し、各プロジェクトは submodule として参照する。
更新時は `split_and_push.sh` を実行して個別リポジトリへ反映する。

---

## プラグイン一覧

| プラグイン | バージョン | 説明 | 依存 |
|---|---|---|---|
| `utility` | 1.0.0 | 汎用ユーティリティ機能集。静的関数（Utility クラス）およびオーディオマネージャー（BGM / SE / Voice）を提供 | なし |
| `localization` | 1.0.0 | 多言語対応のためのテキスト管理。TSVベースの翻訳データ管理、リソースベースの多言語テキスト、エディタ統合 | なし |
| `cartoon` | 1.1.0 | 漫画形式のストーリー演出エンジン | condition, localization, utility |

※ `gut` はサードパーティ製テストフレームワーク（バージョン管理対象外）。
