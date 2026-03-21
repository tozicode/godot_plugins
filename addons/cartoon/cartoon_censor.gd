## モザイク種別を表すための列挙体と、それに関する関数群。
@tool
class_name CartoonCensor

enum {
	CENSOR_MOSAIC,
	CENSOR_BLACK,
	CENSOR_WHITE,
	CENSOR_TYPE_COUNT
}


## 指定のモザイク種別に対応する接尾辞を返す。
static func suffix(type):
	match type:
		CENSOR_MOSAIC:
			return "_mosaic"
		CENSOR_BLACK:
			return "_black"
		CENSOR_WHITE:
			return "_white"


## 文字列の末尾からモザイク種別を表す接尾辞を取り除いた結果を返す。
static func strip_censor_type(s):
	if s.ends_with("_mosaic"):
		return s.substr(0, s.length() - 7)
	if s.ends_with("_black"):
		return s.substr(0, s.length() - 6)
	if s.ends_with("_white"):
		return s.substr(0, s.length() - 6)
	return s
