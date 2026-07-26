extends GutTest

## 説明文中の状態異常リンク（StatusEffectLinkHelper）。

const _Helper := preload("res://scripts/ui/StatusEffectLinkHelper.gd")


func test_linkify_empower_and_alias_激励() -> void:
	var linked: String = _Helper.linkify_bbcode("味方に鼓舞を付与する")
	assert_true(linked.contains("url=status:empower"), linked)
	assert_true(linked.contains("鼓舞"), linked)
	var alias: String = _Helper.linkify_bbcode("激励を付与する")
	assert_true(alias.contains("url=status:empower"), alias)


func test_linkify_prefers_longer_alias() -> void:
	var linked: String = _Helper.linkify_bbcode("小さな鼓舞を付与")
	assert_true(linked.contains("url=status:empower_minor"), linked)
	assert_false(linked.contains("url=status:empower]"), "短い鼓舞に誤マッチしない")


func test_effect_summary_empower() -> void:
	var s: String = _Helper.effect_summary("empower")
	assert_false(s.is_empty())
	assert_true(s.contains("与ダメ") or s.contains("持続"), s)


func test_effect_summary_armor_break() -> void:
	var s: String = _Helper.effect_summary("armor_break")
	assert_true(s.contains("防御"), s)
