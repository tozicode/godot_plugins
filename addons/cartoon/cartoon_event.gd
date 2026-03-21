## コマに紐づくイベントの基底クラス。
extends Resource
class_name CartoonEvent

enum ExecutionTiming { BEFORE_ADDING, AFTER_ADDING }

## このイベントを実行するタイミング。
@export
var execution_timing :ExecutionTiming = ExecutionTiming.BEFORE_ADDING


## このイベントを実行する。
func _execute(player :CartoonPlayer):
	pass
