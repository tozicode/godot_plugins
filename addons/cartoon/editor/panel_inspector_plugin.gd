## CartoonPanel を編集するためのエディタープラグイン。
@tool
extends EditorInspectorPlugin

## 編集の対象とする CartoonPanel インスタンス。
var panel :CartoonPanel

var controler :Control


# 選択されたノードやファイルがこのスクリプトの対象かどうか判定する。
func _can_handle(object: Object) -> bool:
	return object is CartoonPanel


# インスペクタに表示されるときに1回呼ばれる
func _parse_begin(object: Object) -> void:
	# インスペクターに表示しているオブジェクトを保存
	panel = object as CartoonPanel

	# コントローラをセットアップ
	controler = preload(
		"res://addons/cartoon/editor/custom_controler_panel.tscn").instantiate()
	add_custom_control(controler)
	_reset_viewer()
	_setup_tab_container()
	# リスト類のセットアップ
	_setup_sprite_list()
	_setup_speech_frame_selector()
	_setup_onomatopoeia_list()
	_setup_current_layout()
	_setup_layout_type_list()
	_setup_layout_scale_slider()
	# ボタン類のセットアップ
	_setup_filter_button()
	_setup_change_sprite_button()
	_setup_add_speech_button()
	_setup_add_onomatopoeia_button()
	_setup_set_layout_button()
	_setup_delete_layout_button()


func _reset_viewer():
	var viewer :Control = controler.get_node("Viewer/Control")
	for child in viewer.get_children():
		child.queue_free()
	var clone = panel.duplicate()
	clone.position = Vector2(0, 0)
	clone.scale = Vector2(0.2, 0.2)
	var viewer_size = panel.base_size * panel.layout.scale * 0.2
	if viewer_size.y > 200:
		viewer_size.y = 200
	viewer.custom_minimum_size = viewer_size
	viewer.add_child(clone)


func _setup_tab_container():
	var tabs :TabContainer = controler.get_node("Tabs")
	tabs.current_tab = CartoonSpriteManager.current_tab
	tabs.tab_changed.connect(_on_tab_changed)


## SpriteList を初期化する。
func _setup_sprite_list():
	var sprite_list :ItemList = controler.get_node("Tabs/Sprite/SpriteList")
	var text_edit :TextEdit = controler.get_node("Tabs/Sprite/Filter/TextEdit")
	assert(sprite_list != null)
	assert(text_edit != null)
	text_edit.text = CartoonSpriteManager.filter_query
	sprite_list.clear()
	
	var keywords :PackedStringArray = text_edit.text.split(" ")
	CartoonSpriteManager.add_sprites_to_item_list(sprite_list, keywords)


## FilterButton を初期化する。
func _setup_filter_button():
	var button :Button = controler.get_node("Tabs/Sprite/Filter/Button")
	if button != null:
		button.pressed.connect(_on_pressed_filter_button)


## Frame/Selector を初期化する。
func _setup_speech_frame_selector():
	var selector :OptionButton = controler.get_node("Tabs/Speech/Frame/Selector")
	if selector == null:
		printerr("[CartoonPanelEditor] Frame/Selector is not found.")
		return
	for frame_type in CartoonSpeech.FrameType.size():
		var text = CartoonSpeech.FRAME_TYPE_NAMES[frame_type].to_upper()
		selector.add_item(text, frame_type)


## OnomatopoeiaList を初期化する。
func _setup_onomatopoeia_list():
	var item_list :ItemList = controler.get_node("Tabs/Onomatopoeia/OnomatopoeiaList")
	if item_list == null:
		printerr("[CartoonPanelEditor] OnomatopoeiaList is not found.")
		return
	var sprite_dir := CartoonOnomatopoeia.get_sprite_dir()
	for filename in DirAccess.get_files_at(sprite_dir):
		if filename.ends_with(".png"):
			var filepath = sprite_dir + "/" + filename
			var texture = load(filepath)
			item_list.add_icon_item(texture)


func _setup_current_layout():
	var value :TextEdit = controler.get_node("Tabs/Layout/Current/Value")
	var type :String = "Unknown(%d)" % panel.layout.type
	if panel.layout.type >= 0 and panel.layout.type < CartoonLayout.LAYOUT_TYPE_NAMES.size():
		type = CartoonLayout.LAYOUT_TYPE_NAMES[panel.layout.type]
	var specified :String = "" if panel.layout.specified else "(auto)"
	value.text = "%s%s, %d%%" % [specified, type, panel.layout.scale * 100]


func _setup_layout_type_list():
	var layout_type_list :OptionButton = controler.get_node("Tabs/Layout/LayoutTypeList/OptionButton")
	if layout_type_list == null:
		printerr("[CartoonPanelEditor] LayoutTypeList is not found.")
		return
	layout_type_list.clear()
	for s in CartoonLayout.LAYOUT_TYPE_NAMES:
		layout_type_list.add_item(s)


func _setup_layout_scale_slider():
	var slider :HSlider = controler.get_node("Tabs/Layout/LayoutScaleSlider/HSlider")
	if slider == null:
		printerr("[CartoonPanelEditor] LayoutScaleSlider is not found.")
		return
	slider.value_changed.connect(_on_changed_layout_scale)


## ChangeSpriteButton を初期化する。
func _setup_change_sprite_button():
	var button :Button = controler.get_node("Tabs/Sprite/ChangeSpriteButton")
	if button != null:
		button.pressed.connect(_on_pressed_change_sprite_button)
	else:
		printerr("[CartoonPanelEditor] ChangeSpriteButton is not found.")


## AddSpeechButton を初期化する。
func _setup_add_speech_button():
	var button :Button = controler.get_node("Tabs/Speech/AddSpeechButton")
	if button != null:
		button.pressed.connect(_on_pressed_add_speech_button)
	else:
		printerr("[CartoonPanelEditor] AddSpeechButton is not found.")


## AddOnomatopoeiaButton を初期化する。
func _setup_add_onomatopoeia_button():
	var button :Button = controler.get_node("Tabs/Onomatopoeia/AddOnomatopoeiaButton")
	if button != null:
		button.pressed.connect(_on_pressed_add_onomatopoeia_button)
	else:
		printerr("[CartoonPanelEditor] AddOnomatopoeiaButton is not found.")


## SetLayoutButton を初期化する。
func _setup_set_layout_button():
	var button :Button = controler.get_node("Tabs/Layout/SetLayoutButton")
	if button != null:
		button.pressed.connect(_on_pressed_set_layout_button)
	else:
		printerr("[CartoonPanelEditor] SetLayoutButton is not found.")


## SetLayoutButton を初期化する。
func _setup_delete_layout_button():
	var button :Button = controler.get_node("Tabs/Layout/DeleteLayoutButton")
	if button != null:
		button.pressed.connect(_on_pressed_delete_layout_button)
	else:
		printerr("[CartoonPanelEditor] DeleteLayoutButton is not found.")


## タブが切り替わった時に実行される処理。
func _on_tab_changed(tab :int):
	CartoonSpriteManager.current_tab = tab


## フィルターボタンを押された時に実行される処理。
func _on_pressed_filter_button():
	var text_edit :TextEdit = controler.get_node("Tabs/Sprite/Filter/TextEdit")
	CartoonSpriteManager.filter_query = text_edit.text
	_setup_sprite_list()


## スプライト置き換えボタンを押された時に実行する処理。
## 既存のスプライトを全て削除し、選択したスプライトを追加する。
func _on_pressed_change_sprite_button():
	var sprite_list :ItemList = controler.get_node("Tabs/Sprite/SpriteList")
	if sprite_list == null:
		printerr("Sprite selector is not found.")
		return
	var selected = sprite_list.get_selected_items()
	if selected.size() == 0:
		printerr("No sprite is selected.")
		return

	var sprite_names :Array[String] = []
	for idx in selected:
		sprite_names.append(CartoonSprite.filepath_to_sprite_name(
			sprite_list.get_item_icon(selected[0]).resource_path))
	panel.reset_sprites(sprite_names)
	panel.set_display_folded(true)
	EditorInterface.mark_scene_as_unsaved()


## 台詞追加ボタンを押された時に実行される処理。
func _on_pressed_add_speech_button():
	var selector :OptionButton = controler.get_node("Tabs/Speech/Frame/Selector")
	var frame_type = selector.get_selected_id()
	var speech :CartoonSpeech = CartoonSpeech.create(frame_type)
	panel.add_speech(speech)
	speech.set_display_folded(true)
	EditorInterface.mark_scene_as_unsaved()


## オノマトペ追加ボタンを押された時に実行される処理。
func _on_pressed_add_onomatopoeia_button():
	var item_list :ItemList = controler.get_node("Tabs/Onomatopoeia/OnomatopoeiaList")
	if item_list == null:
		printerr("[CartoonPanelEditor] OnomatopoeiaList is not found.")
	var onomatopoeia = CartoonOnomatopoeia.new()
	var selected = item_list.get_selected_items()
	if selected.size() != 1:
		printerr("No sprite is selected.")
		return
	onomatopoeia.texture = item_list.get_item_icon(selected[0])
	panel.add_onomatopoeia(onomatopoeia)
	EditorInterface.mark_scene_as_unsaved()


## 拡大率が変更された時に実行される処理。
func _on_changed_layout_scale(value :float):
	var label :Label = controler.get_node("Tabs/Layout/LayoutScaleSlider/ScaleLabel")
	label.text = "%d%%" % int(value)


## レイアウト設定ボタンが押された時に実行される処理。
func _on_pressed_set_layout_button():
	var layout_type_list :OptionButton = controler.get_node("Tabs/Layout/LayoutTypeList/OptionButton")
	var scale_slider :HSlider = controler.get_node("Tabs/Layout/LayoutScaleSlider/HSlider")
	var layout = CartoonLayout.new()
	layout.specified = true
	layout.type = layout_type_list.selected
	layout.scale = scale_slider.value / 100.0
	panel.layout = layout
	_setup_current_layout()
	EditorInterface.mark_scene_as_unsaved()


func _on_pressed_delete_layout_button():
	panel.layout.specified = false
	panel.layout.type = CartoonLayout.LayoutType.UNDERSPECIFIED
	panel.layout.scale = 1.0
	_setup_current_layout()
	EditorInterface.mark_scene_as_unsaved()
