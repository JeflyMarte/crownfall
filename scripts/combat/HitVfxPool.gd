class_name HitVfxPool
extends RefCounted

## 戦闘ヒット VFX の AnimatedSprite2D 再利用（軽量化 C）。
## 都度 `new`＋`queue_free` を避け、連撃・AoE 時の割当／GC を抑える。

const POOL_CAP: int = 28

var _free: Array = []
var _shared_add_mat: CanvasItemMaterial = null
var _frames_cache: Dictionary = {}


func get_frames(path: String) -> SpriteFrames:
	if path.is_empty():
		return null
	if _frames_cache.has(path):
		return _frames_cache[path] as SpriteFrames
	if not ResourceLoader.exists(path):
		return null
	var frames: SpriteFrames = load(path) as SpriteFrames
	if frames != null:
		_frames_cache[path] = frames
	return frames


func acquire() -> AnimatedSprite2D:
	var spr: AnimatedSprite2D
	if not _free.is_empty():
		spr = _free.pop_back() as AnimatedSprite2D
	else:
		spr = AnimatedSprite2D.new()
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.centered = true
	if _shared_add_mat == null:
		_shared_add_mat = CanvasItemMaterial.new()
		_shared_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	spr.material = _shared_add_mat
	spr.visible = true
	spr.modulate = Color.WHITE
	spr.rotation_degrees = 0.0
	spr.scale = Vector2.ONE
	return spr


func release(spr: AnimatedSprite2D) -> void:
	if spr == null or not is_instance_valid(spr):
		return
	_disconnect_finished(spr)
	spr.stop()
	spr.visible = false
	spr.sprite_frames = null
	var parent: Node = spr.get_parent()
	if parent != null:
		parent.remove_child(spr)
	if _free.size() >= POOL_CAP:
		spr.queue_free()
		return
	_free.append(spr)


func clear() -> void:
	for entry: Variant in _free:
		var spr: AnimatedSprite2D = entry as AnimatedSprite2D
		if spr != null and is_instance_valid(spr):
			spr.queue_free()
	_free.clear()


func free_count() -> int:
	return _free.size()


func _disconnect_finished(spr: AnimatedSprite2D) -> void:
	var conns: Array = spr.animation_finished.get_connections()
	for c: Variant in conns:
		if c is Dictionary:
			var cb: Variant = (c as Dictionary).get("callable", null)
			if cb is Callable and (cb as Callable).is_valid():
				spr.animation_finished.disconnect(cb as Callable)
