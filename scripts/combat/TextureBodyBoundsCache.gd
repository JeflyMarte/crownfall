class_name TextureBodyBoundsCache
extends RefCounted

## AnimatedSprite 正規化用の get_image()/get_used_rect() 結果キャッシュ。
## 同じ Texture2D を部屋遷移ごとに再解析しない（発熱対策パッケージ A）。

const CACHE_SOFT_CAP: int = 160

var _cache: Dictionary = {}


## 戻り: frame_w/h, body_w/h, body_cx, body_bottom, top_inset
func bounds_for(tex: Texture2D) -> Dictionary:
	if tex == null:
		return {}
	var key: int = tex.get_instance_id()
	if _cache.has(key):
		return _cache[key] as Dictionary
	var frame_w: float = float(tex.get_width())
	var frame_h: float = float(tex.get_height())
	var body_w: float = frame_w
	var body_h: float = frame_h
	var body_cx: float = frame_w * 0.5
	var body_bottom: float = frame_h
	var top_inset: float = 0.0
	var img: Image = tex.get_image()
	if img != null:
		var used: Rect2i = img.get_used_rect()
		if used.size.y > 0:
			body_w = float(used.size.x)
			body_h = float(used.size.y)
			body_cx = float(used.position.x) + body_w * 0.5
			body_bottom = float(used.position.y + used.size.y)
			top_inset = float(used.position.y)
	var entry: Dictionary = {
		"frame_w": frame_w,
		"frame_h": frame_h,
		"body_w": body_w,
		"body_h": body_h,
		"body_cx": body_cx,
		"body_bottom": body_bottom,
		"top_inset": top_inset,
	}
	if _cache.size() >= CACHE_SOFT_CAP:
		_cache.clear()
	_cache[key] = entry
	return entry


func clear() -> void:
	_cache.clear()


func size() -> int:
	return _cache.size()
