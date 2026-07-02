class_name JobEvolution
extends RefCounted

## ジョブ進化（到達形）— 英雄管理画面で手動昇格（P3-D037 / P3-D052）。
## Lv到達後、認定で Adventurer.is_evolved = true。補正深化と到達形名は
## JobStatCalculator が is_evolved を見て反映する（job_id は不変）。

## 進化可能か（進化先あり・Lv到達・未進化）。
static func can_evolve(adventurer: Resource) -> bool:
	if adventurer == null or bool(adventurer.is_evolved):
		return false
	var job_data: Resource = DataRegistry.get_job_data(str(adventurer.job_id))
	if job_data == null:
		return false
	if int(job_data.evolution_level) <= 0 or job_data.evolved_display_name.is_empty():
		return false
	return int(adventurer.level) >= int(job_data.evolution_level)

## 認定して進化。成功で true。
static func evolve(adventurer: Resource) -> bool:
	if not can_evolve(adventurer):
		return false
	adventurer.is_evolved = true
	return true

## 進化済みでなくとも到達形名を取得（UI 表示用）。なければ空文字。
static func get_evolved_name(adventurer: Resource) -> String:
	if adventurer == null:
		return ""
	var job_data: Resource = DataRegistry.get_job_data(str(adventurer.job_id))
	if job_data == null:
		return ""
	return str(job_data.evolved_display_name)

## 進化に必要なレベル（0 = 不可）。
static func required_level(adventurer: Resource) -> int:
	if adventurer == null:
		return 0
	var job_data: Resource = DataRegistry.get_job_data(str(adventurer.job_id))
	if job_data == null:
		return 0
	return int(job_data.evolution_level)
