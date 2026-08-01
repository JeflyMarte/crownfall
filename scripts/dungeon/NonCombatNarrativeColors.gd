class_name NonCombatNarrativeColors
extends RefCounted

## 非戦闘フロア下帯の行色分け SSOT（P3-UX-NONCOMBAT-NARRATIVE-COLOR-001 案A）。
## 宝箱の黄／水色／紫を共通化し、ダメージ＝赤／回復＝緑／加護・EXP＝青を足す。
## 入手行は汎用カテゴリアイコン（BBCode img）を前置する。

const HEX_BODY: String = "ebe6dc"
const HEX_GOLD: String = "ffe14a"
const HEX_DAMAGE: String = "ff5959"
const HEX_HEAL: String = "59f27a"
const HEX_BUFF: String = "7ec8ff"
const HEX_MATERIAL: String = "ffb84a"
const HEX_WEAPON: String = "7ec8ff"
const HEX_ACCESSORY: String = "d4a0ff"
const HEX_LORE_TITLE: String = "c9a0ff"
const HEX_FAIL: String = "b8b4aa"
const HEX_AVOID: String = "73eb94"

const ICON_PX: int = 22
const ICON_GOLD: String = "res://assets/ui/batch2/ICO_Gold.png"
const ICON_MATERIAL: String = "res://assets/ui/survey/ICO_Survey_Materials.png"
const ICON_WEAPON: String = "res://assets/ui/equipment_ui/ICO_Equip_Cat_Weapon.png"
const ICON_ACCESSORY: String = "res://assets/ui/equipment_ui/ICO_Equip_Cat_Accessory.png"
const ICON_BLESS: String = "res://assets/ui/status/ICO_STA_Empower.png"
const ICON_LORE: String = "res://assets/ui/codex/ICO_CDX_LF_AncientRecord.png"
const ICON_HEAL: String = "res://assets/ui/status/ICO_STA_Guard.png"


## 組み込み `wrap(value, min, max)` と衝突するため別名。
static func bb_wrap(hex: String, text: String, bold: bool = false) -> String:
	if text.is_empty():
		return ""
	if bold:
		return "[color=#%s][b]%s[/b][/color]" % [hex, text]
	return "[color=#%s]%s[/color]" % [hex, text]


static func reward_img(kind: String) -> String:
	var path: String = ""
	match kind:
		"gold":
			path = ICON_GOLD
		"material":
			path = ICON_MATERIAL
		"weapon":
			path = ICON_WEAPON
		"accessory":
			path = ICON_ACCESSORY
		"bless", "buff":
			path = ICON_BLESS
		"lore":
			path = ICON_LORE
		"heal":
			path = ICON_HEAL
		_:
			path = ""
	if path.is_empty() or not ResourceLoader.exists(path):
		return ""
	return "[img=%dx%d]%s[/img] " % [ICON_PX, ICON_PX, path]


static func body(text: String) -> String:
	return bb_wrap(HEX_BODY, text)


static func gold(text: String, bold: bool = true) -> String:
	return reward_img("gold") + bb_wrap(HEX_GOLD, text, bold)


static func damage(text: String, bold: bool = true) -> String:
	return bb_wrap(HEX_DAMAGE, text, bold)


static func heal(text: String, bold: bool = true) -> String:
	return reward_img("heal") + bb_wrap(HEX_HEAL, text, bold)


static func buff(text: String) -> String:
	return reward_img("bless") + bb_wrap(HEX_BUFF, text)


static func material(text: String) -> String:
	return reward_img("material") + bb_wrap(HEX_MATERIAL, text)


static func weapon(text: String) -> String:
	return reward_img("weapon") + bb_wrap(HEX_WEAPON, text)


static func accessory(text: String) -> String:
	return reward_img("accessory") + bb_wrap(HEX_ACCESSORY, text)


static func lore_title(text: String) -> String:
	return reward_img("lore") + bb_wrap(HEX_LORE_TITLE, text, true)


static func fail(text: String) -> String:
	return bb_wrap(HEX_FAIL, text)


static func avoid(text: String) -> String:
	return bb_wrap(HEX_AVOID, text)


## 報酬・結果行をキーワードで色分け（碑文／探索ボーナス等）。
static func colorize_line(line: String) -> String:
	var t: String = line.strip_edges()
	if t.is_empty():
		return ""
	if t.begins_with("【碑文】"):
		return lore_title(t)
	if t.contains("ダメージ"):
		return damage(t)
	if t.contains("回復"):
		return heal(t)
	if t.contains("ゴールド"):
		return gold(t)
	if t.begins_with("加護") or t.contains("経験値") or t.contains("が晴れた"):
		return buff(t)
	if t.contains("装飾品"):
		return accessory(t)
	if t.contains("武器"):
		return weapon(t)
	if t.begins_with("[探索]"):
		if t.contains("ゴールド"):
			return gold(t)
		if t.contains("装飾"):
			return accessory(t)
		if t.contains("武器"):
			return weapon(t)
		return material(t)
	if t.contains(" x") or t.contains("×"):
		return material(t)
	return body(t)


static func colorize_multiline(text: String) -> String:
	var parts: PackedStringArray = []
	for line: String in text.split("\n"):
		var colored: String = colorize_line(line)
		if not colored.is_empty():
			parts.append(colored)
	return "\n".join(parts)


static func format_fail_bbcode(fail_line: String, penalty_line: String = "") -> String:
	var parts: PackedStringArray = []
	if not fail_line.is_empty():
		parts.append(fail(fail_line))
	if not penalty_line.is_empty():
		parts.append(damage(penalty_line))
	return "\n".join(parts)


static func format_setup_bbcode(setup_line: String) -> String:
	return body(setup_line)


## RichText → Label 同期用。タグを落として改行は残す。
static func strip_bbcode(bbcode: String) -> String:
	var out: String = ""
	var i: int = 0
	var n: int = bbcode.length()
	while i < n:
		if bbcode[i] == "[":
			var close: int = bbcode.find("]", i)
			if close >= 0:
				i = close + 1
				continue
		out += bbcode[i]
		i += 1
	return out
