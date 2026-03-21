## スプライトのキャッシュと検索機能を提供するオートロード。
## エディタ専用（ランタイム時は自動削除される）。
@tool
extends Node

var sprite_name_filepath = {}
var sprite_name_texture = {}
var current_tab :int = 0
var filter_query :String

func _ready():
	if Engine.is_editor_hint():
		update_sprite_name_filepath(CartoonSprite.get_sprite_dir())
	else:
		queue_free()


func update_sprite_name_filepath(dirpath :String):
	for filename in DirAccess.get_files_at(dirpath):
		if filename.ends_with(".png") or filename.ends_with(".jpg"):
			var filepath = dirpath + "/" + filename
			var sprite_name = CartoonSprite.filepath_to_sprite_name(filepath)
			if not sprite_name in sprite_name_filepath:
				sprite_name_filepath[sprite_name] = filepath

	for dirname in DirAccess.get_directories_at(dirpath):
		update_sprite_name_filepath(dirpath + "/" + dirname)


func add_sprites_to_item_list(item_list :ItemList, keywords :PackedStringArray):
	if keywords.is_empty():
		return

	var sprite_names = []
	for sprite_name :String in sprite_name_filepath.keys():
		var is_filtered = true
		for word :String in keywords:
			if not word.is_empty() and sprite_name.contains(word):
				is_filtered = false
				break
		if not is_filtered:
			sprite_names.append(sprite_name)

	sprite_names.sort()
	for sprite_name in sprite_names:
		item_list.add_icon_item(get_texture_from_sprite_name(sprite_name))
		item_list.set_item_tooltip(-1, sprite_name_filepath[sprite_name])


func get_texture_from_sprite_name(sprite_name :String):
	var texture = sprite_name_texture.get(sprite_name)
	if texture == null:
		texture = load(sprite_name_filepath[sprite_name])
		sprite_name_texture[sprite_name] = texture
	return texture
