class_name RoyalMarkSystem
extends RefCounted

## 王痕育成 API（P3-DG-ROYAL-MARK-001 / Decision 144＋146 分岐）。
## 強化・方針・★到達片・周回抽選・ステ倍率。Save は呼び出し側。

const _Config := preload("res://scripts/systems/RoyalMarkConfig.gd")
const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")


static func sanitize_shards(raw: Variant) -> int:
	return maxi(0, int(raw) if raw != null else 0)


static func sanitize_ranks(raw: Variant) -> Dictionary:
	var out: Dictionary = {}
	if not (raw is Dictionary):
		return out
	for k: Variant in (raw as Dictionary).keys():
		var id: String = _Config.normalize_character_id(str(k))
		if id.is_empty():
			continue
		out[id] = _Config.clamp_rank(int((raw as Dictionary)[k]))
	return out


## Decision 146: path 辞書。不正値は unselected。rank≥III 欠落は unselected を補完。
static func sanitize_paths(raw: Variant, ranks: Dictionary = {}) -> Dictionary:
	var out: Dictionary = {}
	if raw is Dictionary:
		for k: Variant in (raw as Dictionary).keys():
			var id: String = _Config.normalize_character_id(str(k))
			if id.is_empty():
				continue
			out[id] = _Config.normalize_path((raw as Dictionary)[k])
	## Rank III+ で欠落しているキーは unselected（migration／欠損救済）
	for rk: Variant in ranks.keys():
		var rid: String = _Config.normalize_character_id(str(rk))
		if rid.is_empty():
			continue
		if _Config.clamp_rank(int(ranks[rk])) < _Config.PATH_MIN_RANK:
			continue
		if not out.has(rid):
			out[rid] = _Config.PATH_UNSELECTED
	return out


static func get_shards() -> int:
	return sanitize_shards(GameState.royal_mark_shards)


static func set_shards(amount: int) -> void:
	GameState.royal_mark_shards = sanitize_shards(amount)


static func add_shards(amount: int) -> int:
	if amount == 0:
		return get_shards()
	set_shards(get_shards() + amount)
	return get_shards()


static func rank_of_id(character_id: String) -> int:
	var id: String = _Config.normalize_character_id(character_id)
	if id.is_empty():
		return 0
	return _Config.clamp_rank(int(GameState.royal_mark_ranks.get(id, 0)))


static func rank_of_member(member: Resource) -> int:
	if member == null:
		return 0
	return rank_of_id(str(member.id))


static func set_rank(character_id: String, rank: int) -> void:
	var id: String = _Config.normalize_character_id(character_id)
	if id.is_empty():
		return
	var r: int = _Config.clamp_rank(rank)
	if r <= 0:
		GameState.royal_mark_ranks.erase(id)
		GameState.royal_mark_paths.erase(id)
	else:
		GameState.royal_mark_ranks[id] = r
		if r >= _Config.PATH_MIN_RANK and not GameState.royal_mark_paths.has(id):
			GameState.royal_mark_paths[id] = _Config.PATH_UNSELECTED


static func path_of_id(character_id: String) -> String:
	var id: String = _Config.normalize_character_id(character_id)
	if id.is_empty():
		return _Config.PATH_UNSELECTED
	return _Config.normalize_path(GameState.royal_mark_paths.get(id, _Config.PATH_UNSELECTED))


static func path_of_member(member: Resource) -> String:
	if member == null:
		return _Config.PATH_UNSELECTED
	return path_of_id(str(member.id))


## Job Skill 強化モード: none / legacy / technique
static func job_skill_mode_for_member(member: Resource) -> String:
	if member == null:
		return "none"
	var rank: int = rank_of_member(member)
	if rank < _Config.SKILL_ENHANCE_MIN_RANK:
		return "none"
	var path: String = path_of_member(member)
	if path == _Config.PATH_UNSELECTED:
		return "legacy"
	if path == _Config.PATH_TECHNIQUE:
		return "technique"
	return "none"


static func offense_outgoing_mult_for_member(member: Resource) -> float:
	if member == null:
		return 1.0
	var rank: int = rank_of_member(member)
	if rank < _Config.PATH_MIN_RANK:
		return 1.0
	if path_of_member(member) != _Config.PATH_OFFENSE:
		return 1.0
	return _Config.offense_outgoing_mult_for_rank(rank)


static func defense_incoming_mult_for_member(member: Resource) -> float:
	if member == null:
		return 1.0
	var rank: int = rank_of_member(member)
	if rank < _Config.PATH_MIN_RANK:
		return 1.0
	if path_of_member(member) != _Config.PATH_DEFENSE:
		return 1.0
	return _Config.defense_incoming_mult_for_rank(rank)


## ダンジョン攻略中は方針変更不可（current_dungeon_id または DungeonScene）。
static func is_path_change_allowed() -> bool:
	if not str(GameState.current_dungeon_id).is_empty():
		return false
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return true
	var scene_path: String = str(tree.current_scene.scene_file_path)
	if scene_path.ends_with("DungeonScene.tscn"):
		return false
	return true


static func can_set_path(member: Resource, new_path: String) -> Dictionary:
	if not is_eligible_member(member):
		return {"ok": false, "reason": "not_eligible"}
	var id: String = _Config.normalize_character_id(str(member.id))
	var rank: int = rank_of_id(id)
	if rank < _Config.PATH_MIN_RANK:
		return {"ok": false, "reason": "rank_gate", "character_id": id, "rank": rank}
	if not is_path_change_allowed():
		return {"ok": false, "reason": "dungeon_lock", "character_id": id}
	var normalized: String = _Config.normalize_path(new_path)
	if not _Config.is_selected_path(normalized):
		## unselected への復帰は不可（初回未選択以外）
		return {"ok": false, "reason": "cannot_unselect", "character_id": id}
	return {
		"ok": true,
		"character_id": id,
		"rank": rank,
		"path": normalized,
		"prev_path": path_of_id(id),
	}


## 無料・何度でも可。unselected へは戻せない。
static func apply_path(member: Resource, new_path: String) -> Dictionary:
	var check: Dictionary = can_set_path(member, new_path)
	if not bool(check.get("ok", false)):
		return check
	var id: String = str(check.get("character_id", ""))
	var path: String = str(check.get("path", ""))
	if id.is_empty() or path.is_empty():
		return {"ok": false, "reason": "recheck_failed", "character_id": id}
	GameState.royal_mark_paths[id] = path
	return {
		"ok": true,
		"character_id": id,
		"path": path,
		"prev_path": str(check.get("prev_path", _Config.PATH_UNSELECTED)),
	}


static func is_content_unlocked() -> bool:
	## デバッグ全解放時は QA 用にメニュー／強化ゲートを開く。
	if GameState.debug_full_unlock:
		return true
	return _DungeonTierConfig.is_main_campaign_tier_cleared(_DungeonTierConfig.TIER_NORMAL)


static func is_owned_in_roster(character_id: String) -> bool:
	var id: String = _Config.normalize_character_id(character_id)
	if id.is_empty():
		return false
	for m: Variant in GameState.roster:
		if m == null:
			continue
		if str(m.id) == id:
			return true
	return false


static func is_eligible_member(member: Resource) -> bool:
	if member == null:
		return false
	if PetSystem.is_pet_member(member):
		return false
	var id: String = _Config.normalize_character_id(str(member.id))
	return not id.is_empty()


## roster 内の王痕対象人間のみ（Jack／pet 除外）。表示順は roster 順。
static func list_owned_eligible_members() -> Array:
	var out: Array = []
	for m: Variant in GameState.roster:
		if m == null:
			continue
		if not is_eligible_member(m as Resource):
			continue
		out.append(m)
	return out


## UI／戦闘共通。member から累積 HP/ATK/DEF 倍率。
static func stat_multipliers_for_member(member: Resource) -> Dictionary:
	return _Config.stat_multipliers_for_rank(rank_of_member(member))


static func apply_stat_multipliers(hp: int, attack: int, defense: int, member: Resource) -> Dictionary:
	var mults: Dictionary = stat_multipliers_for_member(member)
	return {
		"hp": maxi(1, int(round(float(hp) * float(mults.get("hp", 1.0))))) if hp > 0 else 0,
		"attack": maxi(0, int(round(float(attack) * float(mults.get("attack", 1.0))))),
		"defense": maxi(0, int(round(float(defense) * float(mults.get("defense", 1.0))))),
	}


static func apply_hp_multiplier(hp: int, member: Resource) -> int:
	if hp <= 0 or member == null:
		return hp
	var m: float = float(stat_multipliers_for_member(member).get("hp", 1.0))
	return maxi(1, int(round(float(hp) * m)))


static func apply_attack_multiplier(attack: int, member: Resource) -> int:
	if attack <= 0 or member == null:
		return attack
	var m: float = float(stat_multipliers_for_member(member).get("attack", 1.0))
	return maxi(0, int(round(float(attack) * m)))


static func apply_defense_multiplier(defense: int, member: Resource) -> int:
	if defense <= 0 or member == null:
		return defense
	var m: float = float(stat_multipliers_for_member(member).get("defense", 1.0))
	return maxi(0, int(round(float(defense) * m)))


static func can_upgrade(member: Resource) -> Dictionary:
	if not is_eligible_member(member):
		return {"ok": false, "reason": "not_eligible"}
	var id: String = _Config.normalize_character_id(str(member.id))
	if not is_content_unlocked():
		return {"ok": false, "reason": "locked", "character_id": id}
	if not is_owned_in_roster(id):
		return {"ok": false, "reason": "not_owned", "character_id": id}
	if int(member.level) < _Config.MIN_LEVEL:
		return {
			"ok": false,
			"reason": "level_gate",
			"character_id": id,
			"level": int(member.level),
			"need_level": _Config.MIN_LEVEL,
		}
	var rank: int = rank_of_id(id)
	if rank >= _Config.MAX_RANK:
		return {"ok": false, "reason": "max_rank", "character_id": id, "rank": rank}
	var need_shards: int = _Config.upgrade_shard_cost(rank)
	var need_gold: int = _Config.upgrade_gold_cost(rank)
	var have_shards: int = get_shards()
	var have_gold: int = int(GameState.gold)
	if have_shards < need_shards:
		return {
			"ok": false,
			"reason": "need_shards",
			"character_id": id,
			"rank": rank,
			"need_shards": need_shards,
			"have_shards": have_shards,
			"need_gold": need_gold,
			"have_gold": have_gold,
		}
	if have_gold < need_gold:
		return {
			"ok": false,
			"reason": "need_gold",
			"character_id": id,
			"rank": rank,
			"need_shards": need_shards,
			"have_shards": have_shards,
			"need_gold": need_gold,
			"have_gold": have_gold,
		}
	return {
		"ok": true,
		"character_id": id,
		"rank": rank,
		"next_rank": rank + 1,
		"need_shards": need_shards,
		"need_gold": need_gold,
		"have_shards": have_shards,
		"have_gold": have_gold,
	}


## 全条件再検証後、shards → gold → rank を連続更新。途中 return なし（失敗は減算前）。
static func apply_upgrade(member: Resource) -> Dictionary:
	var check: Dictionary = can_upgrade(member)
	if not bool(check.get("ok", false)):
		return check
	var id: String = str(check.get("character_id", ""))
	var need_shards: int = int(check.get("need_shards", 0))
	var need_gold: int = int(check.get("need_gold", 0))
	var next_rank: int = int(check.get("next_rank", 0))
	## 再検証直後に確定値で一括適用（途中 return 禁止）
	var shards_now: int = get_shards()
	var gold_now: int = int(GameState.gold)
	if shards_now < need_shards or gold_now < need_gold or id.is_empty() or next_rank <= 0:
		return {"ok": false, "reason": "recheck_failed", "character_id": id}
	GameState.royal_mark_shards = shards_now - need_shards
	GameState.gold = gold_now - need_gold
	var clamped_next: int = _Config.clamp_rank(next_rank)
	GameState.royal_mark_ranks[id] = clamped_next
	## III 到達時: path 未設定なら unselected（初回選択待ち）
	if clamped_next >= _Config.PATH_MIN_RANK and not GameState.royal_mark_paths.has(id):
		GameState.royal_mark_paths[id] = _Config.PATH_UNSELECTED
	return {
		"ok": true,
		"character_id": id,
		"rank": next_rank,
		"spent_shards": need_shards,
		"spent_gold": need_gold,
	}


## 極限 CLEAR 報酬。二重 commit は GameState.extreme_run_reward_committed で防止。
## force_repeat_roll: 0..1 で注入（<0 なら通常 RNG）。rng も可。
static func grant_extreme_clear_rewards(
	dungeon_id: String,
	prev_best: int,
	stars: int,
	rng: RandomNumberGenerator = null,
	force_repeat_roll: float = -1.0
) -> Dictionary:
	var out: Dictionary = {
		"star_shards": 0,
		"repeat_shards": 0,
		"total": 0,
		"repeat_hit": false,
		"skipped_duplicate": false,
	}
	if dungeon_id.is_empty():
		return out
	if bool(GameState.extreme_run_reward_committed):
		out["skipped_duplicate"] = true
		out["star_shards"] = int(GameState.last_run_royal_mark_shards_star)
		out["repeat_shards"] = int(GameState.last_run_royal_mark_shards_repeat)
		out["total"] = int(GameState.last_run_royal_mark_shards_total)
		out["repeat_hit"] = out["repeat_shards"] > 0
		return out
	var star_shards: int = _Config.star_shards_for_progress(prev_best, stars)
	var repeat_shards: int = 0
	var repeat_hit: bool = false
	var roll: float = force_repeat_roll
	if roll < 0.0:
		roll = rng.randf() if rng != null else randf()
	if roll < _Config.REPEAT_CHANCE:
		repeat_hit = true
		repeat_shards = _Config.REPEAT_SHARDS
	var total: int = star_shards + repeat_shards
	if total > 0:
		add_shards(total)
	GameState.extreme_run_reward_committed = true
	GameState.last_run_royal_mark_shards_star = star_shards
	GameState.last_run_royal_mark_shards_repeat = repeat_shards
	GameState.last_run_royal_mark_shards_total = total
	out["star_shards"] = star_shards
	out["repeat_shards"] = repeat_shards
	out["total"] = total
	out["repeat_hit"] = repeat_hit
	return out


## v17→v18: extreme_mission_progress の best_stars から一度だけ遡及。
static func compute_retroactive_shards_from_progress(progress: Dictionary) -> int:
	var total: int = 0
	if progress.is_empty():
		return 0
	for dungeon_id: String in Constants.EXTREME_MISSION_PLAYABLE_IDS:
		var entry: Variant = progress.get(dungeon_id, {})
		if not (entry is Dictionary):
			continue
		var best: int = clampi(int((entry as Dictionary).get("best_stars", 0)), 0, 4)
		total += _Config.retroactive_shards_for_best(best)
	return total
