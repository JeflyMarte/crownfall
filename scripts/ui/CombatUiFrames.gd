class_name CombatUiFrames
extends RefCounted

## 戦闘 UI 用の装飾枠（9-slice）。`UI_Frame_Panel_Base` をティントして Elite/Boss 等を表現する。
## P3-UI2-014 段階1: コード駆動ティント。専用枠画像は後続で差し替え可能。

const FRAME_TEXTURE_PATH: String = "res://assets/ui/batch1/UI_Frame_Panel_Base.png"

const TIER_NORMAL: String = "normal"
const TIER_ELITE: String = "elite"
const TIER_BOSS: String = "boss"
const TIER_CARD: String = "card"
const TIER_CARD_ACTIVE: String = "card_active"

static func _frame_texture() -> Texture2D:
	if not ResourceLoader.exists(FRAME_TEXTURE_PATH):
		return null
	return load(FRAME_TEXTURE_PATH) as Texture2D

static func panel_style(tier: String) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	var tex: Texture2D = _frame_texture()
	if tex != null:
		style.texture = tex
	style.texture_margin_left = 4.0
	style.texture_margin_top = 4.0
	style.texture_margin_right = 4.0
	style.texture_margin_bottom = 4.0
	match tier:
		TIER_ELITE:
			style.modulate_color = Color(1.12, 0.94, 0.52, 1.0)
			style.content_margin_left = 12.0
			style.content_margin_top = 12.0
			style.content_margin_right = 12.0
			style.content_margin_bottom = 12.0
		TIER_BOSS:
			style.modulate_color = Color(1.15, 0.52, 0.42, 1.0)
			style.content_margin_left = 14.0
			style.content_margin_top = 14.0
			style.content_margin_right = 14.0
			style.content_margin_bottom = 14.0
		TIER_CARD_ACTIVE:
			style.modulate_color = Color(1.08, 0.9, 0.48, 1.0)
			style.content_margin_left = 8.0
			style.content_margin_top = 8.0
			style.content_margin_right = 8.0
			style.content_margin_bottom = 8.0
		TIER_CARD:
			style.modulate_color = Color(0.82, 0.74, 0.58, 0.98)
			style.content_margin_left = 8.0
			style.content_margin_top = 8.0
			style.content_margin_right = 8.0
			style.content_margin_bottom = 8.0
		_:  # normal
			style.modulate_color = Color(0.78, 0.72, 0.58, 0.96)
			style.content_margin_left = 10.0
			style.content_margin_top = 10.0
			style.content_margin_right = 10.0
			style.content_margin_bottom = 10.0
	return style

static func vignette_color(tier: String) -> Color:
	match tier:
		TIER_ELITE:
			return Color(0.08, 0.05, 0.02, 0.22)
		TIER_BOSS:
			return Color(0.12, 0.02, 0.02, 0.28)
		_:
			return Color(0.0, 0.0, 0.0, 0.0)

static func tier_from_room_type(room_type: int) -> String:
	if room_type == Enums.RoomType.BOSS:
		return TIER_BOSS
	if room_type == Enums.RoomType.ELITE:
		return TIER_ELITE
	return TIER_NORMAL
