class_name CurrencyHelper
extends RefCounted

## ガチャ通貨「魔晶石」。内部キーは `GameState.gacha_token`（セーブ互換）。

const ARCANE_CRYSTAL_ID: String = "arcane_crystal"
const DISPLAY_NAME: String = "魔晶石"
const ICON_PATH: String = "res://assets/ui/batch2/ICO_Currency_Arcanite.png"

static func get_amount() -> int:
	return GameState.gacha_token

static func get_icon_texture() -> Texture2D:
	var tex: Texture2D = IconPaths.get_icon_texture(ARCANE_CRYSTAL_ID, "currency")
	if tex != null:
		return tex
	if ResourceLoader.exists(ICON_PATH):
		return load(ICON_PATH) as Texture2D
	return null

static func format_amount(amount: int = -1) -> String:
	var value: int = get_amount() if amount < 0 else amount
	return str(value)

static func format_label(amount: int = -1) -> String:
	return "%s %s" % [DISPLAY_NAME, format_amount(amount)]
