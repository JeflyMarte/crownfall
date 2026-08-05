extends GutTest
## P3-FIX-COMBAT-AUDIT-C-001 — タグ正規化／連携武装／パッシブ effect 整合。

## DungeonScene `_try_fire_passive` match arms（effect キー）。新規 effect 追加時は両方更新。
const KNOWN_PASSIVE_EFFECTS: Array[String] = [
	"apply_status",
	"random_enemy_status",
	"crit_pulse",
	"heal",
	"grant_party_incoming_mult",
	"chance_cast_equipped_skill",
	"bonus_damage",
	"counter_attack",
	"taunt_and_guard",
	"party_rally",
	"opening_strike",
	"grant_next_attack_mult",
	"aoe_burst",
	"abyss_ice_shell_counter",
	"refund_ct",
	"grant_self_evasion",
]


func test_thunder_tag_normalizes_to_lightning() -> void:
	assert_eq(CombatTags.normalize("thunder"), "lightning")
	assert_true(CombatTags.is_known("thunder"))
	assert_eq(CombatTags.display_name("thunder"), "雷")
	assert_true(CombatCombos.tag_eligible("shock", ["lightning"]))
	assert_true(CombatCombos.tag_eligible("shock", [CombatTags.normalize("thunder")]))


func test_pulsekeen_uses_lightning_not_thunder() -> void:
	var wd: Resource = DataRegistry.get_weapon_data("pulsekeen_edge")
	assert_not_null(wd)
	assert_true("lightning" in wd.tags, "pulsekeen must use tag-space lightning")
	assert_false("thunder" in wd.tags)


func test_all_passive_effects_have_dispatcher_arms() -> void:
	var seen: Dictionary = {}
	for pid: String in CombatPassives.all_def_ids():
		var def: Dictionary = CombatPassives.get_def(pid)
		if def.is_empty() or not def.has("effect"):
			continue
		var effect: String = str(def.get("effect", ""))
		if effect.is_empty():
			continue
		seen[effect] = true
		assert_true(
			effect in KNOWN_PASSIVE_EFFECTS,
			"passive %s effect '%s' missing from _try_fire_passive match" % [pid, effect]
		)
	assert_true(seen.has("refund_ct"))
	assert_true(seen.has("apply_status"))


func test_debuff_mark_statuses_cover_common_applies() -> void:
	for sid: String in ["bleed", "poison", "mark", "armor_break", "chill", "stun"]:
		assert_true(CombatLinks.is_debuff_mark_status(sid), sid)
	assert_false(CombatLinks.is_debuff_mark_status("empower"))
	assert_false(CombatLinks.is_debuff_mark_status("guard"))
