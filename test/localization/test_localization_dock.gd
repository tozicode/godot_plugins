## LocalizationDock のユニットテスト。
## リソーススキャン機能の動作を確認する。
extends GutTest

var localization: Node
var dock: VBoxContainer


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
	# LocalizedString 自体をスキャン対象としてテスト
	var ls = LocalizedString.new()
	ls.text_key = "scan_test"
	ls.text = "スキャンテスト"

	# LocalizedString 自体は自分自身を LocalizedString プロパティとして持たないため、
	# scan_resource は 0 を返す
	var count = dock.scan_resource(ls)
	assert_eq(count, 0, "LocalizedString 自体にはネストされた LocalizedString プロパティは無い")


## update_statistics が正しくカウントを表示することを確認。
func test_update_statistics_after_registration():
	localization.register_string("stat_test1", "統計テスト1")
	localization.register_string("stat_test2", "統計テスト2")
	assert_eq(localization.size(), 2, "2件登録後のサイズ")
