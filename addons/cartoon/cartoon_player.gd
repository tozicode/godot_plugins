extends Control
class_name CartoonPlayer

## 次のコマに進むために画面がクリックされた時に発行されるシグナル。
## 下方向スワイプ時にも発行される。
signal progressed

## 再生予約されたシーンを全て再生し終わった状態で画面がクリックされた時に発行されるシグナル。
signal progressed_finished

## focus_index の値が変化した時に発行されるシグナル。
signal changed_focus

## シーンの再生が開始する直前に発行されるシグナル。
signal started_scene(scene :CartoonScene)

## シーンの再生が完了した時に発行されるシグナル。
signal finished_scene(scene :CartoonScene)

## 予約された全てのシーンの再生が完了した時に発行されるシグナル。
signal finished_all_scenes


## スワイプと判定するための最小移動距離（スクリーン座標px）。
const SWIPE_MIN_DISTANCE = 100.0

## スワイプ方向を表す列挙体。
enum SwipeDirection {
	NONE,           ## スワイプなし（通常クリック）
	DOWN,           ## 上から下へのスワイプ
	UP,             ## 下から上へのスワイプ
	LEFT_TO_RIGHT,  ## 左から右へのスワイプ
	RIGHT_TO_LEFT,  ## 右から左へのスワイプ
}

## 条件判定に使用するコンテキスト。
## プロジェクト側で ConditionContext のサブクラスを設定する。
var condition_context :ConditionContext

## 前回の progressed におけるスワイプ方向。
var last_swipe_direction :SwipeDirection = SwipeDirection.NONE

## マウスボタンが押された位置（スワイプ判定用）。
var _drag_start_pos :Vector2

## 次のリリースイベントで progress シグナルを発行すべき状態かどうかのフラグ。
var _is_progress_pending :bool = false


@export
var click_area :Control

## 再生中あるいは再生待ちのシーンを格納するノード。
@export
var scenes_node :Node2D

## CartoonPanel を格納するノード。
@export
var panels_node :Node2D

## 画面の中心に表示するコマのインデックス。
var focus_index :int = 0:
	get :return focus_index
	set(value):
		if count_panels() > 0:
			value = wrapi(value, 0, count_panels())
			if value != focus_index:
				focus_index = value
				changed_focus.emit()

var tween_panels_position :Tween


func _ready():
	assert(click_area)
	assert(scenes_node != null)
	assert(panels_node != null)
	click_area.gui_input.connect(_on_gui_input)
	resized.connect(on_resized)
	changed_focus.connect(_on_changed_focus)
	on_resized()


func _process(_delta: float) -> void:
	if count_scenes() == 0:
		return

	var scene :CartoonScene = scenes_node.get_child(0)
	if scene.has_run:
		scenes_node.remove_child(scene)
		scene.queue_free()
		if count_scenes() == 0:
			print("[CartoonPlayer] finished all scenes")
			finished_all_scenes.emit()
	elif not scene.is_running:
		run_scene(scene)


## 画面解像度が変更された時に実行される処理。
func on_resized():
	# ウィンドウの縦幅に1600pxがちょうど収まるように拡大率を調整する
	var _scale = size.y / 1600.0
	panels_node.scale = Vector2(_scale, _scale)

	move_panels_node_position()


## クリックまたはドラッグされた時の処理。
## 左クリック（リリース）で progressed を発行する。
## スワイプが行われた場合は last_swipe_direction にその方向を記録する。
func _on_gui_input(event :InputEvent):
	if not event is InputEventMouseButton:
		return
	var mouse_event = event as InputEventMouseButton
	match mouse_event.button_index:
		MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				_drag_start_pos = mouse_event.position
				if focus_index == count_panels() - 1:
					_is_progress_pending = true
				else:
					focus_index = -1  # 最新コマへジャンプ
					_is_progress_pending = false
			else:
				_on_left_mouse_released(mouse_event.position)
		MOUSE_BUTTON_WHEEL_UP:
			if mouse_event.pressed:
				focus_index -= 1
		MOUSE_BUTTON_WHEEL_DOWN:
			if mouse_event.pressed:
				focus_index += 1


## マウス左ボタンが離された時の処理。スワイプ方向を判定し適切なシグナルを発行する。
func _on_left_mouse_released(release_pos :Vector2):
	if not _is_progress_pending:
		return
	_is_progress_pending = false

	var dy = release_pos.y - _drag_start_pos.y
	var dx = release_pos.x - _drag_start_pos.x
	var abs_dy = abs(dy)
	var abs_dx = abs(dx)

	last_swipe_direction = SwipeDirection.NONE
	if abs_dy >= abs_dx:
		if dy >= SWIPE_MIN_DISTANCE:
			last_swipe_direction = SwipeDirection.DOWN
		elif -dy >= SWIPE_MIN_DISTANCE:
			last_swipe_direction = SwipeDirection.UP
	else:
		if dx >= SWIPE_MIN_DISTANCE:
			last_swipe_direction = SwipeDirection.LEFT_TO_RIGHT
		elif -dx >= SWIPE_MIN_DISTANCE:
			last_swipe_direction = SwipeDirection.RIGHT_TO_LEFT

	if count_scenes() > 0:
		progressed.emit()
	else:
		if last_swipe_direction == SwipeDirection.NONE:
			progressed_finished.emit()


## フォーカスを変更した時に実行される処理。
func _on_changed_focus():
	move_panels_node_position()


## フォーカスしているパネル（あるいはそれを含むグループ）が画面の中心に来るようにノードの位置をずらす。
func move_panels_node_position():
	if count_panels() == 0:
		return
	var panels :Array[CartoonPanel] = CartoonPanel.extract_panels_group(get_panels(), focus_index)
	var rect :Rect2 = CartoonPanel.get_panels_rect(panels)
	rect.position *= panels_node.scale.x
	rect.size *= panels_node.scale.x

	# 描画領域サイズより表示対象が大きい場合は左下に合わせる
	if rect.size.x > size.x:
		rect.size.x = size.x
	if rect.size.y > size.y:
		rect.position.y += rect.size.y - size.y
		rect.size.y = size.y

	# Tween の設定
	if tween_panels_position:
		tween_panels_position.kill()
	tween_panels_position = panels_node.create_tween()
	tween_panels_position.set_ease(Tween.EASE_OUT)
	tween_panels_position.set_trans(Tween.TRANS_CUBIC)
	tween_panels_position.tween_property(
		panels_node, "position", size / 2 - rect.get_center(), 0.5)
	tween_panels_position.play()


## ファイルからオブジェクトの内容を読み込む。
func read_file(fin :FileAccess):
	# コマの内容を読み込む
	var n_panels = fin.get_32()
	var panels = []
	for i in n_panels:
		var panel = CartoonPanel.create_empty()
		panels_node.add_child(panel)
		panel.read_file_on_cartoon_player(fin, panels)
		panels.append(panel)
	focus_index = count_panels() - 1


## このオブジェクトの内容をファイルに書き出す。
func write_file(fout :FileAccess):
	# コマの内容を書き出す
	fout.store_32(count_panels())
	for panel in get_panels():
		panel.write_file(fout)


## 初期化する。
func initialize():
	Utility.erase_all_children_of(scenes_node)
	Utility.erase_all_children_of(panels_node)


## 指定のシーンの再生を行う。
func run_scene(scene :CartoonScene):
	add_scene(scene)
	print("[CartoonPlayer] run scene: ", scene.name)
	scene.on_beginning_scene()
	started_scene.emit(scene)
	await scene.play_all(self)
	scene.on_ending_scene()
	print("[CartoonPlayer] finished scene: ", scene.name)
	finished_scene.emit(scene)


## 再生予約シーンを追加する。
## 予約されたシーンは順次再生が行われる。
func add_scene(scene :CartoonScene):
	assert(scene != null)
	scenes_node.add_child(scene)


## 新しいコマを追加する。
func add_panel(panel :CartoonPanel):
	print("[CartoonPlayer] add panel")
	panel.update_layout_from_existing_panels(panels_node.get_children())
	panel.name = "Panel_%d" % panels_node.get_child_count()
	panel.make_tween_on_added_to_player()
	panels_node.add_child(panel)
	focus_index = -1


## 指定のインデックスに対応するコマを含むグループを返す。
func get_panel_group(index :int) -> Array[CartoonPanel]:
	var begin = index
	var end = index + 1
	while begin > 0 and get_panel_at(begin).grouped:
		begin -= 1
	while end < count_panels() and get_panel_at(end).grouped:
		end += 1
	var panels :Array[CartoonPanel] = []
	for i in range(begin, end):
		panels.append(get_panel_at(i))
	return panels


## 指定のインデックスに対応するコマを返す。
func get_panel_at(index :int) -> CartoonPanel:
	return panels_node.get_child(index) as CartoonPanel


## コマの一覧を返す。
func get_panels() -> Array[CartoonPanel]:
	var out :Array[CartoonPanel] = []
	for panel in panels_node.get_children():
		out.append(panel as CartoonPanel)
	return out


## 保持しているコマの数を返す。
func count_panels() -> int:
	return panels_node.get_child_count()


## 再生中あるいは再生予約中のシーンの数を返す。
func count_scenes() -> int:
	return scenes_node.get_child_count()
