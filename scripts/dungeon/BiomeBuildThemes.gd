class_name BiomeBuildThemes
extends RefCounted

## 章別ビルドテーマ文言（P3-BAL-BIOME-BUILD-THEME-001）。
## 無限（abyss_*）は親 Biome の傾向を出す。曜日／イベントは空。

const _HINTS: Dictionary = {
	"mourngate": "傾向: 出血・継戦向き ／ 薄い編成は苦戦",
	"whisperwood": "傾向: 毒・出血のDoTで殻を削る ／ 瞬間火力のみは苦戦",
	"mistfen": "傾向: 異常耐性・高火力向き ／ 毒沼に薄い編成は苦戦",
	"blackshore": "傾向: ヴァンガード壁向き ／ 紙編成は苦戦",
	"frostridge": "傾向: 火属性・属性特化向き ／ 無属性鈍火力は苦戦",
}

## 章の象徴雑魚 id（P3-BAL-BIOME-BUILD-THEME-001-8）。UI非表示・テスト／照会用。
const SIGNATURE_ENEMY_IDS: Dictionary = {
	"mourngate": "skullface_mantis",
	"whisperwood": "moss_shell",
	"mistfen": "dead_poison_frog",
	"blackshore": "black_tide_shark",
	"frostridge": "frost_claw_raptor",
}

const _PARENT_ABYSS: Dictionary = {
	"abyss_mourngate": "mourngate",
	"abyss_whisperwood": "whisperwood",
	"abyss_mistfen": "mistfen",
	"abyss_blackshore": "blackshore",
	"abyss_frostridge": "frostridge",
}


static func resolve_biome_id(dungeon_id: String) -> String:
	if dungeon_id.is_empty():
		return ""
	if _HINTS.has(dungeon_id):
		return dungeon_id
	if _PARENT_ABYSS.has(dungeon_id):
		return str(_PARENT_ABYSS[dungeon_id])
	return ""


static func select_hint(dungeon_id: String) -> String:
	var biome_id: String = resolve_biome_id(dungeon_id)
	if biome_id.is_empty():
		return ""
	return str(_HINTS.get(biome_id, ""))
