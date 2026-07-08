class_name PartyLogColors
extends RefCounted

## バトルログ・結果画面で共通のパーティ名色（DungeonScene LOG_PARTY_* と同期）。

const COLOR_MUTED: Color = Color("#A0A4B0")

const COLOR_BY_ADV: Dictionary = {
	"adventurer_0": Color("#E5B870"),
	"adventurer_1": Color("#88C0D0"),
	"adventurer_2": Color("#A3BE8C"),
	"adventurer_3": Color("#B48EAD"),
	"adventurer_4": Color("#D08770"),
}

const COLOR_BY_JOB: Dictionary = {
	"swordsman": Color("#E5B870"),
	"ranger": Color("#88C0D0"),
	"alchemist": Color("#A3BE8C"),
	"vanguard": Color("#B48EAD"),
	"beast_tamer": Color("#D08770"),
}


static func party_color(member: Resource) -> Color:
	if member == null:
		return COLOR_MUTED
	var adv_id: String = str(member.id)
	if COLOR_BY_ADV.has(adv_id):
		return COLOR_BY_ADV[adv_id]
	var job_id: String = str(member.job_id)
	if COLOR_BY_JOB.has(job_id):
		return COLOR_BY_JOB[job_id]
	return COLOR_MUTED


static func color_hex(color: Color) -> String:
	return color.to_html(false)


static func wrap_bbcode(text: String, color: Color) -> String:
	return "[color=%s]%s[/color]" % [color_hex(color), text]
