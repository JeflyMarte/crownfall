extends GutTest

## ヒット VFX プール（軽量化 C）。


const _HitVfxPool := preload("res://scripts/combat/HitVfxPool.gd")


func test_acquire_release_reuses_sprite() -> void:
	var pool: RefCounted = _HitVfxPool.new()
	var a: AnimatedSprite2D = pool.acquire()
	assert_not_null(a)
	assert_eq(pool.free_count(), 0)
	pool.release(a)
	assert_eq(pool.free_count(), 1)
	var b: AnimatedSprite2D = pool.acquire()
	assert_same(a, b)
	assert_eq(pool.free_count(), 0)
	pool.release(b)
	pool.clear()
	assert_eq(pool.free_count(), 0)


func test_get_frames_caches_hit_normal() -> void:
	var pool: RefCounted = _HitVfxPool.new()
	var path: String = "res://resources/animation/FX_Hit_Normal.tres"
	var f1: SpriteFrames = pool.get_frames(path)
	var f2: SpriteFrames = pool.get_frames(path)
	assert_not_null(f1)
	assert_same(f1, f2)


func test_pool_cap_frees_overflow() -> void:
	var pool: RefCounted = _HitVfxPool.new()
	var kept: Array = []
	for _i: int in _HitVfxPool.POOL_CAP + 3:
		var spr: AnimatedSprite2D = pool.acquire()
		kept.append(spr)
	for spr: Variant in kept:
		pool.release(spr as AnimatedSprite2D)
	assert_eq(pool.free_count(), _HitVfxPool.POOL_CAP)
	pool.clear()
