## 漫画のコマの連なりを表現するためのクラス。
## このクラスオブジェクトの子は全て CartoonPanel オブジェクトでなければならない。
@tool
extends Node2D
class_name CartoonScene

## シーンディレクトリのプロジェクト設定キー。
const SETTING_SCENES_DIRECTORY := "cartoon/scenes_directory"
const DEFAULT_SCENES_DIRECTORY := "res://cartoon/scenes"

## 次のフレームで子のコマの位置を再設定するかどうかのフラグ。
var do_rearrange_children :bool = false

## シーンを実行中かどうかのフラグ。
var is_running :bool = false

## シーンを実行済みかどうかのフラグ。
var has_run :bool = false

var scene_name :String:
	get:
		var scenes_dir = get_scenes_directory()
		var prefix = scenes_dir + "/"
		if scene_file_path.begins_with(prefix):
			return scene_file_path.get_basename().substr(prefix.length())
		return scene_file_path.get_basename()


## シーンディレクトリのパスを返す。
static func get_scenes_directory() -> String:
	if ProjectSettings.has_setting(SETTING_SCENES_DIRECTORY):
		return ProjectSettings.get_setting(SETTING_SCENES_DIRECTORY)
	return DEFAULT_SCENES_DIRECTORY


## シーン名に対応するシーンをロードして返す。
static func load_scene(_scene_name :String) -> CartoonScene:
	var tscn :PackedScene = load(get_scenes_directory() + "/" + _scene_name + ".tscn")
	if tscn != null:
		return tscn.instantiate()
	return null


func _ready():
	if Engine.is_editor_hint():
		child_order_changed.connect(_on_children_changed)
		for panel :CartoonPanel in get_children():
			setup_panel(panel)


func _process(_delta :float):
	if do_rearrange_children:
		rearrange_children()
		do_rearrange_children = false


## 子の内容が変化した時に実行される処理。
func _on_children_changed():
	do_rearrange_children = true


## 子の名前や位置座標を再設定する。
func rearrange_children():
	print("[CartoonScene] rearrange children")

	# 名前を変更する
	for i in count_panels():
		get_panel(i).name = "__Panel_%d" % i
	for panel in get_panels():
		panel.name = panel.name.lstrip("_")

	# レイアウトを再設定する。
	var index :int = 0
	var panels :Array = get_panels()
	while index < count_panels():
		var begin = CartoonPanel.get_panels_group_begin(panels, index)
		var end = CartoonPanel.get_panels_group_end(panels, index)
		if absi(begin - end) == 1:
			get_panel(index).update_layout_from_existing_panels(panels.slice(0, index))
		else:
			for i in range(begin, end):
				get_panel(i).update_layout_in_group(panels, i, begin, end)
		index = end


## シーンを CartoonPlayer で再生する直前に実行する処理。
func on_beginning_scene():
	is_running = true


## シーンを CartoonPlayer で再生する直前に実行する処理。
func on_ending_scene():
	is_running = false
	has_run = true


## シーンに含まれるコマを順に再生する。
func play_all(player :CartoonPlayer):
	while count_panels() > 0:
		await play_next(player)


## シーンを CartoonPlayer で再生している時に、次のコマを表示する関数。
func play_next(player :CartoonPlayer, await_clicked :bool = true):
	assert(player != null)
	assert(count_panels() > 0)
	var panel = pop_front_panel()
	await panel.execute_events_before_added(player)
	panel.play_audios()
	player.add_panel(panel)
	if await_clicked:
		await player.progressed
	await panel.execute_events_after_added(player)


## 条件を満たすならコマを表示し、満たさないならスキップする、という手続きを条件の数だけ行う。
func play_branch(player :CartoonPlayer, conditions :Array[bool], await_clicked :bool = true):
	assert(count_panels() > conditions.size())
	for condition in conditions:
		if condition:
			await play_next(player, await_clicked)
			return
		else:
			var panel = pop_front_panel()
			panel.queue_free()
	await play_next(player, await_clicked)


## 別のシーンをこのシーンの一部として再生する。
func play_scene(player :CartoonPlayer, scene :CartoonScene):
	assert(scene != null)
	player.add_scene(scene)
	await player.run_scene(scene)


## 指定のスプライトを持つ新しいコマを追加する。
func add_panel(size :Vector2i, layout_type :int = CartoonLayout.LayoutType.UNDERSPECIFIED) -> CartoonPanel:
	print("[CartoonScene] add panel (size = (%d, %d))" % [size.x, size.y])
	var panel :CartoonPanel = CartoonPanel.create_empty()
	panel.base_size = size
	panel.name = "Panel_%d" % get_child_count()
	panel.layout.type = layout_type as CartoonLayout.LayoutType
	panel.layout.scale = 1.0
	add_child(panel)
	if Engine.is_editor_hint():
		Utility.set_scene_owner_recursively(panel)
	setup_panel(panel)
	return panel


func setup_panel(panel :CartoonPanel):
	if Engine.is_editor_hint():
		panel.changed_size.connect(_on_children_changed)
		panel.changed_grouped.connect(_on_children_changed)
		panel.changed_layout.connect(_on_children_changed)
		panel.request_update_language.connect(update_language)


## 先頭のコマを取り出して返す。
func pop_front_panel() -> CartoonPanel:
	var panel = get_child(0)
	if panel != null:
		remove_child(panel)
	return panel


## このシーンに含まれるテキストの内容を Language に反映する。
func update_language():
	Localization.remove_strings_begins_with("scene:" + scene_name)
	assign_text_keys()
	register_text_keys()
	Localization.write_file()

## このシーンに含まれる CartoonSpeech のテキストキーの再割り当てを行う。
func assign_text_keys():
	for panel_index in count_panels():
		var panel :CartoonPanel = get_panel(panel_index)
		for speech_index in panel.count_speeches():
			var speech :CartoonSpeech = panel.get_speech(speech_index)
			speech.assign_text_key(scene_name, panel_index, speech_index)

func register_text_keys():
	for panel in get_panels():
		for speech in panel.get_speeches():
			Localization.register_string(speech.text_key, speech.text)

## 全てのコマを返す。
func get_panels() -> Array:
	return get_children()


## インデックスで指定されたコマを返す。
func get_panel(index :int) -> CartoonPanel:
	return get_child(index)


## シーンに含まれるコマの数を返す。
func count_panels() -> int:
	return get_child_count()
