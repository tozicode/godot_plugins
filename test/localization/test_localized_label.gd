## LocalizedLabel コンポーネントのユニットテスト。
extends GutTest

var localization: Node


func before_each():
	# Localization オートロードをシミュレート
	localization = load("res://addons/localization/localization.gd").new()
	localization.name = "Localization"
	get_tree().root.add_child(localization)
	# テスト用データを登録
	localization.register_string("label_test", "テストラベル")
	localization.register_string("label_hello", "こんにちは")


func after_each():
	localization.queue_free()


## LocalizedLabel のインスタンスが作成できることを確認。
func test_create_instance():
	var label = LocalizedLabel.new()
	assert_not_null(label, "インスタンスが作成できること")
	assert_eq(label.text_key, "_undefined_", "デフォルトの text_key は _undefined_")
	label.free()


## text_key を設定すると Localization から文字列が取得されることを確認。
func test_text_key_updates_text():
	var label = LocalizedLabel.new()
	add_child(label)
	label.text_key = "label_test"
	assert_eq(label.text, "テストラベル", "text_key 設定時に text が更新されること")
	label.queue_free()


## text_key を変更すると text も更新されることを確認。
func test_text_key_change_updates_text():
	var label = LocalizedLabel.new()
	add_child(label)
	label.text_key = "label_test"
	assert_eq(label.text, "テストラベル")
	label.text_key = "label_hello"
	assert_eq(label.text, "こんにちは", "text_key 変更時に text が更新されること")
	label.queue_free()


## 存在しないキーの場合は text が更新されないことを確認。
func test_missing_key_does_not_update():
	var label = LocalizedLabel.new()
	label.text = "元のテキスト"
	add_child(label)
	label.text_key = "nonexistent_key"
	assert_eq(label.text, "元のテキスト", "存在しないキーでは text は変更されないこと")
	label.queue_free()


## 言語変更時にテキストが再取得されることを確認。
func test_language_change_updates_text():
	# 複数言語のデータを登録
	localization._strings["lang_test"] = PackedStringArray(["日本語テスト", "English Test"])
	var label = LocalizedLabel.new()
	add_child(label)
	label.text_key = "lang_test"
	assert_eq(label.text, "日本語テスト", "日本語のテキストが表示されること")
	localization.language_type = 1
	assert_eq(label.text, "English Test", "言語変更後に英語テキストが表示されること")
	localization.language_type = 0
	label.queue_free()


## text_key 未設定の場合、ランタイムで設定した text が維持されることを確認。
func test_runtime_text_without_key():
	var label = LocalizedLabel.new()
	add_child(label)
	label.text = "ランタイムテキスト"
	# text_key は _undefined_ のまま
	localization.language_type = 1
	assert_eq(label.text, "ランタイムテキスト", "text_key 未設定なら text は変更されないこと")
	localization.language_type = 0
	label.queue_free()
