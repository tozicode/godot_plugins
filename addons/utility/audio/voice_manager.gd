## ボイスの再生を管理するシングルトン。
## オートロードとして登録して使用する。
extends Node

## ボイスファイルが格納されているディレクトリパス。末尾スラッシュ付き。
var voice_dir := "res://audio/voice/"

## 使用するオーディオバス名。
var bus_name := "Voice"

var _player: AudioStreamPlayer


func _ready() -> void:
	_setup_bus()
	_player = AudioStreamPlayer.new()
	_player.bus = bus_name
	add_child(_player)


## 指定したパスのボイスを再生する。
## 再生中のボイスがある場合は即座に停止してから再生を開始する。
## パスが相対パスの場合は voice_dir からの相対パスとして解決する。
## 例: play("intro_001.wav") → voice_dir + "intro_001.wav" を再生
func play(path: String) -> void:
	_player.stop()
	_player.stream = load(_resolve_path(path))
	_player.play()


## 再生中のボイスを停止する。
func stop() -> void:
	_player.stop()


## バスの音量を設定する。0〜100 の範囲で指定する。
func set_volume(value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(value / 100.0))


## オーディオバスが存在しない場合に作成する。
func _setup_bus() -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


## パスを解決する。絶対パス（res:// や user://）はそのまま、相対パスは voice_dir を付与する。
func _resolve_path(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return path
	return voice_dir + path
