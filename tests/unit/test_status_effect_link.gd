extends GutTest

## 説明文中の状態異常リンク（StatusEffectLinkHelper）。

const _Helper := preload("res://scripts/ui/StatusEffectLinkHelper.gd")


func test_linkify_empower_and_alias_激励() -> void:
	var linked: String = _Helper.linkify_bbcode("味方に鼓舞を付与する")
	assert_true(linked.contains("url=status:empower"), linked)
	assert_true(linked.contains("鼓舞"), linked)
	assert_true(linked.contains("[color=#"), linked)
	assert_true(linked.find("[color=") < linked.find("[url="), "金色が url の外側であること: %s" % linked)
	var alias: String = _Helper.linkify_bbcode("激励を付与する")
	assert_true(alias.contains("url=status:empower"), alias)


func test_linkify_prefers_longer_alias() -> void:
	var linked: String = _Helper.linkify_bbcode("小さな鼓舞を付与")
	assert_true(linked.contains("url=status:empower_minor"), linked)
	assert_false(linked.contains("url=status:empower]"), "短い鼓舞に誤マッチしない")
	var short_name: String = _Helper.linkify_bbcode("小鼓舞を付与")
	assert_true(short_name.contains("url=status:empower_minor"), short_name)


func test_buff_taxonomy_recommended_values() -> void:
	var minor: Resource = DataRegistry.get_status_effect("empower_minor")
	assert_eq(str(minor.display_name), "小鼓舞")
	var empower: Resource = DataRegistry.get_status_effect("empower")
	assert_almost_eq(float(empower.outgoing_damage_multiplier), 1.3, 0.001)
	assert_almost_eq(float(empower.incoming_damage_multiplier), 1.0, 0.001)
	var enrage: Resource = DataRegistry.get_status_effect("enrage")
	assert_almost_eq(float(enrage.outgoing_damage_multiplier), 1.5, 0.001)
	assert_almost_eq(float(enrage.incoming_damage_multiplier), 1.25, 0.001)
	var pet: Resource = DataRegistry.get_status_effect("empower_pet")
	assert_almost_eq(float(pet.outgoing_damage_multiplier), 1.3, 0.001)
	assert_almost_eq(float(pet.incoming_damage_multiplier), 0.85, 0.001)
	var pet_line: String = _Helper.effect_one_line("empower_pet")
	assert_true(pet_line.contains("与ダメ"), pet_line)
	assert_true(pet_line.contains("被ダメ"), pet_line)
	var enrage_line: String = _Helper.effect_one_line("enrage")
	assert_true(enrage_line.contains("与ダメ"), enrage_line)
	assert_true(enrage_line.contains("被ダメ"), enrage_line)


func test_effect_summary_empower() -> void:
	var s: String = _Helper.effect_summary("empower")
	assert_false(s.is_empty())
	assert_true(s.contains("与ダメ") or s.contains("続く") or s.contains("一時"), s)


func test_effect_summary_armor_break() -> void:
	var s: String = _Helper.effect_summary("armor_break")
	assert_true(s.contains("防御"), s)


func test_effect_one_line_dot_uses_ongoing_damage() -> void:
	## DoT は CT 間隔。壁時計「1秒」は使わない。名前付き。
	var poison: String = _Helper.effect_one_line("poison")
	assert_eq(poison, "毒:継続（固定＋攻撃）")
	assert_false(poison.contains("刻"))
	assert_false(poison.contains("1秒"))
	var ignite: String = _Helper.effect_one_line("ignite")
	assert_eq(ignite, "炎上:継続（固定＋攻撃）")
	var bleed: String = _Helper.effect_one_line("bleed")
	assert_true(bleed.ends_with(":継続ダメージ"), bleed)


func test_effect_one_line_stat_mod() -> void:
	var empower: String = _Helper.effect_one_line("empower")
	assert_true(empower.contains("与ダメ"), empower)
	assert_true(empower.contains(":"), "名前:効果の形式")
	assert_false(empower.contains("・"), "1行は主効果のみ")
	var stun: String = _Helper.effect_one_line("stun")
	assert_eq(stun, "スタン:行動不能")
	var summary_poison: String = _Helper.effect_summary("poison")
	assert_true(summary_poison.contains("継続ダメージ"), summary_poison)
	assert_false(summary_poison.contains("刻ごと"), summary_poison)
	assert_false(summary_poison.contains("1秒"), summary_poison)
