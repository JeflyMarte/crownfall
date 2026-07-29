extends GutTest
## マイページ記録欄 — プレイ時間／図鑑進捗（敵 100% 超防止）。

const _CommanderLifetime = preload("res://scripts/commander/CommanderLifetime.gd")
const _CommanderProfile = preload("res://scripts/commander/CommanderProfile.gd")


func before_each() -> void:
	GameState.commander = _CommanderLifetime.default_commander_dict()
	GameState.discovery_registry = {}
	_CommanderLifetime.begin_play_session()


func test_format_play_time_minutes_and_hours() -> void:
	assert_eq(_CommanderLifetime.format_play_time(0), "0分")
	assert_eq(_CommanderLifetime.format_play_time(59), "0分")
	assert_eq(_CommanderLifetime.format_play_time(60), "1分")
	assert_eq(_CommanderLifetime.format_play_time(3661), "1時間1分")


func test_flush_play_time_accumulates() -> void:
	var lifetime: Dictionary = _CommanderProfile.get_lifetime()
	lifetime["play_time_sec"] = 100
	GameState.commander["lifetime"] = lifetime
	## アンカーを過去へずらして加算を確定させる。
	_CommanderLifetime._play_session_anchor_unix = int(Time.get_unix_time_from_system()) - 45
	_CommanderLifetime.flush_play_time()
	assert_gte(int(_CommanderProfile.get_lifetime().get("play_time_sec", 0)), 145)


func test_codex_enemy_rate_ignores_non_playable_and_caps_100() -> void:
	## プレイ可能ボス＋プール外ダミーを両方登録しても、分母はプレイ可能のみ／%は≤100。
	DiscoveryRegistry.register("enemy", "serdion")
	DiscoveryRegistry.register("enemy", "nonexistent_pool_enemy_xyz")
	var rates: Dictionary = _CommanderProfile.codex_rates()
	var enemy: Dictionary = rates.get("enemy", {})
	var total: int = int(enemy.get("total", 0))
	var discovered: int = int(enemy.get("discovered", 0))
	var percent: int = int(enemy.get("percent", 0))
	assert_gt(total, 0)
	assert_lte(discovered, total)
	assert_lte(percent, 100)
	assert_true(CatalogHelper.is_playable_codex_enemy("serdion"))
	assert_eq(_CommanderProfile.count_playable_enemy_discoveries(), 1)
