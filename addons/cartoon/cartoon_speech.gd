## 漫画の吹き出しなどを表すクラス。
@tool
extends Node2D
class_name CartoonSpeech

## フレーム種別を変更した時に発行されるシグナル。
signal changed_frame

## 話者設定を変更した時に発行されるシグナル。
signal changed_speaker

## 表示テキストを変更した時に発行されるシグナル。
signal changed_text

enum FrameType {
	MONOLOGUE,
	TALK_DOWN_RIGHT, TALK_DOWN_LEFT, TALK_UP_RIGHT, TALK_UP_LEFT,
	THINK_DOWN_RIGHT, THINK_DOWN_LEFT, THINK_UP_RIGHT, THINK_UP_LEFT,
}

## エディタ上での各フレームの名称
const FRAME_TYPE_NAMES = [
	"monologue",
	"talk_down_right", "talk_down_left", "talk_up_right", "talk_up_left",
	"think_down_right", "think_down_left", "think_up_right", "think_up_left",
]

## 各フレーム種別におけるフレームからラベルの相対位置座標。
const LABEL_POSITIONS_RELATIVE = [
	Vector2(40, 40),
	Vector2(40, 80), Vector2(40, 80), Vector2(40, 35), Vector2(40, 35),
	Vector2(40, 80), Vector2(40, 80), Vector2(40, 35), Vector2(40, 35),
]

## 各フレームの .tscn ファイルが格納されているディレクトリのパス。
const FRAME_SCENE_DIR = "res://addons/cartoon/frames"

## 話者スタイルのプロジェクト設定キー。
const SETTING_SPEAKER_STYLES_PATH := "cartoon/speaker_styles_path"

## 話者スタイルのキャッシュ。
static var _speaker_styles_cache :Array[CartoonSpeakerStyle] = []


@onready
var frame :NinePatchRect = $"Frame"

@onready
var label :Label = $"Label"

## 表示するテキスト。
@export_multiline
var text :String = "":
	get: return text
	set(value):
		text = value
		changed_text.emit()

## 表示テキストに対応した言語データ上のキー。
## キーが空の場合は言語データに未登録であることを表す。
@export
var text_key :String = ""

## フレーム種別。
@export
var frame_type :FrameType:
	get: return frame_type
	set(value):
		if value != frame_type:
			frame_type = value
			changed_frame.emit()

## 話者ID。0 はデフォルト（スタイル指定なし）。
@export
var speaker_id :int = 0:
	get: return speaker_id
	set(value):
		if value != speaker_id:
			speaker_id = value
			changed_speaker.emit()

## フレームからラベルの相対位置座標。
var position_delta :Vector2:
	get: return LABEL_POSITIONS_RELATIVE[frame_type]


## 話者スタイル配列をロードして返す。
static func get_speaker_styles() -> Array[CartoonSpeakerStyle]:
	if not _speaker_styles_cache.is_empty():
		return _speaker_styles_cache
	if ProjectSettings.has_setting(SETTING_SPEAKER_STYLES_PATH):
		var path :String = ProjectSettings.get_setting(SETTING_SPEAKER_STYLES_PATH)
		if not path.is_empty() and ResourceLoader.exists(path):
			var resource = load(path)
			if resource is CartoonSpeakerStyleList:
				_speaker_styles_cache = resource.styles
	return _speaker_styles_cache


## 指定のフレームに対応したシーンを生成して返す。
static func create(frame_type :FrameType) -> CartoonSpeech:
	var filepath = get_scene_filepath(frame_type)
	var speech :CartoonSpeech = load(filepath).instantiate()
	speech.name = FRAME_TYPE_NAMES[frame_type].capitalize().replace(" ", "")
	return speech


## バイナリファイルから CartoonSpeech インスタンスを生成して返す。
static func create_from_file(fin :FileAccess) -> CartoonSpeech:
	var frame_type = fin.get_8()
	var speech = create(frame_type)
	speech.speaker_id = fin.get_8()
	speech.position = Utility.read_vector2(fin)
	speech.scale = Utility.read_vector2(fin)
	speech.rotation = fin.get_float()
	speech.text_key = fin.get_pascal_string()
	return speech


## 指定のフレームに対応したシーンファイルのパスを返す。
static func get_scene_filepath(frame_type :int):
	return FRAME_SCENE_DIR + "/" + FRAME_TYPE_NAMES[frame_type] + ".tscn"


func _ready() -> void:
	if Engine.is_editor_hint():
		changed_frame.connect(_on_changed_frame)
		changed_speaker.connect(_on_changed_speaker)
	else:
		# ランタイム時は Language からテキストを読み込む
		if Localization.has_key(text_key):
			text = Localization.get_string(text_key)

	# 言語設定を変更するのを想定して
	# ランタイムでも changed_text シグナルに応じた処理を設定しておく
	changed_text.connect(_on_changed_text)

	_on_changed_text()
	_on_changed_speaker()


## フレーム種別が変更された時に実行される処理。
func _on_changed_frame():
	var other = create(frame_type)
	for child in other.get_children():
		other.remove_child(child)
		child.set_owner(null)
		add_child(child)
	assert(get_child_count() == 4)
	scene_file_path = get_scene_filepath(frame_type)
	frame = get_child(2)
	label = get_child(3)
	frame.set_owner(self)
	label.set_owner(self)
	# 不要なオブジェクトを削除
	get_child(0).queue_free()
	get_child(1).queue_free()
	other.queue_free()
	# テキストを更新
	_on_changed_speaker()
	_on_changed_text()


## 話者設定が変更された時に実行される処理。
func _on_changed_speaker():
	var styles = get_speaker_styles()
	if speaker_id > 0 and speaker_id <= styles.size():
		var style = styles[speaker_id - 1]
		frame.modulate = style.frame_color
		if style.label_settings != null:
			label.label_settings = style.label_settings
	else:
		# デフォルト: 白フレーム + 黒テキスト
		frame.modulate = Color.WHITE
		var default_label_settings_path = FRAME_SCENE_DIR + "/label_settings_black.tres"
		if ResourceLoader.exists(default_label_settings_path):
			label.label_settings = load(default_label_settings_path)


## テキスト内容が変更された時に実行される処理。
func _on_changed_text():
	var size_old = label.size
	label.set_text(text.replace("<br>", "\n"))
	_resize_label()
	if frame_type == FrameType.MONOLOGUE:
		frame.size = label.size + Vector2(80, 80)
	else:
		frame.size = label.size + Vector2(80, 110)
	match frame_type:
		FrameType.MONOLOGUE:
			frame.set_position(-frame.size / 2)
			label.set_position(frame.position + position_delta)
		FrameType.TALK_DOWN_RIGHT:
			frame.set_position(Vector2.ZERO)
			label.set_position(frame.position + position_delta)
		FrameType.TALK_DOWN_LEFT:
			frame.set_position(Vector2.ZERO)
			label.set_position(Vector2(-frame.size.x, 0) + position_delta)
		FrameType.TALK_UP_RIGHT:
			frame.set_position(Vector2(0, -frame.size.y))
			label.set_position(frame.position + position_delta)
		FrameType.TALK_UP_LEFT:
			frame.set_position(Vector2(0, -frame.size.y))
			label.set_position(-frame.size + position_delta)
		FrameType.THINK_DOWN_RIGHT:
			frame.set_position(Vector2.ZERO)
			label.set_position(frame.position + position_delta)
		FrameType.THINK_DOWN_LEFT:
			frame.set_position(Vector2.ZERO)
			label.set_position(Vector2(-frame.size.x, 0) + position_delta)
		FrameType.THINK_UP_RIGHT:
			frame.set_position(Vector2(0, -frame.size.y))
			label.set_position(frame.position + position_delta)
		FrameType.THINK_UP_LEFT:
			frame.set_position(Vector2(0, -frame.size.y))
			label.set_position(-frame.size + position_delta)


## テキスト内容に応じて label のサイズを調整する。
func _resize_label():
	var font = label.label_settings.font
	var lines = label.text.split("\n")
	var size_new :Vector2 = Vector2.ZERO
	for line in lines:
		size_new.x = max(size_new.x, font.get_string_size(line).x)
	size_new.y = font.get_height(lines.size())
	label.size = size_new


## オブジェクトの内容をファイルに書き出す。
func write_file(fout :FileAccess):
	fout.store_8(frame_type)
	fout.store_8(speaker_id)
	Utility.write_vector2(fout, position)
	Utility.write_vector2(fout, scale)
	fout.store_float(rotation)
	fout.store_pascal_string(text_key)


func assign_text_key(scene_name :String, panel_index :int, speech_index :int):
	text_key = "scene:%s:%02d.%02d" % [scene_name, panel_index, speech_index]


## フレーム名に対応した文字列を返す。
func get_frame_type_name():
	return FRAME_TYPE_NAMES[frame_type].capitalize().replace(" ", "")
