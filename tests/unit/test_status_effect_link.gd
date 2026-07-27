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


func test_effect_summary_empower() -> void:
	var s: String = _Helper.effect_summary("empower")
	assert_false(s.is_empty())
	assert_true(s.contains("与ダメ") or s.contains("続く") or s.contains("一時"), s)


func test_effect_summary_armor_break() -> void:
	var s: String = _Helper.effect_summary("armor_break")
	assert_true(s.contains("防御"), s)


func test_effect_one_line_dot_uses_per_second() -> void:
	## P3-UX-STATUS-LEGEND-001: 「刻」ではなく「1秒ごと」。
	var poison: String = _Helper.effect_one_line("poison")
	assert_eq(poison, "1秒ごとにダメージ")
	assert_false(poison.contains("刻"))
	var ignite: String = _Helper.effect_one_line("ignite")
	assert_eq(ignite, "1秒ごとにダメージ")
	var bleed: String = _Helper.effect_one_line("bleed")
	assert_eq(bleed, "1秒ごとにダメージ")


func test_effect_one_line_stat_mod() -> void:
	var empower: String = _Helper.effect_one_line("empower")
	assert_true(empower.contains("与ダメ"), empower)
	assert_false(empower.contains("・"), "1行は主効果のみ")
	var stun: String = _Helper.effect_one_line("stun")
	assert_eq(stun, "行動不能")
	var summary_poison: String = _Helper.effect_summary("poison")
	assert_true(summary_poison.contains("1秒ごと"), summary_poison)
	assert_false(summary_poison.contains("刻ごと"), summary_poison)
