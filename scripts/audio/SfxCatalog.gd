class_name SfxCatalog
extends RefCounted

## 論理 SE ID → アセットパス（P3-AUDIO-SE-001）。

const DIR: String = "res://assets/audio/sfx/"

const ID_UI_CLICK: String = "ui_click"
const ID_UI_CONFIRM: String = "ui_confirm"
const ID_UI_CANCEL: String = "ui_cancel"
const ID_UI_ERROR: String = "ui_error"
const ID_UI_OPEN: String = "ui_open"
const ID_UI_SWITCH: String = "ui_switch"
const ID_UI_EQUIP: String = "ui_equip"
const ID_COMBAT_HIT: String = "combat_hit"
const ID_COMBAT_CRIT: String = "combat_crit"
const ID_COMBAT_HEAL: String = "combat_heal"
const ID_COMBAT_SKILL: String = "combat_skill"
const ID_COMBAT_ULTIMATE: String = "combat_ultimate"
const ID_COMBAT_DEATH: String = "combat_death"
const ID_TREASURE: String = "treasure"
const ID_ROOM_ENTER: String = "room_enter"
const ID_VICTORY: String = "victory"
const ID_LEVEL_UP: String = "level_up"
const ID_GACHA_REVEAL: String = "gacha_reveal"

const PATHS: Dictionary = {
	ID_UI_CLICK: DIR + "ui_click.ogg",
	ID_UI_CONFIRM: DIR + "ui_confirm.ogg",
	ID_UI_CANCEL: DIR + "ui_cancel.ogg",
	ID_UI_ERROR: DIR + "ui_error.ogg",
	ID_UI_OPEN: DIR + "ui_open.ogg",
	ID_UI_SWITCH: DIR + "ui_switch.ogg",
	ID_UI_EQUIP: DIR + "ui_equip.ogg",
	ID_COMBAT_HIT: DIR + "combat_hit.ogg",
	ID_COMBAT_CRIT: DIR + "combat_crit.ogg",
	ID_COMBAT_HEAL: DIR + "combat_heal.ogg",
	ID_COMBAT_SKILL: DIR + "combat_skill.ogg",
	ID_COMBAT_ULTIMATE: DIR + "combat_ultimate.ogg",
	ID_COMBAT_DEATH: DIR + "combat_death.ogg",
	ID_TREASURE: DIR + "treasure.ogg",
	ID_ROOM_ENTER: DIR + "room_enter.ogg",
	ID_VICTORY: DIR + "victory.ogg",
	ID_LEVEL_UP: DIR + "level_up.ogg",
	ID_GACHA_REVEAL: DIR + "gacha_reveal.ogg",
}


static func path_for(sfx_id: String) -> String:
	return str(PATHS.get(sfx_id, ""))


static func all_ids() -> Array[String]:
	var out: Array[String] = []
	for k: Variant in PATHS.keys():
		out.append(str(k))
	out.sort()
	return out
