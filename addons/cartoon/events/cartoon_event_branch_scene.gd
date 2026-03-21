## 条件分岐でシーンを追加するイベント。
extends CartoonEvent
class_name CartoonEventBranchScene

@export var scene_1 :PackedScene
@export var condition_1 :Condition

@export var scene_2 :PackedScene
@export var condition_2 :Condition

@export var scene_3 :PackedScene
@export var condition_3 :Condition

@export var scene_4 :PackedScene
@export var condition_4 :Condition



## このイベントを実行する。
func _execute(player :CartoonPlayer):
	var context :ConditionContext = player.condition_context
	assert(context != null)

	if condition_1 == null or condition_1.judge(context):
		_add_scene(player, scene_1)
	if condition_2 == null or condition_2.judge(context):
		_add_scene(player, scene_2)
	if condition_3 == null or condition_3.judge(context):
		_add_scene(player, scene_3)
	if condition_4 == null or condition_4.judge(context):
		_add_scene(player, scene_4)


func _add_scene(player :CartoonPlayer, packed_scene :PackedScene):
	var scene = packed_scene.instantiate() as CartoonScene
	assert(scene != null)
	player.add_scene(scene)
