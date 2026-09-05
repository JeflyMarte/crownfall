class_name UltimateSkillResolver
extends RefCounted

## キャラ／助っ人必殺の解決（P3-BAL-CHAR-ULTIMATE-001 / Decision 138）。
## 優先: Adventurer.ultimate_skill_id → ガチャ助っ人 → JobData → DEFAULT。

const _STARTER_ULTIMATES: Dictionary = {
	"adventurer_0": "ouga_retsudan", ## アルド＝王炎断
	"adventurer_1": "mark_shot", ## リーヴァ＝マークショット
	"adventurer_2": "elemental_boost", ## エリアス＝エレメンタルブースト
	"adventurer_3": "titan_roar", ## ガレン＝聖盾咆哮
	"adventurer_4": "beast_dominion", ## ミレイ＝毒牙の嵐
}


static func starter_ultimate_id(adventurer_id: String) -> String:
	return str(_STARTER_ULTIMATES.get(adventurer_id, ""))


static func resolve_ultimate_skill_id(member: Resource) -> String:
	if member == null:
		return ""
	var adv_id: String = str(member.id)
	if Constants.is_pet_id(adv_id):
		return ""
	if "ultimate_skill_id" in member and not str(member.ultimate_skill_id).is_empty():
		return str(member.ultimate_skill_id)
	if _STARTER_ULTIMATES.has(adv_id):
		return str(_STARTER_ULTIMATES[adv_id])
	if adv_id.begins_with("gacha_"):
		var helper: Resource = DataRegistry.get_gacha_helper_data(adv_id.trim_prefix("gacha_"))
		if helper != null and "ultimate_skill_id" in helper and not str(helper.ultimate_skill_id).is_empty():
			return str(helper.ultimate_skill_id)
	var job_id: String = str(member.job_id)
	if not job_id.is_empty():
		var job: Resource = DataRegistry.get_job_data(job_id)
		if job != null and "ultimate_skill_id" in job and not str(job.ultimate_skill_id).is_empty():
			return str(job.ultimate_skill_id)
	return Constants.DEFAULT_ULTIMATE_SKILL_ID


static func resolve_ultimate_skill(member: Resource) -> Resource:
	var ult_id: String = resolve_ultimate_skill_id(member)
	if ult_id.is_empty():
		return null
	return DataRegistry.get_skill_data(ult_id)
