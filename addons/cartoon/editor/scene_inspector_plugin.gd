## CartoonScene を編集するためのエディタープラグイン。
@tool
extends EditorInspectorPlugin

## 編集の対象とする CartoonScene インスタンス。
var scene :CartoonScene

var controler :Control


# 選択されたノードやファイルがこのスクリプトの対象かどうか判定する。
func _can_handle(object: Object) -> bool:
	return object is CartoonScene


# インスペクタに表示されるときに1回呼ばれる
func _parse_begin(object: Object) -> void:
	# インスペクターに表示しているオブジェクトを保存
	scene = object as CartoonScene

	# コントローラをセットアップ
	controler = preload(
		"res://addons/cartoon/editor/custom_controler_scene.tscn").instantiate()
	add_custom_control(controler)
	_setup_sprite_list()
	_setup_filter_button()
	_setup_add_panel_button()
	_setup_test_play_button()


## SpriteList を初期化する。
func _setup_sprite_list():
	var sprite_list :ItemList = controler.get_node("SpriteList")
	var text_edit :TextEdit = controler.get_node("Filter/TextEdit")
	assert(sprite_list != null)
	assert(text_edit != null)
	text_edit.text = CartoonSpriteManager.filter_query
	sprite_list.clear()
	
	var keywords :PackedStringArray = text_edit.text.split(" ")
	CartoonSpriteManager.add_sprites_to_item_list(sprite_list, keywords)


## FilterButton を初期化する。
func _setup_filter_button():
	var button :Button = controler.get_node("Filter/Button")
	if button != null:
		button.pressed.connect(_on_pressed_filter_button)


## AddPanelButton を初期化する。
func _setup_add_panel_button():
	var button :Button = controler.get_node("AddPanelButton")
	if button != null:
		button.pressed.connect(_on_pressed_add_panel_button)


## TestPlayButton を初期化する。
func _setup_test_play_button():
	var button :Button = controler.get_node("TestPlayButton")
	if button != null:
		button.pressed.connect(_on_pressed_test_play_button)


## フィルターボタンを押された時に実行される処理。
func _on_pressed_filter_button():
	var text_edit :TextEdit = controler.get_node("Filter/TextEdit")
	CartoonSpriteManager.filter_query = text_edit.text
	_setup_sprite_list()


## コマ追加ボタンを押された時に実行される処理。
func _on_pressed_add_panel_button():
	var sprite_list :ItemList = controler.get_node("SpriteList")
	if sprite_list == null:
		printerr("Sprite selector is not found.")
		return
	var selected = sprite_list.get_selected_items()
	if selected.size() == 0:
		printerr("No sprite is selected.")
		return

	var sprites = []
	var size :Vector2i = Vector2i.ZERO
	for idx in selected:
		var sprite :CartoonSprite = CartoonSprite.new()
		sprite.sprite_name = CartoonSprite.filepath_to_sprite_name(
			sprite_list.get_item_icon(selected[0]).resource_path)
		size.x = max(size.x, sprite.get_size().x)
		size.y = max(size.y, sprite.get_size().y)
		sprites.append(sprite)
	var panel = scene.add_panel(size, CartoonLayout.LayoutType.UNDERSPECIFIED)
	for sprite in sprites:
		panel.add_sprite(sprite)
	panel.set_display_folded(true)
	EditorInterface.mark_scene_as_unsaved()


func _on_pressed_test_play_button():
	var scene_root = EditorInterface.get_edited_scene_root()
	print("[CartoonSceneEditor] test play: \"%s\"" % scene_root.scene_file_path)
	var debug_target = preload("res://addons/cartoon/editor/debug_target.tres")
	debug_target.scene_path = scene_root.scene_file_path
	EditorInterface.edit_resource(debug_target)
	EditorInterface.play_custom_scene(
		"res://addons/cartoon/editor/cartoon_scene_debugger.tscn")
