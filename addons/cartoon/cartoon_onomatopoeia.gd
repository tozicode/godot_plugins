## オノマトペ表示を扱うためのクラス。
extends Sprite2D
class_name CartoonOnomatopoeia

signal changed_sprite_name

## オノマトペディレクトリのプロジェクト設定キー。
const SETTING_ONOMATOPOEIAS_DIRECTORY := "cartoon/onomatopoeias_directory"
const DEFAULT_ONOMATOPOEIAS_DIRECTORY := "res://cartoon/onomatopoeias"


## スプライトのファイル名から拡張子を取り払った部分の文字列。
var sprite_name :String = "":
	get: return sprite_name
	set(value):
		sprite_name = value
		_on_changed_sprite_name()


## オノマトペディレクトリのパスを返す。
static func get_sprite_dir() -> String:
	if ProjectSettings.has_setting(SETTING_ONOMATOPOEIAS_DIRECTORY):
		return ProjectSettings.get_setting(SETTING_ONOMATOPOEIAS_DIRECTORY)
	return DEFAULT_ONOMATOPOEIAS_DIRECTORY


static func create_from_file(fin :FileAccess):
	var onomatopoeia = CartoonOnomatopoeia.new()
	onomatopoeia.position = Utility.read_vector2(fin)
	onomatopoeia.scale = Utility.read_vector2(fin)
	onomatopoeia.rotation = fin.get_float()
	onomatopoeia.sprite_name = fin.get_pascal_string()
	return onomatopoeia


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


func _on_changed_sprite_name():
	var filepath = get_filepath()
	if filepath.is_empty():
		texture = null
		name = "Empty"
	else:
		texture = load(filepath)
		name = sprite_name


## このオノマトペの情報をバイナリファイルに書き込む。
func write_file(fout :FileAccess):
	Utility.write_vector2(fout, position)
	Utility.write_vector2(fout, scale)
	fout.store_float(rotation)
	fout.store_pascal_string(sprite_name)


## スプライト名からファイルパスを生成して返す。
func get_filepath() -> String:
	return sprite_name_to_filepath(sprite_name)
