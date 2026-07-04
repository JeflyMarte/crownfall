class_name CatalogHelper
extends RefCounted

const _CodexContent := preload("res://scripts/codex/CodexContentHelper.gd")

## M9 Codex カタログ取得（P2-Task046〜049）。

const UNKNOWN_DISPLAY: String = "???"
# History Entry（HE-001〜009）は world/01_History の機械可読ブロックを解析する（旧 16/37 は削除）。
const HISTORY_BIBLE_PATH: String = "res://docs/specs/world/01_History.md"
# 旧 22_DungeonBible は削除。DUNGEON_ID_TO_BIBLE が空のため未使用（file_exists=false で graceful に {} を返す）。
const DUNGEON_BIBLE_PATH: String = ""
const FRAGMENTS_PATH: String = "res://docs/specs/world/12_Fragments.md"

# HE-001〜004=基幹、HE-005〜009=追加（P3-W-019）。lore ドロップ未実装のため全て starter 開示。
const STARTER_HISTORY_IDS: Array[String] = [
	"HE-001", "HE-002", "HE-003", "HE-004",
	"HE-005", "HE-006", "HE-007", "HE-008", "HE-009",
]

const LORE_TO_HISTORY: Dictionary = {}

const DUNGEON_ID_TO_BIBLE: Dictionary = {}

var _history_entries_cache: Array = []
var _dungeon_bible_cache: Dictionary = {}
var _fragment_entries_cache: Array = []

static func get_enemy_entries() -> Array:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	return helper._build_enemy_entries()

static func get_dungeon_entries() -> Array:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	return helper._build_dungeon_entries()

static func get_material_entries() -> Array:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	return helper._build_material_entries()

static func get_weapon_entries() -> Array:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	return helper._build_weapon_entries()

static func get_history_entries() -> Array:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	return helper._build_history_entries()

static func get_lore_entries() -> Array:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	return helper._build_lore_entries()

static func get_lore_body(lore_id: String) -> String:
	var helper: RefCounted = load("res://scripts/codex/CatalogHelper.gd").new()
	for raw in helper._load_fragment_entries():
		if str(raw.get("id", "")) == lore_id:
			return str(raw.get("body", ""))
	return ""

static func get_guide_entries() -> Array:
	return [
		{
			"id": "COMBAT-G001",
			"display_name": "属性の基礎",
			"description": (
				"属性（Element）は 5 種：炎 / 氷 / 電気 / 闇 / 聖\n\n"
				+ "敵が弱点を持つ属性で攻撃すると ×1.25 のダメージ。\n"
				+ "弱点以外（耐性なし）は通常ダメージ（×1.0）。\n\n"
				+ "武器の element が空（\"\"）の場合は無属性攻撃。\n"
				+ "無属性は弱点ボーナスを得られないが、すべての敵に均一なダメージを与える。\n\n"
				+ "⚠ 炎属性（fire）≠ 炎上（ignite）\n"
				+ "  属性はダメージ倍率にのみ影響する。\n"
				+ "  炎上はスキルや Affix が付与する状態異常（DoT）であり別物。"
			),
			"discovered": true,
		},
		{
			"id": "COMBAT-G002",
			"display_name": "状態異常の基礎",
			"description": (
				"状態異常（Status Effect）は 6 種。CombatTimer 1 tick ≒ 1.5 秒。\n\n"
				+ "毒（poison）   DoT +4/tick、5tick、最大 3 スタック\n"
				+ "炎上（ignite） DoT +3/tick、4tick、最大 3 スタック\n"
				+ "冷却（chill）  敵行動 50% スキップ、3tick\n"
				+ "感電（shock）  被ダメ ×1.15 + 行動 30% スキップ、3tick\n"
				+ "呪い（curse）  与ダメ ×0.75、4tick\n"
				+ "スタン（stun） 行動 100% スキップ、2tick\n\n"
				+ "⚠ 属性と状態異常は別系統\n"
				+ "  炎属性の武器が炎上を自動付与するわけではない。\n"
				+ "  炎上はスキルの apply_status や Affix の ignite_chance から付与される。"
			),
			"discovered": true,
		},
	]

static func is_discovered(category: String, entry_id: String) -> bool:
	if entry_id.is_empty() or category.is_empty():
		return false
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
	for data in DataRegistry.get_all_enemy_data():
		if data == null or data.id.is_empty():
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
	return entries

func _build_weapon_entries() -> Array:
	var entries: Array = []
	for data in DataRegistry.get_all_weapon_data():
		if data == null or data.id.is_empty():
			continue
		var description: String = _CodexContent.build_weapon_description(data)
		entries.append(_make_entry(
			data.id,
			data.display_name,
			"",
			description,
			"weapon"
		))
	return entries

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

func _load_fragment_entries() -> Array:
	if not _fragment_entries_cache.is_empty():
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

func _load_history_bible_entries() -> Array:
	if not _history_entries_cache.is_empty():
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
