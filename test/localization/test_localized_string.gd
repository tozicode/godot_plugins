## LocalizedString リソースクラスのユニットテスト。
extends GutTest


## LocalizedString のインスタンスが作成できることを確認。
func test_create_instance():
	var ls = LocalizedString.new()
	assert_not_null(ls, "インスタンスが作成できること")
	assert_eq(ls.text_key, "_undefined_", "デフォルトの text_key は _undefined_")
	assert_eq(ls.text, "", "デフォルトの text は空文字列")


## text プロパティの設定と取得を確認。
func test_set_text():
	var ls = LocalizedString.new()
	ls.text = "テスト文字列"
	assert_eq(ls.text, "テスト文字列", "text が設定できること")


## text_key プロパティの設定と取得を確認。
func test_set_text_key():
	var ls = LocalizedString.new()
	ls.text_key = "item:sword:name"
	assert_eq(ls.text_key, "item:sword:name", "text_key が設定できること")


## create_from_text_key スタティック関数を確認。
func test_create_from_text_key():
	var ls = LocalizedString.create_from_text_key("event:opening:header")
	assert_not_null(ls, "スタティック関数でインスタンスが作成できること")
	assert_eq(ls.text_key, "event:opening:header", "text_key が正しく設定されること")


## changed シグナルが text 変更時に発行されることを確認。
func test_changed_signal_on_text_change():
	var ls = LocalizedString.new()
	watch_signals(ls)
	ls.text = "新しいテキスト"
	assert_signal_emitted(ls, "changed", "text 変更時に changed シグナルが発行されること")


## changed_text_key シグナルが text_key 変更時に発行されることを確認。
func test_changed_text_key_signal():
	var ls = LocalizedString.new()
	watch_signals(ls)
	ls.text_key = "new_key"
	assert_signal_emitted(ls, "changed_text_key", "text_key 変更時に changed_text_key シグナルが発行されること")


## get_text_replaced で辞書置換ができることを確認。
func test_get_text_replaced():
	var ls = LocalizedString.new()
	ls.text = "{name}が{item}を手に入れた"
	var result = ls.get_text_replaced({"name": "勇者", "item": "聖剣"})
	assert_eq(result, "勇者が聖剣を手に入れた", "辞書置換が正しく動作すること")
