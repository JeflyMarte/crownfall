class_name DamageCalculator
extends RefCounted

## ダメージ計算コア（P3-REF-001 — DungeonScene から分離）。
## シーンノードへ依存しない静的関数群。CombatController / DungeonData は引数で受け取り、
## GameState / DataRegistry 等の autoload と静的クラスのみ参照する。
## headless バランスハーネス（tools/balance_sim）とユニットテストから直接呼べる。

# ── 属性解決 ─────────────────────────────────────────────────────────────

static func weapon_element(member_index: int = -1) -> String:
	var weapon: Resource = GameState.get_member_equipped_weapon(member_index)
	if weapon != null and not weapon.weapon_id.is_empty():
		var weapon_data: Resource = DataRegistry.get_weapon_data(weapon.weapon_id)
		if weapon_data != null and not weapon_data.element.is_empty():
			return weapon_data.element
	return ""

static func resolve_skill_element(skill_data: Resource, member_index: int = -1) -> String:
	if skill_data != null and not skill_data.element.is_empty():
		return skill_data.element
	return weapon_element(member_index)

# ── 生態特効（P3-D087） ──────────────────────────────────────────────────

## 装備武器の生態特効（{class, mult}）。特効なしは class="" / mult=1.0。
static func weapon_bane(member_index: int) -> Dictionary:
	var weapon: Resource = GameState.get_member_equipped_weapon(member_index)
	if weapon != null and not weapon.weapon_id.is_empty():
		var wd: Resource = DataRegistry.get_weapon_data(weapon.weapon_id)
		if wd != null and "bane_class" in wd and not str(wd.bane_class).is_empty():
			return {"class": str(wd.bane_class), "mult": float(wd.bane_multiplier)}
	return {"class": "", "mult": 1.0}

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
	if def <= 0.0:
		return damage
	var mult: float = BalanceConfig.DEFENSE_MITIGATION_K / (BalanceConfig.DEFENSE_MITIGATION_K + def)
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
		crit_rate = weapon.critical_rate
	var acc: Resource = GameState.get_member_equipped_accessory(member_index)
	if acc != null:
		var acc_data: Resource = load("res://resources/accessories/" + acc.accessory_id + ".tres")
		if acc_data != null:
			damage += acc_data.attack_bonus
			crit_rate += acc_data.crit_rate_bonus
	var affix_bonuses: Dictionary = AffixStatCalculator.get_bonuses(member_index)
	damage += int(affix_bonuses.get("attack_flat", 0))
	crit_rate += float(affix_bonuses.get("crit_rate_add", 0.0))
	# ロール編成ボーナス（scout×2=会心+8%・P3-D097）
	if combat != null:
		crit_rate += combat.get_party_role_crit_add()
	if member_index >= 0 and member_index < GameState.party_members.size():
		damage += LevelSystem.level_attack_bonus(GameState.party_members[member_index].level)
		var member: Resource = GameState.party_members[member_index]
		if member.base_stats != null:
			damage += int(member.base_stats.attack)
	damage = apply_job_attack_multiplier(damage, member_index)
	return {"base_damage": damage, "crit_rate": crit_rate}

static func apply_job_attack_multiplier(base_damage: int, member_index: int) -> int:
	if base_damage <= 0 or member_index < 0 or member_index >= GameState.party_members.size():
		return base_damage
	var member: Resource = GameState.party_members[member_index]
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
		if not elem_name.is_empty():
			element_tag = "  [弱点:%s]" % elem_name
	elif elem_mult < 1.0:
		damage = maxi(1, int(float(damage) * elem_mult))
		if not elem_name.is_empty():
			element_tag = "  [耐性:%s]" % elem_name
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
		damage = int(damage * BalanceConfig.CRITICAL_MULTIPLIER)
	damage = int(damage * run_damage_multiplier)
	var action_range: String = CombatRange.resolve_for_action(member_index)
	damage = maxi(1, int(float(damage) * combat.get_member_outgoing_damage_multiplier(member_index, action_range)))
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

## 戻り値: {final, base, mitigated, elem_resisted}
static func enemy_damage_to_member(
	combat: CombatController,
	target_index: int,
	power_multiplier: float = 1.0,
	attacker_atk: int = -1,
	attacker_slot: int = -1,
	rng: RandomNumberGenerator = null
) -> Dictionary:
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
		defense = armor.rolled_defense
	var acc: Resource = GameState.get_member_equipped_accessory(target_index)
	if acc != null:
		var acc_data: Resource = load("res://resources/accessories/" + acc.accessory_id + ".tres")
		if acc_data != null:
			defense += acc_data.defense_bonus
	defense += int(AffixStatCalculator.get_bonuses(target_index).get("defense_flat", 0))
	if target_index >= 0 and target_index < GameState.party_members.size():
		var member: Resource = GameState.party_members[target_index]
		if member.base_stats != null:
			defense += int(member.base_stats.defense)
		var job_mods: Dictionary = JobStatCalculator.get_member_modifiers(member)
		var def_mult: float = float(job_mods.get("defense_multiplier", JobStatCalculator.DEFAULT_MULTIPLIER))
		defense = maxi(0, int(round(float(defense) * def_mult)))
	var final_dmg: int = max(1, base_dmg - defense)
	# 防御(guard)等の被ダメ補正（P3-D085）。
	var incoming_mult: float = combat.get_member_incoming_damage_multiplier(target_index)
	if not is_equal_approx(incoming_mult, 1.0):
		final_dmg = maxi(0, int(round(float(final_dmg) * incoming_mult)))
	# 防具の属性耐性（P3-D103）: 敵攻撃属性が防具 resist_elements と一致なら軽減。
	var elem_resisted: bool = false
	var atk_elem: String = enemy_attack_element_at(combat, out_slot)
	if member_resists_element(target_index, atk_elem):
		final_dmg = maxi(0, int(round(float(final_dmg) * BalanceConfig.ARMOR_RESIST_MULTIPLIER)))
		elem_resisted = true
	# ±乱数（P3-D158）: 敵→味方（通常/スキル）の最終段で1回だけ適用。
	if final_dmg > 0:
		final_dmg = apply_variance(final_dmg, rng)
	var mitigated: int = base_dmg - final_dmg
	return {"final": final_dmg, "base": base_dmg, "mitigated": mitigated, "elem_resisted": elem_resisted}

static func enemy_attack_element_at(combat: CombatController, slot: int) -> String:
	var ed: Resource = combat.get_enemy_data_at(slot)
	return str(ed.attack_element) if ed != null else ""

## 防御側属性耐性（P3-D103）。
static func member_resists_element(target_index: int, attack_element: String) -> bool:
	if attack_element.is_empty():
		return false
	var armor: Resource = GameState.get_member_equipped_armor(target_index)
	if armor == null:
		return false
	var armor_data: Resource = load("res://resources/armors/" + str(armor.armor_id) + ".tres")
	if armor_data == null or not ("resist_elements" in armor_data):
		return false
	return attack_element in armor_data.resist_elements
