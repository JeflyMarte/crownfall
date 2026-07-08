extends Node

const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")
const _RunCombatStats = preload("res://scripts/result/RunCombatStats.gd")
const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _PassiveProgression = preload("res://scripts/systems/PassiveProgression.gd")

# 所持ゴールド（永続）
var gold: int = 0

# 編成中（アクティブ）の冒険者リスト（Adventurer Resource × 最大3）。roster の部分集合（参照）。
var party_members: Array = []

# 所持冒険者ロスター（基本5職 + ガチャ入手分）。party_members はここから3名選択（P3-D036b）。
var roster: Array = []

# ガチャ通貨（無償のみ） — P3-D036b
var gacha_token: int = 0  ## 魔晶石（ガチャ通貨・表示名は CurrencyHelper）
## EquipmentScene 起動時に選択するメンバー index（-1=先頭）。RosterScene 詳細ボタン用（P3-UI2-017）。
var equipment_focus_member_index: int = -1
## BaseScene 起動時ビュー: "hub" | "menu_grid"（下ナビ「メニュー」用・P3-UI-Base-A）。
var base_initial_view: String = "hub"
## 拠点機能遷移時の NPC 1行台詞（P3-LORE-003）。{ npc, line }。
var hub_npc_hint: Dictionary = {}
# ガチャ所持数 { helper_id: count }（重複＝凸用カウント。MVP は還元のみ）
var owned_helpers: Dictionary = {}
# 天井カウンタ（未所持が出ていない連続抽選回数）
var gacha_pity: int = 0

# 所持アイテムリスト（WeaponInstance）
var inventory: Array = []

# 現在選択中のダンジョンID
var current_dungeon_id: String = ""

## 選択中のサブステージ ID（P3-DG-STG）。空=Biome 単体ラン。
var current_stage_id: String = ""

## 章別クリア { stage_id: { cleared: bool } }。
var stage_progress: Dictionary = {}

## 選択中の危険度ティア（0=ノーマル / 1=ハード / 2=ナイトメア — P3-DG-TIER）。
var current_dungeon_tier: int = 0

## ダンジョン別ティアクリア { dungeon_id: { "0": true, "1": true } }。
var dungeon_tier_cleared: Dictionary = {}

# ダンジョン別の発見度・解放状態 { dungeon_id: { discovery: float, hidden_room: bool, hidden_boss: bool } }
var dungeon_progress: Dictionary = {}

# 発見登録 { "category:entry_id": true } — Codex 基盤（P2-Task018）
var discovery_registry: Dictionary = {}

# チュートリアル進行フラグ { flag_name: bool }
var tutorial_flags: Dictionary = {}

var armor_inventory: Array = []
var accessory_inventory: Array = []

var last_run_exp_reward: int = 0
var last_run_gold_reward: int = 0
# 直近ランで獲得した魔晶石（成功時のみ >0） — P3-D036b-D
var last_run_token_reward: int = 0
var last_run_weapon_dropped: String = ""
var last_run_armor_dropped: String = ""
var last_run_accessory_dropped: String = ""
# 直近ランで入手（新規解放）した遺物 id（P3-D093）。Result 表示用。
var last_run_relic_dropped: String = ""
# 直近ランの獲得レベル { member_id: gained_levels } — Result 表示用（P3-D035）
var last_run_level_ups: Dictionary = {}
## 直近ランの EXP スナップショット { member_id: {...} } — Result LvUP アニメ用（P3-UX-RESULT-002）。
var last_run_exp_snapshots: Dictionary = {}
## 直近ランの戦闘統計 { member_id: {...} } — MVP 画面用（P3-UX-RESULT-003）。
var last_run_combat_stats: Dictionary = {}
# 直近ランの帰還種別（Result 表示用）: clear / retire / wipe
const RUN_OUTCOME_CLEAR: String = "clear"
const RUN_OUTCOME_RETIRE: String = "retire"
const RUN_OUTCOME_WIPE: String = "wipe"
var last_run_outcome: String = ""
var last_run_exploration_policy: String = ""
var run_material_start: Dictionary = {}
var last_run_material_gains: Dictionary = {}
var last_run_weather: String = ""
## 直近ランのサブステージ id（Result 表示用 — P3-DG-STG）。
var last_run_stage_id: String = ""
# 直近ランで発動した戦闘補正の回数 { 表示ラベル: 回数 }（P3-UX-001 戦闘可読性）。
# DungeonScene のログ経路で集計し、Result で上位を「効いた戦闘要素」として表示する。
var last_run_modifier_counts: Dictionary = {}

var _run_combat_stats: RefCounted = null

func reset_run_combat_stats() -> void:
	_run_combat_stats = _RunCombatStats.new()

func get_run_combat_stats() -> RefCounted:
	if _run_combat_stats == null:
		_run_combat_stats = _RunCombatStats.new()
	return _run_combat_stats

func record_run_damage(
	member_index: int,
	amount: int,
	skill_id: String = "",
	skill_name: String = ""
) -> void:
	var member: Resource = get_combatant(member_index)
	if member == null:
		return
	get_run_combat_stats().record_damage(str(member.id), amount, skill_id, skill_name)

func record_run_heal(member_index: int, amount: int) -> void:
	var member: Resource = get_combatant(member_index)
	if member == null:
		return
	get_run_combat_stats().record_heal(str(member.id), amount)

func record_run_modifier(label: String) -> void:
	if label.is_empty():
		return
	last_run_modifier_counts[label] = int(last_run_modifier_counts.get(label, 0)) + 1

## 発動回数の多い順に上位 limit 件を [{label, count}] で返す。
func top_run_modifiers(limit: int = 3) -> Array:
	var entries: Array = []
	for label in last_run_modifier_counts:
		entries.append({"label": str(label), "count": int(last_run_modifier_counts[label])})
	entries.sort_custom(func(a, b): return int(a["count"]) > int(b["count"]))
	return entries.slice(0, limit)

# ギルド日課（P3-DAILY）— SaveManager が永続化。
var daily_mission_state: Dictionary = {}

func begin_run_material_tracking() -> void:
	run_material_start = material_inventory.duplicate()
	last_run_material_gains = {}

func _compute_run_material_gains() -> Dictionary:
	var gains: Dictionary = {}
	var all_keys: Dictionary = {}
	for k in run_material_start.keys():
		all_keys[str(k)] = true
	for k in material_inventory.keys():
		all_keys[str(k)] = true
	for mat_id: String in all_keys.keys():
		var delta: int = get_material_quantity(mat_id) - int(run_material_start.get(mat_id, 0))
		if delta > 0:
			gains[mat_id] = delta
	return gains

func snapshot_last_run_context() -> void:
	last_run_exploration_policy = current_exploration_policy
	last_run_material_gains = _compute_run_material_gains()
	last_run_weather = current_weather

static func run_outcome_label(outcome: String) -> String:
	match outcome:
		RUN_OUTCOME_CLEAR:
			return "完走"
		RUN_OUTCOME_RETIRE:
			return "リタイア（クリアなし）"
		RUN_OUTCOME_WIPE:
			return "全滅"
		_:
			return "—"

# 素材インベントリ { material_id: quantity } — P2-Task024
var material_inventory: Dictionary = {}

func get_active_dungeon_id() -> String:
	if current_dungeon_id.is_empty():
		return Constants.DEFAULT_DUNGEON_ID
	return current_dungeon_id

func get_active_stage_id() -> String:
	return current_stage_id

func is_stage_cleared(stage_id: String, tier: int = -1) -> bool:
	if stage_id.is_empty():
		return false
	var progress: Dictionary = stage_progress.get(stage_id, {})
	if tier < 0:
		return bool(progress.get("cleared", false))
	var tiers: Dictionary = progress.get("tiers", {})
	return bool(tiers.get(str(_DungeonTierConfig.clamp_tier(tier)), false))

func mark_stage_cleared(stage_id: String, tier: int = -1) -> void:
	if stage_id.is_empty():
		return
	var t: int = _DungeonTierConfig.clamp_tier(tier if tier >= 0 else current_dungeon_tier)
	var progress: Dictionary = stage_progress.get(stage_id, {})
	progress["cleared"] = true
	var tiers: Dictionary = progress.get("tiers", {})
	if not tiers is Dictionary:
		tiers = {}
	tiers[str(t)] = true
	progress["tiers"] = tiers
	stage_progress[stage_id] = progress
	var stage: Resource = DataRegistry.get_stage_data(stage_id)
	if stage == null:
		return
	var biome_id: String = str(stage.biome_id)
	if bool(stage.has_boss_floor()):
		mark_dungeon_tier_cleared(biome_id, t)
		if t == _DungeonTierConfig.TIER_NORMAL:
			mark_dungeon_cleared(biome_id)

func count_cleared_stages(biome_id: String) -> int:
	var count: int = 0
	for stage in DataRegistry.get_stages_for_biome(biome_id):
		if stage != null and is_stage_cleared(str(stage.id)):
			count += 1
	return count

func get_stage_progress_label(biome_id: String) -> String:
	if not Constants.SUB_STAGES_PLAYABLE:
		return ""
	var stages: Array = DataRegistry.get_stages_for_biome(biome_id)
	if stages.is_empty():
		return ""
	return "章 %d/%d" % [count_cleared_stages(biome_id), stages.size()]

func sanitize_current_stage_id() -> void:
	if current_stage_id.is_empty():
		return
	var stage: Resource = DataRegistry.get_stage_data(current_stage_id)
	if stage == null or not is_stage_unlocked(current_stage_id):
		current_stage_id = ""
		return
	if not current_dungeon_id.is_empty() and str(stage.biome_id) != current_dungeon_id:
		current_stage_id = ""

func sync_progress_from_stages() -> void:
	if not Constants.SUB_STAGES_PLAYABLE:
		return
	for data in DataRegistry.get_all_dungeon_data():
		if data == null or str(data.route_type) != "main":
			continue
		var biome_id: String = str(data.id)
		var final_stage: Resource = DataRegistry.get_stage_by_chapter(biome_id, 5)
		if final_stage == null:
			continue
		var final_id: String = str(final_stage.id)
		if not is_stage_cleared(final_id):
			continue
		var prog: Dictionary = stage_progress.get(final_id, {})
		var tiers: Dictionary = prog.get("tiers", {})
		if tiers.is_empty() and bool(prog.get("cleared", false)):
			mark_dungeon_cleared(biome_id)
			mark_dungeon_tier_cleared(biome_id, _DungeonTierConfig.TIER_NORMAL)
			continue
		for tier_key in tiers.keys():
			if bool(tiers[tier_key]):
				mark_dungeon_tier_cleared(biome_id, int(tier_key))
		if bool(tiers.get(str(_DungeonTierConfig.TIER_NORMAL), false)):
			mark_dungeon_cleared(biome_id)

func is_stage_unlocked(stage_id: String) -> bool:
	if stage_id.is_empty():
		return false
	var stage: Resource = DataRegistry.get_stage_data(stage_id)
	if stage == null:
		return false
	if not is_dungeon_unlocked(str(stage.biome_id)):
		return false
	if int(stage.chapter_index) <= 1:
		return true
	var prev: Resource = DataRegistry.get_stage_by_chapter(str(stage.biome_id), int(stage.chapter_index) - 1)
	if prev == null:
		return true
	return is_stage_cleared(str(prev.id))

func resolve_stage_for_run(biome_id: String) -> String:
	if not Constants.SUB_STAGES_PLAYABLE:
		return ""
	if not current_stage_id.is_empty():
		var selected: Resource = DataRegistry.get_stage_data(current_stage_id)
		if selected != null and str(selected.biome_id) == biome_id and is_stage_unlocked(current_stage_id):
			return current_stage_id
	var stages: Array = DataRegistry.get_stages_for_biome(biome_id)
	if stages.is_empty():
		return ""
	for stage in stages:
		if is_stage_unlocked(str(stage.id)) and not is_stage_cleared(str(stage.id)):
			return str(stage.id)
	for stage in stages:
		if is_stage_unlocked(str(stage.id)):
			return str(stage.id)
	return str(stages[0].id)

# ダンジョン選択画面の CLEAR バッジ用。ラン完走（ボス突破→EXIT 到達）時に立てる。
func mark_dungeon_cleared(dungeon_id: String) -> void:
	if dungeon_id.is_empty():
		return
	var progress: Dictionary = dungeon_progress.get(dungeon_id, {})
	progress["cleared"] = true
	dungeon_progress[dungeon_id] = progress

func is_dungeon_cleared(dungeon_id: String) -> bool:
	if dungeon_id.is_empty():
		return false
	if Constants.SUB_STAGES_PLAYABLE:
		var final_stage: Resource = DataRegistry.get_stage_by_chapter(dungeon_id, 5)
		if final_stage != null:
			var final_id: String = str(final_stage.id)
			var prog: Dictionary = stage_progress.get(final_id, {})
			var tiers: Dictionary = prog.get("tiers", {})
			if bool(tiers.get(str(_DungeonTierConfig.TIER_NORMAL), false)):
				return true
			if bool(prog.get("cleared", false)) and tiers.is_empty():
				return true
	var progress: Dictionary = dungeon_progress.get(dungeon_id, {})
	return bool(progress.get("cleared", false))

func is_dungeon_tier_cleared(dungeon_id: String, tier: int) -> bool:
	if dungeon_id.is_empty():
		return false
	var per_dungeon: Variant = dungeon_tier_cleared.get(dungeon_id, {})
	if not per_dungeon is Dictionary:
		return false
	return bool((per_dungeon as Dictionary).get(str(_DungeonTierConfig.clamp_tier(tier)), false))

func is_dungeon_tier_unlocked(dungeon_id: String, tier: int) -> bool:
	var t: int = _DungeonTierConfig.clamp_tier(tier)
	if t == _DungeonTierConfig.TIER_NORMAL:
		return true
	return is_dungeon_tier_cleared(dungeon_id, t - 1)

func mark_dungeon_tier_cleared(dungeon_id: String, tier: int) -> void:
	if dungeon_id.is_empty():
		return
	var t: int = _DungeonTierConfig.clamp_tier(tier)
	if not dungeon_tier_cleared.has(dungeon_id):
		dungeon_tier_cleared[dungeon_id] = {}
	var per_dungeon: Dictionary = dungeon_tier_cleared[dungeon_id]
	per_dungeon[str(t)] = true
	dungeon_tier_cleared[dungeon_id] = per_dungeon

# ダンジョン解放判定（P3-D157）。メインルートは難易度順の直列解放
# メイン以外（サブルート等）は当面 unlock_after_dungeon_id（空=常時解放）で判定する。
func is_dungeon_unlocked(dungeon_id: String) -> bool:
	if dungeon_id.is_empty() or not ResourceLoader.exists(Constants.RESOURCE_DUNGEONS_PATH + dungeon_id + ".tres"):
		return false
	var data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
	if data == null:
		return false
	if not Constants.is_playable_dungeon_route(str(data.route_type)):
		return false
	if str(data.route_type) != "main":
		var req: String = str(data.unlock_after_dungeon_id) if "unlock_after_dungeon_id" in data else ""
		return req.is_empty() or is_dungeon_cleared(req)
	var mains: Array = []
	for d in DataRegistry.get_all_dungeon_data():
		if d != null and str(d.route_type) == "main":
			mains.append(d)
	mains.sort_custom(func(a, b): return int(a.difficulty) < int(b.difficulty))
	var prev_id: String = ""
	for d in mains:
		if str(d.id) == dungeon_id:
			return prev_id.is_empty() or is_dungeon_cleared(prev_id)
		prev_id = str(d.id)
	return false

func get_member(member_index: int) -> Resource:
	if member_index < 0 or member_index >= party_members.size():
		return null
	return party_members[member_index]

func get_member_equipped_weapon(member_index: int) -> Resource:
	var member: Resource = get_member(member_index)
	if member == null:
		return null
	return member.equipped_weapon

func get_member_equipped_armor(member_index: int) -> Resource:
	var member: Resource = get_member(member_index)
	if member == null:
		return null
	return member.equipped_armor

func get_member_equipped_accessory(member_index: int) -> Resource:
	var member: Resource = get_member(member_index)
	if member == null:
		return null
	return member.equipped_accessory

# ---- 装備スキル（P3-D077 / P3-SKILL-001） ----
# 解放済みジョブスキルの先頭 MAX_EQUIPPED_SKILLS 個を既定装備とする。
func get_default_skill_ids(member: Resource) -> Array[String]:
	var out: Array[String] = []
	if member == null:
		return out
	for sid in SkillProgression.get_unlocked_job_skill_ids(member):
		if out.size() >= Constants.MAX_EQUIPPED_SKILLS:
			break
		out.append(sid)
	return out

# 現在の装備スキル。未設定（空）なら解放済み既定にフォールバック。
func get_equipped_skill_ids(member: Resource) -> Array[String]:
	if member == null:
		return [] as Array[String]
	SkillProgression.normalize_equipped_skills(member)
	if "equipped_skill_ids" in member and not member.equipped_skill_ids.is_empty():
		return member.equipped_skill_ids
	return get_default_skill_ids(member)

# スキルの装備/解除トグル（最大 MAX_EQUIPPED_SKILLS）。未解放は不可。
func toggle_member_skill(member: Resource, skill_id: String) -> void:
	if member == null or skill_id.is_empty():
		return
	if not SkillProgression.can_equip_job_skill(member, skill_id):
		return
	var ids: Array[String] = get_equipped_skill_ids(member).duplicate()
	if ids.has(skill_id):
		ids.erase(skill_id)
	elif ids.size() < Constants.MAX_EQUIPPED_SKILLS:
		ids.append(skill_id)
	else:
		return
	member.equipped_skill_ids = ids

# ---- 装備パッシブ（P3-D088 拡張 / P3-RELIC-PASSIVE） ----
func get_default_passive_ids(member: Resource) -> Array[String]:
	var out: Array[String] = []
	if member == null:
		return out
	for pid in CombatPassives.selectable_passive_ids(member):
		if out.size() >= Constants.MAX_EQUIPPED_PASSIVES:
			break
		out.append(pid)
	return out

func get_equipped_character_passive_ids(member: Resource) -> Array[String]:
	if member == null:
		return [] as Array[String]
	_PassiveProgression.normalize_equipped_passives(member)
	var out: Array[String] = []
	for pid: String in get_equipped_passive_ids(member):
		if CombatPassives.is_relic_passive(pid):
			continue
		out.append(pid)
	return out

func get_equipped_relic_passive_id(member: Resource) -> String:
	if member == null:
		return ""
	_PassiveProgression.normalize_equipped_passives(member)
	for pid: String in get_equipped_passive_ids(member):
		if CombatPassives.is_relic_passive(pid):
			return pid
	return ""

func get_equipped_passive_ids(member: Resource) -> Array[String]:
	if member == null:
		return [] as Array[String]
	_PassiveProgression.normalize_equipped_passives(member)
	if _passive_slots_customized(member):
		return member.equipped_passive_ids
	if "equipped_passive_ids" in member and not member.equipped_passive_ids.is_empty():
		return member.equipped_passive_ids
	return get_default_passive_ids(member)

func _passive_slots_customized(member: Resource) -> bool:
	return "passive_slots_customized" in member and bool(member.passive_slots_customized)

func toggle_member_passive(member: Resource, passive_id: String) -> void:
	if member == null or passive_id.is_empty() or CombatPassives.is_relic_passive(passive_id):
		return
	if not _PassiveProgression.can_equip_passive(member, passive_id):
		return
	var char_ids: Array[String] = get_equipped_character_passive_ids(member).duplicate()
	var relic_id: String = get_equipped_relic_passive_id(member)
	if char_ids.has(passive_id):
		char_ids.erase(passive_id)
	else:
		if char_ids.size() >= Constants.MAX_EQUIPPED_PASSIVES:
			char_ids.clear()
		char_ids.append(passive_id)
	_set_equipped_passive_slots(member, char_ids, relic_id, true)

func toggle_member_relic_passive(member: Resource, passive_id: String) -> void:
	if member == null:
		return
	var char_ids: Array[String] = get_equipped_character_passive_ids(member).duplicate()
	var relic_id: String = get_equipped_relic_passive_id(member)
	if passive_id.is_empty():
		relic_id = ""
	elif not CombatPassives.is_relic_passive(passive_id) or not has_relic(passive_id):
		return
	elif relic_id == passive_id:
		relic_id = ""
	else:
		relic_id = passive_id
	_set_equipped_passive_slots(member, char_ids, relic_id, true)

func _set_equipped_passive_slots(
	member: Resource,
	char_ids: Array[String],
	relic_id: String,
	mark_customized: bool = false,
) -> void:
	var merged: Array[String] = char_ids.duplicate()
	if not relic_id.is_empty():
		merged.append(relic_id)
	member.equipped_passive_ids = merged
	if mark_customized and "passive_slots_customized" in member:
		member.passive_slots_customized = true

func normalize_all_equipped_passives() -> void:
	for member in roster:
		_PassiveProgression.normalize_equipped_passives(member)

func normalize_all_equipped_skills() -> void:
	for member in roster:
		SkillProgression.normalize_equipped_skills(member)

# ---- 戦術（AI設定・P3-D086） ----
# メンバーの戦術 id（未設定/無効なら既定 "balanced"）。
func get_member_tactics_id(member: Resource) -> String:
	if member == null:
		return CombatTactics.DEFAULT_TACTICS_ID
	if "tactics_id" in member:
		return CombatTactics.normalize_id(str(member.tactics_id))
	return CombatTactics.DEFAULT_TACTICS_ID

func set_member_tactics(member: Resource, tactics_id: String) -> void:
	if member == null:
		return
	member.tactics_id = CombatTactics.normalize_id(tactics_id)

# ---- カスタム戦術（ガンビット・A1） ----
func get_member_tactics_custom_enabled(member: Resource) -> bool:
	if member != null and "tactics_custom_enabled" in member:
		return bool(member.tactics_custom_enabled)
	return false

func set_member_tactics_custom_enabled(member: Resource, enabled: bool) -> void:
	if member == null:
		return
	member.tactics_custom_enabled = enabled

func get_member_tactics_custom_target(member: Resource) -> String:
	if member == null:
		return CombatTactics.DEFAULT_TARGET
	if "tactics_custom_target" in member:
		var target: String = str(member.tactics_custom_target)
		if target in CombatTactics.TARGET_RULES:
			return target
	return CombatTactics.DEFAULT_TARGET

func set_member_tactics_custom_target(member: Resource, target: String) -> void:
	if member == null:
		return
	member.tactics_custom_target = target if target in CombatTactics.TARGET_RULES else CombatTactics.DEFAULT_TARGET

func get_member_tactics_custom_plan(member: Resource) -> Array:
	if member == null:
		return []
	if "tactics_custom_plan" in member and member.tactics_custom_plan is Array:
		return CombatGambit.normalize_plan(member.tactics_custom_plan)
	return []

func set_member_tactics_custom_plan(member: Resource, plan: Array) -> void:
	if member == null:
		return
	member.tactics_custom_plan = CombatGambit.normalize_plan(plan)

func copy_member_tactics_preset_to_custom(member: Resource) -> void:
	if member == null:
		return
	var tid: String = get_member_tactics_id(member)
	member.tactics_custom_target = CombatTactics.get_target_rule(tid)
	var raw: Array = CombatTactics.get_slot_plan(tid).duplicate(true)
	member.tactics_custom_plan = CombatGambit.normalize_plan(CombatGambit.assign_skill_indices_for_copy(raw))
	member.tactics_custom_enabled = true

# ---- レリック（解放型パッシブ・P3-RELIC-PASSIVE） ----
func get_member_relic_id(member: Resource) -> String:
	return get_equipped_relic_passive_id(member)

func set_member_relic(member: Resource, relic_id: String) -> void:
	if member == null:
		return
	var pid: String = CombatPassives.migrate_relic_passive_id(relic_id)
	if pid.is_empty():
		toggle_member_relic_passive(member, "")
		return
	if not has_relic(pid):
		return
	for other in party_members:
		if other != null and other != member and get_equipped_relic_passive_id(other) == pid:
			toggle_member_relic_passive(other, "")
	toggle_member_relic_passive(member, pid)

# ---- 陣形（前列/後列・P3-D106） ----
const FORMATION_FRONT: int = 0
const FORMATION_BACK: int = 1
const FORMATION_BACK_INCOMING: float = BalanceConfig.FORMATION_BACK_INCOMING  # 後列の被ダメ倍率
const FORMATION_BACK_THREAT: float = BalanceConfig.FORMATION_BACK_THREAT     # 後列の Threat 基礎倍率
const FORMATION_MELEE_BACK_OUTGOING: float = 0.85
const FORMATION_LONG_FRONT_OUTGOING: float = 0.85
const FORMATION_MID_BACK_OUTGOING: float = 0.92

func get_member_formation_row(member: Resource) -> int:
	if member != null and "formation_row" in member:
		return FORMATION_BACK if int(member.formation_row) == FORMATION_BACK else FORMATION_FRONT
	return FORMATION_FRONT

func set_member_formation_row(member: Resource, row: int) -> void:
	if member == null:
		return
	member.formation_row = FORMATION_BACK if row == FORMATION_BACK else FORMATION_FRONT

func get_member_formation_slot(member: Resource) -> int:
	if member != null and "formation_slot" in member:
		return clampi(int(member.formation_slot), 0, 3)
	return 0

func set_member_formation_slot(member: Resource, slot: int) -> void:
	if member == null:
		return
	member.formation_slot = clampi(slot, 0, 3)

func get_combatant_formation_slot(member_index: int) -> int:
	return get_member_formation_slot(get_combatant(member_index))

# formation_slot 未保存の旧データ向け。formation_row から空きスロットへ割当。
func migrate_formation_slots_if_needed() -> void:
	var needs_unset: bool = false
	for m in party_members:
		if m != null and int(m.formation_slot) < 0:
			needs_unset = true
			break
	if needs_unset:
		var front_fill: int = 0
		var back_fill: int = 0
		for m in party_members:
			if m == null or int(m.formation_slot) >= 0:
				continue
			if get_member_formation_row(m) == FORMATION_BACK:
				m.formation_slot = 2 + (back_fill % 2)
				back_fill += 1
			else:
				m.formation_slot = front_fill % 2
				front_fill += 1
	_dedupe_formation_slots()

# 初期編成などで formation_slot が全員 0 のまま重なると、戦闘場で1体しか見えない。
func _dedupe_formation_slots() -> void:
	var used: Dictionary = {}
	var overflow: Array = []
	for m in party_members:
		if m == null:
			continue
		var slot: int = clampi(int(m.formation_slot), 0, 3)
		if not used.has(slot):
			m.formation_slot = slot
			used[slot] = m
		else:
			overflow.append(m)
	for m in overflow:
		for candidate in range(4):
			if not used.has(candidate):
				m.formation_slot = candidate
				used[candidate] = m
				break

func is_member_back_row(member_index: int) -> bool:
	return get_member_formation_row(get_combatant(member_index)) == FORMATION_BACK

# 後列の被ダメ軽減倍率（CombatController が乗算）。
func formation_incoming_multiplier(member_index: int) -> float:
	return FORMATION_BACK_INCOMING if is_member_back_row(member_index) else 1.0

# 行の Threat 基礎倍率（後列は狙われにくい）。
func formation_threat_multiplier(member_index: int) -> float:
	return FORMATION_BACK_THREAT if is_member_back_row(member_index) else 1.0

# 陣形×射程の与ダメ倍率（P3-D106b）。
func formation_range_outgoing_multiplier(member_index: int, range_cat: String) -> float:
	var back := is_member_back_row(member_index)
	match range_cat:
		"melee":
			return FORMATION_MELEE_BACK_OUTGOING if back else 1.0
		"long", "global":
			return FORMATION_LONG_FRONT_OUTGOING if not back else 1.0
		"mid":
			return FORMATION_MID_BACK_OUTGOING if back else 1.0
		_:
			return 1.0

func formation_range_log_tag(member_index: int, range_cat: String) -> String:
	if formation_range_outgoing_multiplier(member_index, range_cat) >= 1.0:
		return ""
	match range_cat:
		"melee":
			return "  [陣形:近接不利]"
		"long", "global":
			return "  [陣形:遠隔不利]"
		"mid":
			return "  [陣形:中距離不利]"
		_:
			return ""

# 陣形プリセット適用（前から row 数だけ前列、残りを後列）。preset: "balanced"/"front"/"back"
func apply_formation_preset(preset: String) -> void:
	var n: int = party_members.size()
	var front_count: int = n
	match preset:
		"front": front_count = n
		"back": front_count = maxi(1, n - 2)
		_: front_count = maxi(1, n - 1) # balanced=最後尾1人を後列
	for i in n:
		set_member_formation_row(party_members[i], FORMATION_FRONT if i < front_count else FORMATION_BACK)

# ---- レリック 所持（解放型） ----
var owned_relics: Array = []

func has_relic(relic_id: String) -> bool:
	var pid: String = CombatPassives.migrate_relic_passive_id(str(relic_id))
	return pid in owned_relics

func unlock_relic(relic_id: String) -> bool:
	var rid: String = CombatPassives.migrate_relic_passive_id(relic_id)
	if rid.is_empty() or rid in owned_relics:
		return false
	owned_relics.append(rid)
	return true

func unowned_relic_ids() -> Array:
	var out: Array = []
	for rid: String in CombatPassives.relic_passive_ids():
		if rid not in owned_relics:
			out.append(rid)
	return out

# ---- 作戦プリセット（P3-D091 / P3-D121） ----
# party 全体の「戦術＋遺物＋装備＋探索方針」を最大 COMBAT_PRESET_SLOTS スロット保存し、一括適用する。
# 各スロット: {"name", "exploration_policy", "settings": { member_id: {tactics_id, relic_id,
#   weapon_instance_id, armor_instance_id, accessory_instance_id} }}
# member_id キーで保持するため編成順が変わっても正しく復元できる。
const COMBAT_PRESET_SLOTS: int = 3
var combat_presets: Array = []

# 探索方針（P3-D098）。run 単位で1つ。プリセットに内包され、適用時にここへ反映される。
# ""=なし / safe=安全優先 / material=素材優先 / relic=遺物優先 / codex=図鑑優先
const EXPLORATION_POLICIES: Array = ["", "safe", "material", "relic", "codex"]
var current_exploration_policy: String = ""

func get_exploration_policy() -> String:
	return current_exploration_policy

func set_exploration_policy(policy: String) -> void:
	current_exploration_policy = policy if policy in EXPLORATION_POLICIES else ""

static func exploration_policy_label(policy: String) -> String:
	match policy:
		"safe": return "安全優先"
		"material": return "素材優先"
		"relic": return "レリック優先"
		"codex": return "図鑑優先"
		_: return "なし"

static func exploration_policy_hint(policy: String) -> String:
	match policy:
		"safe": return "被ダメ×0.92・群れ出現率半減"
		"material": return "Gold+15%・ELITE素材率UP"
		"relic": return "ボス+5%・ELITE+5% レリック率UP"
		"codex": return "図鑑進捗2倍・未完了敵はEXP+10%・素材率UP"
		_: return "方針なし（通常報酬）"

# 安全優先＝被ダメ軽減倍率（CombatController が乗算）。
func exploration_incoming_multiplier() -> float:
	return 0.92 if current_exploration_policy == "safe" else 1.0

# 天候（環境変化・P3-D101）。run 開始時に DungeonController が抽選してセット。run 揮発。
var current_weather: String = ""

func get_weather() -> String:
	return current_weather

func set_weather(weather: String) -> void:
	current_weather = weather

func get_combat_presets() -> Array:
	return combat_presets

func has_combat_preset(slot: int) -> bool:
	if slot < 0 or slot >= combat_presets.size():
		return false
	var p = combat_presets[slot]
	return p is Dictionary and not (p as Dictionary).is_empty()

func get_combat_preset_name(slot: int) -> String:
	if not has_combat_preset(slot):
		return ""
	return str((combat_presets[slot] as Dictionary).get("name", ""))

func get_combat_preset_summary(slot: int) -> String:
	if not has_combat_preset(slot):
		return ""
	var settings: Dictionary = (combat_presets[slot] as Dictionary).get("settings", {})
	var equip_count: int = 0
	for raw in settings.values():
		if not raw is Dictionary:
			continue
		var s: Dictionary = raw as Dictionary
		for key: String in ["weapon_instance_id", "armor_instance_id", "accessory_instance_id"]:
			if not str(s.get(key, "")).is_empty():
				equip_count += 1
	var parts: PackedStringArray = PackedStringArray()
	if equip_count > 0:
		parts.append("装備%d" % equip_count)
	var policy: String = str((combat_presets[slot] as Dictionary).get("exploration_policy", ""))
	if not policy.is_empty():
		parts.append(exploration_policy_label(policy))
	var custom_count: int = 0
	for raw in settings.values():
		if not raw is Dictionary:
			continue
		if bool((raw as Dictionary).get("tactics_custom_enabled", false)):
			custom_count += 1
	if custom_count > 0:
		parts.append("カスタム%d" % custom_count)
	return "・".join(parts)

func find_weapon_instance(instance_id: String) -> Resource:
	if instance_id.is_empty():
		return null
	for item in inventory:
		if item != null and str(item.instance_id) == instance_id:
			return item
	return null

func find_armor_instance(instance_id: String) -> Resource:
	if instance_id.is_empty():
		return null
	for item in armor_inventory:
		if item != null and str(item.instance_id) == instance_id:
			return item
	return null

func find_accessory_instance(instance_id: String) -> Resource:
	if instance_id.is_empty():
		return null
	for item in accessory_inventory:
		if item != null and str(item.instance_id) == instance_id:
			return item
	return null

static func _equipped_instance_id(item: Resource) -> String:
	if item == null:
		return ""
	if "instance_id" in item:
		return str(item.instance_id)
	return ""

# 現在の party 全員の戦術/遺物をスロットへ保存。name 空なら "作戦N"。
func save_combat_preset(slot: int, preset_name: String = "") -> void:
	if slot < 0 or slot >= COMBAT_PRESET_SLOTS:
		return
	var settings: Dictionary = {}
	for member in party_members:
		if member == null:
			continue
		settings[str(member.id)] = {
			"tactics_id": get_member_tactics_id(member),
			"relic_passive_id": get_equipped_relic_passive_id(member),
			"tactics_custom_enabled": get_member_tactics_custom_enabled(member),
			"tactics_custom_target": get_member_tactics_custom_target(member),
			"tactics_custom_plan": get_member_tactics_custom_plan(member).duplicate(true),
			"weapon_instance_id": _equipped_instance_id(member.equipped_weapon),
			"armor_instance_id": _equipped_instance_id(member.equipped_armor),
			"accessory_instance_id": _equipped_instance_id(member.equipped_accessory),
		}
	while combat_presets.size() <= slot:
		combat_presets.append({})
	var nm: String = preset_name.strip_edges()
	if nm.is_empty():
		nm = default_combat_preset_name(slot)
	combat_presets[slot] = {
		"name": nm,
		"settings": settings,
		"exploration_policy": current_exploration_policy,
	}

# 既存プリセットの表示名のみ変更（中身は不変）。
func rename_combat_preset(slot: int, preset_name: String) -> bool:
	if slot < 0 or slot >= COMBAT_PRESET_SLOTS:
		return false
	if not has_combat_preset(slot):
		return false
	var nm: String = preset_name.strip_edges()
	if nm.is_empty():
		return false
	var preset: Dictionary = (combat_presets[slot] as Dictionary).duplicate(true)
	preset["name"] = nm
	combat_presets[slot] = preset
	return true

func default_combat_preset_name(slot: int) -> String:
	return "作戦%d" % (slot + 1)

static func preset_equipment_kind_label(kind: String) -> String:
	match kind:
		"weapon":
			return "武器"
		"armor":
			return "防具"
		"accessory":
			return "装飾品"
		_:
			return kind

static func preset_equipment_skip_label(reason: String) -> String:
	match reason:
		"missing":
			return "未所持"
		"conflict":
			return "他員に使用中"
		_:
			return reason

# スロットの設定を現在の party へ一括適用（member_id 一致分のみ）。
# 戻り値: { ok: bool, skipped: Array[Dictionary] } — skipped 各要素は
# { member_name, kind, reason }（reason = missing | conflict）。
func apply_combat_preset(slot: int) -> Dictionary:
	var empty: Dictionary = {"ok": false, "skipped": []}
	if not has_combat_preset(slot):
		return empty
	var settings: Dictionary = (combat_presets[slot] as Dictionary).get("settings", {})
	var claimed_items: Dictionary = {}
	var skipped: Array = []
	for i in party_members.size():
		var member: Resource = party_members[i]
		if member == null:
			continue
		var s = settings.get(str(member.id), {})
		if not (s is Dictionary) or (s as Dictionary).is_empty():
			continue
		var entry: Dictionary = s as Dictionary
		set_member_tactics(member, str(entry.get("tactics_id", "")))
		var relic_raw: String = str(entry.get("relic_passive_id", entry.get("relic_id", "")))
		set_member_relic(member, relic_raw)
		if entry.has("tactics_custom_enabled"):
			set_member_tactics_custom_enabled(member, bool(entry.get("tactics_custom_enabled", false)))
		if entry.has("tactics_custom_target"):
			set_member_tactics_custom_target(member, str(entry.get("tactics_custom_target", "")))
		if entry.has("tactics_custom_plan") and entry.get("tactics_custom_plan") is Array:
			set_member_tactics_custom_plan(member, entry.get("tactics_custom_plan"))
		_apply_preset_equipment(member, i, entry, claimed_items, skipped)
	set_exploration_policy(str((combat_presets[slot] as Dictionary).get("exploration_policy", "")))
	return {"ok": true, "skipped": skipped}

func _apply_preset_equipment(member: Resource, member_index: int, entry: Dictionary, claimed_items: Dictionary, skipped: Array) -> void:
	if entry.has("weapon_instance_id"):
		_apply_preset_equipment_slot(
			member, member_index, "weapon",
			str(entry.get("weapon_instance_id", "")),
			claimed_items,
			skipped,
		)
	if entry.has("armor_instance_id"):
		_apply_preset_equipment_slot(
			member, member_index, "armor",
			str(entry.get("armor_instance_id", "")),
			claimed_items,
			skipped,
		)
	if entry.has("accessory_instance_id"):
		_apply_preset_equipment_slot(
			member, member_index, "accessory",
			str(entry.get("accessory_instance_id", "")),
			claimed_items,
			skipped,
		)

func _apply_preset_equipment_slot(
	member: Resource,
	member_index: int,
	kind: String,
	instance_id: String,
	claimed_items: Dictionary,
	skipped: Array,
) -> void:
	if instance_id.is_empty():
		match kind:
			"weapon":
				member.equipped_weapon = null
			"armor":
				member.equipped_armor = null
			"accessory":
				member.equipped_accessory = null
		return
	var item: Resource = null
	match kind:
		"weapon":
			item = find_weapon_instance(instance_id)
		"armor":
			item = find_armor_instance(instance_id)
		"accessory":
			item = find_accessory_instance(instance_id)
	var member_name: String = str(member.display_name) if member != null else "?"
	if item == null:
		skipped.append({"member_name": member_name, "kind": kind, "reason": "missing"})
		return
	if claimed_items.has(instance_id):
		skipped.append({"member_name": member_name, "kind": kind, "reason": "conflict"})
		return
	claimed_items[instance_id] = member_index
	clear_item_from_other_members(item, member_index)
	match kind:
		"weapon":
			member.equipped_weapon = item
		"armor":
			member.equipped_armor = item
		"accessory":
			member.equipped_accessory = item

func find_item_equipped_member_index(item: Resource) -> int:
	if item == null:
		return -1
	for i in party_members.size():
		var member: Resource = party_members[i]
		if member == null:
			continue
		if (
			member.equipped_weapon == item
			or member.equipped_armor == item
			or member.equipped_accessory == item
		):
			return i
	return -1

func clear_item_from_other_members(item: Resource, keep_member_index: int) -> void:
	if item == null:
		return
	for i in party_members.size():
		if i == keep_member_index:
			continue
		var member: Resource = party_members[i]
		if member == null:
			continue
		if member.equipped_weapon == item:
			member.equipped_weapon = null
		if member.equipped_armor == item:
			member.equipped_armor = null
		if member.equipped_accessory == item:
			member.equipped_accessory = null

# 新規ゲーム時にジョブごとへ付与する初期武器 { job_id: weapon_id }
const STARTING_WEAPON_BY_JOB: Dictionary = {
	"swordsman": "iron_sword",
	"ranger": "hunting_bow",
	"alchemist": "apprentice_staff",
	"vanguard": "iron_sword",
	"beast_tamer": "hunting_bow",
}

const _GachaRarityConfig: Script = preload("res://scripts/gacha/GachaRarityConfig.gd")

# 初期ロスター（基本5職・ガチャ対象外の特別キャラ）。アクティブ編成は先頭4名（P3-D036b-9 / P3-D105）。
const BASE_ROSTER_DEFS: Array = [
	{"id": "adventurer_0", "name": "アルド", "job": "swordsman"},
	{"id": "adventurer_1", "name": "リーヴァ", "job": "ranger"},
	{"id": "adventurer_2", "name": "エリアス", "job": "alchemist"},
	{"id": "adventurer_3", "name": "ガレン", "job": "vanguard"},
	{"id": "adventurer_4", "name": "ミレイ", "job": "beast_tamer"},
]
const ACTIVE_PARTY_SIZE: int = 4
# 戦闘スロット上限（スプライト/HPバー枠＝4）。助っ人含む同時表示の最大数（P3-D105）。
const COMBAT_SLOT_MAX: int = 4

func _ready() -> void:
	_init_party()

func _init_party() -> void:
	roster = []
	for def in BASE_ROSTER_DEFS:
		roster.append(_create_base_adventurer(def))
	party_members = []
	for i in mini(ACTIVE_PARTY_SIZE, roster.size()):
		party_members.append(roster[i])
	migrate_formation_slots_if_needed()
	normalize_roster_rarity()
	_grant_starting_equipment()
	normalize_all_equipped_skills()
	normalize_all_equipped_passives()

func _create_base_adventurer(def: Dictionary) -> Resource:
	var adventurer_class = load("res://scripts/domain/Adventurer.gd")
	var adv = adventurer_class.new()
	adv.id = str(def["id"])
	adv.display_name = str(def["name"])
	adv.job_id = str(def["job"])
	adv.rarity = Adventurer.STARTER_RARITY
	_GachaRarityConfig.apply_base_stats_to_adventurer(adv, Adventurer.STARTER_RARITY, CombatController.BASE_MEMBER_HP)
	return adv

# 初期武器を生成し、inventory に登録した上で装備させる（ロスター全員分）。
# 装備品が inventory に存在することは SaveManager の装備復元（instance_id 解決）の前提。
func _grant_starting_equipment() -> void:
	for member in roster:
		_grant_member_starting_weapon(member)

func _grant_member_starting_weapon(member: Resource) -> void:
	if member == null or member.equipped_weapon != null:
		return
	var weapon_id: String = str(STARTING_WEAPON_BY_JOB.get(member.job_id, ""))
	if weapon_id.is_empty():
		return
	var instance: Resource = _create_starting_weapon(member.id, weapon_id)
	if instance == null:
		return
	inventory.append(instance)
	member.equipped_weapon = instance

# 旧セーブ復元時など、ロスターに欠けている基本職を補完する（武器も付与）。
func ensure_base_roster_complete() -> void:
	for def in BASE_ROSTER_DEFS:
		if find_roster_member_by_id(str(def["id"])) != null:
			continue
		var adv: Resource = _create_base_adventurer(def)
		roster.append(adv)
		_grant_member_starting_weapon(adv)

# 旧セーブに残る基本職の display_name / job_id を現行定義へ正規化する。
# （旧名「戦士/盗賊/魔術師」等の残存を解消。基本職にカスタム改名機能は無いため上書き安全）
func normalize_base_roster() -> void:
	for def in BASE_ROSTER_DEFS:
		var m: Resource = find_roster_member_by_id(str(def["id"]))
		if m == null:
			continue
		m.display_name = str(def["name"])
		m.job_id = str(def["job"])
		m.rarity = Adventurer.STARTER_RARITY
		_GachaRarityConfig.apply_base_stats_to_adventurer(m, Adventurer.STARTER_RARITY, CombatController.BASE_MEMBER_HP)

# スターター5職の★を揃え、ガチャ助っ人は helper 定義へ同期する。
func normalize_roster_rarity() -> void:
	for adv in roster:
		if adv == null:
			continue
		var adv_id: String = str(adv.id)
		if adv_id.begins_with("gacha_"):
			continue
		if find_base_roster_def(adv_id) != null:
			adv.rarity = Adventurer.STARTER_RARITY

func find_base_roster_def(adventurer_id: String) -> Variant:
	for def in BASE_ROSTER_DEFS:
		if str(def["id"]) == adventurer_id:
			return def
	return null

func is_starter_adventurer(adventurer_id: String) -> bool:
	return find_base_roster_def(adventurer_id) != null

func _create_starting_weapon(member_id: String, weapon_id: String) -> Resource:
	var weapon_data: Resource = DataRegistry.get_weapon_data(weapon_id)
	if weapon_data == null:
		return null
	var instance_class = load("res://scripts/domain/WeaponInstance.gd")
	if instance_class == null:
		return null
	var instance = instance_class.new()
	instance.instance_id = "starting_" + member_id + "_" + weapon_id
	instance.weapon_id = weapon_id
	instance.is_appraised = true
	_WeaponStatResolver.apply_drop_stats(instance, weapon_data)
	return instance

# ---- 戦闘参加者（編成メンバーのみ） ----

func get_combatants() -> Array:
	return party_members

func combatant_count() -> int:
	return party_members.size()

func get_combatant(i: int) -> Resource:
	if i < 0 or i >= party_members.size():
		return null
	return party_members[i]

# ---- 生態図鑑進捗（P3-CODEX5-001） ----
const STAGE4_KILLS: int = 3
const STAGE5_KILLS: int = 6

var enemy_codex: Dictionary = {}

func mark_enemy_seen(enemy_id: String) -> void:
	if enemy_id.is_empty():
		return
	if not enemy_codex.has(enemy_id):
		enemy_codex[enemy_id] = {"seen": true, "kills": 0}
	else:
		enemy_codex[enemy_id]["seen"] = true

func add_enemy_kill(enemy_id: String) -> void:
	if enemy_id.is_empty():
		return
	if not enemy_codex.has(enemy_id):
		enemy_codex[enemy_id] = {"seen": true, "kills": 1}
	else:
		enemy_codex[enemy_id]["seen"] = true
		enemy_codex[enemy_id]["kills"] = int(enemy_codex[enemy_id].get("kills", 0)) + 1

func mark_boss_phase_seen(enemy_id: String, phase_index: int) -> void:
	if enemy_id.is_empty() or phase_index < 0:
		return
	mark_enemy_seen(enemy_id)
	var seen: Array = enemy_codex[enemy_id].get("phases_seen", [])
	if phase_index not in seen:
		seen.append(phase_index)
	enemy_codex[enemy_id]["phases_seen"] = seen

func get_boss_phases_seen(enemy_id: String) -> Array:
	if not enemy_codex.has(enemy_id):
		return []
	return (enemy_codex[enemy_id].get("phases_seen", []) as Array).duplicate()

func get_enemy_stage(enemy_id: String) -> int:
	if not enemy_codex.has(enemy_id):
		return 1
	var entry: Dictionary = enemy_codex[enemy_id]
	var kills: int = int(entry.get("kills", 0))
	if kills >= STAGE5_KILLS:
		return 5
	if kills >= STAGE4_KILLS:
		return 4
	if kills >= 1:
		return 3
	if bool(entry.get("seen", false)):
		return 2
	return 1

func add_material(material_id: String, amount: int = 1) -> void:
	if material_id.is_empty() or amount <= 0:
		return
	var current: int = int(material_inventory.get(material_id, 0))
	material_inventory[material_id] = current + amount

func get_material_quantity(material_id: String) -> int:
	return int(material_inventory.get(material_id, 0))

func consume_materials(required_materials: Dictionary) -> bool:
	for mat_id in required_materials:
		if get_material_quantity(mat_id) < int(required_materials[mat_id]):
			return false
	for mat_id in required_materials:
		material_inventory[mat_id] = get_material_quantity(mat_id) - int(required_materials[mat_id])
	print("[GameState] consume_materials: ", required_materials)
	return true

# ---- ロスター / 編成（P3-D036b） ----

func get_roster() -> Array:
	return roster

func is_member_active(adv: Resource) -> bool:
	return adv != null and party_members.has(adv)

func add_roster_member(adv: Resource) -> void:
	if adv != null and not roster.has(adv):
		roster.append(adv)

func find_roster_member_by_id(member_id: String) -> Resource:
	if member_id.is_empty():
		return null
	for adv in roster:
		if adv != null and str(adv.id) == member_id:
			return adv
	return null

# アクティブ編成を更新。members は roster 内 Adventurer の配列（1〜ACTIVE_PARTY_SIZE）。
# 無効（roster外/重複/数超過/空）なら false で現状維持。
func set_active_party(members: Array) -> bool:
	if members.is_empty() or members.size() > ACTIVE_PARTY_SIZE:
		return false
	var seen: Array = []
	for adv in members:
		if adv == null or not roster.has(adv) or seen.has(adv):
			return false
		seen.append(adv)
	party_members = members.duplicate()
	migrate_formation_slots_if_needed()
	return true
