class_name ChrIdlePortrait
extends RefCounted

## UI 用 Idle ドット（`assets/characters/{folder}/idle_*.png`）。
## folder は job_id、またはガチャ助っ人の helper_id。
## 戦闘 SpriteFrames の `idle`（=walk）とは別系統。

const IDLE_FPS: float = 8.0
const FRAME_PATH: String = "res://assets/characters/%s/idle_%d.png"
## これ未満の高さ比は安定とみなす。
const STABLE_HEIGHT_RATIO: float = 1.04
## これ未満は「軽微」→ 拡縮フレームを間引く（再配置しない。横跳び防止）。
## 以上は「重度」→ 足元固定で全フレーム正規化（ビーストテイマー等）。
const MILD_HEIGHT_RATIO: float = 1.12
## 軽微補正で残す高さ（max からの許容 px）。
const MILD_HEIGHT_SLACK_PX: int = 2


## Adventurer から Idle フォルダ名を解決（助っ人優先、なければ職）。
static func folder_id_for_member(member: Resource) -> String:
	if member == null:
		return ""
	var member_id: String = str(member.id)
	if Constants.is_gacha_helper_id(member_id):
		var helper_id: String = member_id.trim_prefix("gacha_")
		if not helper_id.is_empty() and ResourceLoader.exists(FRAME_PATH % [helper_id, 0]):
			return helper_id
	return str(member.job_id)


static func idle_frame_paths(folder_id: String) -> PackedStringArray:
	var out: PackedStringArray = []
	if folder_id.is_empty():
		return out
	var i: int = 0
	while i < 64:
		var path: String = FRAME_PATH % [folder_id, i]
		if not ResourceLoader.exists(path):
			break
		out.append(path)
		i += 1
	return out


static func load_idle_textures(folder_id: String) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for path in idle_frame_paths(folder_id):
		var tex: Texture2D = load(path) as Texture2D
		if tex != null:
			textures.append(tex)
	return _prepare_idle_textures(textures)


static func load_idle_textures_for_member(member: Resource) -> Array[Texture2D]:
	return load_idle_textures(folder_id_for_member(member))


static func get_idle_texture(folder_id: String) -> Texture2D:
	var textures: Array[Texture2D] = load_idle_textures(folder_id)
	if textures.is_empty():
		return null
	return textures[0]


static func _prepare_idle_textures(textures: Array[Texture2D]) -> Array[Texture2D]:
	if textures.size() <= 1:
		return textures
	## get_image が空／失敗したら元テクスチャのまま（VRAM 圧縮端末向けフォールバック）。
	## モバイルを一律スキップするとビーストテイマー等の拡縮が実機で再発する。
	var images: Array[Image] = []
	for tex in textures:
		var img: Image = tex.get_image()
		if img == null or img.get_width() <= 0 or img.get_height() <= 0:
			return textures
		if img.is_compressed():
			img.decompress()
		if img.get_width() <= 0 or img.get_height() <= 0:
			return textures
		images.append(img)
	var min_h: int = 0
	var max_h: int = 0
	var heights: Array[int] = []
	for img in images:
		var used: Rect2i = img.get_used_rect()
		var h: int = used.size.y
		heights.append(h)
		if h <= 0:
			continue
		if min_h == 0 or h < min_h:
			min_h = h
		if h > max_h:
			max_h = h
	if min_h <= 0 or max_h <= 0:
		return textures
	var ratio: float = float(max_h) / float(min_h)
	if ratio < STABLE_HEIGHT_RATIO:
		return textures
	# ヴァンガード等: 元キャンバス配置を保ったまま、縮んだフレームだけ落とす。
	if ratio < MILD_HEIGHT_RATIO:
		var filtered: Array[Texture2D] = _filter_stable_height_frames(textures, heights, max_h)
		if filtered.size() >= 2:
			return filtered
	# ビーストテイマー等: 全フレームを足元固定で揃える。
	return _stabilize_idle_in_place(textures, images, max_h)


static func _filter_stable_height_frames(
	textures: Array[Texture2D],
	heights: Array[int],
	max_h: int
) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	var floor_h: int = max_h - MILD_HEIGHT_SLACK_PX
	for i in textures.size():
		if heights[i] >= floor_h:
			out.append(textures[i])
	return out


## 重度のズーム揺れを、基準高さ・足元固定でその場アニメ可能にする。
static func _stabilize_idle_in_place(
	textures: Array[Texture2D],
	images: Array[Image],
	target_h: int
) -> Array[Texture2D]:
	var ref_rect: Rect2i = images[0].get_used_rect()
	if ref_rect.size.y <= 0 or target_h <= 0:
		return textures
	var canvas_w: int = images[0].get_width()
	var canvas_h: int = images[0].get_height()
	var ref_foot: Vector2 = _foot_anchor(images[0], ref_rect)
	var out: Array[Texture2D] = []
	for img in images:
		var used: Rect2i = img.get_used_rect()
		if used.size.y <= 0:
			out.append(ImageTexture.create_from_image(img))
			continue
		var scale: float = float(target_h) / float(used.size.y)
		var new_w: int = maxi(1, int(round(float(used.size.x) * scale)))
		var cropped: Image = img.get_region(used)
		cropped.resize(new_w, target_h, Image.INTERPOLATE_NEAREST)
		var src_foot: Vector2 = _foot_anchor(img, used)
		var src_foot_local_x: float = (src_foot.x - float(used.position.x)) * scale
		var canvas := Image.create(canvas_w, canvas_h, false, Image.FORMAT_RGBA8)
		canvas.fill(Color(0, 0, 0, 0))
		var dest_x: int = int(round(ref_foot.x - src_foot_local_x))
		var dest_y: int = int(round(ref_foot.y - float(target_h)))
		dest_x = clampi(dest_x, -new_w + 1, canvas_w - 1)
		dest_y = clampi(dest_y, -target_h + 1, canvas_h - 1)
		_blit_image(canvas, cropped, Vector2i(dest_x, dest_y))
		out.append(ImageTexture.create_from_image(canvas))
	return out


## 不透明画素の下辺帯の中心を「足元」として使う。
static func _foot_anchor(img: Image, used: Rect2i) -> Vector2:
	var band_h: int = maxi(1, int(round(float(used.size.y) * 0.18)))
	var y0: int = used.position.y + used.size.y - band_h
	var min_x: int = used.position.x + used.size.x
	var max_x: int = used.position.x
	var found: bool = false
	for y in range(y0, used.position.y + used.size.y):
		for x in range(used.position.x, used.position.x + used.size.x):
			if img.get_pixel(x, y).a < 0.08:
				continue
			found = true
			min_x = mini(min_x, x)
			max_x = maxi(max_x, x)
	if not found:
		return Vector2(
			float(used.position.x) + float(used.size.x) * 0.5,
			float(used.position.y + used.size.y)
		)
	return Vector2(float(min_x + max_x) * 0.5, float(used.position.y + used.size.y))


static func _blit_image(dst: Image, src: Image, dest_pos: Vector2i) -> void:
	var src_w: int = src.get_width()
	var src_h: int = src.get_height()
	var dst_w: int = dst.get_width()
	var dst_h: int = dst.get_height()
	for y in range(src_h):
		var dy: int = dest_pos.y + y
		if dy < 0 or dy >= dst_h:
			continue
		for x in range(src_w):
			var dx: int = dest_pos.x + x
			if dx < 0 or dx >= dst_w:
				continue
			var px: Color = src.get_pixel(x, y)
			if px.a <= 0.001:
				continue
			dst.set_pixel(dx, dy, px)
