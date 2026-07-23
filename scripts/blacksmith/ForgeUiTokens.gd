class_name ForgeUiTokens
extends RefCounted

const ROOT: String = "res://assets/ui/forge/"

const ORNAMENT_DIAMOND: String = ROOT + "UI_Ornament_Diamond.png"
const ICO_BACK: String = ROOT + "UI_Ico_Back_Gold.png"
const ANVIL_PANEL: String = ROOT + "UI_Forge_AnvilPanel.png"
const HERO_GLOW: String = ROOT + "UI_Forge_HeroGlow.png"
const HERO_ITEM_BG: String = ROOT + "UI_Forge_HeroItemBg.png"
const TAB_ACTIVE: String = ROOT + "UI_Forge_Tab_Active.png"
const TAB_INACTIVE: String = ROOT + "UI_Forge_Tab_Inactive.png"
const DETAIL_PANEL: String = ROOT + "UI_Forge_DetailPanel.png"
const CRAFTABLE_PANEL: String = ROOT + "UI_Forge_CraftablePanel.png"
const LIST_CARD_NORMAL: String = ROOT + "UI_Forge_ListCard_Normal.png"
const LIST_CARD_SELECTED: String = ROOT + "UI_Forge_ListCard_Selected.png"
const CRAFT_CHIP_NORMAL: String = ROOT + "UI_Forge_CraftChip_Normal.png"
const CRAFT_CHIP_SELECTED: String = ROOT + "UI_Forge_CraftChip_Selected.png"
const MATERIAL_CELL: String = ROOT + "UI_Forge_MaterialCell.png"
const ITEM_CELL_NORMAL: String = ROOT + "UI_Forge_ItemCell_Normal.png"
const ITEM_CELL_SELECTED: String = ROOT + "UI_Forge_ItemCell_Selected.png"
const BTN_PRODUCE: String = ROOT + "UI_Forge_Btn_Produce.png"
const BTN_PRODUCE_DISABLED: String = ROOT + "UI_Forge_Btn_Produce_Disabled.png"
const BTN_DISMANTLE: String = ROOT + "UI_Forge_Btn_Dismantle.png"
const BTN_DISMANTLE_DISABLED: String = ROOT + "UI_Forge_Btn_Dismantle_Disabled.png"
const BTN_BULK_DISMANTLE: String = ROOT + "UI_Forge_Btn_BulkDismantle.png"
const BTN_BULK_DISMANTLE_DISABLED: String = ROOT + "UI_Forge_Btn_BulkDismantle_Disabled.png"
const BTN_ENHANCE: String = ROOT + "UI_Forge_Btn_Enhance.png"
const BTN_ENHANCE_DISABLED: String = ROOT + "UI_Forge_Btn_Enhance_Disabled.png"
const TITLE_COMPLETE: String = ROOT + "UI_Forge_Title_Complete.png"
const RESULT_PANEL: String = ROOT + "UI_Forge_ResultPanel.png"
const SUCCESS_RING: String = ROOT + "UI_Forge_SuccessRing.png"

const PRIMARY_BTN_MARGINS: Vector4i = Vector4i(20, 16, 20, 16)

const ITEM_CELLS_RARITY: Array[String] = EquipmentUiTokens.INV_CELLS

const STAT_ICONS: Dictionary = {
	"atk": ROOT + "ICO_Forge_Stat_ATK.png",
	"def": ROOT + "ICO_Forge_Stat_DEF.png",
	"crit": ROOT + "ICO_Forge_Stat_CRIT.png",
	"hp": ROOT + "ICO_Forge_Stat_HP.png",
}

const CATEGORY_ICONS: Dictionary = {
	"weapon": ROOT + "ICO_Forge_Cat_Weapon.png",
	"armor": ROOT + "ICO_Forge_Cat_Armor.png",
	"accessory": ROOT + "ICO_Forge_Cat_Accessory.png",
}

const CATEGORY_MIN_SIZE: Vector2 = Vector2(72, 88)
## 詳細ヒーロー: 武器背景の上に透過アイコン。背景は少し大きめ。
const HERO_PEDESTAL_PX: int = 200
const HERO_DISPLAY_PX: int = 168
const HERO_ICON_PX: int = HERO_DISPLAY_PX
const HERO_STACK_PX: int = 220
const HERO_ROTATION_DEG: float = 0.0
## ヒーローを枠上端から離す（クレスト／アーチとの被り防止）。
const HERO_NUDGE_Y_PX: float = 28.0
const STAT_ICON_PX: int = 32
const ANVIL_PANEL_HEIGHT: int = 120
const ITEM_CELL_DESIGN_PX: int = 128
const LIST_CARD_MARGINS: Vector4i = Vector4i(12, 12, 12, 12)
const ITEM_CELL_MARGINS: Vector4i = Vector4i(12, 12, 12, 12)
## 詳細枠（装備画面フレーム）。上アーチ＋クレスト分を多めに。
const DETAIL_PANEL_MARGINS: Vector4i = Vector4i(36, 72, 36, 28)
const CRAFTABLE_PANEL_MARGINS: Vector4i = Vector4i(20, 22, 20, 18)
const TAB_MARGINS: Vector4i = Vector4i(16, 12, 16, 14)
## 生産／強化など主ボタンの横幅上限（EXPAND せず中央寄せ）。
const PRIMARY_BTN_WIDTH_PX: float = 240.0
const PRIMARY_BTN_HEIGHT_PX: float = 64.0

static func load_tex(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

static func ornament_diamond() -> Texture2D:
	return load_tex(ORNAMENT_DIAMOND)

static func back_icon() -> Texture2D:
	return load_tex(ICO_BACK)

static func stat_icon(stat_key: String) -> Texture2D:
	return load_tex(str(STAT_ICONS.get(stat_key, "")))

static func category_icon(category: String) -> Texture2D:
	return load_tex(str(CATEGORY_ICONS.get(category, "")))

static func texture_stylebox(
	path: String,
	margins: Vector4i = Vector4i(16, 16, 16, 16),
	content_margin: float = 8.0
) -> StyleBoxTexture:
	var tex: Texture2D = load_tex(path)
	var sb := StyleBoxTexture.new()
	if tex == null:
		return sb
	sb.texture = tex
	sb.texture_margin_left = margins.x
	sb.texture_margin_top = margins.y
	sb.texture_margin_right = margins.z
	sb.texture_margin_bottom = margins.w
	sb.set_content_margin_all(content_margin)
	return sb

static func tab_active_style() -> StyleBox:
	return texture_stylebox(TAB_ACTIVE, TAB_MARGINS, 8.0)


static func tab_inactive_style() -> StyleBox:
	return texture_stylebox(TAB_INACTIVE, TAB_MARGINS, 8.0)


static func detail_panel_style() -> StyleBox:
	return texture_stylebox(DETAIL_PANEL, DETAIL_PANEL_MARGINS, 10.0)


static func craftable_band_style() -> StyleBox:
	return texture_stylebox(CRAFTABLE_PANEL, CRAFTABLE_PANEL_MARGINS, 10.0)


static func list_card_normal_style() -> StyleBox:
	return texture_stylebox(LIST_CARD_NORMAL, LIST_CARD_MARGINS, 8.0)

static func list_card_selected_style() -> StyleBox:
	return texture_stylebox(LIST_CARD_SELECTED, LIST_CARD_MARGINS, 8.0)

static func craft_chip_style(selected: bool) -> StyleBox:
	var path: String = CRAFT_CHIP_SELECTED if selected else CRAFT_CHIP_NORMAL
	return texture_stylebox(path, ITEM_CELL_MARGINS, 6.0)

static func material_cell_style(rarity: int = 0, highlight: bool = true) -> StyleBox:
	return EquipmentUiTokens.rarity_slot_style(rarity, highlight, ITEM_CELL_DESIGN_PX)

static func item_cell_style(rarity: int, selected: bool) -> StyleBox:
	if selected:
		return texture_stylebox(ITEM_CELL_SELECTED, ITEM_CELL_MARGINS, 6.0)
	var idx: int = clampi(rarity, 0, ITEM_CELLS_RARITY.size() - 1)
	var rarity_path: String = ITEM_CELLS_RARITY[idx]
	var sb: StyleBoxTexture = texture_stylebox(rarity_path, ITEM_CELL_MARGINS, 6.0)
	if sb.texture != null:
		return sb
	return texture_stylebox(ITEM_CELL_NORMAL, ITEM_CELL_MARGINS, 6.0)

static func produce_button_styles() -> Dictionary:
	return labeled_primary_button_styles(BTN_PRODUCE, BTN_PRODUCE_DISABLED)


static func dismantle_button_styles() -> Dictionary:
	return labeled_primary_button_styles(BTN_DISMANTLE, BTN_DISMANTLE_DISABLED)


static func bulk_dismantle_button_styles() -> Dictionary:
	return labeled_primary_button_styles(BTN_BULK_DISMANTLE, BTN_BULK_DISMANTLE_DISABLED)


static func enhance_button_styles() -> Dictionary:
	return labeled_primary_button_styles(BTN_ENHANCE, BTN_ENHANCE_DISABLED)


static func labeled_primary_button_styles(normal_path: String, disabled_path: String) -> Dictionary:
	## content_margin が texture_margin より狭いと、ラベルが左枠クロムに食い込んで欠ける。
	return {
		"normal": texture_stylebox(normal_path, PRIMARY_BTN_MARGINS, 18.0),
		"disabled": texture_stylebox(disabled_path, PRIMARY_BTN_MARGINS, 18.0),
	}


## 後方互換（旧 API）
static func produce_button_style() -> StyleBox:
	return produce_button_styles()["normal"]

static func anvil_panel_style() -> StyleBox:
	return texture_stylebox(ANVIL_PANEL, Vector4i(24, 20, 24, 28))


## 生産／強化完了オーバーレイ枠（縦長オーナメントパネル）
static func result_panel_style() -> StyleBox:
	return texture_stylebox(RESULT_PANEL, Vector4i(72, 140, 72, 120), 20.0)


static func title_complete_tex() -> Texture2D:
	return load_tex(TITLE_COMPLETE)


static func success_ring_tex() -> Texture2D:
	return load_tex(SUCCESS_RING)


static func decorate_title(label: Label) -> void:
	var text: String = label.text.strip_edges()
	if text.begins_with("◆"):
		return
	label.text = "◆ %s ◆" % text
