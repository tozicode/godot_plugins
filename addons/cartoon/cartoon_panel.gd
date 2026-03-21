## 漫画の各コマを表すクラス。
@tool
extends Node2D
class_name CartoonPanel

## コマの基本サイズが変更された時に発行されるシグナル。
signal changed_base_size

## コマのサイズが変更された時に発行されるシグナル。
signal changed_size

## コマの枠の表示フラグが変更された時に発行されるシグナル。
signal changed_framed

## グルーピングのフラグが変更された時に発行されるシグナル。
signal changed_grouped

## レイアウトが変更された時に発行されるシグナル。
signal changed_layout

## コマ内のセリフの内容や参照キーが変更された時など
## Language の更新が必要になった時に発行されるシグナル。
signal request_update_language

## コマの形状を表す列挙体。
enum PanelShape {
	UNKNOWN = -1,
	SQUARE,           ## 1000x1000
	HORIZONTAL_RECT,  ## 1600x1000
	VERTICAL_RECT,    ## 1000x1600
	LARGE_RECT,       ## 2500x1600
}


## 直前のコマとグルーピングするかどうかのフラグ。
@export
var grouped :bool = false:
	get: return grouped
	set(value):
		grouped = value
		changed_grouped.emit()

## このコマが表示された際に鳴らすサウンドのリスト。
@export
var audios :Array[CartoonAudio] = []

## 拡大率が 1.0 の場合のコマの大きさ。
@export
var base_size :Vector2i = Vector2i.ZERO:
	get: return base_size
	set(value):
		base_size = value
		changed_base_size.emit()

## CartoonPlayer 上でこのコマを表示する際に実行されるイベント群。
@export
var events :Array[CartoonEvent] = []

## scale を加味した上でのコマの大きさ。
## base_size と layout.scale から計算される。
var size :Vector2i:
	get: return base_size * layout.scale

## コマの中心座標。
var center :Vector2:
	get: return position + Vector2(size) / 2

## コマの左辺のX座標。
var x_left :int:
	get: return int(position.x)

## コマの中心のX座標。
var x_center :int:
	get: return int(position.x + size.x / 2)

## コマの右辺のX座標。
var x_right :int:
	get: return int(position.x + size.x)

## コマの上辺のY座標。
var y_top :int:
	get: return int(position.y)

## コマの中心のY座標。
var y_center :int:
	get: return int(position.y + size.y / 2)

## コマの下辺のY座標。
var y_bottom :int:
	get: return int(position.y + size.y)

## このコマの配置方法の情報。
@export
var layout :CartoonLayout = CartoonLayout.new():
	get: return layout
	set(value):
		layout = value
		changed_layout.emit()

## 画像を枠で囲むかどうかのフラグ。
@export
var framed :bool = true:
	get: return framed
	set(value):
		framed = value
		changed_framed.emit()

## 各スプライトを格納するノード。
@onready var sprites :Node2D = $"Sprites"

## 各オノマトペを格納するノード。
@onready var onomatopoeias :Node2D = $"Onomatopoeias"

## 各吹き出しを格納するノード。
@onready var speeches :Node2D = $"Speeches"

## AudioPlayer を格納するノード。
@onready var audio_players :Node = $"AudioPlayers"

## コマ枠を表すノード。
@onready var frame :NinePatchRect = $"Frame"

## エディタ上で grouped フラグを表示するためのアイコン。
@onready var grouped_icon :TextureRect = $"Grouped"


## 空の CartoonPanel インスタンスを返す。
static func create_empty() -> CartoonPanel:
	var scene = preload("res://addons/cartoon/cartoon_panel.tscn")
	var inst = scene.instantiate()
	inst.scene_file_path = ""
	return inst


## 指定のコマ列から指定のインデックスを含むグループを抽出して返す。
static func extract_panels_group(panels :Array, index :int) -> Array[CartoonPanel]:
	var begin = get_panels_group_begin(panels, index)
	var end = get_panels_group_end(panels, index)
	var out :Array[CartoonPanel] = []
	for i in range(begin, end):
		out.append(panels[i] as CartoonPanel)
	return out


## 指定のコマ列から指定のインデックスを含むグループの最小インデックスを返す。。
static func get_panels_group_begin(panels :Array, index :int) -> int:
	var begin = index
	while begin > 0 and panels[begin].grouped:
		begin -= 1
	return begin


## 指定のコマ列から指定のインデックスを含むグループを抽出して返す。
static func get_panels_group_end(panels :Array, index :int) -> int:
	var end = index + 1
	while end < panels.size() and panels[end].grouped:
		end += 1
	return end


## 指定のコマ列を囲む最小の領域を返す。
static func get_panels_rect(panels :Array) -> Rect2:
	var x_left :float = 0
	var x_right :float = 0
	var y_top :float = 0
	var y_bottom :float = 0
	for panel in panels:
		if x_left == x_right:
			x_left = panel.x_left
			x_right = panel.x_right
			y_top = panel.y_top
			y_bottom = panel.y_bottom
		else:
			x_left = min(x_left, panel.x_left)
			x_right = max(x_right, panel.x_right)
			y_top = min(y_top, panel.y_top)
			y_bottom = max(y_bottom, panel.y_bottom)
	return Rect2(
		Vector2(x_left, y_top),
		Vector2(x_right - x_left, y_bottom - y_top))


func _ready():
	if not Engine.is_editor_hint():
		grouped_icon.queue_free()
		grouped_icon = null
	else:
		speeches.child_order_changed.connect(rename_speeches)
		changed_grouped.connect(_on_changed_grouped)
		_on_changed_grouped()
		for speech in speeches.get_children():
			speech.changed_text.connect(emit_request_update_language)
	changed_base_size.connect(_on_changed_size)
	changed_framed.connect(_on_changed_framed)
	layout.changed_scale.connect(_on_changed_layout_scale)
	_on_changed_size()
	_on_changed_framed()
	_on_changed_layout_scale()


## コマのサイズが変更された時に実行される処理。
func _on_changed_size():
	frame.size = Vector2(size.x + 12, size.y + 12)
	changed_size.emit()


## framed の値が変更された時に実行される処理。
func _on_changed_framed():
	if framed:
		frame.show()
	else:
		frame.hide()


## grouped の値が変更された時に実行される処理。
func _on_changed_grouped():
	if grouped_icon != null:
		if grouped:
			grouped_icon.show()
		else:
			grouped_icon.hide()


## layout.scale の値が変更された時に実行される処理。
func _on_changed_layout_scale():
	sprites.scale = Vector2(layout.scale, layout.scale)
	_on_changed_size()


## ファイルから CartoonPlayer を復元する際のサブルーチン。
## バイナリファイルからコマを復元して配置する。
func read_file_on_cartoon_player(fin :FileAccess, existing_panels :Array):
	assert(sprites != null)
	assert(onomatopoeias != null)
	assert(speeches != null)
	base_size = Utility.read_vector2i(fin)
	layout.read_file(fin)
	update_layout_from_existing_panels(existing_panels)

	# スプライトの読み込み
	var n_sprites = fin.get_16()
	for i in n_sprites:
		var sprite = CartoonSprite.create_from_file(fin)
		add_sprite(sprite)

	# オノマトペの読み込み
	var n_onomatopoeias = fin.get_16()
	for i in n_onomatopoeias:
		var onomatopoeia = CartoonOnomatopoeia.create_from_file(fin)
		add_onomatopoeia(onomatopoeia)

	# 台詞の読み込み
	var n_speeches = fin.get_16()
	for i in n_speeches:
		var speech = CartoonSpeech.create_from_file(fin)
		add_speech(speech)

	# オーディオ再生の読み込み。
	audios.clear()
	var n_audios = fin.get_16()
	for i in n_audios:
		var audio = CartoonAudio.new()
		audio.read_file(fin)
		audios.append(audio)


## ファイルにコマの情報を書き込む。
func write_file(fout :FileAccess):
	Utility.write_vector2i(fout, base_size)
	layout.write_file(fout)

	# スプライトの書き込み
	fout.store_16(sprites.get_child_count())
	for sprite :CartoonSprite in sprites.get_children():
		sprite.write_file(fout)

	# オノマトペの書き込み
	fout.store_16(onomatopoeias.get_child_count())
	for onomatopoeia :CartoonOnomatopoeia in onomatopoeias.get_children():
		onomatopoeia.write_file(fout)

	# 台詞の書き込み
	fout.store_16(speeches.get_child_count())
	for speech :CartoonSpeech in speeches.get_children():
		speech.write_file(fout)

	# オーディオ再生の書き込み
	fout.store_16(audios.size())
	for audio :CartoonAudio in audios:
		audio.write_file(fout)


## CartoonPlayer や CartoonScene に追加された時にコマ配置を更新する処理。
func update_layout_from_existing_panels(panels :Array):
	if not layout.specified:
		layout.scale = 1.0
		layout.type = CartoonLayout.get_layout_type_from_existing_panels(size, panels)
	position = CartoonLayout.get_position(size, layout.type, panels)


## 複数のコマからなるグループに含まれるコマの配置を更新する処理。
func update_layout_in_group(
	panels :Array, index_self :int, index_group_begin :int, index_group_end :int):
	assert(index_group_begin >= 0 and index_group_begin < panels.size())
	assert(index_group_end > 0 and index_group_end <= panels.size())
	assert(index_group_begin < index_group_end)
	assert(index_self >= index_group_begin and index_self < index_group_end)
	#print("update_layout_in_group(%d, %d, %d)" % [index_self, index_group_begin, index_group_end])
	if not layout.specified:
		var _layout = CartoonLayout.get_layout_type_in_group(
			panels, index_self, index_group_begin, index_group_end)
		if _layout != null:
			if index_self == index_group_begin:
				layout.type = CartoonLayout.get_layout_type_from_existing_panels(
					size, panels.slice(0, index_self))
			else:
				layout.type = _layout.type
			layout.scale = _layout.scale
		else:
			update_layout_from_existing_panels(panels.slice(0, index_self))
	position = CartoonLayout.get_position(
		size, layout.type, panels.slice(0, index_self))


## CartoonPlayer に追加された時の Tween 設定を行う。
func make_tween_on_added_to_player():
	modulate = Color(1, 1, 1, 0)
	for speech in speeches.get_children():
		speech.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)
	for speech in speeches.get_children():
		tween.tween_property(speech, "modulate", Color(1, 1, 1, 1), 0.2)
	tween.play()


## コマのサイズおよびスプライトをリセットする。
func reset_sprites(sprite_names :Array[String]):
	clear_sprites()
	var size_new = Vector2i(0, 0)
	for sprite_name in sprite_names:
		var sprite = CartoonSprite.new()
		sprite.sprite_name = sprite_name
		size_new.x = max(size_new.x, sprite.get_size().x)
		size_new.y = max(size_new.y, sprite.get_size().y)
		add_sprite(sprite)
	base_size = size_new


## 既存のスプライトを全て削除する。
func clear_sprites():
	while sprites.get_child_count() > 0:
		var sprite = sprites.get_child(0)
		sprites.remove_child(sprite)
		sprite.queue_free()


## スプライトを追加する。
func add_sprite(sprite :CartoonSprite):
	assert(sprites != null)
	assert(sprite != null)
	sprites.add_child(sprite)
	if Engine.is_editor_hint():
		sprite.set_owner(get_owner())


## オノマトペを追加する。
func add_onomatopoeia(onomatopoeia :CartoonOnomatopoeia):
	assert(onomatopoeias != null)
	assert(onomatopoeia != null)
	onomatopoeias.add_child(onomatopoeia)
	if Engine.is_editor_hint():
		onomatopoeia.set_owner(get_tree().edited_scene_root)


## 台詞をこのコマに追加する。
func add_speech(speech :CartoonSpeech):
	assert(speeches != null)
	assert(speech != null)
	speech.name = "Speech_%d" % speeches.get_child_count()
	speeches.add_child(speech)
	if Engine.is_editor_hint():
		speech.set_owner(get_tree().edited_scene_root)
		speech.changed_text.connect(emit_request_update_language)
	rename_speeches()


## 各 CartoonSpeech オブジェクトの名前を一斉にリネームする。
func rename_speeches():
	assert(speeches != null)
	var frame_count = {}
	for speech :CartoonSpeech in speeches.get_children():
		if not frame_count.has(speech.frame_type):
			frame_count[speech.frame_type] = 0
		frame_count[speech.frame_type] += 1
		speech.name = (
			"__" + speech.get_frame_type_name() +
			("_%d" % frame_count[speech.frame_type]))
	for speech :CartoonSpeech in speeches.get_children():
		speech.name = speech.name.lstrip("_")


func emit_request_update_language():
	print("[CartoonPanel] request update language")
	request_update_language.emit()


## 登録されているオーディオをそれぞれ再生する。
func play_audios():
	for i in audios.size():
		play_audio_at(i)


## 登録されているオーディオのうちインデックスで指定される要素を再生する。
func play_audio_at(index :int):
	var audio :CartoonAudio = audios[index]
	var player_name = "Player_%d" % index
	if not audio_players.has_node(player_name):
		var player = AudioStreamPlayer.new()
		player.name = player_name
		player.stream = audio.stream
		audio_players.add_child(player)
	var player :AudioStreamPlayer = audio_players.get_node(player_name)
	assert(player != null)
	if audio.delay > 0:
		await get_tree().create_timer(audio.delay).timeout
	player.pitch_scale = 1.0 + randf_range(
		-audio.pitch_scale_amplitude, audio.pitch_scale_amplitude)
	player.play()


## CartoonPlayer 上でこのコマが表示される直前に実行すべきイベントを実行する。
func execute_events_before_added(player :CartoonPlayer):
	for event in events:
		if event.execution_timing == CartoonEvent.ExecutionTiming.BEFORE_ADDING:
			await event._execute(player)


## CartoonPlayer 上でこのコマが表示された後に実行すべきイベントを実行する。
func execute_events_after_added(player :CartoonPlayer):
	for event in events:
		if event.execution_timing == CartoonEvent.ExecutionTiming.AFTER_ADDING:
			await event._execute(player)


## コマの形状に対応する列挙体を返す。
func get_shape() -> PanelShape:
	match base_size:
		Vector2i(1000, 1000): return PanelShape.SQUARE
		Vector2i(1600, 1000): return PanelShape.HORIZONTAL_RECT
		Vector2i(1000, 1600): return PanelShape.VERTICAL_RECT
		Vector2i(2500, 1600): return PanelShape.LARGE_RECT
		_: return PanelShape.UNKNOWN


## コマに含まれる CartoonSpeech の数を返す。
func count_speeches():
	return speeches.get_child_count()


## コマに含まれる CartoonSpeech を全て返す。
func get_speeches() -> Array:
	return speeches.get_children()


## インデックスで指定される CartoonSpeech を返す。
func get_speech(index :int) -> CartoonSpeech:
	return speeches.get_child(index) as CartoonSpeech


## 前回のパネルと横方向に連結しているなら true を返す。
func is_horizontally_joint_with(last :CartoonPanel):
	return abs(x_right - last.x_left) < 100


## 前回のパネルと縦方向に連結しているなら true を返す。
func is_vertically_joint_with(last :CartoonPanel):
	return abs(y_top - last.y_bottom) < 100


## 前回のパネルと下辺の高さが概ね一致しているなら true を返す。
func is_horizontally_aligned_with(last :CartoonPanel):
	return abs(y_bottom - last.y_bottom) < 10


## 前回のパネルと左辺のX座標が概ね一致しているなら true を返す。
func is_vertically_aligned_with(last :CartoonPanel):
	return abs(x_left - last.x_left) < 10


## パネルが横に長い形状なら true を返す。
func is_horizontally_long():
	return size.x > size.y


## パネルが縦に長い形状なら true を返す。
func is_vertically_long():
	return size.x < size.y


## 自身のノード名をパースしてインデックス値として返す。
## 例えば "Panel_2" の場合は 2 が返る。
func get_index_from_name():
	var substr = name.get_slice("_", 1)
	return substr.to_int() if not substr.is_empty() else -1
