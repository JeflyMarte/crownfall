extends GutTest
## P3-UX-RESULT-005 — MVP 画面演出パラメータ。

const _MvpPresentation = preload("res://scripts/result/MvpPresentation.gd")


func test_asset_paths_exist() -> void:
	assert_true(ResourceLoader.exists(_MvpPresentation.BG_PATH))
	assert_true(ResourceLoader.exists(_MvpPresentation.FRAME_HERO_PATH))
	assert_true(ResourceLoader.exists(_MvpPresentation.CROWN_ICON_PATH))


func test_podium_layout_orders_center_first() -> void:
	var ranked: Array = [
		{"member_id": "a", "score": 100},
		{"member_id": "b", "score": 80},
		{"member_id": "c", "score": 60},
	]
	var layout: Array = _MvpPresentation.podium_layout(ranked)
	assert_eq(layout.size(), 3)
	assert_eq(layout[0]["slot"], "center")
	assert_eq(layout[1]["slot"], "left")
	assert_eq(layout[2]["slot"], "right")


func test_pick_subtitle_prefers_heal_when_dominant() -> void:
	var entry: Dictionary = {"damage_total": 20, "heal_total": 80, "damage_max_hit": 10}
	assert_true("守りの要" in _MvpPresentation.pick_subtitle(entry))


func test_stat_cards_omit_score() -> void:
	var cards: Array = _MvpPresentation.stat_cards({"damage_total": 10, "damage_max_hit": 5, "heal_total": 2, "score": 11})
	assert_eq(cards.size(), 3)
	assert_eq(cards[0]["key"], "与ダメージ")
	assert_eq(cards[1]["key"], "最大ヒット")
	assert_eq(cards[2]["key"], "回復量")
	for card: Dictionary in cards:
		assert_ne(str(card.get("key", "")), "MVPスコア")


func test_backdrop_style_has_opaque_fill() -> void:
	var header: StyleBoxFlat = _MvpPresentation.backdrop_style("header")
	assert_gt(header.bg_color.a, 0.8)
	var stat: StyleBoxFlat = _MvpPresentation.backdrop_style("stat")
	assert_gt(stat.bg_color.a, 0.9)
