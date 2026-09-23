@tool
extends ColorRect
class_name RectGauge

## 内側の矩形と枠の間に空ける余白 (px)。上下左右それぞれに 1px ずつ。
const INNER_MARGIN :float = 1.0


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
	gauge_front.position = Vector2(INNER_MARGIN, INNER_MARGIN)
	gauge_delta.position = Vector2(INNER_MARGIN, INNER_MARGIN)
	gauge_front.size = Vector2(0, inner_height())
	gauge_delta.size = Vector2(0, inner_height())

	resized.connect(on_resized)
	changed_value.connect(on_changed_value)
	on_changed_value(0, value)
	changed_gauge_color.connect(on_changed_gauge_color)
	on_changed_gauge_color()


func on_resized():
	on_changed_value(value, value)


## 内側の矩形の高さ。枠から上下の余白を引いたもの。
func inner_height() -> float:
	return maxf(size.y - INNER_MARGIN * 2.0, 0.0)


## 内側の矩形の最大幅。枠から左右の余白を引いたもの。
func inner_width() -> float:
	return maxf(size.x - INNER_MARGIN * 2.0, 0.0)


## 数値が変更された時に実行される処理。
func on_changed_value(value_old, value_new):
	# **高さは毎回ここで枠に追従させる。**
	# `_ready()` で一度きり決めていた頃は、コンテナに縦へ引き伸ばされると
	# 枠だけ伸びて中身が伸びず、下に隙間が空いていた。
	# `HBoxContainer` などは既定で子を縦いっぱいに広げるため確実に踏む。
	gauge_front.size.y = inner_height()
	gauge_delta.size.y = inner_height()

	var w_max :float = inner_width()
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
