class_name CommanderProfile
extends RefCounted

const _CommanderDefaults := preload("res://scripts/commander/CommanderDefaults.gd")
const _CommanderSurveyPoints := preload("res://scripts/commander/CommanderSurveyPoints.gd")
const _CommanderGiftBox := preload("res://scripts/commander/CommanderGiftBox.gd")

## 指揮官（隊長）プロフィール SSOT（P3-CMD-001 / P3-CMD-RANK-REWARD-001）。

const DEFAULT_NAME: String = _CommanderDefaults.DEFAULT_NAME

## 固定帯（D〜S）。S 以降は S+1…（P3-CMD-RANK-SPLUS-001）。
const RANK_ORDER: Array[String] = ["D", "C", "B", "A", "S"]
const S_RANK_THRESHOLD: int = 2200
const S_PLUS_INTERVAL: int = 400
const S_PLUS_GIFT_GOLD: int = 1500
const S_PLUS_GIFT_TOKEN: int = 15
const S_PLUS_SUBTITLE: String = "継続調査許可"

## 現行閾値（P3-CMD-RANK-CURVE-003 案A — 終盤〜ハード寄りでS）。
const RANK_THRESHOLDS: Dictionary = {
	"D": 0,
	"C": 400,
	"B": 900,
	"A": 1500,
	"S": S_RANK_THRESHOLD,
}

## 初版閾値（rank_curve_v2 移行の据置用）。
const LEGACY_RANK_THRESHOLDS: Dictionary = {
	"D": 0,
	"C": 100,
	"B": 350,
	"A": 750,
	"S": 1200,
}

## v2 閾値（P3-CMD-RANK-REWARD-001 / rank_curve_v3 移行の据置用）。
const RANK_THRESHOLDS_V2: Dictionary = {
	"D": 0,
	"C": 200,
	"B": 700,
	"A": 1500,
	"S": 2800,
}

## v3 閾値（P3-CMD-RANK-CURVE-002 / rank_curve_v4 移行の据置用）。
const RANK_THRESHOLDS_V3: Dictionary = {
	"D": 0,
	"C": 300,
	"B": 650,
	"A": 1050,
	"S": 1450,
}

const RANK_SUBTITLES: Dictionary = {
	"D": "仮調査許可",
	"C": "区域調査許可",
	"B": "遠域調査許可",
	"A": "深度調査許可",
	"S": "広域調査許可",
}

## 到達時配布（配布ボックス経由・P3-CMD-RANK-CURVE-003）。
const RANK_GIFT_GOLD: Dictionary = {
	"C": 800,
	"B": 2000,
	"A": 4000,
	"S": 8000,
}
const RANK_GIFT_TOKEN: Dictionary = {
	"C": 10,
	"B": 25,
	"A": 50,
	"S": 100,
}
## 等級コード → { material_id: qty }
const RANK_GIFT_MATERIALS: Dictionary = {
	"A": {"base_ore": 20, "relic_shard": 15},
	"S": {"base_ore": 40, "relic_shard": 30, "elite_relic_shard": 8},
}

const EXTENDED_RECORDS_UNLOCK_RANK: String = "A"
const GOLD_SEAL_RANK: String = "S"
const RANK_CURVE_FLAG: String = "rank_curve_v2"
const RANK_CURVE_V3_FLAG: String = "rank_curve_v3"
const RANK_CURVE_V4_FLAG: String = "rank_curve_v4"


static func normalize_rank_code(code: String) -> String:
	return code.strip_edges().to_upper()


## S+n の n（S 自体は 0）。不正は -1。
static func s_plus_level(code: String) -> int:
	var c: String = normalize_rank_code(code)
	if c == "S":
		return 0
	if not c.begins_with("S+"):
		return -1
	var rest: String = c.substr(2)
	if rest.is_empty() or not rest.is_valid_int():
		return -1
	var n: int = int(rest)
	return n if n >= 1 else -1


static func is_valid_rank_code(code: String) -> bool:
	var c: String = normalize_rank_code(code)
	if RANK_ORDER.has(c):
		return true
	return s_plus_level(c) >= 1


## D=0 … S=4, S+1=5, S+2=6 …。不正は -1。
static func rank_index(code: String) -> int:
	var c: String = normalize_rank_code(code)
	var base_i: int = RANK_ORDER.find(c)
	if base_i >= 0:
		return base_i
	var n: int = s_plus_level(c)
	if n >= 1:
		return RANK_ORDER.size() - 1 + n
	return -1


static func rank_code_at(index: int) -> String:
	if index < 0:
		return "D"
	if index < RANK_ORDER.size():
		return RANK_ORDER[index]
	var n: int = index - (RANK_ORDER.size() - 1)
	return "S+%d" % n


static func threshold_for_rank(code: String, thresholds: Dictionary = RANK_THRESHOLDS) -> int:
	var c: String = normalize_rank_code(code)
	var n: int = s_plus_level(c)
	if n >= 1:
		var s_base: int = int(thresholds.get("S", S_RANK_THRESHOLD))
		return s_base + n * S_PLUS_INTERVAL
	return int(thresholds.get(c, 0))


static func rank_subtitle(code: String) -> String:
	var c: String = normalize_rank_code(code)
	if RANK_SUBTITLES.has(c):
		return str(RANK_SUBTITLES[c])
	if s_plus_level(c) >= 1:
		return S_PLUS_SUBTITLE
	return ""


static func gift_gold_for_rank(code: String) -> int:
	var c: String = normalize_rank_code(code)
	if RANK_GIFT_GOLD.has(c):
		return int(RANK_GIFT_GOLD[c])
	if s_plus_level(c) >= 1:
		return S_PLUS_GIFT_GOLD
	return 0


static func gift_token_for_rank(code: String) -> int:
	var c: String = normalize_rank_code(code)
	if RANK_GIFT_TOKEN.has(c):
		return int(RANK_GIFT_TOKEN[c])
	if s_plus_level(c) >= 1:
		return S_PLUS_GIFT_TOKEN
	return 0


static func gift_materials_for_rank(code: String) -> Dictionary:
	var c: String = normalize_rank_code(code)
	var raw: Variant = RANK_GIFT_MATERIALS.get(c, {})
	if raw is Dictionary and not (raw as Dictionary).is_empty():
		return (raw as Dictionary).duplicate(true)
	var n: int = s_plus_level(c)
	if n >= 5 and n % 5 == 0:
		return {"base_ore": 10, "relic_shard": 5}
	return {}


static func ensure_commander() -> void:
	if GameState.commander is Dictionary and not GameState.commander.is_empty():
		_sanitize_commander()
		migrate_rank_curve_v2_if_needed()
		migrate_rank_curve_v3_if_needed()
		migrate_rank_curve_v4_if_needed()
		return
	GameState.commander = _CommanderDefaults.default_commander_dict()
	_sanitize_commander()
	migrate_rank_curve_v2_if_needed()
	migrate_rank_curve_v3_if_needed()
	migrate_rank_curve_v4_if_needed()


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
	return rank_for_sp_with(RANK_THRESHOLDS, sp)


static func rank_for_sp_with(thresholds: Dictionary, sp: int) -> String:
	var rank: String = "D"
	for code: String in RANK_ORDER:
		if sp >= int(thresholds.get(code, 0)):
			rank = code
	if rank != "S":
		return rank
	var s_th: int = int(thresholds.get("S", S_RANK_THRESHOLD))
	var n: int = int((sp - s_th) / S_PLUS_INTERVAL) if sp >= s_th else 0
	if n < 1:
		return "S"
	return "S+%d" % n


static func higher_rank(a: String, b: String) -> String:
	var ai: int = rank_index(a)
	var bi: int = rank_index(b)
	if ai < 0:
		ai = 0
	if bi < 0:
		bi = 0
	return rank_code_at(maxi(ai, bi))


## SP のみからの等級（据置フロアなし）。
static func rank_from_sp_only() -> String:
	return rank_for_sp(survey_points())


## 表示等級。SP等級と acknowledged（据置下限）の高い方（P3-CMD-RANK-REWARD-001-2）。
static func current_rank() -> String:
	ensure_commander()
	var sp_rank: String = rank_from_sp_only()
	## bootstrap 中は SP のみ（ack 循環を避ける）。
	if bool(GameState.commander.get("_ack_needs_bootstrap", false)):
		return sp_rank
	var ack: String = normalize_rank_code(str(GameState.commander.get("acknowledged_rank", "D")))
	if not is_valid_rank_code(ack):
		ack = "D"
	return higher_rank(sp_rank, ack)


## 拠点で祝辞表示済みの等級。未設定セーブは現行等級で埋めて二重表示を避ける。
static func get_acknowledged_rank() -> String:
	ensure_commander()
	bootstrap_acknowledged_rank_if_needed()
	var code: String = normalize_rank_code(str(GameState.commander.get("acknowledged_rank", "D")))
	if not is_valid_rank_code(code):
		return "D"
	return code


## 未表示のランクアップがある場合、到達等級コードを返す（無ければ空）。
static func pending_rank_up() -> String:
	bootstrap_acknowledged_rank_if_needed()
	var sp_rank: String = rank_from_sp_only()
	var acknowledged: String = get_acknowledged_rank()
	if rank_index(sp_rank) > rank_index(acknowledged):
		return sp_rank
	return ""


static func acknowledge_rank(rank_code: String = "", grant_rewards: bool = true) -> void:
	ensure_commander()
	GameState.commander.erase("_ack_needs_bootstrap")
	var code: String = (
		normalize_rank_code(rank_code) if not rank_code.is_empty() else current_rank()
	)
	if not is_valid_rank_code(code):
		code = current_rank()
	var ack: String = normalize_rank_code(str(GameState.commander.get("acknowledged_rank", "D")))
	var ack_idx: int = rank_index(ack)
	if ack_idx < 0:
		ack_idx = 0
	var new_idx: int = rank_index(code)
	if new_idx >= ack_idx:
		if grant_rewards:
			_grant_rank_rewards_between(ack_idx, new_idx)
		GameState.commander["acknowledged_rank"] = code


## 旧セーブで acknowledged_rank が無い場合、ensure 外で現行等級へ埋める。
## （sanitize 内で evaluate すると get_lifetime→ensure 再入でスタックする）
static func bootstrap_acknowledged_rank_if_needed() -> void:
	ensure_commander()
	if not bool(GameState.commander.get("_ack_needs_bootstrap", false)):
		return
	GameState.commander.erase("_ack_needs_bootstrap")
	GameState.commander["acknowledged_rank"] = rank_from_sp_only()


## 閾値改定の一度きりの移行。旧閾値到達分を ack 下限にし、ギフトは出さない。
static func migrate_rank_curve_v2_if_needed() -> void:
	_migrate_rank_curve_if_needed(RANK_CURVE_FLAG, LEGACY_RANK_THRESHOLDS)


## P3-CMD-RANK-CURVE-002: v2→v3。表示等級は下げない。
static func migrate_rank_curve_v3_if_needed() -> void:
	_migrate_rank_curve_if_needed(RANK_CURVE_V3_FLAG, RANK_THRESHOLDS_V2)


## P3-CMD-RANK-CURVE-003: v3→現行。表示等級は下げない。
static func migrate_rank_curve_v4_if_needed() -> void:
	_migrate_rank_curve_if_needed(RANK_CURVE_V4_FLAG, RANK_THRESHOLDS_V3)


static func _migrate_rank_curve_if_needed(flag_key: String, previous_thresholds: Dictionary) -> void:
	if not GameState.commander is Dictionary:
		return
	if bool(GameState.commander.get(flag_key, false)):
		return
	## evaluate→get_lifetime→ensure 再入を防ぐため先にフラグを立てる。
	GameState.commander[flag_key] = true
	var sp: int = _CommanderSurveyPoints.evaluate()
	var previous_rank: String = rank_for_sp_with(previous_thresholds, sp)
	var ack: String = normalize_rank_code(str(GameState.commander.get("acknowledged_rank", "D")))
	if not is_valid_rank_code(ack):
		ack = "D"
	## bootstrap 待ちは旧閾値到達で埋める（新閾値で下げない）。
	if bool(GameState.commander.get("_ack_needs_bootstrap", false)):
		GameState.commander.erase("_ack_needs_bootstrap")
		ack = "D"
	GameState.commander["acknowledged_rank"] = higher_rank(ack, previous_rank)
	## 既到達分はギフト再配布しない。
	var rewarded: Array = _rank_reward_ranks()
	var floor_idx: int = rank_index(str(GameState.commander.get("acknowledged_rank", "D")))
	for i in range(1, maxi(floor_idx, 0) + 1):
		var code: String = rank_code_at(i)
		if code not in rewarded:
			rewarded.append(code)
	GameState.commander["rank_reward_ranks"] = rewarded


static func is_rank_at_least(rank_code: String) -> bool:
	var target: int = rank_index(rank_code)
	if target < 0:
		return false
	var current: int = rank_index(current_rank())
	return current >= target


## 隊長台帳の閲覧可否（P3-CMD-001-8: ランク不問で常時閲覧可）。
static func is_profile_unlocked() -> bool:
	return true


static func rank_display(include_subtitle: bool = true) -> String:
	var code: String = current_rank()
	if not include_subtitle:
		return "%s級" % code
	var sub: String = rank_subtitle(code)
	if sub.is_empty():
		return "%s級" % code
	return "%s級・%s" % [code, sub]


static func progress_to_next_rank() -> Dictionary:
	var sp: int = survey_points()
	var rank: String = current_rank()
	var idx: int = rank_index(rank)
	if idx < 0:
		idx = 0
	var next_rank: String = rank_code_at(idx + 1)
	var floor_sp: int = threshold_for_rank(rank)
	var next_sp: int = threshold_for_rank(next_rank)
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
	if is_rank_at_least("B"):
		return 2
	if is_rank_at_least("C"):
		return 1
	return 0


static func _rank_reward_ranks() -> Array:
	var raw: Variant = GameState.commander.get("rank_reward_ranks", [])
	return (raw as Array).duplicate() if raw is Array else []


static func _grant_rank_rewards_between(from_idx: int, to_idx: int) -> void:
	if to_idx <= from_idx:
		return
	var rewarded: Array = _rank_reward_ranks()
	var permit_ranks: Array = []
	for i in range(from_idx + 1, to_idx + 1):
		var code: String = rank_code_at(i)
		if code in rewarded:
			continue
		var gold: int = gift_gold_for_rank(code)
		var tokens: int = gift_token_for_rank(code)
		var materials: Dictionary = gift_materials_for_rank(code)
		if gold > 0 or tokens > 0 or not materials.is_empty():
			_CommanderGiftBox.enqueue({
				"title": "%s級到達手当" % code,
				"message": "調査許可等級が%s級に上がった祝いです。" % code,
				"gold": gold,
				"gacha_token": tokens,
				"materials": materials,
				"source": "rank_up",
			})
		if s_plus_level(code) >= 1:
			permit_ranks.append(code)
		rewarded.append(code)
	GameState.commander["rank_reward_ranks"] = rewarded
	const _CommanderPermitBoost := preload("res://scripts/commander/CommanderPermitBoost.gd")
	_CommanderPermitBoost.grant_points_for_ranks(permit_ranks)
	const _CommanderTitles := preload("res://scripts/commander/CommanderTitles.gd")
	_CommanderTitles.refresh_unlocks()


## 未配布の到達手当 Gold 合計（互換・合計表示用）。
static func pending_rank_gift_gold(to_rank: String = "") -> int:
	return int(_pending_rank_gift_totals(to_rank).get("gold", 0))


## 祝辞用の到達手当要約（ack〜到達の未付与分）。
static func pending_rank_gift_summary(to_rank: String = "") -> String:
	var totals: Dictionary = _pending_rank_gift_totals(to_rank)
	var parts: PackedStringArray = []
	var gold: int = int(totals.get("gold", 0))
	if gold > 0:
		parts.append("ゴールド %d" % gold)
	var tokens: int = int(totals.get("gacha_token", 0))
	if tokens > 0:
		parts.append("%s %d" % [CurrencyHelper.DISPLAY_NAME, tokens])
	var mats: Variant = totals.get("materials", {})
	if mats is Dictionary:
		for mat_id: Variant in mats:
			var qty: int = int((mats as Dictionary)[mat_id])
			if qty <= 0:
				continue
			var mat_name: String = DataRegistry.get_material_name(str(mat_id))
			if mat_name.is_empty():
				mat_name = str(mat_id)
			parts.append("%s ×%d" % [mat_name, qty])
	var permit_n: int = int(totals.get("permit_points", 0))
	if permit_n > 0:
		parts.append("許可点 +%d" % permit_n)
	if parts.is_empty():
		return ""
	## 許可点はボックス外でも付与されるが、祝辞では同一行にまとめる。
	return "到達祝い %s" % " / ".join(parts)


static func _pending_rank_gift_totals(to_rank: String = "") -> Dictionary:
	ensure_commander()
	var code: String = (
		normalize_rank_code(to_rank) if not to_rank.is_empty() else current_rank()
	)
	var to_idx: int = rank_index(code)
	var out: Dictionary = {"gold": 0, "gacha_token": 0, "materials": {}, "permit_points": 0}
	if to_idx < 0:
		return out
	var ack: String = normalize_rank_code(str(GameState.commander.get("acknowledged_rank", "D")))
	var from_idx: int = rank_index(ack)
	if from_idx < 0:
		from_idx = 0
	var rewarded: Array = _rank_reward_ranks()
	var mats_total: Dictionary = {}
	var permit_n: int = 0
	for i in range(from_idx + 1, to_idx + 1):
		var rank_code: String = rank_code_at(i)
		if rank_code in rewarded:
			continue
		out["gold"] = int(out["gold"]) + gift_gold_for_rank(rank_code)
		out["gacha_token"] = int(out["gacha_token"]) + gift_token_for_rank(rank_code)
		var raw_mats: Dictionary = gift_materials_for_rank(rank_code)
		for mat_id: Variant in raw_mats:
			var qty: int = int(raw_mats[mat_id])
			if qty > 0:
				mats_total[str(mat_id)] = int(mats_total.get(str(mat_id), 0)) + qty
		if s_plus_level(rank_code) >= 1:
			permit_n += 1
	out["materials"] = mats_total
	out["permit_points"] = permit_n
	return out


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


## 図鑑分母（プレイ可能敵）に含まれる発見のみを数える。プール外登録で 100% 超を防ぐ。
static func count_playable_enemy_discoveries() -> int:
	var playable: Dictionary = CatalogHelper.playable_enemy_id_set()
	var n: int = 0
	for key: Variant in GameState.discovery_registry.keys():
		var s: String = str(key)
		if not s.begins_with("enemy:"):
			continue
		var eid: String = s.substr("enemy:".length())
		if playable.has(eid):
			n += 1
	return n


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
	var discovered: int = (
		count_playable_enemy_discoveries()
		if category == "enemy"
		else DiscoveryRegistry.count_by_category(category)
	)
	if total <= 0:
		return {"discovered": discovered, "total": 0, "percent": 0}
	## 表示用に分母でクランプ（旧セーブの余剰登録でも 100% 超を出さない）。
	var shown: int = mini(discovered, total)
	return {
		"discovered": shown,
		"total": total,
		"percent": mini(100, int(round(float(shown) * 100.0 / float(total)))),
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
	if not GameState.commander.has("lifetime") or not GameState.commander["lifetime"] is Dictionary:
		GameState.commander["lifetime"] = _CommanderDefaults.default_lifetime_dict()
	else:
		var lifetime: Dictionary = GameState.commander["lifetime"] as Dictionary
		if not lifetime.has("play_time_sec"):
			lifetime["play_time_sec"] = 0
	if not GameState.commander.has("titles_unlocked"):
		GameState.commander["titles_unlocked"] = []
	if not GameState.commander.has("recent_highlights"):
		GameState.commander["recent_highlights"] = []
	if not GameState.commander.has("gift_box") or not GameState.commander["gift_box"] is Array:
		GameState.commander["gift_box"] = []
	if not GameState.commander.has("rank_reward_ranks") or not GameState.commander["rank_reward_ranks"] is Array:
		GameState.commander["rank_reward_ranks"] = []
	if not GameState.commander.has("permit_points_earned"):
		GameState.commander["permit_points_earned"] = 0
	if not GameState.commander.has("permit_alloc") or not GameState.commander["permit_alloc"] is Dictionary:
		GameState.commander["permit_alloc"] = {"plunder": 0, "growth": 0, "power": 0}
	const _CommanderPermitBoost := preload("res://scripts/commander/CommanderPermitBoost.gd")
	_CommanderPermitBoost.sync_earned_from_acknowledged_rank()
	if not GameState.commander.has("name") or str(GameState.commander.get("name", "")).strip_edges().is_empty():
		GameState.commander["name"] = DEFAULT_NAME
	## 既存セーブ: キー欠落は仮 D＋bootstrap フラグ。評価は ensure 外で行う。
	if not GameState.commander.has("acknowledged_rank"):
		GameState.commander["acknowledged_rank"] = "D"
		GameState.commander["_ack_needs_bootstrap"] = true
	else:
		var ack: String = normalize_rank_code(str(GameState.commander.get("acknowledged_rank", "")))
		if not is_valid_rank_code(ack):
			GameState.commander["acknowledged_rank"] = "D"
			GameState.commander["_ack_needs_bootstrap"] = true
	## rank_curve_v2 / v3 欠落は migrate 側で処理（ここでは触らない）。
