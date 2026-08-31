class_name DamageNumberPool
extends RefCounted

## ダメージ数字 Label の再利用＋同時表示上限（発熱対策パッケージ A）。
## `_damage_numbers_layer` 上の他ノード（紙吹雪等）とは meta で区別する。

const ACTIVE_CAP: int = 24
const POOL_CAP: int = 32
const META_POOLED: StringName = &"_cf_dmg_num_pooled"

var _free: Array = []
var _active: Array = []


func acquire() -> Label:
	_evict_if_over_cap()
	var lbl: Label
	if not _free.is_empty():
		lbl = _free.pop_back() as Label
	else:
		lbl = Label.new()
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.set_meta(META_POOLED, true)
	lbl.visible = true
	lbl.modulate = Color.WHITE
	lbl.rotation_degrees = 0.0
	lbl.scale = Vector2.ONE
	lbl.pivot_offset = Vector2.ZERO
	_active.append(lbl)
	return lbl


func release(lbl: Label) -> void:
	if lbl == null or not is_instance_valid(lbl):
		return
	if not _active.has(lbl):
		return
	if lbl.has_meta(&"_cf_dmg_tween"):
		var ot: Variant = lbl.get_meta(&"_cf_dmg_tween")
		if ot is Tween and is_instance_valid(ot):
			(ot as Tween).kill()
		lbl.remove_meta(&"_cf_dmg_tween")
	_active.erase(lbl)
	lbl.visible = false
	lbl.text = ""
	lbl.modulate = Color.WHITE
	lbl.rotation_degrees = 0.0
	lbl.scale = Vector2.ONE
	var parent: Node = lbl.get_parent()
	if parent != null:
		parent.remove_child(lbl)
	if _free.size() >= POOL_CAP:
		lbl.queue_free()
		return
	_free.append(lbl)


func release_layer_children(layer: Node) -> void:
	if layer == null:
		return
	var children: Array = layer.get_children()
	for child: Node in children:
		if child is Label and bool(child.get_meta(META_POOLED, false)):
			release(child as Label)
		else:
			child.queue_free()


func clear() -> void:
	for entry: Variant in _active.duplicate():
		release(entry as Label)
	_active.clear()
	for entry: Variant in _free:
		var lbl: Label = entry as Label
		if lbl != null and is_instance_valid(lbl):
			lbl.free()
	_free.clear()


func active_count() -> int:
	return _active.size()


func free_count() -> int:
	return _free.size()


func _evict_if_over_cap() -> void:
	while _active.size() >= ACTIVE_CAP:
		var oldest: Label = null
		for entry: Variant in _active:
			var cand: Label = entry as Label
			if cand != null and is_instance_valid(cand):
				oldest = cand
				break
		if oldest == null:
			_active.clear()
			return
		release(oldest)
