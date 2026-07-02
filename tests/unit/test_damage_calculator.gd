extends GutTest

## P3-REF-001 — DamageCalculator の純粋関数テスト。
## シーン非依存の計算式（防御逓減・Biome相性・属性解決）を検証する。

const EnemyDataScript = preload("res://scripts/data/EnemyData.gd")
const DungeonDataScript = preload("res://scripts/data/DungeonData.gd")

func _make_enemy(defense: int) -> Resource:
	var e: Resource = EnemyDataScript.new()
	e.defense = defense
	return e

# ── 敵防御 逓減軽減 K/(K+DEF) ────────────────────────────────────────────

func test_defense_mitigation_formula() -> void:
	# K=100, DEF=100 → 軽減率 0.5
	var result: int = DamageCalculator.apply_enemy_defense(100, _make_enemy(100))
	assert_eq(result, 50, "DEF=K で与ダメ半減")

func test_defense_zero_is_passthrough() -> void:
	assert_eq(DamageCalculator.apply_enemy_defense(80, _make_enemy(0)), 80, "DEF=0 は素通し")

func test_defense_never_reduces_below_one() -> void:
	assert_eq(DamageCalculator.apply_enemy_defense(1, _make_enemy(9999)), 1, "最低1ダメージ保証")

func test_defense_null_enemy_passthrough() -> void:
	assert_eq(DamageCalculator.apply_enemy_defense(42, null), 42, "敵データ null は素通し")

func test_armor_break_reduces_effective_defense() -> void:
	var base: int = DamageCalculator.apply_enemy_defense(100, _make_enemy(100))
	var broken: int = DamageCalculator.apply_enemy_defense(100, _make_enemy(100), 0.5)
	assert_gt(broken, base, "防御DOWN で与ダメ増")
	# DEF 100→50: 100×(100/150)=67
	assert_eq(broken, 67, "def_reduction=0.5 の逓減値")

func test_armor_break_reduction_clamped() -> void:
	var full: int = DamageCalculator.apply_enemy_defense(100, _make_enemy(100), 5.0)
	# clamp 0.95 → DEF 5: 100×(100/105)=95
	assert_eq(full, 95, "def_reduction は 0.95 で頭打ち")

# ── Biome 属性相性 ───────────────────────────────────────────────────────

func test_biome_favored_match() -> void:
	var dg: Resource = DungeonDataScript.new()
	dg.favored_element = "dark"
	assert_true(DamageCalculator.is_biome_favored("dark", dg), "有利属性一致で true")
	assert_false(DamageCalculator.is_biome_favored("fire", dg), "不一致で false")

func test_biome_favored_empty_or_null() -> void:
	assert_false(DamageCalculator.is_biome_favored("", DungeonDataScript.new()), "無属性は false")
	assert_false(DamageCalculator.is_biome_favored("dark", null), "ダンジョン null は false")

# ── スキル属性解決 ───────────────────────────────────────────────────────

func test_skill_element_overrides_weapon() -> void:
	var skill: Resource = load("res://resources/skills/hex_bolt.tres")
	assert_not_null(skill, "hex_bolt が存在すること")
	if not str(skill.element).is_empty():
		assert_eq(
			DamageCalculator.resolve_skill_element(skill, -1), str(skill.element),
			"スキル自身の属性が優先されること"
		)

func test_skill_element_null_falls_back_to_weapon() -> void:
	# member_index=-1 は武器なし → 空文字
	assert_eq(DamageCalculator.resolve_skill_element(null, -1), "", "スキル/武器なしは無属性")
