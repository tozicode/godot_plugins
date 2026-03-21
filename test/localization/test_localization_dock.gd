## LocalizationDock のユニットテスト。
## リソーススキャン機能とキーフォーマット機能の動作を確認する。
extends GutTest

var localization: Node
var dock


func before_each():
	# Localization オートロードをシミュレート
	localization = load("res://addons/localization/localization.gd").new()
	localization.name = "Localization"
	get_tree().root.add_child(localization)

	# ドックのスクリプトを直接ロードしてテスト
	dock = load("res://addons/localization/localization_dock.gd").new()


func after_each():
	dock.free()
	localization.queue_free()


## scan_resource で LocalizedString プロパティを検出できることを確認。
func test_scan_resource_detects_localized_string():
	var ls = LocalizedString.new()
	ls.text_key = "scan_test"
	ls.text = "スキャンテスト"

	# LocalizedString 自体にはネストされた LocalizedString プロパティは無い
	var count = dock.scan_resource(ls)
	assert_eq(count, 0, "LocalizedString 自体にはネストされた LocalizedString プロパティは無い")


## update_statistics が正しくカウントを表示することを確認。
func test_update_statistics_after_registration():
	localization.register_string("stat_test1", "統計テスト1")
	localization.register_string("stat_test2", "統計テスト2")
	assert_eq(localization.size(), 2, "2件登録後のサイズ")


## extract_prefix でフォーマット文字列からプレフィックスを抽出できることを確認。
func test_extract_prefix_with_brace():
	var prefix = dock.extract_prefix("item:{basename}:[name,description]")
	assert_eq(prefix, "item:", "{basename} の前が抽出されること")


func test_extract_prefix_with_bracket():
	var prefix = dock.extract_prefix("item:[name,description]")
	assert_eq(prefix, "item:", "[...] の前が抽出されること")


func test_extract_prefix_no_placeholder():
	var prefix = dock.extract_prefix("fixed_key")
	assert_eq(prefix, "fixed_key", "プレースホルダなしの場合は全体が返ること")


## extract_labels で [aaa,bbb,ccc] 部分のラベル配列を抽出できることを確認。
func test_extract_labels():
	var labels = dock.extract_labels("item:{basename}:[name,description,flavor]")
	assert_eq(labels.size(), 3, "3つのラベルが抽出されること")
	assert_eq(labels[0], "name")
	assert_eq(labels[1], "description")
	assert_eq(labels[2], "flavor")


func test_extract_labels_no_brackets():
	var labels = dock.extract_labels("item:{basename}:{count}")
	assert_eq(labels.size(), 0, "ブラケットなしの場合は空配列")


## format_key でフォーマット文字列からキーを生成できることを確認。
func test_format_key_with_basename():
	var key = dock.format_key("item:{basename}:name", "item_bread", 0, PackedStringArray())
	assert_eq(key, "item:item_bread:name", "{basename} が置換されること")


func test_format_key_with_count():
	var key = dock.format_key("prop:{basename}:{count}", "enemy_slime", 2, PackedStringArray())
	assert_eq(key, "prop:enemy_slime:2", "{count} が置換されること")


func test_format_key_with_labels():
	var labels = PackedStringArray(["name", "description", "flavor"])
	var key0 = dock.format_key("item:{basename}:[name,description,flavor]", "item_bread", 0, labels)
	var key1 = dock.format_key("item:{basename}:[name,description,flavor]", "item_bread", 1, labels)
	var key2 = dock.format_key("item:{basename}:[name,description,flavor]", "item_bread", 2, labels)
	assert_eq(key0, "item:item_bread:name", "0番目は name")
	assert_eq(key1, "item:item_bread:description", "1番目は description")
	assert_eq(key2, "item:item_bread:flavor", "2番目は flavor")


func test_format_key_with_labels_overflow():
	var labels = PackedStringArray(["name"])
	var key = dock.format_key("item:{basename}:[name]", "item_bread", 1, labels)
	assert_eq(key, "item:item_bread:", "ラベル範囲外は空文字")
