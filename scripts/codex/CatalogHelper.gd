class_name CatalogHelper
extends RefCounted

const _CodexContent := preload("res://scripts/codex/CodexContentHelper.gd")
const _GuideCatalog := preload("res://scripts/codex/GuideCatalog.gd")
const _CharacterCodexProfiles := preload("res://scripts/codex/CharacterCodexProfiles.gd")

## M9 Codex カタログ取得（P2-Task046〜049）。

const UNKNOWN_DISPLAY: String = "???"
# 実行時はエクスポート同梱の bake JSON を読む（docs/ は実機に載らない）。
# SSOT Markdown は tools/bake_codex_bible.py で再生成。開発時のみ MD フォールバック。
const HISTORY_BAKE_PATH: String = "res://resources/codex/history_entries.json"
const FRAGMENTS_BAKE_PATH: String = "res://resources/codex/fragment_entries.json"
const HISTORY_BIBLE_PATH: String = "res://docs/specs/world/01_History.md"
# 旧 22_DungeonBible は削除。DUNGEON_ID_TO_BIBLE が空のため未使用（file_exists=false で graceful に {} を返す）。
const DUNGEON_BIBLE_PATH: String = ""
const FRAGMENTS_PATH: String = "res://docs/specs/world/12_Fragments.md"

# HE-001〜004=基幹、HE-005〜050=追加。lore ドロップ未実装のため全て starter 開示。
const STARTER_HISTORY_IDS: Array[String] = [
	"HE-001", "HE-002", "HE-003", "HE-004",
	"HE-005", "HE-006", "HE-007", "HE-008", "HE-009",
	"HE-010", "HE-011",
	"HE-012", "HE-013", "HE-014", "HE-015", "HE-016",
	"HE-017", "HE-018", "HE-019", "HE-020",
	"HE-021", "HE-022", "HE-023", "HE-024", "HE-025",
	"HE-026", "HE-027", "HE-028", "HE-029",
	"HE-030", "HE-031", "HE-032", "HE-033", "HE-034",
	"HE-035", "HE-036", "HE-037", "HE-038",
	"HE-039", "HE-040", "HE-041", "HE-042", "HE-043", "HE-044",
	"HE-045", "HE-046", "HE-047", "HE-048", "HE-049", "HE-050",
]

const LORE_TO_HISTORY: Dictionary = {}

const DUNGEON_ID_TO_BIBLE: Dictionary = {}

var _history_entries_cache: Array = []
var _dungeon_bible_cache: Dictionary = {}
var _fragment_entries_cache: Array = []

static func get_enemy_entries() -> Array:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	return helper._build_enemy_entries()


## プレイ可能なダンジョン（main / event / abyss 等）のプールに載る敵 ID。
## 寄り道・征討オミット（SUB_DUNGEONS_PLAYABLE=false）やプール外の未実装敵は図鑑・達成率から除外。
static func playable_enemy_id_set() -> Dictionary:
	var ids: Dictionary = {}
	for data in DataRegistry.get_all_dungeon_data():
		if data == null:
			continue
		if not Constants.is_playable_dungeon_route(str(data.route_type)):
			continue
		for eid in data.enemy_pool:
			var s: String = str(eid)
			if not s.is_empty():
				ids[s] = true
		for eid in data.elite_pool:
			var s2: String = str(eid)
			if not s2.is_empty():
				ids[s2] = true
		var boss: String = str(data.boss_id)
		if not boss.is_empty():
			ids[boss] = true
	return ids


static func is_playable_codex_enemy(enemy_id: String) -> bool:
	if enemy_id.is_empty():
		return false
	return playable_enemy_id_set().has(enemy_id)

static func get_dungeon_entries() -> Array:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	return helper._build_dungeon_entries()

static func get_material_entries() -> Array:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	return helper._build_material_entries()

static func get_weapon_entries() -> Array:
	## 互換: 旧「武器」呼び出しは装備品カタログへ。
	return get_equipment_entries()


## 武器・防具・装飾を横断した装備品カタログ（常時開示・説明付き）。
static func get_equipment_entries() -> Array:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	return helper._build_equipment_entries()

static func get_history_entries() -> Array:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	return helper._build_history_entries()

static func get_lore_entries() -> Array:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	return helper._build_lore_entries()


## 世界観タブ＝WORLD 手引き（常時開示）＋記録断片 LF（発見制）。
static func get_worldview_entries() -> Array:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	return helper._build_worldview_entries()


## キャラタブ＝初期5＋排出助っ人（所持／遭遇のみ本文開示）。
static func get_character_entries() -> Array:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	return helper._build_character_entries()


static func get_lore_body(lore_id: String) -> String:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	for raw in helper._load_fragment_entries():
		if str(raw.get("id", "")) == lore_id:
			return str(raw.get("body", ""))
	return ""


static func get_lore_title(lore_id: String) -> String:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	for raw in helper._load_fragment_entries():
		if str(raw.get("id", "")) == lore_id:
			return str(raw.get("title", ""))
	return ""

static func get_guide_entries() -> Array:
	return _GuideCatalog.get_entries()

static func is_discovered(category: String, entry_id: String) -> bool:
	if entry_id.is_empty() or category.is_empty():
		return false
	## デバッグフル所持中は図鑑を全開示（セーブ欠落でも UI で欠けない）。
	if GameState.debug_full_unlock:
		return true
	if category == "history":
		if entry_id in STARTER_HISTORY_IDS:
			return true
		if _registry_has("history", entry_id):
			return true
		for lore_id in LORE_TO_HISTORY:
			if str(LORE_TO_HISTORY[lore_id]) == entry_id and _registry_has("lore", lore_id):
				return true
		return false
	return _registry_has(category, entry_id)

static func _registry_has(category: String, entry_id: String) -> bool:
	return GameState.discovery_registry.has("%s:%s" % [category, entry_id])

func _build_enemy_entries() -> Array:
	var entries: Array = []
	var playable: Dictionary = playable_enemy_id_set()
	for data in DataRegistry.get_all_enemy_data():
		if data == null or data.id.is_empty():
			continue
		if not playable.has(str(data.id)):
			continue
		var stage: int = GameState.get_enemy_stage(data.id)
		entries.append({
			"id": data.id,
			"display_name": data.display_name if stage >= 2 else UNKNOWN_DISPLAY,
			"stage": stage,
			"codex_class": data.codex_class,
			"codex_danger": data.codex_danger,
			"codex_habitat": data.codex_habitat,
			"element_weakness": data.element_weakness.duplicate(),
			"element_resist": data.element_resist.duplicate(),
			"codex_research_note": data.codex_research_note,
			"codex_materials": data.codex_materials.duplicate(),
			"attack_speed": data.attack_speed,
			"on_hit_status_id": data.on_hit_status_id,
			"on_hit_status_chance": data.on_hit_status_chance,
			"skill_ids": data.skill_ids.duplicate(),
		})
	return entries

func _build_dungeon_entries() -> Array:
	var entries: Array = []
	var bible_map: Dictionary = _load_dungeon_bible_map()
	for data in DataRegistry.get_all_dungeon_data():
		if data == null or data.id.is_empty():
			continue
		var bible_id: String = str(DUNGEON_ID_TO_BIBLE.get(data.id, ""))
		var bible: Dictionary = bible_map.get(bible_id, {})
		var display_name: String = str(bible.get("name", ""))
		if display_name.is_empty():
			display_name = data.display_name
		var overview: String = _CodexContent.build_dungeon_overview(data, str(bible.get("overview", "")))
		entries.append(_make_dungeon_entry(data.id, display_name, overview, bible, data))
	return entries

func _build_material_entries() -> Array:
	var entries: Array = []
	for data in DataRegistry.get_all_material_data():
		if data == null or data.id.is_empty():
			continue
		if not EquipmentEnhancer.is_enhancement_material(str(data.id)):
			continue
		var description: String = str(data.description)
		var lore_id: String = str(data.lore_id)
		if not lore_id.is_empty():
			description += "\n\n関連歴史: %s" % _history_title(lore_id)
		entries.append(_make_entry(
			data.id,
			data.display_name,
			str(data.icon),
			description,
			"material"
		))
		entries[entries.size() - 1]["rarity"] = int(data.rarity)
	return entries

func _build_weapon_entries() -> Array:
	## 互換エイリアス。
	return _build_equipment_entries()


func _build_equipment_entries() -> Array:
	var entries: Array = []
	for data in DataRegistry.get_all_weapon_data():
		if data == null or str(data.id).is_empty():
			continue
		entries.append(_make_equipment_entry(
			str(data.id),
			str(data.display_name),
			_CodexContent.build_weapon_description(data),
			"weapon",
			"武器",
			int(data.rarity)
		))
	for data in DataRegistry.get_all_armor_data():
		if data == null:
			continue
		var armor_id: String = str(data.armor_id)
		if armor_id.is_empty():
			continue
		entries.append(_make_equipment_entry(
			armor_id,
			str(data.display_name),
			_CodexContent.build_armor_description(data),
			"armor",
			"防具",
			int(data.rarity)
		))
	for data in DataRegistry.get_all_accessory_data():
		if data == null or str(data.id).is_empty():
			continue
		entries.append(_make_equipment_entry(
			str(data.id),
			str(data.display_name),
			_CodexContent.build_accessory_description(data),
			"accessory",
			"装飾",
			int(data.rarity)
		))
	return entries


func _make_equipment_entry(
	entry_id: String,
	display_name: String,
	description: String,
	equip_kind: String,
	kind_label: String,
	rarity: int
) -> Dictionary:
	## 装備品タブは図鑑カタログとして常時開示（説明対象＝全件）。
	return {
		"id": entry_id,
		"display_name": display_name,
		"icon": "",
		"description": description,
		"discovered": true,
		"equip_kind": equip_kind,
		"equip_kind_label": kind_label,
		"rarity": rarity,
		"rarity_label": _CodexContent.rarity_label(rarity),
		"list_label": "【%s】%s" % [kind_label, display_name],
	}


func _build_history_entries() -> Array:
	var entries: Array = []
	for raw in _load_history_bible_entries():
		var he_id: String = str(raw.get("id", ""))
		if he_id.is_empty():
			continue
		entries.append(_make_history_entry(raw))
	return entries

func _build_lore_entries() -> Array:
	var entries: Array = []
	for raw in _load_fragment_entries():
		var lf_id: String = str(raw.get("id", ""))
		if lf_id.is_empty():
			continue
		var body: String = str(raw.get("body", ""))
		var medium: String = str(raw.get("medium", ""))
		var source: String = str(raw.get("source", ""))
		var description: String = body
		if not medium.is_empty():
			description += "\n\n媒体: " + medium
		if not source.is_empty():
			description += "\n出自: " + source
		entries.append(_make_entry(lf_id, str(raw.get("title", "")), "", description, "lore"))
	return entries


func _build_worldview_entries() -> Array:
	var entries: Array = []
	## 常時開示の世界観解説を先に。
	for world: Dictionary in _GuideCatalog.get_world_entries():
		var row: Dictionary = world.duplicate()
		row["section"] = "world"
		row["list_prefix"] = "【解説】"
		entries.append(row)
	## 探索発見制の記録断片。
	for lore: Dictionary in _build_lore_entries():
		var row: Dictionary = lore.duplicate()
		row["section"] = "fragment"
		row["list_prefix"] = "【断片】"
		entries.append(row)
	return entries


const _STARTER_FLAVOR: Dictionary = {
	"adventurer_0": "王炎の覇気を宿す剣士。前線で斬り込む隊の要。",
	"adventurer_1": "毒矢と単独行動を得意とする狩人。影から仕留める。",
	"adventurer_2": "野戦調合の錬成士。味方の傷をいち早く閉じる。",
	"adventurer_3": "聖盾の砦を張る守護者。被弾しても反撃を忘れない。",
	"adventurer_4": "相棒と共鳴する獣使い。ペットの力を引き出す。",
}


func _build_character_entries() -> Array:
	var entries: Array = []
	## 拠点NPC（常時開示）。
	for npc_id: String in _CharacterCodexProfiles.NPC_ORDER:
		entries.append(_build_npc_entry(npc_id))
	for def: Variant in GameState.BASE_ROSTER_DEFS:
		if def is not Dictionary:
			continue
		var adv_id: String = str(def.get("id", ""))
		var job_id: String = str(def.get("job", ""))
		var display: String = str(def.get("name", ""))
		var owned: bool = GameState.is_starter_unlocked(adv_id)
		var profile: Dictionary = _CharacterCodexProfiles.starter_profile(adv_id)
		var rarity: int = int(profile.get("rarity", 3))
		var body: String = _CharacterCodexProfiles.format_profile_body(
			str(profile.get("hometown", "")),
			int(profile.get("height_cm", 0)),
			str(profile.get("likes", "")),
			str(profile.get("dislikes", "")),
			str(profile.get("backstory", _STARTER_FLAVOR.get(adv_id, ""))),
			str(profile.get("record_note", "")),
			"",
			""
		)
		entries.append(_make_character_entry(
			adv_id,
			display,
			job_id,
			rarity,
			body,
			"",
			owned,
			"starter",
			profile
		))
	## 随伴ペット（所持のみ開示）。
	const _PetSystem := preload("res://scripts/pets/PetSystem.gd")
	for pet_id: String in ["pet_jack", "pet_ash", "pet_ink"]:
		entries.append(_build_pet_entry(pet_id, _PetSystem.owns_pet(pet_id)))
	## 排出プール助っ人（所持時開示。`_omitted` は昇格まで非掲載）。
	for helper: Resource in DataRegistry.get_all_gacha_helper_data():
		if helper == null:
			continue
		var hid: String = str(helper.id)
		if hid.is_empty():
			continue
		var owned_h: bool = int(GameState.owned_helpers.get(hid, 0)) > 0
		var profile_h: Dictionary = {
			"hometown": str(helper.hometown),
			"height_cm": int(helper.height_cm),
			"likes": str(helper.likes),
			"dislikes": str(helper.dislikes),
			"backstory": str(helper.backstory),
			"record_note": str(helper.record_note),
		}
		var body_h: String = _CharacterCodexProfiles.format_profile_body(
			str(helper.hometown),
			int(helper.height_cm),
			str(helper.likes),
			str(helper.dislikes),
			str(helper.backstory) if not str(helper.backstory).is_empty() else str(helper.origin_note),
			str(helper.record_note),
			str(helper.summon_quote),
			str(helper.passive_id)
		)
		entries.append(_make_character_entry(
			hid,
			str(helper.display_name),
			str(helper.job_id),
			int(helper.rarity),
			body_h,
			str(helper.portrait_resource_path),
			owned_h,
			"helper",
			profile_h
		))
	## 九王・九英雄（伝承・常時開示）。
	for kid: String in _CharacterCodexProfiles.LEGEND_KING_ORDER:
		entries.append(_build_legend_entry(kid, "legend_king"))
	for hid2: String in _CharacterCodexProfiles.LEGEND_HERO_ORDER:
		entries.append(_build_legend_entry(hid2, "legend_hero"))
	return entries


func _build_npc_entry(npc_id: String) -> Dictionary:
	var profile: Dictionary = _CharacterCodexProfiles.npc_profile(npc_id)
	var display: String = str(profile.get("display_name", npc_id))
	var role: String = str(profile.get("role_name", "関係者"))
	var revealed: bool = bool(profile.get("codex_revealed", false))
	var body: String = _CharacterCodexProfiles.format_profile_body(
		str(profile.get("hometown", "")),
		int(profile.get("height_cm", 0)),
		str(profile.get("likes", "")),
		str(profile.get("dislikes", "")),
		str(profile.get("backstory", "")),
		str(profile.get("record_note", "")),
		str(profile.get("quote", "")),
		""
	)
	profile["role_name"] = role
	return _make_character_entry(
		npc_id,
		display,
		"",
		int(profile.get("rarity", 0)),
		body,
		str(profile.get("portrait_path", "")),
		revealed,
		"npc",
		profile
	)


func _build_legend_entry(legend_id: String, kind: String) -> Dictionary:
	var profile: Dictionary = {}
	if kind == "legend_king":
		profile = _CharacterCodexProfiles.legend_king_profile(legend_id)
	else:
		profile = _CharacterCodexProfiles.legend_hero_profile(legend_id)
	var display: String = str(profile.get("display_name", legend_id))
	var role: String = str(profile.get("role_name", "伝承"))
	var body: String = _CharacterCodexProfiles.format_profile_body(
		str(profile.get("hometown", "")),
		int(profile.get("height_cm", 0)),
		str(profile.get("likes", "")),
		str(profile.get("dislikes", "")),
		str(profile.get("backstory", "")),
		str(profile.get("record_note", "")),
		str(profile.get("quote", "")),
		""
	)
	profile["role_name"] = role
	## 伝承枠はデータ残置のみ。一覧は未実装扱い（???）。
	return _make_character_entry(
		legend_id,
		display,
		"",
		0,
		body,
		"",
		false,
		kind,
		profile
	)


func _build_pet_entry(pet_id: String, owned: bool) -> Dictionary:
	const _PetSystem := preload("res://scripts/pets/PetSystem.gd")
	var profile: Dictionary = _CharacterCodexProfiles.pet_profile(pet_id)
	var pet_data: Resource = _PetSystem.get_pet_data(pet_id)
	var display: String = str(pet_data.display_name) if pet_data != null else pet_id
	var rarity: int = int(pet_data.rarity) if pet_data != null else int(profile.get("rarity", 1))
	var role: String = str(profile.get("role_name", "随伴ペット"))
	var backstory: String = str(profile.get("backstory", ""))
	if backstory.is_empty() and pet_data != null:
		backstory = str(pet_data.origin_note)
	var body: String = _CharacterCodexProfiles.format_profile_body(
		str(profile.get("hometown", "")),
		int(profile.get("height_cm", 0)),
		str(profile.get("likes", "")),
		str(profile.get("dislikes", "")),
		backstory,
		str(profile.get("record_note", "")),
		"",
		"",
		"体高"
	)
	profile["role_name"] = role
	return _make_character_entry(
		pet_id,
		display,
		"",
		rarity,
		body,
		"",
		owned,
		"pet",
		profile
	)


func _make_character_entry(
	entry_id: String,
	display_name: String,
	job_id: String,
	rarity: int,
	description: String,
	portrait_path: String,
	owned: bool,
	kind: String,
	profile: Dictionary = {}
) -> Dictionary:
	if GameState.debug_full_unlock:
		owned = true
	var job_name: String = str(profile.get("role_name", ""))
	if job_name.is_empty():
		job_name = job_id
		var job_data: Resource = DataRegistry.get_job_data(job_id)
		if job_data != null:
			job_name = str(job_data.display_name)
	if not owned:
		return {
			"id": entry_id,
			"display_name": UNKNOWN_DISPLAY,
			"description": "",
			"discovered": false,
			"job_id": job_id,
			"job_name": "",
			"rarity": rarity,
			"portrait_path": "",
			"kind": kind,
			"list_label": UNKNOWN_DISPLAY,
			"hometown": "",
			"height_cm": 0,
		}
	## 一覧タイトルは名前のみ（職名・★は詳細側に残す）。
	return {
		"id": entry_id,
		"display_name": display_name,
		"description": description,
		"discovered": true,
		"job_id": job_id,
		"job_name": job_name,
		"rarity": rarity,
		"portrait_path": portrait_path,
		"kind": kind,
		"list_label": display_name,
		"hometown": str(profile.get("hometown", "")),
		"height_cm": int(profile.get("height_cm", 0)),
	}


func _load_fragment_entries() -> Array:
	if not _fragment_entries_cache.is_empty():
		return _fragment_entries_cache
	var baked: Array = _load_json_array(FRAGMENTS_BAKE_PATH)
	if not baked.is_empty():
		_fragment_entries_cache = baked
		return _fragment_entries_cache
	if not FileAccess.file_exists(FRAGMENTS_PATH):
		_fragment_entries_cache = []
		return _fragment_entries_cache
	var lines: PackedStringArray = FileAccess.get_file_as_string(FRAGMENTS_PATH).split("\n")
	var entries: Array = []
	var i: int = 0
	while i < lines.size():
		var line: String = lines[i].strip_edges()
		if not line.begins_with("# LF "):
			i += 1
			continue
		var body_text: String = line.substr(5).strip_edges()
		var space_idx: int = body_text.find(" ")
		var lf_id: String = body_text.substr(0, space_idx) if space_idx >= 0 else body_text
		var title: String = body_text.substr(space_idx + 1).strip_edges() if space_idx >= 0 else ""
		i += 1
		var sections: Dictionary = _collect_markdown_sections(lines, i, "## ", "# LF ")
		i = int(sections.get("next_index", i))
		entries.append({
			"id": lf_id,
			"title": title,
			"body": str(sections.get("Body", "")),
			"medium": str(sections.get("Medium", "")),
			"source": str(sections.get("Source", "")),
		})
	_fragment_entries_cache = entries
	return _fragment_entries_cache

func _make_entry(entry_id: String, display_name: String, icon: String, description: String, category: String) -> Dictionary:
	var discovered: bool = is_discovered(category, entry_id)
	return {
		"id": entry_id,
		"display_name": display_name if discovered else UNKNOWN_DISPLAY,
		"icon": icon if discovered else "",
		"description": description if discovered else "",
		"discovered": discovered,
	}

func _make_history_entry(raw: Dictionary) -> Dictionary:
	var he_id: String = str(raw.get("id", ""))
	var title: String = str(raw.get("title", ""))
	var overview: String = str(raw.get("overview", ""))
	var entry: Dictionary = _make_entry(he_id, title, "", overview, "history")
	if not bool(entry.get("discovered", false)):
		entry["era"] = ""
		entry["related_entries"] = []
		return entry
	entry["era"] = str(raw.get("era", ""))
	entry["related_entries"] = raw.get("related_entries", []).duplicate()
	return entry

func _make_dungeon_entry(entry_id: String, display_name: String, overview: String, bible: Dictionary, dungeon_data: Resource = null) -> Dictionary:
	var entry: Dictionary = _make_entry(entry_id, display_name, "", overview, "dungeon")
	if not bool(entry.get("discovered", false)):
		entry["location"] = ""
		entry["exploration_theme"] = ""
		entry["related_history"] = []
		return entry
	var location: String = str(bible.get("location", ""))
	if location.is_empty():
		location = _CodexContent.dungeon_location(entry_id, display_name)
	entry["location"] = location
	var theme: String = str(bible.get("exploration_theme", ""))
	if theme.is_empty() and dungeon_data != null:
		theme = _CodexContent.dungeon_exploration_theme(dungeon_data)
	entry["exploration_theme"] = theme
	var related: Array = bible.get("related_history", []).duplicate()
	if related.is_empty():
		related = _CodexContent.dungeon_related_history(entry_id)
	entry["related_history"] = related
	return entry

func _load_json_array(path: String) -> Array:
	if path.is_empty() or not FileAccess.file_exists(path):
		return []
	var raw: String = FileAccess.get_file_as_string(path)
	if raw.is_empty():
		return []
	var parsed: Variant = JSON.parse_string(raw)
	if parsed is Array:
		return parsed
	return []


func _load_history_bible_entries() -> Array:
	if not _history_entries_cache.is_empty():
		return _history_entries_cache
	var baked: Array = _load_json_array(HISTORY_BAKE_PATH)
	if not baked.is_empty():
		_history_entries_cache = baked
		return _history_entries_cache
	if not FileAccess.file_exists(HISTORY_BIBLE_PATH):
		_history_entries_cache = []
		return _history_entries_cache
	var lines: PackedStringArray = FileAccess.get_file_as_string(HISTORY_BIBLE_PATH).split("\n")
	var entries: Array = []
	var i: int = 0
	while i < lines.size():
		var line: String = lines[i].strip_edges()
		if not line.begins_with("# HE-"):
			i += 1
			continue
		var body: String = line.substr(2).strip_edges()
		var space_idx: int = body.find(" ")
		var he_id: String = body.substr(0, space_idx) if space_idx >= 0 else body
		var title: String = body.substr(space_idx + 1).strip_edges() if space_idx >= 0 else ""
		i += 1
		var sections: Dictionary = _collect_markdown_sections(lines, i, "## ", "# HE-")
		i = int(sections.get("next_index", i))
		entries.append({
			"id": he_id,
			"title": title,
			"overview": str(sections.get("Overview", "")),
			"era": str(sections.get("Era", "")),
			"related_entries": _parse_related_ids(str(sections.get("Related History Entries", ""))),
		})
	_history_entries_cache = entries
	return _history_entries_cache

func _load_dungeon_bible_map() -> Dictionary:
	if not _dungeon_bible_cache.is_empty():
		return _dungeon_bible_cache
	if not FileAccess.file_exists(DUNGEON_BIBLE_PATH):
		_dungeon_bible_cache = {}
		return _dungeon_bible_cache
	var lines: PackedStringArray = FileAccess.get_file_as_string(DUNGEON_BIBLE_PATH).split("\n")
	var map: Dictionary = {}
	var i: int = 0
	while i < lines.size():
		var line: String = lines[i].strip_edges()
		if not line.begins_with("## Dungeon-"):
			i += 1
			continue
		var body: String = line.substr(3).strip_edges()
		var space_idx: int = body.find(" ")
		var bible_id: String = body.substr(0, space_idx) if space_idx >= 0 else body
		var name: String = body.substr(space_idx + 1).strip_edges() if space_idx >= 0 else ""
		i += 1
		var sections: Dictionary = _collect_markdown_sections(lines, i, "### ", "## Dungeon-")
		i = int(sections.get("next_index", i))
		map[bible_id] = {
			"id": bible_id,
			"name": name,
			"overview": str(sections.get("Overview", "")),
			"location": str(sections.get("Location", "")),
			"exploration_theme": str(sections.get("Exploration Theme", "")),
			"related_history": _parse_related_ids(str(sections.get("Related History Entries", ""))),
		}
	_dungeon_bible_cache = map
	return _dungeon_bible_cache

func _collect_markdown_sections(
	lines: PackedStringArray,
	start_index: int,
	section_prefix: String,
	stop_prefix: String
) -> Dictionary:
	var sections: Dictionary = {"next_index": start_index}
	var i: int = start_index
	while i < lines.size():
		var line: String = lines[i].strip_edges()
		if line.begins_with(stop_prefix):
			sections["next_index"] = i
			return sections
		if line.begins_with(section_prefix):
			var section_name: String = line.substr(section_prefix.length()).strip_edges()
			i += 1
			var parts: PackedStringArray = []
			while i < lines.size():
				var inner: String = lines[i].strip_edges()
				if inner.begins_with(section_prefix) or inner.begins_with(stop_prefix) or inner == "---":
					break
				if not inner.is_empty():
					parts.append(inner)
				i += 1
			sections[section_name] = "\n".join(parts)
			continue
		i += 1
	sections["next_index"] = i
	return sections

func _history_title(he_id: String) -> String:
	for raw in _load_history_bible_entries():
		if str(raw.get("id", "")) == he_id:
			var title: String = str(raw.get("title", ""))
			if title.is_empty():
				return he_id
			return "%s %s" % [he_id, title]
	return he_id


func _parse_related_ids(section_body: String) -> Array[String]:
	var ids: Array[String] = []
	if section_body.is_empty():
		return ids
	for line in section_body.split("\n"):
		var trimmed: String = line.strip_edges()
		if not trimmed.begins_with("- "):
			continue
		var rest: String = trimmed.substr(2).strip_edges()
		if not rest.begins_with("HE-"):
			continue
		var space_idx: int = rest.find(" ")
		var he_id: String = rest.substr(0, space_idx) if space_idx >= 0 else rest
		if not he_id.is_empty():
			ids.append(he_id)
	return ids
