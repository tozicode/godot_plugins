## BGM の再生を管理するシングルトン。
## オートロードとして登録して使用する。
extends Node

## BGM ファイルが格納されているディレクトリパス。末尾スラッシュ付き。
var music_dir := "res://audio/music/"

## 使用するオーディオバス名。
var bus_name := "BGM"

## フェードアウトの所要時間（秒）。
var fade_out_duration := 1.5

var _player: AudioStreamPlayer
var _fade_tween: Tween


func _ready() -> void:
	_setup_bus()
	_player = AudioStreamPlayer.new()
	_player.bus = bus_name
	add_child(_player)


## 指定したパスの BGM を再生する。
## パスが相対パスの場合は music_dir からの相対パスとして解決する。
## 例: play("title.ogg") → music_dir + "title.ogg" を再生
func play(path: String) -> void:
	_cancel_fade()
	_player.stop()
	_player.volume_db = 0.0
	_player.stream = load(_resolve_path(path))
	_player.play()


## 再生中の BGM をフェードアウトさせて停止する。
func stop() -> void:
	if not _player.playing:
		return
	_cancel_fade()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_player, "volume_db", -80.0, fade_out_duration)
	_fade_tween.tween_callback(_player.stop)
	_fade_tween.tween_callback(func() -> void: _player.volume_db = 0.0)


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


## パスを解決する。絶対パス（res:// や user://）はそのまま、相対パスは music_dir を付与する。
func _resolve_path(path: String) -> String:
	if path.begins_with("res://") or path.begins_with("user://"):
		return path
	return music_dir + path


func _cancel_fade() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
		_fade_tween = null
