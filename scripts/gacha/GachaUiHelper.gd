class_name GachaUiHelper
extends RefCounted

const _GachaLimitBreak := preload("res://scripts/gacha/GachaLimitBreak.gd")
const _CharacterStatBonuses := preload("res://scripts/roster/CharacterStatBonuses.gd")
const _ChrIdlePortraitView := preload("res://scripts/ui/ChrIdlePortraitView.gd")

const COLOR_GOLD: Color = Color(0.86, 0.74, 0.45)
const COLOR_SUB: Color = Color(0.72, 0.69, 0.62)
const COLOR_OWNED: Color = Color(0.55, 0.88, 0.5)

const LINEUP_ICON_PX: int = 40
const BANNER_PORTRAIT_MAX: int = 3
const BANNER_PORTRAIT_MIN_W: int = 96
## Featured プレビュー対象の最低★（★4→★3。★2 は出さない / P3-GACHA-FEATURE-IDLE-001）
const FEATURED_MIN_RARITY: int = 3
const FEATURED_IDLE_PX: float = 196.0
const FEATURED_STATS_MIN_W: float = 168.0

static func sorted_helpers() -> Array:
	if not Constants.are_gacha_helpers_playable():
		return []
	var helpers: Array = DataRegistry.get_all_gacha_helper_data()
	helpers.sort_custom(func(a, b): return int(a.rarity) > int(b.rarity))
	return helpers


## ★4 先・同帯は display_name 昇順。
static func featured_helpers() -> Array:
	var out: Array = []
	for helper in sorted_helpers():
		if helper == null:
			continue
		if int(helper.rarity) < FEATURED_MIN_RARITY:
			continue
		out.append(helper)
	out.sort_custom(func(a, b):
		var ra: int = int(a.rarity)
		var rb: int = int(b.rarity)
		if ra != rb:
			return ra > rb
		return str(a.display_name) < str(b.display_name)
	)
	return out


static func preview_combat_stats(helper: Resource) -> Dictionary:
	if helper == null:
		return {"hp": 1, "attack": 1, "defense": 1}
	var rarity: int = GachaRarityConfig.clamp_rarity(int(helper.rarity))
	var base_hp: int = CombatController.BASE_MEMBER_HP
	if helper.base_stats != null and int(helper.base_stats.hp) > 0:
		base_hp = int(helper.base_stats.hp)
	var bonuses: Dictionary = GachaRarityConfig.get_stat_bonuses(rarity)
	var pers: Dictionary = _CharacterStatBonuses.for_helper_id(str(helper.id))
	return {
		"hp": maxi(1, base_hp + int(bonuses.get("hp", 0)) + int(pers.get("hp", 0))),
		"attack": maxi(1, int(bonuses.get("attack", 0)) + int(pers.get("attack", 0))),
		"defense": maxi(1, int(bonuses.get("defense", 0)) + int(pers.get("defense", 0))),
	}


static func job_display_name_for_helper(helper: Resource) -> String:
	if helper == null:
		return "—"
	var job_data: Resource = DataRegistry.get_job_data(str(helper.job_id))
	if job_data != null and not str(job_data.display_name).is_empty():
		return str(job_data.display_name)
	return str(helper.job_id)


static func unique_line_for_helper(helper: Resource) -> String:
	if helper == null:
		return ""
	var pid: String = str(helper.passive_id) if "passive_id" in helper else ""
	if not pid.is_empty():
		var def: Dictionary = CombatPassives.get_def(pid)
		var desc: String = str(def.get("description", "")).strip_edges()
		if not desc.is_empty():
			return desc
		var pname: String = str(def.get("display_name", "")).strip_edges()
		if not pname.is_empty():
			return pname
	var note: String = str(helper.origin_note) if "origin_note" in helper else ""
	return note.strip_edges()


static func banner_portrait_textures(max_count: int = BANNER_PORTRAIT_MAX) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	for helper in featured_helpers():
		if out.size() >= max_count:
			break
		if helper == null:
			continue
		var tex: Texture2D = helper.get_portrait_texture()
		if tex != null:
			out.append(tex)
	return out

static func catchcopy() -> String:
	return GachaUiTokens.BANNER_CATCHCOPY

static func pull_title() -> String:
	return "招待状を開く"

static func pull_cost_amount(pulls: int = 1) -> int:
	return GachaSystem.PULL_COST * maxi(1, pulls)

static func owned_label(helper_id: String) -> String:
	if not GameState.owned_helpers.has(helper_id):
		return "未所持"
	var bt: int = _GachaLimitBreak.breakthrough_for_helper_id(helper_id)
	if bt > 0:
		return "限界突破 +%d" % bt
	return "所持済"

static func owned_color(helper_id: String) -> Color:
	return COLOR_OWNED if GameState.owned_helpers.has(helper_id) else COLOR_SUB

## Featured idle + ステパネルのシェルを host に構築。返り値はノード参照 Dictionary。
static func build_featured_shell(host: Control) -> Dictionary:
	var empty: Dictionary = {}
	if host == null:
		return empty
	for child in host.get_children():
		child.queue_free()
	host.mouse_filter = Control.MOUSE_FILTER_STOP
	host.clip_contents = true

	var fade := Control.new()
	fade.name = "FeaturedFade"
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(fade)

	var row := HBoxContainer.new()
	row.name = "FeaturedRow"
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.add_child(row)

	var idle_wrap := CenterContainer.new()
	idle_wrap.name = "IdleWrap"
	idle_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	idle_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	idle_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(idle_wrap)

	var idle: Control = _ChrIdlePortraitView.new()
	idle.name = "FeaturedIdle"
	if idle.has_method("set_portrait_size"):
		idle.call("set_portrait_size", FEATURED_IDLE_PX)
	idle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	idle_wrap.add_child(idle)

	var stats := VBoxContainer.new()
	stats.name = "StatsCol"
	stats.custom_minimum_size = Vector2(FEATURED_STATS_MIN_W, 0)
	stats.size_flags_horizontal = Control.SIZE_SHRINK_END
	stats.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stats.add_theme_constant_override("separation", 4)
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(stats)

	var name_lbl := Label.new()
	name_lbl.name = "LabelName"
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UiTypography.apply_body(name_lbl, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	stats.add_child(name_lbl)

	var stars_lbl := Label.new()
	stars_lbl.name = "LabelStars"
	stars_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	UiTypography.apply_caption(stars_lbl)
	stats.add_child(stars_lbl)

	var job_lbl := Label.new()
	job_lbl.name = "LabelJob"
	job_lbl.clip_text = true
	job_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UiTypography.apply_caption(job_lbl)
	stats.add_child(job_lbl)

	var hp_lbl := Label.new()
	hp_lbl.name = "LabelHp"
	hp_lbl.clip_text = false
	UiTypography.apply_body(hp_lbl, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	stats.add_child(hp_lbl)

	var atk_lbl := Label.new()
	atk_lbl.name = "LabelAtk"
	atk_lbl.clip_text = false
	UiTypography.apply_body(atk_lbl, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	stats.add_child(atk_lbl)

	var def_lbl := Label.new()
	def_lbl.name = "LabelDef"
	def_lbl.clip_text = false
	UiTypography.apply_body(def_lbl, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	stats.add_child(def_lbl)

	var unique_lbl := Label.new()
	unique_lbl.name = "LabelUnique"
	unique_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	unique_lbl.max_lines_visible = 2
	unique_lbl.custom_minimum_size = Vector2(FEATURED_STATS_MIN_W, 0)
	UiTypography.apply_caption(unique_lbl, COLOR_SUB)
	stats.add_child(unique_lbl)

	return {
		"fade": fade,
		"idle": idle,
		"name": name_lbl,
		"stars": stars_lbl,
		"job": job_lbl,
		"hp": hp_lbl,
		"atk": atk_lbl,
		"def": def_lbl,
		"unique": unique_lbl,
	}


static func apply_featured_helper(shell: Dictionary, helper: Resource) -> void:
	if shell.is_empty() or helper == null:
		return
	var idle: Control = shell.get("idle") as Control
	if idle != null and idle.has_method("set_from_helper_id"):
		idle.call("set_from_helper_id", str(helper.id), str(helper.job_id))
	var name_lbl: Label = shell.get("name") as Label
	if name_lbl != null:
		name_lbl.text = str(helper.display_name)
	var stars_lbl: Label = shell.get("stars") as Label
	if stars_lbl != null:
		stars_lbl.text = RosterUiHelper.stars_text(int(helper.rarity))
	var job_lbl: Label = shell.get("job") as Label
	if job_lbl != null:
		job_lbl.text = job_display_name_for_helper(helper)
	var stats: Dictionary = preview_combat_stats(helper)
	var hp_lbl: Label = shell.get("hp") as Label
	if hp_lbl != null:
		hp_lbl.text = "HP  %d" % int(stats.get("hp", 1))
	var atk_lbl: Label = shell.get("atk") as Label
	if atk_lbl != null:
		atk_lbl.text = "ATK  %d" % int(stats.get("attack", 1))
	var def_lbl: Label = shell.get("def") as Label
	if def_lbl != null:
		def_lbl.text = "DEF  %d" % int(stats.get("defense", 1))
	var unique_lbl: Label = shell.get("unique") as Label
	if unique_lbl != null:
		unique_lbl.text = unique_line_for_helper(helper)

static func setup_pull_button(btn: Button, enabled: bool) -> void:
	if btn == null:
		return
	GachaUiTokens.apply_pull_button(btn, enabled)
	btn.text = ""
	for child in btn.get_children():
		child.free()
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(row)
	var title := Label.new()
	title.text = pull_title()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_menu_label(
		title,
		UiTypography.SIZE_BUTTON,
		UiTypography.COLOR_LOCKED if not enabled else UiTypography.COLOR_BODY
	)
	row.add_child(title)
	var token_tex: Texture2D = GachaUiTokens.token_icon()
	if token_tex != null:
		var icon := TextureRect.new()
		icon.texture = token_tex
		icon.custom_minimum_size = Vector2(24, 24)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not enabled:
			icon.modulate = Color(0.62, 0.6, 0.55, 1.0)
		row.add_child(icon)
	var cost := Label.new()
	cost.text = str(pull_cost_amount(1))
	cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_menu_label(
		cost,
		UiTypography.SIZE_BUTTON,
		UiTypography.COLOR_LOCKED if not enabled else UiTypography.COLOR_GOLD
	)
	row.add_child(cost)


static func ticket_pull_title() -> String:
	return "チケットで招待"


static func setup_ticket_pull_button(btn: Button, enabled: bool) -> void:
	if btn == null:
		return
	GachaUiTokens.apply_pull_button(btn, enabled)
	btn.text = ""
	btn.tooltip_text = TicketSystem.display_name(TicketIds.GACHA_FREE)
	for child in btn.get_children():
		child.free()
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(row)
	var title := Label.new()
	title.text = ticket_pull_title()
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_menu_label(
		title,
		UiTypography.SIZE_BUTTON,
		UiTypography.COLOR_LOCKED if not enabled else UiTypography.COLOR_BODY
	)
	row.add_child(title)
	var icon_tex: Texture2D = IconPaths.get_icon_texture(TicketIds.GACHA_FREE, "ticket")
	if icon_tex != null:
		var icon := TextureRect.new()
		icon.texture = icon_tex
		icon.custom_minimum_size = Vector2(24, 24)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not enabled:
			icon.modulate = Color(0.62, 0.6, 0.55, 1.0)
		row.add_child(icon)
	var cost := Label.new()
	cost.text = "×%d" % TicketSystem.free_gacha_qty()
	cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_menu_label(
		cost,
		UiTypography.SIZE_BUTTON,
		UiTypography.COLOR_LOCKED if not enabled else UiTypography.COLOR_GOLD
	)
	row.add_child(cost)

static func make_lineup_row(helper: Resource) -> PanelContainer:
	var helper_id: String = str(helper.id)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", GachaUiTokens.panel_dark_style())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var icon_box := PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(LINEUP_ICON_PX, LINEUP_ICON_PX)
	icon_box.add_theme_stylebox_override("panel", GachaUiTokens.lineup_cell_style())
	var icon_tex: Texture2D = helper.get_portrait_texture()
	if icon_tex != null:
		var icon := TextureRect.new()
		icon.texture = icon_tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_box.add_child(icon)
	else:
		var glyph := Label.new()
		glyph.text = "?"
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_box.add_child(glyph)
	row.add_child(icon_box)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	info.add_child(name_row)
	var name_label := Label.new()
	name_label.text = str(helper.display_name)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UiTypography.apply_body(name_label, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	name_row.add_child(name_label)
	var stars := Label.new()
	stars.text = RosterUiHelper.stars_text(int(helper.rarity))
	stars.add_theme_color_override("font_color", COLOR_GOLD)
	UiTypography.apply_caption(stars)
	name_row.add_child(stars)

	var sub := Label.new()
	var job_data: Resource = DataRegistry.get_job_data(str(helper.job_id))
	var role_id: String = str(job_data.role) if job_data != null else str(helper.job_id)
	var origin_note: String = str(helper.origin_note) if "origin_note" in helper else ""
	if not origin_note.is_empty():
		sub.text = origin_note
	else:
		sub.text = str(RosterUiHelper.ROLE_LABELS.get(role_id, str(helper.job_id)))
	sub.clip_text = true
	sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UiTypography.apply_caption(sub)
	info.add_child(sub)

	var badge := Label.new()
	badge.text = owned_label(helper_id)
	badge.add_theme_color_override("font_color", owned_color(helper_id))
	UiTypography.apply_caption(badge)
	row.add_child(badge)
	return panel

static func make_carousel_cell(helper: Resource, featured: bool = false) -> PanelContainer:
	var helper_id: String = str(helper.id)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(GachaUiTokens.LINEUP_CELL_PX, GachaUiTokens.LINEUP_CELL_PX)
	var style: StyleBox = GachaUiTokens.lineup_cell_style()
	panel.add_theme_stylebox_override("panel", style)
	if featured:
		panel.modulate = Color(1.05, 1.0, 0.88, 1.0)
	var stack := VBoxContainer.new()
	stack.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stack.offset_left = 4
	stack.offset_top = 4
	stack.offset_right = -4
	stack.offset_bottom = -4
	stack.add_theme_constant_override("separation", 1)
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(stack)

	var stars := Label.new()
	stars.text = RosterUiHelper.stars_text(int(helper.rarity))
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.add_theme_color_override("font_color", COLOR_GOLD)
	UiTypography.apply_caption(stars)
	stack.add_child(stars)

	var icon_tex: Texture2D = helper.get_portrait_texture()
	if icon_tex != null:
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(68, 68)
		icon.texture = icon_tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stack.add_child(icon)

	var name := Label.new()
	name.text = str(helper.display_name)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.clip_text = true
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UiTypography.apply_caption(name, owned_color(helper_id))
	stack.add_child(name)
	return panel
