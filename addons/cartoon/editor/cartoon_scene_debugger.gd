extends Control

@export var debug_target :Resource

@onready var cartoon_player :CartoonPlayer = $"CartoonPlayer"


func _ready():
	assert(debug_target and not debug_target.scene_path.is_empty())
	var scene = load(debug_target.scene_path)
	var instantiated :CartoonScene = scene.instantiate()
	cartoon_player.add_scene(instantiated)
