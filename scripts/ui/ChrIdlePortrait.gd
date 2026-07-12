class_name ChrIdlePortrait
extends RefCounted

## ジョブ別 UI 用 Idle ドット（`assets/characters/{job}/idle_*.png`）。
## 戦闘 SpriteFrames の `idle`（=walk）とは別系統。

const IDLE_FPS: float = 8.0
const FRAME_PATH: String = "res://assets/characters/%s/idle_%d.png"

static func idle_frame_paths(job_id: String) -> PackedStringArray:
	var out: PackedStringArray = []
	if job_id.is_empty():
		return out
	var i: int = 0
	while i < 64:
		var path: String = FRAME_PATH % [job_id, i]
		if not ResourceLoader.exists(path):
			break
		out.append(path)
		i += 1
	return out

static func load_idle_textures(job_id: String) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for path in idle_frame_paths(job_id):
		var tex: Texture2D = load(path) as Texture2D
		if tex != null:
			textures.append(tex)
	return textures

static func get_idle_texture(job_id: String) -> Texture2D:
	var textures: Array[Texture2D] = load_idle_textures(job_id)
	if textures.is_empty():
		return null
	return textures[0]
