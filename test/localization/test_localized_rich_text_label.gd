## LocalizedRichTextLabel コンポーネントのユニットテスト。
extends GutTest

var localization: Node


func before_each():
	# Localization オートロードをシミュレート
	localization = load("res://addons/localization/localization.gd").new()
	localization.name = "Localization"
	get_tree().root.add_child(localization)
	# テスト用データを登録
	localization.register_string("rtl_test", "リッチテキストテスト")
	localization.register_string("rtl_hello", "こんにちは")


func after_each():
	localization.queue_free()


## LocalizedRichTextLabel のインスタンスが作成できることを確認。
func test_create_instance():
	var rtl = LocalizedRichTextLabel.new()
	assert_not_null(rtl, "インスタンスが作成できること")
	assert_eq(rtl.text_key, "_undefined_", "デフォルトの text_key は _undefined_")
	rtl.free()


## text_key を設定すると Localization から文字列が取得されることを確認。
func test_text_key_updates_text():
	var rtl = LocalizedRichTextLabel.new()
	add_child(rtl)
	rtl.text_key = "rtl_test"
	assert_eq(rtl.text, "リッチテキストテスト", "text_key 設定時に text が更新されること")
	rtl.queue_free()


## 言語変更時にテキストが再取得されることを確認。
func test_language_change_updates_text():
	localization._strings["rtl_lang"] = PackedStringArray(["日本語", "English"])
	var rtl = LocalizedRichTextLabel.new()
	add_child(rtl)
	rtl.text_key = "rtl_lang"
	assert_eq(rtl.text, "日本語", "日本語のテキストが表示されること")
	localization.language_type = 1
	assert_eq(rtl.text, "English", "言語変更後に英語テキストが表示されること")
	localization.language_type = 0
	rtl.queue_free()


## text_key 未設定の場合、ランタイムで設定した text が維持されることを確認。
func test_runtime_text_without_key():
	var rtl = LocalizedRichTextLabel.new()
	add_child(rtl)
	rtl.text = "ランタイムテキスト"
	localization.language_type = 1
	assert_eq(rtl.text, "ランタイムテキスト", "text_key 未設定なら text は変更されないこと")
	localization.language_type = 0
	rtl.queue_free()


## 存在しないキーの場合は text が更新されないことを確認。
func test_missing_key_does_not_update():
	var rtl = LocalizedRichTextLabel.new()
	rtl.text = "元のテキスト"
	add_child(rtl)
	rtl.text_key = "nonexistent_key"
	assert_eq(rtl.text, "元のテキスト", "存在しないキーでは text は変更されないこと")
	rtl.queue_free()
