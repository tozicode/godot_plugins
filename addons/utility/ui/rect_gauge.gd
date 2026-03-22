@tool
extends ColorRect
class_name RectGauge

signal changed_value(value_old, value_new)
signal changed_gauge_color

@onready
var gauge_front :ColorRect = $"Front"

@onready
var gauge_delta :ColorRect = $"Delta"

@export_range(0, 100, 0.1)
var value :float:
	get: return value
	set(_value):
		var value_old = value
		value = _value
		changed_value.emit(value_old, value)

## ゲージの色。
@export
var color_front :Color:
	get: return color_front
	set(x):
		color_front = x
		changed_gauge_color.emit()

## ゲージの増減量を表す部分の色。
@export
var color_delta :Color:
	get: return color_delta
	set(x):
		color_delta = x
		changed_gauge_color.emit()

var tween :Tween


func _ready():
	gauge_front.position = Vector2(1, 1)
	gauge_delta.position = Vector2(1, 1)
	gauge_front.size = Vector2(0, size.y - 2)
	gauge_delta.size = Vector2(0, size.y - 2)

	resized.connect(on_resized)
	changed_value.connect(on_changed_value)
	on_changed_value(0, value)
	changed_gauge_color.connect(on_changed_gauge_color)
	on_changed_gauge_color()


func on_resized():
	on_changed_value(value, value)


## 数値が変更された時に実行される処理。
func on_changed_value(value_old, value_new):
	var w_max :float = size.x - 2
	var w_old :float = w_max * value_old / 100.0
	var w_new :float = w_max * value_new / 100.0

	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	if value_new < value_old:
		gauge_front.size.x = w_new
		gauge_delta.size.x = w_old
		tween.tween_property(gauge_delta, "size:x", w_new, 0.8)
	else:
		gauge_front.size.x = w_old
		gauge_delta.size.x = w_new
		tween.tween_property(gauge_front, "size:x", w_new, 0.8)
	tween.play()


func on_changed_gauge_color():
	gauge_front.color = color_front
	gauge_delta.color = color_delta
