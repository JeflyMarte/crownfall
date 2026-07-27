class_name JobEvolution
extends RefCounted

## ジョブ進化（到達形）— 英雄管理／ギルド認定（P3-D037 / P3-D052）。
## βでは Constants.JOB_EVOLUTION_PLAYABLE=false で完全オミット（P3-JOB-EVO-OMIT-001）。
## データ・セーブの is_evolved は残置するが、効果・UI・新規認定は出さない。

static func is_playable() -> bool:
	return Constants.JOB_EVOLUTION_PLAYABLE


## 進化可能か（進化先あり・Lv到達・未進化）。オミット時は常に false。
static func can_evolve(adventurer: Resource) -> bool:
	if not is_playable():
		return false
	if adventurer == null or bool(adventurer.is_evolved):
		return false
	var job_data: Resource = DataRegistry.get_job_data(str(adventurer.job_id))
	if job_data == null:
		return false
	if int(job_data.evolution_level) <= 0 or job_data.evolved_display_name.is_empty():
		return false
	return int(adventurer.level) >= int(job_data.evolution_level)


## 認定して進化。成功で true。オミット時は常に false。
static func evolve(adventurer: Resource) -> bool:
	if not is_playable():
		return false
	if not can_evolve(adventurer):
		return false
	adventurer.is_evolved = true
	return true


## 進化済みでなくとも到達形名を取得（UI 表示用）。オミット時は空。
static func get_evolved_name(adventurer: Resource) -> String:
	if not is_playable():
		return ""
	if adventurer == null:
		return ""
	var job_data: Resource = DataRegistry.get_job_data(str(adventurer.job_id))
	if job_data == null:
		return ""
	return str(job_data.evolved_display_name)


## 進化に必要なレベル（0 = 不可）。オミット時は 0。
static func required_level(adventurer: Resource) -> int:
	if not is_playable():
		return 0
	if adventurer == null:
		return 0
	var job_data: Resource = DataRegistry.get_job_data(str(adventurer.job_id))
	if job_data == null:
		return 0
	return int(job_data.evolution_level)
