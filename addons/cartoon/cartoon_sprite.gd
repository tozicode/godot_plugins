## 漫画の各コマで用いられるスプライトを扱うためのクラス。
@tool
extends Sprite2D
class_name CartoonSprite

signal changed_sprite_name

## スプライトディレクトリのプロジェクト設定キー。
const SETTING_SPRITES_DIRECTORY := "cartoon/sprites_directory"
const DEFAULT_SPRITES_DIRECTORY := "res://cartoon/sprites"

## スプライトとして扱う画像ファイル拡張子。優先順位順に並べる。
const SUPPORTED_EXTENSIONS := [".png", ".jpg"]


## CartoonSprite はコマ内の座標を左上基準で扱うため、Sprite2D の centered の
## デフォルト (true) を上書きして常に左上原点にする。
func _init():
	centered = false


## スプライトのファイル名から拡張子を取り払った部分の文字列。
## 値が更新されると対応する画像を自動的にロードして texture にセットし、
## ノード名もスプライト名と同期する（識別性のため）。
@export
var sprite_name :String:
	get: return sprite_name
	set(value):
		sprite_name = value
		if sprite_name.is_empty():
			texture = null
			name = "Empty"
		else:
			texture = load(sprite_name_to_filepath(sprite_name))
			# Godot のノード名は "/" や "." 等を含められず、Node が自動的に
			# "_" に置換する。そのままそのまま代入してよい。
			name = sprite_name
		changed_sprite_name.emit()


## スプライトディレクトリのパスを返す。
static func get_sprite_dir() -> String:
	if ProjectSettings.has_setting(SETTING_SPRITES_DIRECTORY):
		return ProjectSettings.get_setting(SETTING_SPRITES_DIRECTORY)
	return DEFAULT_SPRITES_DIRECTORY


## 指定のファイルパスに対応するスプライト名を返す。
## SUPPORTED_EXTENSIONS のいずれかで終わるパスを受け付ける。
static func filepath_to_sprite_name(filepath :String):
	var sprite_dir = get_sprite_dir()
	if not filepath.begins_with(sprite_dir):
		return ""
	for ext in SUPPORTED_EXTENSIONS:
		if filepath.ends_with(ext):
			return filepath.substr(
				sprite_dir.length() + 1,
				filepath.length() - sprite_dir.length() - 1 - ext.length())
	return ""


## スプライト名からファイルパスを生成して返す。
## 実ファイルが存在する拡張子を SUPPORTED_EXTENSIONS の順序で探索する。
## 見つからない場合は先頭拡張子 (.png) を付けたパスを返す。
static func sprite_name_to_filepath(sprite_name :String) -> String:
	if sprite_name.is_empty():
		return ""
	var base = get_sprite_dir() + "/" + sprite_name
	for ext in SUPPORTED_EXTENSIONS:
		if FileAccess.file_exists(base + ext):
			return base + ext
	return base + SUPPORTED_EXTENSIONS[0]


## バイナリファイルから CartoonSprite を生成して返す。
## texture は sprite_name のセッターが自動的にロードする。
static func create_from_file(fin :FileAccess) -> CartoonSprite:
	var sprite = CartoonSprite.new()
	sprite.position = Utility.read_vector2(fin)
	sprite.scale = Utility.read_vector2(fin)
	sprite.rotation = fin.get_float()
	sprite.sprite_name = fin.get_pascal_string()
	return sprite


## このスプライトの情報をバイナリファイルに書き込む。
func write_file(fout :FileAccess):
	Utility.write_vector2(fout, position)
	Utility.write_vector2(fout, scale)
	fout.store_float(rotation)
	fout.store_pascal_string(sprite_name)


## スプライト画像のサイズを返す。
func get_size() -> Vector2:
	if texture != null:
		return texture.get_size()
	return Vector2.ZERO
