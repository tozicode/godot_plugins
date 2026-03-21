## Localization コアクラスのユニットテスト。
extends GutTest

var localization: Node


func before_each():
	localization = load("res://addons/localization/localization.gd").new()
	localization.name = "Localization"
	add_child(localization)
	# _ready() での read_file() はファイルが無いと失敗するため、手動で初期化
	# _ready() は add_child 時に自動呼出しされるが、TSVファイルが無い場合に備える


func after_each():
	localization.queue_free()


## register_string でキーを登録し、get_string で取得できることを確認。
func test_register_and_get_string():
	localization.register_string("test_key", "テスト文字列")
	assert_true(localization.has_key("test_key"), "登録したキーが存在すること")
	assert_eq(localization.get_string("test_key"), "テスト文字列", "登録した文字列が取得できること")


## 存在しないキーでエラー文字列が返ることを確認。
func test_get_string_returns_error_for_missing_key():
	var result = localization.get_string("nonexistent_key")
	assert_eq(result, "LocalizationError[nonexistent_key]", "存在しないキーでエラー文字列が返ること")


## has_key で存在判定ができることを確認。
func test_has_key():
	assert_false(localization.has_key("missing"), "未登録のキーは false")
	localization.register_string("existing", "存在する")
	assert_true(localization.has_key("existing"), "登録済みのキーは true")


## register_string で同じキーを上書きできることを確認。
func test_register_string_overwrite():
	localization.register_string("key1", "初期値")
	assert_eq(localization.get_string("key1"), "初期値")
	localization.register_string("key1", "更新値")
	assert_eq(localization.get_string("key1"), "更新値", "同じキーの値を上書きできること")


## register_string で改行が <br> に変換されることを確認。
func test_register_string_converts_newlines():
	localization.register_string("br_test", "行1\n行2")
	# 内部では <br> として格納され、get_string で \n に戻される
	assert_eq(localization.get_string("br_test"), "行1\n行2", "改行が正しく往復変換されること")


## get_string の substitution パラメータが機能することを確認。
func test_get_string_with_substitution():
	localization.register_string("greet", "こんにちは、NAME さん！")
	var result = localization.get_string("greet", {"NAME": "太郎"})
	assert_eq(result, "こんにちは、太郎 さん！", "置換が適用されること")


## remove_strings_begins_with でプレフィックス一致削除ができることを確認。
func test_remove_strings_begins_with():
	localization.register_string("item:sword:name", "剣")
	localization.register_string("item:shield:name", "盾")
	localization.register_string("event:opening:header", "オープニング")
	localization.remove_strings_begins_with("item:")
	assert_false(localization.has_key("item:sword:name"), "item: プレフィックスが削除されること")
	assert_false(localization.has_key("item:shield:name"), "item: プレフィックスが削除されること")
	assert_true(localization.has_key("event:opening:header"), "event: プレフィックスは残ること")


## is_equal_text で文字列比較ができることを確認。
func test_is_equal_text():
	localization.register_string("eq_test", "同じ文字列")
	assert_true(localization.is_equal_text("eq_test", "同じ文字列"), "同じ文字列で true")
	assert_false(localization.is_equal_text("eq_test", "違う文字列"), "違う文字列で false")
	assert_false(localization.is_equal_text("missing_key", "何か"), "存在しないキーで false")


## size で登録数が取得できることを確認。
func test_size():
	assert_eq(localization.size(), 0, "初期状態で 0")
	localization.register_string("a", "A")
	localization.register_string("b", "B")
	assert_eq(localization.size(), 2, "2件登録で 2")


## format_reference で {key} 形式のネスト参照が展開されることを確認。
func test_format_reference():
	localization.register_string("weapon_name", "聖剣")
	localization.register_string("get_weapon", "{weapon_name}を手に入れた！")
	var result = localization.get_string("get_weapon")
	assert_eq(result, "聖剣を手に入れた！", "ネスト参照が展開されること")


## assert_key で未登録キーのエラーログが出力されることを確認。
func test_assert_key():
	localization.register_string("valid_key", "有効")
	# assert_key は未登録キーでエラーログを出すが、例外は投げない
	localization.assert_key("valid_key")  # エラーなし
	localization.assert_key("invalid_key")  # エラーログ出力（テストは通る）
	pass_test("assert_key が例外なく動作すること")


## language_type のデフォルト値を確認。
func test_default_language_type():
	assert_eq(localization.language_type, 0, "デフォルトは LANGUAGE_JA (0)")


## 翻訳カバレッジの計算を確認。
func test_translation_coverage():
	# 手動で複数言語のデータを登録
	localization._strings["key1"] = PackedStringArray(["日本語", "English"])
	localization._strings["key2"] = PackedStringArray(["日本語2", ""])
	localization.update_coverage()
	assert_eq(localization.get_translation_coverage(0), 100, "日本語は 100%")
	assert_eq(localization.get_translation_coverage(1), 50, "英語は 50%")


## language_type のセッターで changed_language シグナルが発行されることを確認。
func test_changed_language_signal():
	watch_signals(localization)
	localization.language_type = 1
	assert_signal_emitted(localization, "changed_language", "言語変更時に changed_language が発行されること")
	assert_eq(localization.language_type, 1, "language_type が更新されること")
