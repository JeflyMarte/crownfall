class_name DamageCalculator
extends RefCounted

const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ArmorStatResolver = preload("res://scripts/equipment/ArmorStatResolver.gd")
const _AccessoryStatResolver = preload("res://scripts/equipment/AccessoryStatResolver.gd")

## ダメージ計算コア（P3-REF-001 — DungeonScene から分離）。
## シーンノードへ依存しない静的関数群。CombatController / DungeonData は引数で受け取り、
## GameState / DataRegistry 等の autoload と静的クラスのみ参照する。
## headless バランスハーネス（tools/balance_sim）とユニットテストから直接呼べる。

# ── 属性解決 ─────────────────────────────────────────────────────────────

static func weapon_element(member_index: int = -1) -> String:
	var weapon: Resource = GameState.get_member_equipped_weapon(member_index)
	return _WeaponStatResolver.resolve_element(weapon)

static func weapon_element_power(member_index: int = -1) -> int:
	var weapon: Resource = GameState.get_member_equipped_weapon(member_index)
	return _WeaponStatResolver.resolve_element_power(weapon)

static func apply_element_power_bonus(damage: int, attack_element: String, member_index: int) -> int:
	if damage <= 0 or attack_element.is_empty() or member_index < 0:
		return damage
	var elem_power: int = weapon_element_power(member_index)
	if elem_power <= 0:
		return damage
	return maxi(
		1,
		int(round(float(damage) * _WeaponStatResolver.element_power_multiplier(elem_power)))
	)

static func resolve_skill_element(skill_data: Resource, member_index: int = -1) -> String:
	if skill_data != null and not skill_data.element.is_empty():
		return skill_data.element
	return weapon_element(member_index)

# ── 生態特効（P3-D087） ──────────────────────────────────────────────────

## 装備武器の生態特効（{class, mult}）。特効なしは class="" / mult=1.0。
static func weapon_bane(member_index: int) -> Dictionary:
	return _WeaponStatResolver.resolve_bane(GameState.get_member_equipped_weapon(member_index))

# ── Biome 属性相性（P3-D099） ────────────────────────────────────────────

static func is_biome_favored(attack_element: String, dungeon_data: Resource) -> bool:
	if attack_element.is_empty() or dungeon_data == null:
		return false
	return str(dungeon_data.favored_element) == attack_element

# ── 敵防御（逓減軽減） ───────────────────────────────────────────────────

## 敵DEFによる逓減軽減: damage × K/(K+DEF)。最低1。
## def_reduction（armor_break・P3-D107）で実効 DEF を下げてから計算する。
static func apply_enemy_defense(damage: int, enemy_data: Resource, def_reduction: float = 0.0) -> int:
	if enemy_data == null or damage <= 0:
		return damage
	var def: float = float(enemy_data.defense)
	if def_reduction > 0.0:
		def *= (1.0 - clampf(def_reduction, 0.0, 0.95))
	return apply_defense_mitigation(damage, int(round(def)))


## 味方DEFによる逓減軽減（P3-BAL-OPENING-002）。敵→味方も味方→敵と同式。
## 旧 flat `ATK−DEF` は高DEFで常時1ダメになり脅威が消えるため廃止。
static func apply_member_defense(damage: int, defense: int) -> int:
	return apply_defense_mitigation(damage, defense)


## 共通: damage × K/(K+DEF)。DEF≤0 は素通し。最低1。
static func apply_defense_mitigation(damage: int, defense: int) -> int:
	if damage <= 0:
		return damage
	if defense <= 0:
		return damage
	var mult: float = BalanceConfig.DEFENSE_MITIGATION_K / (
		BalanceConfig.DEFENSE_MITIGATION_K + float(defense)
	)
	return maxi(1, int(round(float(damage) * mult)))

# ── ダメージ±乱数（P3-D158） ────────────────────────────────────────────

## 最終ダメージへ ±DAMAGE_VARIANCE の一様乱数を掛ける（ブレークポイント緩和）。
## rng 省略時はグローバル randf（実プレイ）。テスト/シミュは注入可。
static func apply_variance(damage: int, rng: RandomNumberGenerator = null) -> int:
	if damage <= 0 or BalanceConfig.DAMAGE_VARIANCE <= 0.0:
		return damage
	var roll: float = (rng.randf() if rng != null else randf()) * 2.0 - 1.0
	return maxi(1, int(round(float(damage) * (1.0 + roll * BalanceConfig.DAMAGE_VARIANCE))))

# ── 味方与ダメ（基礎値・ジョブ補正） ─────────────────────────────────────

static func attack_base(combat: CombatController, member_index: int = -1) -> Dictionary:
	var damage: int = BalanceConfig.FALLBACK_ATTACK
	var crit_rate: float = 0.0
	var weapon: Resource = GameState.get_member_equipped_weapon(member_index)
	if weapon != null:
		damage = EquipmentEnhancer.get_effective_attack(weapon)
		crit_rate = _WeaponStatResolver.resolve_critical_rate(weapon)
	var acc: Resource = GameState.get_member_equipped_accessory(member_index)
	if acc != null:
		var acc_data: Resource = DataRegistry.get_accessory_data(str(acc.accessory_id))
		if acc_data != null:
			damage += EquipmentEnhancer.effective_accessory_int_bonus(acc, "attack_bonus", acc_data)
			crit_rate += EquipmentEnhancer.effective_accessory_float_bonus(acc, "crit_rate_bonus", acc_data)
	var affix_bonuses: Dictionary = AffixStatCalculator.get_bonuses(member_index)
	damage += int(affix_bonuses.get("attack_flat", 0))
	crit_rate += float(affix_bonuses.get("crit_rate_add", 0.0))
	# ロール編成ボーナス（scout×2=会心+8%・P3-D097）
	if combat != null:
		crit_rate += combat.get_party_role_crit_add()
	crit_rate += EvolutionTraits.member_crit_add(member_index)
	if member_index >= 0:
		crit_rate += float(CombatPassives.weapon_stat_modifiers_for_member(member_index).get("crit_rate_add", 0.0))
	if member_index >= 0:
		var member: Resource = GameState.get_combatant(member_index)
		if member != null:
			damage += LevelSystem.level_attack_bonus(member.level)
			if member.base_stats != null:
				damage += int(member.base_stats.attack)
	damage = apply_job_attack_multiplier(damage, member_index)
	return {"base_damage": damage, "crit_rate": crit_rate}

static func apply_job_attack_multiplier(base_damage: int, member_index: int) -> int:
	if base_damage <= 0 or member_index < 0:
		return base_damage
	var member: Resource = GameState.get_combatant(member_index)
	if member == null:
		return base_damage
	var job_mods: Dictionary = JobStatCalculator.get_member_modifiers(member)
	var atk_mult: float = float(job_mods.get("attack_multiplier", JobStatCalculator.DEFAULT_MULTIPLIER))
	var weapon_inst: Resource = GameState.get_member_equipped_weapon(member_index)
	if weapon_inst != null and not weapon_inst.weapon_id.is_empty():
		var weapon_data: Resource = DataRegistry.get_weapon_data(weapon_inst.weapon_id)
		atk_mult *= JobStatCalculator.get_preferred_weapon_multiplier(member, weapon_data)
	return maxi(0, int(round(float(base_damage) * atk_mult)))

# ── 敵側軽減（属性/特効/シナジー/地形/天候/防御） ────────────────────────

## 敵の属性(弱点×1.25 / 耐性×0.75)・特効・シナジー・地形・天候・防御を与ダメへ反映する。
## 戻り値: {damage, element_tag}
static func enemy_mitigation(
	combat: CombatController,
	dungeon_data: Resource,
	damage: int,
	attack_element: String,
	member_index: int = -1,
	target_slot: int = -1,
	rng: RandomNumberGenerator = null
) -> Dictionary:
	var element_tag: String = ""
	if target_slot < 0:
		target_slot = combat.get_member_target_slot(member_index) if member_index >= 0 else combat.active_enemy_index
	var enemy_data: Resource = combat.get_enemy_data_at(target_slot)
	if enemy_data == null or damage <= 0:
		return {"damage": damage, "element_tag": element_tag}
	var elem_mult: float = ElementResolver.get_damage_multiplier(
		attack_element,
		enemy_data.element_weakness,
		enemy_data.element_resist
	)
	var elem_name: String = ElementResolver.get_display_name(attack_element)
	if elem_mult > 1.0:
		damage = maxi(1, int(float(damage) * elem_mult))
		damage = maxi(1, int(round(float(damage) * EvolutionTraits.member_weakness_mult(member_index, elem_mult))))
		if not elem_name.is_empty():
			element_tag = "  [弱点:%s]" % elem_name
	elif elem_mult < 1.0:
		damage = maxi(1, int(float(damage) * elem_mult))
		if not elem_name.is_empty():
			element_tag = "  [耐性:%s]" % elem_name
	# 属性値（P3-EQ-STAT-005 案A）: 属性あり時 damage × (1 + power × K)
	if member_index >= 0 and not attack_element.is_empty():
		var elem_power: int = weapon_element_power(member_index)
		if elem_power > 0:
			damage = apply_element_power_bonus(damage, attack_element, member_index)
			if not elem_name.is_empty():
				element_tag += "  [属性値+%d]" % elem_power
	# 生態特効（P3-D087）: 武器 bane_class が敵 codex_class と一致で増幅。属性と乗算。
	if member_index >= 0:
		var bane: Dictionary = weapon_bane(member_index)
		var bane_class: String = str(bane.get("class", ""))
		if not bane_class.is_empty() and bane_class == str(enemy_data.codex_class):
			damage = maxi(1, int(round(float(damage) * float(bane.get("mult", 1.0)))))
			element_tag += "  [特効:%s]" % bane_class
	# 同系統タグ・シナジー（P3-D095）: 属性をパーティで複数人共有なら、その属性の与ダメ増幅。
	var synergy: float = combat.get_element_synergy_bonus(attack_element)
	if synergy > 0.0:
		damage = maxi(1, int(round(float(damage) * (1.0 + synergy))))
		element_tag += "  [シナジー:%s]" % ElementResolver.get_display_name(attack_element)
	# Biome 属性相性（P3-D099）: ダンジョンの有利属性と一致なら与ダメ増幅。
	if is_biome_favored(attack_element, dungeon_data):
		damage = maxi(1, int(round(float(damage) * BalanceConfig.BIOME_FAVORED_BONUS)))
		element_tag += "  [地形:%s]" % ElementResolver.get_display_name(attack_element)
	# 天候（環境変化・P3-D101）: 属性別補正＋全体与ダメ補正。
	var weather: String = GameState.get_weather()
	var weather_mult: float = CombatWeather.element_multiplier(weather, attack_element) * CombatWeather.outgoing_multiplier(weather)
	if weather_mult != 1.0:
		damage = maxi(1, int(round(float(damage) * weather_mult)))
		element_tag += "  [天候:%s]" % CombatWeather.label(weather)
	# 防御DOWN（armor_break・P3-D107）: 敵 DEF を減少率ぶん下げてから逓減軽減。
	var def_reduction: float = combat.get_enemy_defense_reduction_at(target_slot)
	if def_reduction > 0.0:
		element_tag += "  [防御DOWN]"
	damage = apply_enemy_defense(damage, enemy_data, def_reduction)
	# ±乱数（P3-D158）: 味方→敵の全経路（通常/スキル/必殺）の最終段で1回だけ適用。
	damage = apply_variance(damage, rng)
	return {"damage": damage, "element_tag": element_tag}

# ── 味方通常攻撃 最終ダメージ ────────────────────────────────────────────

## 戻り値: {damage, is_critical, element_tag, formation_tag, target_slot}
## rng 省略時はグローバル randf でクリティカル判定（実プレイ）。テスト/シミュは注入可。
static func member_attack_damage(
	combat: CombatController,
	dungeon_data: Resource,
	run_damage_multiplier: float,
	member_index: int = -1,
	target_slot: int = -1,
	rng: RandomNumberGenerator = null
) -> Dictionary:
	if target_slot < 0 and member_index >= 0:
		target_slot = combat.get_member_target_slot(member_index)
	var base_info: Dictionary = attack_base(combat, member_index)
	var crit_roll: float = rng.randf() if rng != null else randf()
	var is_critical: bool = crit_roll < base_info["crit_rate"]
	var damage: int = base_info["base_damage"]
	if is_critical:
		var weapon: Resource = GameState.get_member_equipped_weapon(member_index)
		var crit_mult: float = _WeaponStatResolver.resolve_critical_damage(weapon)
		if member_index >= 0:
			crit_mult += float(CombatPassives.weapon_stat_modifiers_for_member(member_index).get("crit_damage_add", 0.0))
		damage = int(round(float(damage) * crit_mult))
	damage = int(damage * run_damage_multiplier)
	var action_range: String = CombatRange.resolve_for_action(member_index)
	damage = maxi(1, int(float(damage) * combat.get_member_outgoing_damage_multiplier(
		member_index, action_range, false, weapon_element(member_index), target_slot
	)))
	var elem_result: Dictionary = enemy_mitigation(
		combat, dungeon_data, damage, weapon_element(member_index), member_index, target_slot, rng
	)
	damage = elem_result["damage"]
	if target_slot < 0:
		target_slot = combat.active_enemy_index
	damage = maxi(
		1,
		int(float(damage) * combat.get_enemy_incoming_damage_multiplier_at(target_slot))
	)
	return {
		"damage": damage,
		"is_critical": is_critical,
		"element_tag": elem_result["element_tag"],
		"formation_tag": GameState.formation_range_log_tag(member_index, action_range),
		"target_slot": target_slot,
	}

# ── 敵 → 味方 被ダメ ─────────────────────────────────────────────────────

## 装備合算回避率（防具+装飾品、上限 BalanceConfig.EVASION_RATE_CAP）。
static func member_evasion_rate(member_index: int) -> float:
	if member_index < 0:
		return 0.0
	var total: float = 0.0
	var armor: Resource = GameState.get_member_equipped_armor(member_index)
	if armor != null:
		total += _ArmorStatResolver.resolve_evasion_rate(armor)
	var acc: Resource = GameState.get_member_equipped_accessory(member_index)
	if acc != null:
		total += _AccessoryStatResolver.resolve_evasion_rate(acc)
	total += float(CombatPassives.character_stat_modifiers_for_member(member_index).get("evasion_rate_add", 0.0))
	return minf(BalanceConfig.EVASION_RATE_CAP, total)

## true = 回避成功（被弾なし）。
static func roll_member_evasion(member_index: int, rng: RandomNumberGenerator = null) -> bool:
	var rate: float = member_evasion_rate(member_index)
	if rate <= 0.0:
		return false
	var roll: float = rng.randf() if rng != null else randf()
	return roll < rate

## 戻り値: {final, base, mitigated, elem_resisted, missed}
static func enemy_damage_to_member(
	combat: CombatController,
	target_index: int,
	power_multiplier: float = 1.0,
	attacker_atk: int = -1,
	attacker_slot: int = -1,
	rng: RandomNumberGenerator = null
) -> Dictionary:
	if roll_member_evasion(target_index, rng):
		return {"final": 0, "base": 0, "mitigated": 0, "elem_resisted": false, "missed": true}
	var atk: int = attacker_atk if attacker_atk >= 0 else combat.get_enemy_attack()
	var base_dmg: int = int(float(atk) * power_multiplier)
	var out_slot: int = attacker_slot if attacker_slot >= 0 else combat.active_enemy_index
	var enemy_id: String = combat.get_enemy_id_at(out_slot)
	var phase_mult: float = CombatBossPhases.attack_mult(
		enemy_id, combat.get_enemy_phase_index(out_slot)
	)
	base_dmg = maxi(1, int(round(float(base_dmg) * phase_mult)))
	base_dmg = maxi(1, int(float(base_dmg) * combat.get_enemy_outgoing_damage_multiplier_at(out_slot)))
	var defense: int = 0
	var armor: Resource = GameState.get_member_equipped_armor(target_index)
	if armor != null:
		defense = EquipmentEnhancer.effective_armor_defense(armor)
	var acc: Resource = GameState.get_member_equipped_accessory(target_index)
	if acc != null:
		var acc_data: Resource = DataRegistry.get_accessory_data(str(acc.accessory_id))
		if acc_data != null:
			defense += EquipmentEnhancer.effective_accessory_int_bonus(acc, "defense_bonus", acc_data)
	defense += int(AffixStatCalculator.get_bonuses(target_index).get("defense_flat", 0))
	## オトモは party_members 外の combatant。index 範囲を party に限定すると DEF0 になる。
	if target_index >= 0:
		var member: Resource = GameState.get_combatant(target_index)
		if member != null:
			if member.base_stats != null:
				defense += int(member.base_stats.defense)
			var job_mods: Dictionary = JobStatCalculator.get_member_modifiers(member)
			var def_mult: float = float(job_mods.get("defense_multiplier", JobStatCalculator.DEFAULT_MULTIPLIER))
			defense = maxi(0, int(round(float(defense) * def_mult)))
	var final_dmg: int = apply_member_defense(base_dmg, defense)
	# 防御(guard)等の被ダメ補正（P3-D085）。
	var incoming_mult: float = combat.get_member_incoming_damage_multiplier(target_index)
	if not is_equal_approx(incoming_mult, 1.0):
		final_dmg = maxi(0, int(round(float(final_dmg) * incoming_mult)))
	var wpn_block: Dictionary = CombatPassives.weapon_stat_modifiers_for_member(target_index)
	var block_chance: float = float(wpn_block.get("incoming_block_chance", 0.0))
	if block_chance > 0.0 and final_dmg > 0:
		var block_roll: float = rng.randf() if rng != null else randf()
		if block_roll < block_chance:
			final_dmg = maxi(0, int(round(float(final_dmg) * float(wpn_block.get("incoming_block_mult", 1.0)))))
	# 防具の属性耐性（P3-D103）: 敵攻撃属性が防具 resist_elements と一致なら軽減。
	var elem_resisted: bool = false
	var atk_elem: String = enemy_attack_element_at(combat, out_slot)
	if member_resists_element(target_index, atk_elem):
		var resist_mult: float = member_element_resist_multiplier(target_index, atk_elem)
		final_dmg = maxi(0, int(round(float(final_dmg) * resist_mult)))
		elem_resisted = true
	# ±乱数（P3-D158）: 敵→味方（通常/スキル）の最終段で1回だけ適用。
	if final_dmg > 0:
		final_dmg = apply_variance(final_dmg, rng)
	var mitigated: int = base_dmg - final_dmg
	return {
		"final": final_dmg,
		"base": base_dmg,
		"mitigated": mitigated,
		"elem_resisted": elem_resisted,
		"missed": false,
	}

static func enemy_attack_element_at(combat: CombatController, slot: int) -> String:
	var ed: Resource = combat.get_enemy_data_at(slot)
	return str(ed.attack_element) if ed != null else ""

## 防御側属性耐性（P3-D103）。
static func member_resists_element(target_index: int, attack_element: String) -> bool:
	return _ArmorStatResolver.member_resists_element(target_index, attack_element)

static func member_element_resist_multiplier(target_index: int, attack_element: String) -> float:
	return _ArmorStatResolver.member_element_resist_multiplier(target_index, attack_element)
