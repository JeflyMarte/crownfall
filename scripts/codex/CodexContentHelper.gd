class_name CodexContentHelper
extends RefCounted

## 図鑑表示用テキスト生成（武器・ダンジョン等）。

const WEAPON_TYPE_NAMES: Dictionary = {
	"greatsword": "大剣",
	"bow": "弓",
	"staff": "杖",
	"dual_blades": "双刃",
	"dagger": "短刃",
}

const ELEMENT_NAMES: Dictionary = {
	"fire": "炎",
	"ice": "氷",
	"thunder": "雷",
	"holy": "聖",
	"dark": "闇",
}

const RARITY_NAMES: Array[String] = ["通常", "上質", "希少", "伝説"]

const DUNGEON_CODEX_META: Dictionary = {
	"mourngate": {
		"location": "王都アステリア・地下封印区画",
		"exploration_theme": "闇属性有利・遺構回収",
		"related_history": ["HE-007", "HE-001"],
	},
	"astoria_ruins": {
		"location": "王都アステリア外郭",
		"exploration_theme": "廃墟踏破・歴史調査",
		"related_history": ["HE-007", "HE-005"],
	},
	"whisperwood": {
		"location": "大陸西部ヴェルディア・原生林",
		"exploration_theme": "炎属性有利・森の生態調査",
		"related_history": ["HE-004", "HE-009"],
	},
	"green_hollow": {
		"location": "翠の湿地帯",
		"exploration_theme": "雷属性有利・湿地探索",
		"related_history": ["HE-004"],
	},
	"mistfen": {
		"location": "霧沼地帯・ミストフェン",
		"exploration_theme": "雷属性有利・沼地踏破",
		"related_history": ["HE-003", "HE-004"],
	},
	"broken_marsh": {
		"location": "崩落街道橋・旧王都街道",
		"exploration_theme": "雷属性有利・寄り道ルート",
		"related_history": ["HE-009", "HE-007"],
	},
	"blackshore": {
		"location": "沈没航路・ブラックショア",
		"exploration_theme": "聖属性有利・海底遺構",
		"related_history": ["HE-004", "HE-005"],
	},
	"westbay_flats": {
		"location": "ウェストベイ干潟",
		"exploration_theme": "聖属性有利・潮間帯探索",
		"related_history": ["HE-004"],
	},
	"frostridge": {
		"location": "最果て・氷裂フロストリッジ",
		"exploration_theme": "氷属性有利・極寒踏破",
		"related_history": ["HE-005", "HE-004"],
	},
	"frostwall_path": {
		"location": "フロストウォール・雪道",
		"exploration_theme": "氷属性有利・雪原縦断",
		"related_history": ["HE-004"],
	},
}

const WEAPON_BIOME_FLAVOR: Array[Dictionary] = [
	{"keys": ["mourngate", "sepia", "rune", "crown", "clock", "crystal_hedgehog", "relic", "sanctified", "consecrated", "heater", "rusted", "iron_sword"], "text": "王都地下モーンゲート一帯で流通する装備。"},
	{"keys": ["verd", "moss", "bark", "pyre", "tinder", "willow", "symbiont", "mist_piercer", "silvaria", "veld", "granvel", "wyvern", "spore", "warden"], "text": "囁きの森ウィスパーウッドの探索で手に入る。"},
	{"keys": ["bog", "leech", "mire", "driftwood", "fen", "carapace", "thunderfen", "volt", "volgrave", "seradion", "moldgar", "marsh"], "text": "霧沼ミストフェン由来の装備。"},
	{"keys": ["black", "pharos", "nerei", "barnacle", "brine", "ship", "skull", "undertaker", "samurai", "ninja", "tide", "kelp", "sanctum"], "text": "沈没航路ブラックショアで回収された。"},
	{"keys": ["frost", "glacier", "snow", "perma", "rime", "aurora", "eldion", "umbra", "white", "greios", "oldrex", "vergaron", "storm_joe"], "text": "極寒のフロストリッジ一帯で見つかる。"},
	{"keys": ["westbay", "beacon", "lighthouse", "galvanic"], "text": "沿岸・干潟の探索で入手できる。"},
]


static func weapon_type_label(weapon_type: String) -> String:
	return str(WEAPON_TYPE_NAMES.get(weapon_type, weapon_type if not weapon_type.is_empty() else "武器"))


static func element_label(element: String) -> String:
	if element.is_empty():
		return "無属性"
	return str(ELEMENT_NAMES.get(element, element))


static func rarity_label(rarity: int) -> String:
	return RARITY_NAMES[clampi(rarity, 0, RARITY_NAMES.size() - 1)]


static func build_weapon_description(data: Resource) -> String:
	if data == null:
		return ""
	var lines: PackedStringArray = []
	var wtype: String = weapon_type_label(str(data.weapon_type))
	lines.append("【%s】%s" % [wtype, str(data.display_name)])

	var stats: PackedStringArray = []
	stats.append("属性: %s" % element_label(str(data.element)))
	stats.append("希少度: %s" % rarity_label(int(data.rarity)))
	stats.append("攻撃力: %d" % int(data.base_attack))
	if not str(data.bane_class).is_empty():
		stats.append("%s特効 ×%.1f" % [str(data.bane_class), float(data.bane_multiplier)])
	lines.append(" ｜ ".join(stats))

	var description: String = str(data.description).strip_edges() if "description" in data else ""
	if not description.is_empty():
		lines.append(description)

	var skill_id: String = str(data.fixed_skill_id)
	var passive_text: String = EquipmentItemDetailHelper.weapon_legendary_effect_text_from_data(data)
	if not passive_text.is_empty():
		lines.append("固有効果: %s" % passive_text)
	elif not skill_id.is_empty():
		var skill_data: Resource = DataRegistry.get_skill_data(skill_id)
		var skill_name: String = skill_id
		if skill_data != null and not skill_data.display_name.is_empty():
			skill_name = skill_data.display_name
		lines.append("固定スキル: %s" % skill_name)

	lines.append(_weapon_flavor_line(data))
	return "\n".join(lines)


static func _weapon_flavor_line(data: Resource) -> String:
	var rarity: int = int(data.rarity)
	var item_id: String = str(data.id)
	if rarity >= 3:
		return "伝説級の逸品。名と力が探索者の間で語り継がれる。"
	if rarity >= 2:
		return "希少素材で鍛えられた強力な装備。熟練の探索者が求める一品。"
	for entry in WEAPON_BIOME_FLAVOR:
		for key in entry.get("keys", []):
			if item_id.find(str(key)) >= 0:
				return str(entry.get("text", ""))
	if rarity >= 1:
		return "探索ギルドで取引される上質な武器。"
	return "各地の遺構や商人から入手できる一般的な装備。"


static func build_dungeon_overview(data: Resource, bible_overview: String) -> String:
	if data != null and not str(data.flavor_text).is_empty():
		return str(data.flavor_text)
	return bible_overview


static func dungeon_meta(dungeon_id: String) -> Dictionary:
	return DUNGEON_CODEX_META.get(dungeon_id, {})


static func dungeon_location(dungeon_id: String, display_name: String) -> String:
	var meta: Dictionary = dungeon_meta(dungeon_id)
	var location: String = str(meta.get("location", ""))
	if not location.is_empty():
		return location
	return display_name


static func dungeon_exploration_theme(data: Resource) -> String:
	if data == null:
		return ""
	var dungeon_id: String = str(data.id)
	var meta: Dictionary = dungeon_meta(dungeon_id)
	var theme: String = str(meta.get("exploration_theme", ""))
	if not theme.is_empty():
		return theme
	var favored: String = element_label(str(data.favored_element))
	if favored != "無属性":
		return "%sが有利" % favored
	return ""


static func dungeon_related_history(dungeon_id: String) -> Array:
	var meta: Dictionary = dungeon_meta(dungeon_id)
	return meta.get("related_history", []).duplicate()
