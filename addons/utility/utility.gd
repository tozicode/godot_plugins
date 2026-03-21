class_name Utility

const MAX_8BIT = 1 << 8
const MAX_7BIT = 1 << 7
const MAX_16BIT = 1 << 16
const MAX_15BIT = 1 << 15
const MAX_32BIT = 1 << 32
const MAX_31BIT = 1 << 31

## 秒数を時間・分・秒に分割するためのクラス。
class PlayTime:
	var hour :int
	var minute :int
	var second :int
	func _init(seconds :int):
		hour = int(seconds / 3600)
		minute = int((seconds % 3600) / 60)
		second = seconds % 60


## 指定ノードの子を全て削除する。
static func erase_all_children_of(node :Node):
	while node.get_child_count() > 0:
		var child = node.get_child(0)
		node.remove_child(child)
		child.queue_free()


## 指定のノードとその子孫の owner を再帰的に設定する。
static func set_scene_owner_recursively(node :Node):
	node.set_owner(EditorInterface.get_edited_scene_root())
	for child in node.get_children():
		set_scene_owner_recursively(child)


## ファイルから Vector2 インスタンスを読み込んで返す。
static func read_vector2(fin :FileAccess) -> Vector2:
	return Vector2(fin.get_float(), fin.get_float())


## ファイルに Vector2 インスタンスを書き出す。
static func write_vector2(fout :FileAccess, vec :Vector2):
	fout.store_float(vec.x)
	fout.store_float(vec.y)


## ファイルから Vector2i インスタンスを読み込んで返す。
static func read_vector2i(fin :FileAccess) -> Vector2i:
	return Vector2i(
		unsigned_to_signed_32(fin.get_32()),
		unsigned_to_signed_32(fin.get_32()))


## ファイルに Vector2i インスタンスを書き出す。
static func write_vector2i(fout :FileAccess, vec :Vector2i):
	fout.store_32(vec.x)
	fout.store_32(vec.y)


## "2,3" のような文字列から Vector2i を生成して返す。
static func string_to_vector2i(str :String) -> Vector2i:
	var csv = str.split(",")
	assert(csv.size() == 2)
	return Vector2i(int(csv[0]), int(csv[1]))


## 8bit長の符号なし整数を符号つき整数に変換して返す。
static func unsigned_to_signed_8(unsigned :int) -> int:
	return (unsigned + MAX_7BIT) % MAX_8BIT - MAX_7BIT


## 16bit長の符号なし整数を符号つき整数に変換して返す。
static func unsigned_to_signed_16(unsigned :int) -> int:
	return (unsigned + MAX_15BIT) % MAX_16BIT - MAX_15BIT


## 32bit長の符号なし整数を符号つき整数に変換して返す。
static func unsigned_to_signed_32(unsigned :int) -> int:
	return (unsigned + MAX_31BIT) % MAX_32BIT - MAX_31BIT
