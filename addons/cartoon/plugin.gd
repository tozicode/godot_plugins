@tool
extends EditorPlugin

var panel_inspector_plugin
var scene_inspector_plugin


func _enter_tree():
	# オートロードの登録
	add_autoload_singleton("CartoonSpriteManager",
		"res://addons/cartoon/cartoon_sprite_manager.gd")

	# インスペクタプラグインの登録
	panel_inspector_plugin = preload(
		"res://addons/cartoon/editor/panel_inspector_plugin.gd").new()
	scene_inspector_plugin = preload(
		"res://addons/cartoon/editor/scene_inspector_plugin.gd").new()
	add_inspector_plugin(panel_inspector_plugin)
	add_inspector_plugin(scene_inspector_plugin)

	# プロジェクト設定の登録
	_register_project_settings()


func _exit_tree():
	remove_autoload_singleton("CartoonSpriteManager")
	remove_inspector_plugin(panel_inspector_plugin)
	remove_inspector_plugin(scene_inspector_plugin)


func _register_project_settings():
	_add_setting(
		CartoonSprite.SETTING_SPRITES_DIRECTORY,
		TYPE_STRING,
		CartoonSprite.DEFAULT_SPRITES_DIRECTORY)
	_add_setting(
		CartoonScene.SETTING_SCENES_DIRECTORY,
		TYPE_STRING,
		CartoonScene.DEFAULT_SCENES_DIRECTORY)
	_add_setting(
		CartoonOnomatopoeia.SETTING_ONOMATOPOEIAS_DIRECTORY,
		TYPE_STRING,
		CartoonOnomatopoeia.DEFAULT_ONOMATOPOEIAS_DIRECTORY)
	_add_setting(
		CartoonSpeech.SETTING_SPEAKER_STYLES_PATH,
		TYPE_STRING,
		"")


func _add_setting(name :String, type :int, default_value):
	if not ProjectSettings.has_setting(name):
		ProjectSettings.set_setting(name, default_value)
	ProjectSettings.set_initial_value(name, default_value)
