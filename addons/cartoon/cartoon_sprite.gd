## 漫画の各コマで用いられるスプライトを扱うためのクラス。
@tool
extends Sprite2D
class_name CartoonSprite

signal changed_sprite_name

## スプライトディレクトリのプロジェクト設定キー。
const SETTING_SPRITES_DIRECTORY := "cartoon/sprites_directory"
const DEFAULT_SPRITES_DIRECTORY := "res://cartoon/sprites"


## スプライトのファイル名から拡張子を取り払った部分の文字列。
@export
var sprite_name :String:
	get: return sprite_name
	set(value):
		sprite_name = value
		changed_sprite_name.emit()


## スプライトディレクトリのパスを返す。
static func get_sprite_dir() -> String:
	if ProjectSettings.has_setting(SETTING_SPRITES_DIRECTORY):
		return ProjectSettings.get_setting(SETTING_SPRITES_DIRECTORY)
	return DEFAULT_SPRITES_DIRECTORY


## 指定のファイルパスに対応するスプライト名を返す。
static func filepath_to_sprite_name(filepath :String):
	var sprite_dir = get_sprite_dir()
	if not filepath.ends_with(".png") or not filepath.begins_with(sprite_dir):
		return ""
	return filepath.substr(
		sprite_dir.length() + 1,
		filepath.length() - sprite_dir.length() - 5)


## スプライト名からファイルパスを生成して返す。
static func sprite_name_to_filepath(sprite_name :String):
	if sprite_name.is_empty():
		return ""
	return get_sprite_dir() + "/" + sprite_name + ".png"


## バイナリファイルから CartoonSprite を生成して返す。
static func create_from_file(fin :FileAccess) -> CartoonSprite:
	var sprite = CartoonSprite.new()
	sprite.position = Utility.read_vector2(fin)
	sprite.scale = Utility.read_vector2(fin)
	sprite.rotation = fin.get_float()
	sprite.sprite_name = fin.get_pascal_string()
	sprite.texture = load(sprite_name_to_filepath(sprite.sprite_name))
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
