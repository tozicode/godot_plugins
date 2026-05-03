# addons/cartoon について

このディレクトリは `godot_plugins` モノレポから `git subtree split` で個別リポジトリ
(`tozicode/godot-plugin-cartoon`) に分離されたものを、各プロジェクトが
git submodule として参照しているものです。

複数プロジェクトで共有されているため、編集時には以下のワークフローに必ず従ってください。

## プラグイン同期ワークフロー

### 1. 編集前: ブランチを当てて最新化

`git submodule update` 直後の submodule は detached HEAD 状態のため、
そのまま commit してもブランチに記録されません。編集前に必ずブランチを当て、
最新を取り込んでください。

```bash
cd <project>/addons/cartoon
git checkout main
git pull origin main
```

### 2. 編集後: 即座に個別リポジトリへ push

push を後回しにすると、他プロジェクトの独自系統と衝突して解消が複雑化します。
**commit したら必ず即座に push してください。**

```bash
cd <project>/addons/cartoon
git add .
git commit -m "..."
git push origin main      # ← 必ず即 push
```

### 3. 親プロジェクトで submodule pointer をコミット

```bash
cd ../..
git add addons/cartoon
git commit -m "chore: cartoon プラグインを更新"
```

## プロジェクト固有の設定ファイル

`editor/debug_target.tres` は各プロジェクトでテスト対象シーンが異なるため、
`.gitignore` で除外されています。新規セットアップ時は `editor/debug_target.tres.example`
を `editor/debug_target.tres` にコピーし、`scene_path` をプロジェクト内のテスト対象シーンに
書き換えて使用してください。**commit してはいけません。**

## .tscn / .tres における UID と unique_id について

このプラグインは複数プロジェクトで submodule として共有されているため、
Godot 4.x の以下の慣習に従ってください。

- **UID (`uid="uid://..."`)** は削除する: submodule 間で UID が衝突するのを防ぐため。
  Godot は UID が無くても問題なく動作する。
- **unique_id (Godot 4.6 で追加)** は維持する: シーン継承時の参照安定化に必要。

## このプラグインを共有しているプロジェクト

- `kanade_loop`
- `zunko-kiritan`

## 詳細仕様

詳細は `godot_plugins` モノレポの `KNOWLEDGE.md` の「プラグイン同期ワークフロー」を参照。
