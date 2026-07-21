class_name EventData
extends Resource

## 期間限定バフイベント定義（P3-EVT-HUB）。端末日付（JST 5:00 境界）で開催。

@export var id: String = ""
@export var title: String = ""
@export var tag_text: String = "期間限定"
@export var banner_desc: String = ""
@export_multiline var description: String = ""
## exp / gold / weapon_drop / codex / featured_biome / elite_material
## + none / weather / wander_duck / wander_raven / enemy_level / swarm / elite_rooms（P3-EVT-FIELD-001）
@export var modifier_type: String = ""
@export var modifier_mult: float = 1.5
## featured_biome のみ — 報酬ボーナス対象 Biome（空=全体）
@export var featured_biome_id: String = ""
## weather スロットのみ — rain / night / fog
@export var weather_id: String = ""
## 開始（JST 日付または日時文字列）
@export var start_date_jst: String = ""
## 終了（JST 日付または日時文字列）
@export var end_date_jst: String = ""
