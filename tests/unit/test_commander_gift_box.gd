extends GutTest
## 隊長台帳・配布ボックス（P3-CMD-002 MVP）。

const _CommanderGiftBox = preload("res://scripts/commander/CommanderGiftBox.gd")
const _CommanderLifetime = preload("res://scripts/commander/CommanderLifetime.gd")


func before_each() -> void:
	GameState.gold = 100
	GameState.gacha_token = 0
	GameState.material_inventory = {}
	GameState.commander = _CommanderLifetime.default_commander_dict()


func test_enqueue_and_claim_gold() -> void:
	var gift_id: String = _CommanderGiftBox.enqueue({
		"title": "補填テスト",
		"message": "お詫び",
		"gold": 250,
	})
	assert_false(gift_id.is_empty())
	assert_eq(_CommanderGiftBox.pending_count(), 1)
	var result: Dictionary = _CommanderGiftBox.claim(gift_id)
	assert_true(result.get("ok", false))
	assert_eq(GameState.gold, 350)
	assert_eq(_CommanderGiftBox.pending_count(), 0)


func test_claim_all_applies_materials_and_tokens() -> void:
	_CommanderGiftBox.enqueue({
		"title": "A",
		"gold": 10,
	})
	_CommanderGiftBox.enqueue({
		"title": "B",
		"gacha_token": 2,
		"materials": {"base_ore": 3},
	})
	var result: Dictionary = _CommanderGiftBox.claim_all()
	assert_true(result.get("ok", false))
	assert_eq(int(result.get("count", 0)), 2)
	assert_eq(GameState.gold, 110)
	assert_eq(GameState.gacha_token, 2)
	assert_eq(GameState.get_material_quantity("base_ore"), 3)
