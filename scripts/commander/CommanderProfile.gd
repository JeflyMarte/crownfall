class_name CommanderProfile
extends RefCounted

const _CommanderDefaults := preload("res://scripts/commander/CommanderDefaults.gd")
const _CommanderSurveyPoints := preload("res://scripts/commander/CommanderSurveyPoints.gd")

## 指揮官（隊長）プロフィール SSOT（P3-CMD-001）。

const DEFAULT_NAME: String = _CommanderDefaults.DEFAULT_NAME

const RANK_ORDER: Array[String] = ["D", "C", "B", "A", "S"]

const RANK_THRESHOLDS: Dictionary = {
	"D": 0,
	"C": 100,
	"B": 350,
	"A": 750,
	"S": 1200,
}

const RANK_SUBTITLES: Dictionary = {
	"D": "仮調査許可",
	"C": "区域調査許可",
	"B": "遠域調査許可",
	"A": "深度調査許可",
	"S": "広域調査許可",
}

const EXTENDED_RECORDS_UNLOCK_RANK: String = "A"
const GOLD_SEAL_RANK: String = "S"


static func ensure_commander() -> void:
	if GameState.commander is Dictionary and not GameState.commander.is_empty():
		_sanitize_commander()
		return
	GameState.commander = _CommanderDefaults.default_commander_dict()
	_sanitize_commander()


static func get_commander_name() -> String:
	ensure_commander()
	var cmd_name: String = str(GameState.commander.get("name", DEFAULT_NAME)).strip_edges()
	return cmd_name if not cmd_name.is_empty() else DEFAULT_NAME


static func set_commander_name(raw_name: String) -> bool:
	ensure_commander()
	var trimmed: String = raw_name.strip_edges()
	if trimmed.is_empty():
		return false
	GameState.commander["name"] = trimmed.substr(0, 16)
	return true


static func apply_intro_commander_name(raw_name: String) -> bool:
	return GameState.apply_intro_commander_name(raw_name)


static func set_name_for_intro(raw_name: String) -> bool:
	return apply_intro_commander_name(raw_name)


## 指揮官名の変更可否（P3-CMD-001-9: ランク不問で常時可）。
static func can_edit_name() -> bool:
	return true


static func survey_points() -> int:
	return _CommanderSurveyPoints.evaluate()


static func rank_for_sp(sp: int) -> String:
	var rank: String = "D"
	for code: String in RANK_ORDER:
		if sp >= int(RANK_THRESHOLDS.get(code, 0)):
			rank = code
	return rank


static func current_rank() -> String:
	return rank_for_sp(survey_points())


## 拠点で祝辞表示済みの等級。未設定セーブは現行等級で埋めて二重表示を避ける。
static func get_acknowledged_rank() -> String:
	ensure_commander()
	bootstrap_acknowledged_rank_if_needed()
	var code: String = str(GameState.commander.get("acknowledged_rank", "D")).strip_edges().to_upper()
	if RANK_ORDER.find(code) < 0:
		return "D"
	return code


## 未表示のランクアップがある場合、到達等級コードを返す（無ければ空）。
static func pending_rank_up() -> String:
	bootstrap_acknowledged_rank_if_needed()
	var current: String = current_rank()
	var acknowledged: String = get_acknowledged_rank()
	if RANK_ORDER.find(current) > RANK_ORDER.find(acknowledged):
		return current
	return ""


static func acknowledge_rank(rank_code: String = "") -> void:
	ensure_commander()
	GameState.commander.erase("_ack_needs_bootstrap")
	var code: String = rank_code.strip_edges().to_upper() if not rank_code.is_empty() else current_rank()
	if RANK_ORDER.find(code) < 0:
		code = current_rank()
	var ack: String = str(GameState.commander.get("acknowledged_rank", "D")).strip_edges().to_upper()
	var ack_idx: int = RANK_ORDER.find(ack)
	if ack_idx < 0:
		ack_idx = 0
	var new_idx: int = RANK_ORDER.find(code)
	if new_idx >= ack_idx:
		GameState.commander["acknowledged_rank"] = code


## 旧セーブで acknowledged_rank が無い場合、ensure 外で現行等級へ埋める。
## （sanitize 内で evaluate すると get_lifetime→ensure 再入でスタックする）
static func bootstrap_acknowledged_rank_if_needed() -> void:
	ensure_commander()
	if not bool(GameState.commander.get("_ack_needs_bootstrap", false)):
		return
	GameState.commander.erase("_ack_needs_bootstrap")
	GameState.commander["acknowledged_rank"] = current_rank()


static func is_rank_at_least(rank_code: String) -> bool:
	var target: int = RANK_ORDER.find(rank_code)
	if target < 0:
		return false
	var current: int = RANK_ORDER.find(current_rank())
	return current >= target


## 隊長台帳の閲覧可否（P3-CMD-001-8: ランク不問で常時閲覧可）。
static func is_profile_unlocked() -> bool:
	return true


static func rank_display(include_subtitle: bool = true) -> String:
	var code: String = current_rank()
	if not include_subtitle:
		return "%s級" % code
	return "%s級・%s" % [code, str(RANK_SUBTITLES.get(code, ""))]


static func progress_to_next_rank() -> Dictionary:
	var sp: int = survey_points()
	var rank: String = current_rank()
	var rank_index: int = RANK_ORDER.find(rank)
	if rank_index < 0:
		rank_index = 0
	if rank_index >= RANK_ORDER.size() - 1:
		return {
			"current_rank": rank,
			"next_rank": "",
			"current_sp": sp,
			"next_threshold": sp,
			"progress": 1.0,
			"label": "最大等級",
		}
	var next_rank: String = RANK_ORDER[rank_index + 1]
	var floor_sp: int = int(RANK_THRESHOLDS.get(rank, 0))
	var next_sp: int = int(RANK_THRESHOLDS.get(next_rank, floor_sp))
	var span: int = maxi(next_sp - floor_sp, 1)
	var progress: float = clampf(float(sp - floor_sp) / float(span), 0.0, 1.0)
	return {
		"current_rank": rank,
		"next_rank": next_rank,
		"current_sp": sp,
		"next_threshold": next_sp,
		"progress": progress,
		"label": "%d / %d SP" % [sp, next_sp],
	}


static func rank_glyph() -> String:
	return current_rank()


static func rank_icon_texture(rank_code: String = "") -> Texture2D:
	var code: String = rank_code if not rank_code.is_empty() else current_rank()
	return CommanderUiTokens.rank_icon(code)


static func title_slot_limit() -> int:
	if is_rank_at_least("S"):
		return 3
	if is_rank_at_least("C"):
		return 1
	return 0


static func get_equipped_title() -> String:
	ensure_commander()
	return str(GameState.commander.get("equipped_title", ""))


static func get_unlocked_titles() -> Array:
	ensure_commander()
	var titles: Variant = GameState.commander.get("titles_unlocked", [])
	return (titles as Array).duplicate() if titles is Array else []


static func equip_title(title_id: String) -> bool:
	ensure_commander()
	if title_id.is_empty():
		GameState.commander["equipped_title"] = ""
		return true
	if title_id not in get_unlocked_titles():
		return false
	GameState.commander["equipped_title"] = title_id
	return true


static func unlock_title(title_id: String) -> bool:
	ensure_commander()
	var titles: Array = get_unlocked_titles()
	if title_id.is_empty() or title_id in titles:
		return false
	titles.append(title_id)
	GameState.commander["titles_unlocked"] = titles
	return true


static func get_lifetime() -> Dictionary:
	ensure_commander()
	var lifetime: Variant = GameState.commander.get("lifetime", {})
	if lifetime is Dictionary:
		return lifetime as Dictionary
	return _CommanderDefaults.default_lifetime_dict()


static func get_recent_highlights() -> Array:
	ensure_commander()
	var highlights: Variant = GameState.commander.get("recent_highlights", [])
	return (highlights as Array).duplicate() if highlights is Array else []


static func codex_rates() -> Dictionary:
	var enemy_total: int = CatalogHelper.get_enemy_entries().size()
	var material_total: int = CatalogHelper.get_material_entries().size()
	var weapon_total: int = CatalogHelper.get_weapon_entries().size()
	return {
		"enemy": _rate("enemy", enemy_total),
		"material": _rate("material", material_total),
		"weapon": _rate("weapon", weapon_total),
	}


static func top_materials(limit: int = 8) -> Array:
	var rows: Array = []
	for mat_id: Variant in GameState.material_inventory.keys():
		var qty: int = int(GameState.material_inventory[mat_id])
		if qty <= 0:
			continue
		rows.append({
			"id": str(mat_id),
			"name": DataRegistry.get_material_name(str(mat_id)),
			"qty": qty,
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("qty", 0)) != int(b.get("qty", 0)):
			return int(a.get("qty", 0)) > int(b.get("qty", 0))
		return str(a.get("name", "")) < str(b.get("name", ""))
	)
	return rows.slice(0, limit)


static func top_deployed_members(limit: int = 5) -> Array:
	var lifetime: Dictionary = get_lifetime()
	var counts: Dictionary = lifetime.get("deployment_counts", {})
	if not counts is Dictionary:
		return []
	var rows: Array = []
	for member_id: Variant in counts.keys():
		var count: int = int(counts[member_id])
		if count <= 0:
			continue
		rows.append({
			"member_id": str(member_id),
			"display_name": _member_display_name(str(member_id)),
			"count": count,
			"mvp_count": int((lifetime.get("mvp_counts", {}) as Dictionary).get(str(member_id), 0)),
		})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("count", 0)) != int(b.get("count", 0)):
			return int(a.get("count", 0)) > int(b.get("count", 0))
		return str(a.get("display_name", "")) < str(b.get("display_name", ""))
	)
	return rows.slice(0, limit)


static func _rate(category: String, total: int) -> Dictionary:
	var discovered: int = DiscoveryRegistry.count_by_category(category)
	if total <= 0:
		return {"discovered": discovered, "total": 0, "percent": 0}
	return {
		"discovered": discovered,
		"total": total,
		"percent": int(round(float(discovered) * 100.0 / float(total))),
	}


static func _member_display_name(member_id: String) -> String:
	for adv: Resource in GameState.roster:
		if adv != null and str(adv.id) == member_id:
			return str(adv.display_name)
	return member_id


static func _sanitize_commander() -> void:
	if not GameState.commander is Dictionary:
		GameState.commander = _CommanderDefaults.default_commander_dict()
		return
	if not GameState.commander.has("lifetime"):
		GameState.commander["lifetime"] = _CommanderDefaults.default_lifetime_dict()
	if not GameState.commander.has("titles_unlocked"):
		GameState.commander["titles_unlocked"] = []
	if not GameState.commander.has("recent_highlights"):
		GameState.commander["recent_highlights"] = []
	if not GameState.commander.has("gift_box") or not GameState.commander["gift_box"] is Array:
		GameState.commander["gift_box"] = []
	if not GameState.commander.has("redeemed_codes") or not GameState.commander["redeemed_codes"] is Array:
		GameState.commander["redeemed_codes"] = []
	if not GameState.commander.has("name") or str(GameState.commander.get("name", "")).strip_edges().is_empty():
		GameState.commander["name"] = DEFAULT_NAME
	## 既存セーブ: キー欠落は仮 D＋bootstrap フラグ。評価は ensure 外で行う。
	if not GameState.commander.has("acknowledged_rank"):
		GameState.commander["acknowledged_rank"] = "D"
		GameState.commander["_ack_needs_bootstrap"] = true
	else:
		var ack: String = str(GameState.commander.get("acknowledged_rank", "")).strip_edges().to_upper()
		if RANK_ORDER.find(ack) < 0:
			GameState.commander["acknowledged_rank"] = "D"
			GameState.commander["_ack_needs_bootstrap"] = true
