## 話者ごとの吹き出しスタイルを定義するリソース。
extends Resource
class_name CartoonSpeakerStyle

## 話者の識別名。
## CartoonSpeech.speaker_id をインスペクターで選択する際の表示ラベルとして使われる。
## 空文字列の場合は "SPEAKER_<index>" の形にフォールバックする。
@export
var name :StringName = &""

## 吹き出しフレームの色。
@export
var frame_color :Color = Color.WHITE

## ラベルの色・アウトライン・影などを定義する設定。
## フォントとフォントサイズは Theme から取得するため、ここで指定しても無視される。
## (Theme の解決順は label.theme → 親 → ルート Theme)
@export
var label_settings :LabelSettings

## 話者ごとにフォントを切替えたい場合、Localization の theme_styles に登録した
## スタイル名（例: "cartoon_speaker_a"）を指定する。
## 空文字列の場合はデフォルトの "cartoon" スタイル Theme が使われる。
@export
var theme_style_name :String = ""
