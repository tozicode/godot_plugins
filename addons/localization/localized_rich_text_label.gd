## 言語設定によって文字列を変更する RichTextLabel。
## フォント・フォントサイズ・文字修飾はすべて Theme から適用される。
## text_key を設定しない場合は通常の RichTextLabel として使用可能（Theme のフォントのみ適用）。
## 文字修飾 (色・アウトライン・影) も Theme に統合する設計のため、label_settings は使用しない。
##
## テキスト中のバッククォート区間 (`+6` など) は number_theme_style で指定した Theme の
## フォントに置換される。数字を専用フォント (Playfair 等) で描画したいときに使う。
extends RichTextLabel
class_name LocalizedRichTextLabel

## テキストに対応するキー文字列。
@export
var text_key: String = "_undefined_":
	get: return text_key
	set(value):
		text_key = value
		update_text_by_key()

## 適用する Theme のスタイル名。空の場合はルートの Theme がそのまま適用される。
@export
var theme_style: String = "":
	set(value):
		theme_style = value
		_apply_style_theme()

## バッククォート区間 (`...`) に適用する Theme スタイル名。
## 空の場合は区間置換なし。"number" などの言語非依存スタイルで数字専用フォントに切り替える用途を想定。
@export
var number_theme_style: String = "":
	set(value):
		number_theme_style = value
		_reformat()

## set_formatted_text() で受け取った書式なし文字列のキャッシュ。
## 言語切替 / number_theme_style 更新時の再整形に使う。
var _raw_text: String = ""


func _ready():
	bbcode_enabled = true
	update_text_by_key()
	_apply_style_theme()
	if not Localization.changed_language.is_connected(_on_changed_language):
		Localization.changed_language.connect(_on_changed_language)


## 言語が変更されたときのコールバック。
func _on_changed_language():
	update_text_by_key()
	_apply_style_theme()
	_reformat()


## スタイルに対応する Theme を自身に適用する。
func _apply_style_theme():
	if theme_style.is_empty():
		theme = null
		return
	var t = Localization.get_theme(theme_style)
	if t == null:
		theme = null
		return
	theme = t


## 書式なしテキストを受け取り、backtick 展開を適用して text にセットする。
## 例: set_formatted_text("攻撃力`+6`") → "攻撃力[font=<num_font>][font_size=N]+6[/font_size][/font]"
## プログラムから動的に text を設定する場合はこの関数を使う (キャッシュに保存され、
## 言語切替時に自動で再整形される)。
func set_formatted_text(raw :String) -> void:
	_raw_text = raw
	text = _format(raw)


## number_theme_style が変更されたときに、キャッシュ済みの _raw_text から text を再生成する。
func _reformat() -> void:
	if _raw_text.is_empty():
		return
	text = _format(_raw_text)


## 書式なし文字列に backtick 展開を適用した文字列を返す。
## 色・アウトライン・影は Theme (RichTextLabel/colors/... 等) で自動適用される。
func _format(raw :String) -> String:
	return _wrap_number_segments(raw)


## キー文字列によって Localization から参照される文字列で text を更新する。
func update_text_by_key():
	if text_key == "_undefined_" or text_key.is_empty():
		return
	if Localization.has_key(text_key):
		var raw_text = Localization.get_string(text_key)
		set_formatted_text(raw_text)


## バッククォート区間 (`...`) を number_theme_style で指定した Theme のフォント BBCode で
## 置換する。number_theme_style が未指定 or Theme が見つからない場合はバッククォートを
## そのまま残す (誤って書式表示されるより素で見えるほうがデバッグしやすいため)。
func _wrap_number_segments(raw :String) -> String:
	if number_theme_style.is_empty():
		return raw
	var t :Theme = Localization.get_theme(number_theme_style)
	if t == null or t.default_font == null:
		return raw
	var font_path :String = t.default_font.resource_path
	var font_size :int = t.default_font_size
	var result :String = ""
	var pos :int = 0
	while true:
		var start :int = raw.find("`", pos)
		if start < 0:
			result += raw.substr(pos)
			break
		var stop :int = raw.find("`", start + 1)
		if stop < 0:
			# ペアで見つからない終端の ` はそのまま残す
			result += raw.substr(pos)
			break
		result += raw.substr(pos, start - pos)
		var segment :String = raw.substr(start + 1, stop - start - 1)
		if segment.length() > 0:
			result += (
				"[font=%s][font_size=%d]%s[/font_size][/font]"
				% [font_path, font_size, segment])
		pos = stop + 1
	return result
