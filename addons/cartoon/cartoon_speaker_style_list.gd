## 話者スタイルのリストを保持するリソース。
## ProjectSettings の cartoon/speaker_styles_path に設定するリソースとして使用する。
extends Resource
class_name CartoonSpeakerStyleList

@export
var styles :Array[CartoonSpeakerStyle] = []
