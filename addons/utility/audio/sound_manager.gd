## 効果音の再生を管理するシングルトン。
## オートロードとして登録して使用する。
extends Node

## 効果音ファイルが格納されているディレクトリパス。末尾スラッシュ付き。
var sound_dir := "res://audio/sound/"

## 使用するオーディオバス名。
var bus_name := "Sound"

## プレイヤープールのサイズ。同時再生可能な効果音の数。
var pool_size := 8

var _pool: Array[AudioStreamPlayer] = []


func _ready() -> void:
	_setup_bus()
	for i in pool_size:
		var player := AudioStreamPlayer.new()
		player.bus = bus_name
		add_child(player)
		_pool.append(player)


## 指定したパスの効果音を再生する。
## パスが相対パスの場合は sound_dir からの相対パスとして解決する。
## 例: play("click.wav") → sound_dir + "click.wav" を再生
func play(sound_path: String) -> void:
	var player := _get_free_player()
	if player == null:
		return
	player.stream = load(_resolve_path(sound_path))
	player.play()


## バスの音量を設定する。0〜100 の範囲で指定する。
func set_volume(value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(value / 100.0))


## 再生可能なプレイヤーを返す。すべて使用中の場合は null を返す。
func _get_free_player() -> AudioStreamPlayer:
	for player in _pool:
		if not player.playing:
			return player
	return null


## オーディオバスが存在しない場合に作成する。
func _setup_bus() -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


## パスを解決する。絶対パス（res:// や user://）はそのまま、相対パスは sound_dir を付与する。
func _resolve_path(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return path
	return sound_dir + path
