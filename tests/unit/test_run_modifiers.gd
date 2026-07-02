extends GutTest

## P3-UX-001 — ラン戦闘補正カウンタ（Result「効いた戦闘要素」）のテスト。

func before_each() -> void:
	GameState.last_run_modifier_counts = {}

func after_all() -> void:
	GameState.last_run_modifier_counts = {}

func test_record_and_count() -> void:
	GameState.record_run_modifier("弱点属性")
	GameState.record_run_modifier("弱点属性")
	GameState.record_run_modifier("パーティ連携")
	assert_eq(int(GameState.last_run_modifier_counts["弱点属性"]), 2, "同ラベルは加算")
	assert_eq(int(GameState.last_run_modifier_counts["パーティ連携"]), 1)

func test_empty_label_ignored() -> void:
	GameState.record_run_modifier("")
	assert_true(GameState.last_run_modifier_counts.is_empty(), "空ラベルは無視")

func test_top_run_modifiers_sorted_and_limited() -> void:
	for i in 5:
		GameState.record_run_modifier("シナジー")
	for i in 3:
		GameState.record_run_modifier("特効")
	GameState.record_run_modifier("天候")
	GameState.record_run_modifier("コンボ")
	var top: Array = GameState.top_run_modifiers(3)
	assert_eq(top.size(), 3, "上位3件に制限")
	assert_eq(str(top[0]["label"]), "シナジー", "回数降順の先頭")
	assert_eq(int(top[0]["count"]), 5)
	assert_eq(str(top[1]["label"]), "特効")

func test_top_run_modifiers_empty() -> void:
	assert_true(GameState.top_run_modifiers().is_empty(), "未集計は空配列")
