class_name SurveyStaff
extends RefCounted

## 調査室専用スタッフ（戦闘ロスター外・P3-SURVEY-STAFF-001）。

const ID_NINA: String = "staff_nina"
const ID_NONOKA: String = "staff_nonoka"

## おまかせ時のスタッフ優先順（先頭1人を採用）。
const AUTO_PRIORITY: Array[String] = [ID_NONOKA, ID_NINA]

## 研究速度（戦闘ステ非依存）。担当一致で +ROLE。
const STAFF_SPEED_BASE: float = 0.10

const _DEFS: Dictionary = {
	ID_NINA: {
		"display_name": "ニーナ",
		"job_label": "記録官",
		"preferred_role": "documents",
		"icon_path": "res://assets/npc/ICO_NPC_Nina.png",
		"portrait_path": "res://assets/npc/ART_NPC_Nina.png",
	},
	ID_NONOKA: {
		"display_name": "ノノカ",
		"job_label": "研究員",
		"preferred_role": "archaeology",
		"icon_path": "res://assets/npc/ICO_NPC_Nonoka.png",
		"portrait_path": "res://assets/npc/ART_NPC_Nonoka.png",
	},
}


static func is_staff_id(member_id: String) -> bool:
	return _DEFS.has(member_id)


static func all_ids() -> Array[String]:
	return AUTO_PRIORITY.duplicate()


static func display_name(member_id: String) -> String:
	return str(_DEFS.get(member_id, {}).get("display_name", member_id))


static func job_label(member_id: String) -> String:
	return str(_DEFS.get(member_id, {}).get("job_label", "調査スタッフ"))


static func preferred_role(member_id: String) -> String:
	return str(_DEFS.get(member_id, {}).get("preferred_role", "documents"))


static func icon_path(member_id: String) -> String:
	return str(_DEFS.get(member_id, {}).get("icon_path", ""))


static func portrait_path(member_id: String) -> String:
	return str(_DEFS.get(member_id, {}).get("portrait_path", ""))


static func load_icon_texture(member_id: String) -> Texture2D:
	var path: String = icon_path(member_id)
	if path.is_empty():
		path = portrait_path(member_id)
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	if FileAccess.file_exists(path):
		var img := Image.load_from_file(path)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null
