extends GutTest

## P3-TEST-001 — SaveManager のセーブラウンドトリップ・マイグレーション・耐性テスト。
##
## 注意: SaveManager は実セーブ（user://save_data.json）を直接読み書きするため、
## before_all/after_all で実セーブを退避・復元する。テスト中に実データは失われない。

const SAVE_PATH: String = "user://save_data.json"
const BACKUP_PATH: String = "user://save_data.json.p3test_bak"
const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")
const _CommanderProfile = preload("res://scripts/commander/CommanderProfile.gd")

var _had_real_save: bool = false

func before_all() -> void:
	_had_real_save = FileAccess.file_exists(SAVE_PATH)
	if _had_real_save:
		DirAccess.rename_absolute(SAVE_PATH, BACKUP_PATH)

func after_all() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	if _had_real_save and FileAccess.file_exists(BACKUP_PATH):
		DirAccess.rename_absolute(BACKUP_PATH, SAVE_PATH)

func before_each() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	_reset_game_state()

## GameState を新規ゲーム相当へリセット。
## _init_party は inventory を追記するため、先に在庫類をクリアする。
func _reset_game_state() -> void:
	GameState.inventory = []
	GameState.armor_inventory = []
	GameState.accessory_inventory = []
	GameState._init_party()
	# ストーリーON時 _init_party は空ロスターになるため、既存セーブ系テスト用に全解放する
	if Constants.STARTER_STORY_RECRUIT:
		GameState.seed_all_starters_unlocked()
	GameState.gold = 0
	GameState.gacha_token = 0
	GameState.gacha_pity = 0
	GameState.owned_helpers = {}
	GameState.owned_relics = []
	GameState.current_dungeon_id = Constants.DEFAULT_DUNGEON_ID
	GameState.current_stage_id = ""
	GameState.stage_progress = {}
	GameState.commander = {}
func _write_raw_save(text: String) -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	assert_not_null(file, "テスト用セーブファイルを開けること")
	file.store_string(text)
	file.close()

## 破損 JSON テストで JSON.parse_string が出すエンジンエラーは想定内。
## GUT 9.7 のエラー追跡が「未処理エラー」としてテストを落とさないよう消費する。
func _consume_expected_parse_errors() -> int:
	var consumed: int = 0
	for e in get_errors():
		if not e.handled and e.is_engine_error():
			e.handled = true
			consumed += 1
	return consumed

# ── a) save → load ラウンドトリップ ──────────────────────────────────────────

func test_roundtrip_restores_gold_and_gacha_token() -> void:
	GameState.gold = 1234
	GameState.gacha_token = 56
	SaveManager.save_game()
	GameState.gold = 0
	GameState.gacha_token = 0
	SaveManager.load_game()
	assert_eq(GameState.gold, 1234, "gold が復元されること")
	assert_eq(GameState.gacha_token, 56, "gacha_token が復元されること")

func test_roundtrip_restores_roster_member_progress() -> void:
	var member: Resource = GameState.roster[0]
	var member_id: String = str(member.id)
	member.level = 17
	member.exp = 4200
	SaveManager.save_game()
	member.level = 1
	member.exp = 0
	SaveManager.load_game()
	var loaded: Resource = GameState.find_roster_member_by_id(member_id)
	assert_not_null(loaded, "セーブしたメンバーがロスターに存在すること")
	assert_eq(int(loaded.level), 17, "level が復元されること")
	assert_eq(int(loaded.exp), 4200, "exp が復元されること")

func test_roundtrip_keeps_base_roster_complete() -> void:
	GameState.seed_all_starters_unlocked()
	var before_size: int = GameState.roster.size()
	SaveManager.save_game()
	SaveManager.load_game()
	assert_gte(GameState.roster.size(), 5, "基本5職が揃っていること（全解放シード後）")
	assert_eq(GameState.roster.size(), before_size, "ロスター人数が保存前後で一致すること")
	assert_false(GameState.party_members.is_empty(), "アクティブ編成が復元されること")

# ── b) job_id マイグレーション ────────────────────────────────────────────────

func test_migrate_job_id_legacy_names() -> void:
	assert_eq(SaveManager._migrate_job_id("warrior"), "swordsman", "warrior→swordsman")
	assert_eq(SaveManager._migrate_job_id("mage"), "alchemist", "mage→alchemist")
	assert_eq(SaveManager._migrate_job_id("guardian"), "vanguard", "guardian→vanguard")

func test_migrate_job_id_passthrough_and_fallback() -> void:
	assert_eq(SaveManager._migrate_job_id("ranger"), "ranger", "現行 id はそのまま")
	assert_eq(SaveManager._migrate_job_id("unknown_job_xyz"), "swordsman", "未知 id は swordsman へフォールバック")

func test_load_migrates_legacy_job_id_in_save_file() -> void:
	var legacy_save: Dictionary = {
		"gold": 10,
		"roster": [{
			"id": "legacy_hero",
			"display_name": "旧勇者",
			"level": 3,
			"exp": 0,
			"job_id": "warrior",
		}],
	}
	_write_raw_save(JSON.stringify(legacy_save))
	SaveManager.load_game()
	var loaded: Resource = GameState.find_roster_member_by_id("legacy_hero")
	assert_not_null(loaded, "旧セーブのメンバーが復元されること")
	assert_eq(str(loaded.job_id), "swordsman", "セーブファイル経由でも warrior→swordsman")

# ── c) dungeon_id マイグレーション ────────────────────────────────────────────

func test_migrate_dungeon_id_legacy_names() -> void:
	assert_eq(SaveManager._migrate_dungeon_id("royal_ruins"), Constants.MOURNGATE_DUNGEON_ID, "royal_ruins→mourngate")
	assert_eq(SaveManager._migrate_dungeon_id("graveyard"), Constants.MOURNGATE_DUNGEON_ID, "graveyard→mourngate")

func test_migrate_dungeon_id_passthrough_and_fallback() -> void:
	assert_eq(SaveManager._migrate_dungeon_id(Constants.MOURNGATE_DUNGEON_ID), Constants.MOURNGATE_DUNGEON_ID, "現行 id はそのまま")
	assert_eq(SaveManager._migrate_dungeon_id("frostridge"), "frostridge", "登録済み DL id はそのまま")
	assert_eq(SaveManager._migrate_dungeon_id("nonexistent_dg"), Constants.MOURNGATE_DUNGEON_ID, "未知 id は mourngate へフォールバック")

func test_load_migrates_legacy_dungeon_id_in_save_file() -> void:
	_write_raw_save(JSON.stringify({"current_dungeon_id": "royal_ruins"}))
	SaveManager.load_game()
	assert_eq(GameState.current_dungeon_id, Constants.MOURNGATE_DUNGEON_ID, "セーブファイル経由でも royal_ruins→mourngate")

# ── d) 欠損キー・空 JSON の graceful 処理 ─────────────────────────────────────

func test_load_without_save_file_is_noop() -> void:
	GameState.gold = 777
	SaveManager.load_game()
	assert_eq(GameState.gold, 777, "セーブファイル無しではロードは no-op")

func test_load_empty_file_keeps_state() -> void:
	GameState.gold = 777
	_write_raw_save("")
	SaveManager.load_game()
	assert_eq(GameState.gold, 777, "空ファイルでは状態を変更しない")
	assert_gt(_consume_expected_parse_errors(), 0, "空ファイルのパースエラーは想定内")

func test_load_invalid_json_keeps_state() -> void:
	GameState.gold = 777
	_write_raw_save("{ this is not json !!")
	SaveManager.load_game()
	assert_eq(GameState.gold, 777, "破損 JSON では状態を変更しない")
	assert_gt(_consume_expected_parse_errors(), 0, "破損 JSON のパースエラーは想定内")

func test_load_non_dict_json_keeps_state() -> void:
	GameState.gold = 777
	_write_raw_save("[1, 2, 3]")
	SaveManager.load_game()
	assert_eq(GameState.gold, 777, "Dictionary 以外の JSON では状態を変更しない")

func test_load_empty_dict_does_not_crash() -> void:
	GameState.gold = 777
	var roster_size: int = GameState.roster.size()
	_write_raw_save("{}")
	SaveManager.load_game()
	assert_eq(GameState.gold, 777, "欠損キーだらけ（空 dict）でも gold は維持")
	assert_eq(GameState.roster.size(), roster_size, "ロスターも維持")

func test_load_partial_keys_applies_only_present() -> void:
	GameState.gold = 1
	GameState.gacha_token = 99
	_write_raw_save(JSON.stringify({"gold": 500}))
	SaveManager.load_game()
	assert_eq(GameState.gold, 500, "存在するキーは適用")
	assert_eq(GameState.gacha_token, 99, "欠損キーは既存値を維持")

func test_roundtrip_restores_stage_progress() -> void:
	GameState.mark_stage_cleared("mourngate_1_1")
	GameState.stage_progress["mourngate_1_2"] = {"cleared": true, "tiers": {"0": true}}
	GameState.current_stage_id = "mourngate_1_2"
	SaveManager.save_game()
	GameState.stage_progress = {}
	GameState.current_stage_id = ""
	SaveManager.load_game()
	assert_true(GameState.is_stage_cleared("mourngate_1_2"))
	assert_eq(GameState.current_stage_id, "mourngate_1_2")

func test_migrate_v2_stage_progress_adds_tiers() -> void:
	var migrated: Dictionary = SaveManager._migrate_save_data({
		"save_version": 2,
		"stage_progress": {
			"mourngate_1_1": {"cleared": true},
		},
	})
	var prog: Dictionary = migrated["stage_progress"]["mourngate_1_1"]
	assert_true(bool(prog["tiers"][str(_DungeonTierConfig.TIER_NORMAL)]))

# ── e) save_version スキーマバージョン ───────────────────────────────────────

func test_migrate_v4_adds_commander_block() -> void:
	var migrated: Dictionary = SaveManager._migrate_save_data({
		"save_version": 4,
		"gold": 100,
	})
	assert_true(migrated.has("commander"))
	assert_eq(str(migrated["commander"].get("name", "")), _CommanderProfile.DEFAULT_NAME)

func test_save_writes_current_save_version() -> void:
	SaveManager.save_game()
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	assert_eq(int(data.get("save_version", -1)), SaveManager.SAVE_VERSION, "セーブに save_version が書かれること")

func test_load_legacy_save_without_version() -> void:
	_write_raw_save(JSON.stringify({"gold": 321}))
	SaveManager.load_game()
	assert_eq(GameState.gold, 321, "save_version 無しの旧セーブ（v0）もロードできること")

func test_migrate_save_data_stamps_current_version() -> void:
	var migrated: Dictionary = SaveManager._migrate_save_data({"gold": 1})
	assert_eq(int(migrated["save_version"]), SaveManager.SAVE_VERSION, "マイグレーション後は現行バージョンが刻印されること")

func test_load_future_version_is_best_effort() -> void:
	_write_raw_save(JSON.stringify({"save_version": 999, "gold": 654}))
	SaveManager.load_game()
	assert_eq(GameState.gold, 654, "将来バージョンのセーブも best-effort でロードすること")

func test_has_save_and_delete_save() -> void:
	assert_false(SaveManager.has_save(), "初期はセーブなし")
	SaveManager.save_game()
	assert_true(SaveManager.has_save(), "save_game 後はセーブあり")
	SaveManager.delete_save()
	assert_false(SaveManager.has_save(), "delete_save 後はセーブなし")
	assert_false(FileAccess.file_exists(SAVE_PATH), "ファイルも消えていること")


func test_reset_for_new_game_clears_progress() -> void:
	GameState.gold = 999
	GameState.dungeon_progress = {"mourngate": true}
	GameState.starter_unlocked_ids = ["adventurer_0"]
	GameState.starter_pick_pending = false
	GameState.reset_for_new_game()
	assert_eq(GameState.gold, 0)
	assert_eq(GameState.dungeon_progress.size(), 0)
	if Constants.STARTER_STORY_RECRUIT:
		assert_true(GameState.starter_pick_pending)
		assert_eq(GameState.roster.size(), 0)
		assert_eq(GameState.starter_unlocked_ids.size(), 0)


func test_title_scene_exists() -> void:
	assert_true(ResourceLoader.exists("res://scenes/title/TitleScene.tscn"))


func test_load_clamps_oversized_active_party() -> void:
	GameState.seed_all_starters_unlocked()
	var ids: Array = []
	for m in GameState.roster:
		ids.append(str(m.id))
	_write_raw_save(JSON.stringify({
		"roster": SaveManager._serialize_roster(),
		"starter_unlocked_ids": GameState.starter_unlocked_ids.duplicate(),
		"starter_pick_pending": false,
		"active_party_ids": ids,
	}))
	SaveManager.load_game()
	assert_eq(GameState.party_members.size(), GameState.ACTIVE_PARTY_SIZE, "先頭 ACTIVE_PARTY_SIZE 人のみ採用")
