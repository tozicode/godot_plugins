## 各コマで鳴らすサウンドについての情報を扱うためのクラス。
extends Resource
class_name CartoonAudio

## 再生するオーディオ。
@export
var stream :AudioStream

## コマを表示してから再生を開始するまでの時間。
@export_range(0.0, 1.0)
var delay :float = 0.0

## ピッチスケールの振れ幅。
@export_range(0.0, 1.0)
var pitch_scale_amplitude :float = 0.0


## ファイルから情報を読み込む。
func read_file(fin :FileAccess):
	var resource_path = fin.get_pascal_string()
	if not resource_path.is_empty():
		stream = load(resource_path) as AudioStream
	delay = fin.get_float()
	pitch_scale_amplitude = fin.get_float()


## ファイルに情報を書き込む。
func write_file(fout :FileAccess):
	fout.store_pascal_string(stream.resource_path if stream != null else "")
	fout.store_float(delay)
	fout.store_float(pitch_scale_amplitude)


## 再生するオーディオが無ければ true を返す。
func is_empty() -> bool:
	return stream == null
