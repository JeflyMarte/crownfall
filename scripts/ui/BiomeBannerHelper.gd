class_name BiomeBannerHelper
extends RefCounted

## ダンジョン選択／解放演出で共有する Biome バナー解決。

const PATHS: Dictionary = {
	"mourngate": "res://assets/ui/dungeon/BAN_DG_Mourngate.png",
	"whisperwood": "res://assets/ui/dungeon/BAN_DG_Whisperwood.png",
	"mistfen": "res://assets/ui/dungeon/BAN_DG_Mistfen.png",
	"blackshore": "res://assets/ui/dungeon/BAN_DG_Blackshore.png",
	"frostridge": "res://assets/ui/dungeon/BAN_DG_Frostridge.png",
	"cosmic_rift": "res://assets/ui/dungeon/BAN_DG_CosmicRift.png",
	"crown_rookery": "res://assets/ui/dungeon/BAN_DG_CrownRookery.png",
	"golden_nest": "res://assets/ui/dungeon/BAN_DG_GoldenNest.png",
	"shadow_hunt": "res://assets/ui/dungeon/BAN_DG_ShadowHunt.png",
	"rock_stampede": "res://assets/ui/dungeon/BAN_DG_RockStampede.png",
	"chronos_mausoleum": "res://assets/ui/dungeon/BAN_DG_ChronosMausoleum.png",
	"valgard_boundary": "res://assets/ui/dungeon/BAN_DG_ValgardBoundary.png",
	"north_reach": "res://assets/ui/dungeon/BAN_DG_NorthReach.png",
}

## 専用バナーが無いサブ／奈落は親 Biome を流用。
const SUB_FALLBACK: Dictionary = {
	"astoria_ruins": "mourngate",
	"green_hollow": "whisperwood",
	"broken_marsh": "mistfen",
	"westbay_flats": "blackshore",
	"frostwall_path": "frostridge",
	"red_ridge_mine": "whisperwood",
	"thunder_peak": "mistfen",
	"mistfen_depths": "mistfen",
	"blackshore_abyss": "blackshore",
	"red_forge_depths": "frostridge",
	"abyss_mourngate": "mourngate",
	"abyss_whisperwood": "whisperwood",
	"abyss_mistfen": "mistfen",
	"abyss_blackshore": "blackshore",
	"abyss_frostridge": "frostridge",
}


static func resolve_path(dungeon_id: String) -> String:
	var path: String = str(PATHS.get(dungeon_id, ""))
	if not path.is_empty():
		return path
	var fallback_id: String = str(SUB_FALLBACK.get(dungeon_id, ""))
	if fallback_id.is_empty() and dungeon_id.begins_with("abyss_"):
		fallback_id = dungeon_id.substr(6)
	if fallback_id.is_empty():
		return ""
	return str(PATHS.get(fallback_id, ""))


static func load_texture(dungeon_id: String) -> Texture2D:
	var path: String = resolve_path(dungeon_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


## バナー重ねタイトル用フォントサイズ。
## メイン帯は同一サイズを優先し、深層／はみ出し時のみ段階縮小（文字数閾値は使わない）。
const TITLE_MAX_WIDTH: float = 520.0
const TITLE_MAX_WIDTH_WITH_CLEAR: float = 440.0


static func title_font_size(
	dungeon_id: String,
	title_text: String,
	with_clear: bool = false
) -> int:
	var text: String = title_text.strip_edges()
	if text.is_empty():
		text = "？"
	var max_w: float = TITLE_MAX_WIDTH_WITH_CLEAR if with_clear else TITLE_MAX_WIDTH
	var sizes: Array[int] = [
		UiTypography.SIZE_BODY,
		UiTypography.SIZE_BODY_SMALL,
		UiTypography.SIZE_CAPTION,
	]
	const _AbyssDungeonConfig := preload("res://scripts/dungeon/AbyssDungeonConfig.gd")
	## 深層の「無限〜の最果て」は最初から一段小さく。
	if _AbyssDungeonConfig.is_abyss_dungeon_id(dungeon_id):
		sizes = [UiTypography.SIZE_BODY_SMALL, UiTypography.SIZE_CAPTION]
	var font: Font = UiTypography.display_font()
	if font == null:
		return sizes[0]
	for sz: int in sizes:
		var measured: float = font.get_string_size(
			text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz
		).x
		if measured <= max_w:
			return sz
	return sizes[sizes.size() - 1]
