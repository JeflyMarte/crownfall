class_name CrystalExcavateChrHelper
extends RefCounted

## 発掘戦闘用 — 戦闘と同じ SpriteFrames（idle=walk／attack）。

const CHR_SPRITE_MAP: Dictionary = {
	"swordsman": "res://resources/animation/CHR_Swordsman.tres",
	"ranger": "res://resources/animation/CHR_Ranger.tres",
	"alchemist": "res://resources/animation/CHR_Alchemist.tres",
	"vanguard": "res://resources/animation/CHR_Vanguard.tres",
	"beast_tamer": "res://resources/animation/CHR_BeastTamer.tres",
	"engineer": "res://resources/animation/CHR_Helper_q.tres",
}


static func sprite_path_for_member(member: Resource) -> String:
	if member == null:
		return ""
	var member_id: String = str(member.id)
	if Constants.is_pet_id(member_id):
		return preload("res://scripts/pets/PetSystem.gd").sprite_path_for(member)
	if Constants.is_gacha_helper_id(member_id):
		var helper_id: String = member_id.trim_prefix("gacha_")
		var helper: Resource = DataRegistry.get_gacha_helper_data(helper_id)
		if helper != null:
			var helper_path: String = str(helper.sprite_resource_path)
			if not helper_path.is_empty() and ResourceLoader.exists(helper_path):
				return helper_path
	return str(CHR_SPRITE_MAP.get(str(member.job_id), ""))


static func load_frames_for_member(member: Resource) -> SpriteFrames:
	var path: String = sprite_path_for_member(member)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as SpriteFrames


static func normalize_scale(sprite: AnimatedSprite2D, frames: SpriteFrames, target_h: float) -> void:
	if sprite == null or frames == null:
		return
	var anim: String = "idle"
	if not frames.has_animation(anim):
		var names: PackedStringArray = frames.get_animation_names()
		if names.is_empty():
			return
		anim = str(names[0])
	var tex: Texture2D = frames.get_frame_texture(anim, 0)
	if tex == null or tex.get_height() <= 0:
		return
	var s: float = target_h / float(tex.get_height())
	sprite.scale = Vector2(s, s)
