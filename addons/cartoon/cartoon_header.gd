## 各シーンの見出し情報を扱うためのクラス。
extends RefCounted
class_name CartoonHeader


## 見出しの名前。
var header_name :LocalizedString

## 見出しの説明文。
var header_description :LocalizedString

## このシーンが開始する CartoonPlayer 上のコマのインデックス。
var panel_index :int

## このシーンが開始する時点での時間カウント値。
var time_count :int

## このシーンが開始する時点でのループ回数。
var loop_count :int


## ファイルから情報を読み込む。
func read_file(fin :FileAccess):
	header_name = LocalizedString.create_from_text_key(fin.get_pascal_string())
	header_description = LocalizedString.create_from_text_key(fin.get_pascal_string())
	panel_index = fin.get_32()
	time_count = fin.get_32()
	loop_count = fin.get_32()


## 情報をファイルに書き出す。
func write_file(fout :FileAccess):
	assert(header_name != null)
	assert(header_description != null)
	fout.store_pascal_string(header_name.text_key)
	fout.store_pascal_string(header_description.text_key)
	fout.store_32(panel_index)
	fout.store_32(time_count)
	fout.store_32(loop_count)


## 見出しテキストを返す。
func get_header_name():
	return header_name.text


## 見出しの説明文テキストを返す。
func get_header_description() -> String:
	return header_description.text.replace("<br>", "\n")
