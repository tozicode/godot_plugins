## 漫画のコマの配置を表すための列挙体。
@tool
extends Resource
class_name CartoonLayout

## 配置種別が変更された時に発行されるシグナル。
signal changed_layout_type

## 拡大率が変更された時に発行されるシグナル。
signal changed_scale

## コマの配置の種別を表す列挙体。
enum LayoutType {
	UNDERSPECIFIED = -1, ## 不定。
	INITIAL,             ## 座標 (0, 0) に合わせる。
	LEFT,                ## 前要素の左に、互いの中心Y座標を合わせて配置する。
	LEFT_UP,             ## 前要素の左に、前要素の上辺に中心Y座標を合わせて配置する。
	LEFT_UP_UP,          ## 前要素の左に、前要素の上辺に自身の上辺を合わせて配置する。
	LEFT_BOTTOM,         ## 前要素の左に、前要素の下辺に中心Y座標を合わせて配置する。
	BOTTOM,              ## 前要素の下に、互いの中心X座標を合わせて配置する。
	BOTTOM_RIGHT,        ## 前要素の下に、前要素の右辺に中心X座標を合わせて配置する。
	BOTTOM_RIGHT_RIGHT,  ## 前要素の下に、前要素の右辺に自身の右辺を合わせて配置する。
	BOTTOM_LEFT,         ## 前要素の下に、前要素の左辺に中心X座標を合わせて配置する。
	BOTTOM_LEFT_LEFT,    ## 前要素の下に、前要素の左辺に左辺を合わせて配置する。
	GROUP_TOP,           ## 自身が属するグループの上辺に自身の上辺を合わせて配置する。
	SEPARATED            ## 既存の要素とは隣接しない位置に配置する。
}

## グループ単位での配置種別を表す列挙体。
enum GroupLayoutType {
	UNKNOWN = -1,
	VERTICAL_RECT, ## 縦長のコマ一つ
	LARGE_RECT,    ## 大きなコマ一つ
	TWO_SQUARES,  ## 小コマ2つ
	TWO_H_RECTS,  ## 横長コマ2つ
	TWO_SQUARES_AND_H_RECT, ## 小コマ2つと横長コマ
	H_RECT_AND_TWO_SQUARES, ## 横長コマと小コマ2つ
}

## 各 GroupLayoutType におけるコマの数。
const GROUP_LAYOUT_PANEL_COUNT = {
	GroupLayoutType.VERTICAL_RECT : 1,
	GroupLayoutType.LARGE_RECT : 1,
	GroupLayoutType.TWO_SQUARES : 2,
	GroupLayoutType.TWO_H_RECTS : 2,
	GroupLayoutType.TWO_SQUARES_AND_H_RECT : 3,
	GroupLayoutType.H_RECT_AND_TWO_SQUARES : 3,
}

const LAYOUT_TYPE_NAMES = [
	"Initial", "Left", "Left Up", "Left Up-Up", "Left Bottom",
	"Bottom", "Bottom Right", "Bottom Right-Right",
	"Bottom Left", "Bottom Left-Left",
	"Group Top", "Separated",
	"Underspecified"
]

## コマとコマの間の幅。
const MARGIN = 80

## 配置方法がマニュアルで指定されているかどうかのフラグ。
@export
var specified :bool = false

## コマの配置方法の種別。
@export
var type :LayoutType = LayoutType.UNDERSPECIFIED:
	get: return type
	set(value):
		type = value
		changed_layout_type.emit()

## 本来のサイズに対する拡大率。
@export
var scale :float = 1.0:
	get: return scale
	set(value):
		scale = value
		changed_scale.emit()


## 前のコマの配置を基に、次のコマの配置種別を返す。
static func get_layout_type_from_existing_panels(size :Vector2i, existing_panels :Array) -> LayoutType:
	if existing_panels.size() == 0:
		return LayoutType.INITIAL
	# 前回のパネルを考慮する場合
	var last_panel :CartoonPanel = existing_panels[-1]
	if last_panel.layout.type == LayoutType.SEPARATED:
		return LayoutType.BOTTOM
	if existing_panels.size() == 1:
		if last_panel.is_horizontally_long():
			return LayoutType.BOTTOM
		else:
			return LayoutType.LEFT
	# 前回と前々回のパネルを考慮する場合
	var last_before_panel :CartoonPanel = existing_panels[-2]
	if last_panel.is_horizontally_joint_with(last_before_panel):
		if last_panel.is_horizontally_aligned_with(last_before_panel):
			return LayoutType.BOTTOM_RIGHT
		if last_panel.y_bottom < last_before_panel.y_bottom:
			if size.x > last_panel.size.x:
				return LayoutType.BOTTOM_LEFT
		return LayoutType.BOTTOM
	if last_panel.is_vertically_joint_with(last_before_panel):
		if last_panel.is_vertically_aligned_with(last_before_panel):
			return LayoutType.LEFT_UP
		if size.y > last_panel.size.y:
			if last_panel.x_left > last_before_panel.x_left:
				return LayoutType.LEFT_BOTTOM
		return LayoutType.LEFT
	return LayoutType.BOTTOM


## グループに含まれるコマに対する配置や拡大率を決定して返す。
static func get_layout_type_in_group(
	panels :Array, index_self :int, index_group_begin :int, index_group_end :int) -> CartoonLayout:
	assert(index_group_begin >= 0 and index_group_begin < panels.size())
	assert(index_group_end > 0 and index_group_end <= panels.size())
	assert(index_group_begin < index_group_end)
	assert(index_self >= index_group_begin and index_self < index_group_end)
	#print("get_layout_type_in_group(%d, %d, %d)" % [index_self, index_group_begin, index_group_end])
	var shapes = []
	for i in range(index_group_begin, index_group_end):
		shapes.append(panels[i].get_shape())
	var layout_types = get_group_layout_ids(shapes)
	if not layout_types.is_empty():
		var index = index_group_begin
		for type in layout_types:
			var n = GROUP_LAYOUT_PANEL_COUNT.get(type, 0)
			assert(n > 0)
			if index_self >= index and index_self < index + n:
				return _get_group_layout(type, index_self - index)
			else:
				index += n
	return null


## コマ形状を表す列挙体の配列から配置種別の列を決定して返す。
static func get_group_layout_ids(shapes :Array):
	var ids :Array[GroupLayoutType] = []
	var i = 0
	while i < shapes.size():
		var found :bool = false
		for d in range(3, 0, -1):
			if shapes.size() - i < d:
				continue
			var id = _get_group_layout_id(shapes.slice(i, i + d))
			if id != GroupLayoutType.UNKNOWN:
				ids.append(id)
				i += d
				found = true
				break
		if not found:
			ids.clear()
			break
	return ids


## コマ形状を表す列挙体の配列から配置種別を決定して返す。
static func _get_group_layout_id(shapes :Array) -> GroupLayoutType:
	match shapes:
		[2]:       return GroupLayoutType.VERTICAL_RECT
		[3]:       return GroupLayoutType.LARGE_RECT
		[0, 0]:    return GroupLayoutType.TWO_SQUARES
		[1, 1]:    return GroupLayoutType.TWO_H_RECTS
		[0, 0, 1]: return GroupLayoutType.TWO_SQUARES_AND_H_RECT
		[1, 0, 0]: return GroupLayoutType.H_RECT_AND_TWO_SQUARES
		_: return GroupLayoutType.UNKNOWN ## 該当なし


## 配置種別に対応する具体的な配置方法や拡大率を返す。
static func _get_group_layout(type :GroupLayoutType, index :int) -> CartoonLayout:
	#print("get_group_layout(%d, %d)" % [type, index])
	var layout = CartoonLayout.new()
	match type:
		GroupLayoutType.VERTICAL_RECT:
			layout.type = LayoutType.GROUP_TOP
			layout.scale = 1.0
		GroupLayoutType.LARGE_RECT:
			layout.type = LayoutType.GROUP_TOP
			layout.scale = 1.0
		GroupLayoutType.TWO_SQUARES:
			layout.type = LayoutType.GROUP_TOP if index == 0 else LayoutType.BOTTOM
			layout.scale = 0.76
		GroupLayoutType.TWO_H_RECTS:
			layout.type = LayoutType.GROUP_TOP if index == 0 else LayoutType.BOTTOM
			layout.scale = 0.76
		GroupLayoutType.TWO_SQUARES_AND_H_RECT:
			match index:
				0: layout.type = LayoutType.GROUP_TOP
				1: layout.type = LayoutType.LEFT
				2: layout.type = LayoutType.BOTTOM_LEFT_LEFT
			layout.scale = 0.664 if index < 2 else 0.865
		GroupLayoutType.H_RECT_AND_TWO_SQUARES:
			match index:
				0: layout.type = LayoutType.GROUP_TOP
				1: layout.type = LayoutType.BOTTOM_RIGHT_RIGHT
				2: layout.type = LayoutType.LEFT
			layout.scale = 0.865 if index == 0 else 0.664
	return layout


## 配置種別に応じて新たに追加するコマの位置座標を決定して返す。
static func get_position(size :Vector2i, layout_type :LayoutType, existing_panels :Array) -> Vector2i:
	assert(layout_type != LayoutType.UNDERSPECIFIED)
	if existing_panels.size() == 0 or layout_type == LayoutType.INITIAL:
		return Vector2i(0, 0)
	var last_panel :CartoonPanel = existing_panels[-1]
	match layout_type:
		LayoutType.LEFT:
			return Vector2i(
				last_panel.x_left - size.x - MARGIN,
				last_panel.y_center - size.y / 2)
		LayoutType.LEFT_UP:
			return Vector2i(
				last_panel.x_left - size.x - MARGIN,
				last_panel.y_top - size.y / 2)
		LayoutType.LEFT_UP_UP:
			return Vector2i(
				last_panel.x_left - size.x - MARGIN,
				last_panel.y_top)
		LayoutType.LEFT_BOTTOM:
			return Vector2i(
				last_panel.x_left - size.x - MARGIN,
				last_panel.y_bottom - size.y / 2)
		LayoutType.BOTTOM:
			return Vector2i(
				last_panel.x_center - size.x / 2,
				last_panel.y_bottom + MARGIN)
		LayoutType.BOTTOM_RIGHT:
			return Vector2i(
				last_panel.x_right - size.x / 2,
				last_panel.y_bottom + MARGIN)
		LayoutType.BOTTOM_RIGHT_RIGHT:
			return Vector2i(
				last_panel.x_right - size.x,
				last_panel.y_bottom + MARGIN)
		LayoutType.BOTTOM_LEFT:
			return Vector2i(
				last_panel.x_left - size.x / 2,
				last_panel.y_bottom + MARGIN)
		LayoutType.BOTTOM_LEFT_LEFT:
			return Vector2i(
				last_panel.x_left,
				last_panel.y_bottom + MARGIN)
		LayoutType.GROUP_TOP:
			var p = Vector2i(0, 0)
			for i in range(existing_panels.size() - 1, 0, -1):
				if i == existing_panels.size() - 1:
					p.x = existing_panels[i].x_left
					p.y = existing_panels[i].y_top
				else:
					p.x = mini(p.x, existing_panels[i].x_left)
					p.y = mini(p.y, existing_panels[i].y_top)
				if not existing_panels[i].grouped:
					break
			return Vector2i(p.x - size.x - MARGIN, p.y)
		_: # SEPARATED:
			var y_max = 0
			for i in min(10, existing_panels.size()):
				y_max = max(y_max, existing_panels[-(i+1)].y_bottom)
			return Vector2i(
				last_panel.x_center - size.x / 2,
				y_max + MARGIN)


func _to_string() -> String:
	return "CartoonLayout(%d, %.2f)" % [type, scale]


## 情報をファイルに読み込む。
func read_file(file :FileAccess):
	specified = file.get_8() != 0
	type = file.get_8()
	scale = file.get_float()


## 情報をファイルに書き込む。
func write_file(file :FileAccess):
	file.store_8(1 if specified else 0)
	file.store_8(type)
	file.store_float(scale)
