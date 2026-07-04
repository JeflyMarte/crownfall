class_name EventData
extends Resource

## 期間限定バフイベント定義（P3-EVT-HUB）。端末日付（JST 5:00 境界）で開催。

@export var id: String = ""
@export var title: String = ""
@export var tag_text: String = "期間限定"
@export var banner_desc: String = ""
@export_multiline var description: String = ""
## exp / gold / weapon_drop
@export var modifier_type: String = ""
@export var modifier_mult: float = 1.5
## 開始日（この日 5:00 JST から有効・YYYY-MM-DD）
@export var start_date_jst: String = ""
## 終了日（この日 5:00 JST で終了・未満まで有効・YYYY-MM-DD）
@export var end_date_jst: String = ""
