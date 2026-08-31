extends GutTest

## 発熱対策パッケージ A: ダメ数字プール／テクスチャ bounds キャッシュ／モバイルループ抑止配線。

const _DamageNumberPool = preload("res://scripts/combat/DamageNumberPool.gd")
const _TextureBodyBoundsCache = preload("res://scripts/combat/TextureBodyBoundsCache.gd")


func test_damage_number_pool_reuses_and_caps_active() -> void:
	var pool: RefCounted = _DamageNumberPool.new()
	var host := Control.new()
	add_child_autofree(host)
	for _i: int in 30:
		var lbl: Label = pool.acquire() as Label
		host.add_child(lbl)
	assert_eq(pool.active_count(), _DamageNumberPool.ACTIVE_CAP)
	assert_lte(host.get_child_count(), _DamageNumberPool.ACTIVE_CAP)
	var recycled: Label = pool.acquire() as Label
	assert_true(is_instance_valid(recycled))
	assert_eq(pool.active_count(), _DamageNumberPool.ACTIVE_CAP)
	pool.release(recycled)
	assert_eq(pool.free_count(), 1)
	pool.clear()
	assert_eq(pool.active_count(), 0)
	assert_eq(pool.free_count(), 0)


func test_texture_body_bounds_cache_hits() -> void:
	var cache: RefCounted = _TextureBodyBoundsCache.new()
	var img := Image.create(8, 12, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	var tex := ImageTexture.create_from_image(img)
	var a: Dictionary = cache.bounds_for(tex)
	var b: Dictionary = cache.bounds_for(tex)
	assert_eq(int(a.get("frame_w", 0)), 8)
	assert_eq(int(a.get("frame_h", 0)), 12)
	assert_eq(float(a.get("body_h", 0.0)), float(b.get("body_h", -1.0)))
	assert_eq(cache.size(), 1)
	cache.clear()
	assert_eq(cache.size(), 0)


func test_dungeon_wires_pack_a_gates_and_pools() -> void:
	var src: String = FileAccess.get_file_as_string("res://scripts/dungeon/DungeonScene.gd")
	assert_true(src.contains("DamageNumberPool"), "damage number pool wired")
	assert_true(src.contains("TextureBodyBoundsCache"), "texture bounds cache wired")
	assert_true(src.contains("_release_damage_number"), "pool release callback")
	## 瀕死カード／スキルCD満タンのループがモバイル抑止と同居。
	var crit_idx: int = src.find("func _start_party_card_critical_pulse")
	assert_gt(crit_idx, 0)
	var crit_snip: String = src.substr(crit_idx, 220)
	assert_true(crit_snip.contains("mobile_throttle_idle_loops"), "critical pulse throttled")
	var pulse_idx: int = src.find("func _set_skill_cd_ready_pulse")
	assert_gt(pulse_idx, 0)
	var pulse_snip: String = src.substr(pulse_idx, 520)
	assert_true(pulse_snip.contains("mobile_throttle_idle_loops"), "skill ready pulse throttled")
