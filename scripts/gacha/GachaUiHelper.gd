class_name GachaUiHelper
extends RefCounted

const _GachaLimitBreak := preload("res://scripts/gacha/GachaLimitBreak.gd")

const COLOR_GOLD: Color = Color(0.86, 0.74, 0.45)
const COLOR_SUB: Color = Color(0.72, 0.69, 0.62)
const COLOR_OWNED: Color = Color(0.55, 0.88, 0.5)

const LINEUP_ICON_PX: int = 40
const BANNER_PORTRAIT_MAX: int = 3
const BANNER_PORTRAIT_MIN_W: int = 96

static func sorted_helpers() -> Array:
	if not Constants.are_gacha_helpers_playable():
		return []
	var helpers: Array = DataRegistry.get_all_gacha_helper_data()
	helpers.sort_custom(func(a, b): return int(a.rarity) > int(b.rarity))
	return helpers

static func banner_portrait_textures(max_count: int = BANNER_PORTRAIT_MAX) -> Array[Texture2D]:
	var out: Array[Texture2D] = []
	for helper in sorted_helpers():
		if out.size() >= max_count:
			break
		if helper == null:
			continue
		var tex: Texture2D = helper.get_portrait_texture()
		if tex != null:
			out.append(tex)
	return out

static func catchcopy_for_tab(tab_index: int) -> String:
	match tab_index:
		0:
			return "期間限定ピックアップ英雄（準備中）"
		1:
			return "プレミアム英雄召喚（準備中）"
		_:
			return "王国の未来を担う新たな英雄たち"

static func pull_title(pulls: int) -> String:
	return "%d回召喚" % maxi(1, pulls)

static func pull_cost_amount(pulls: int) -> int:
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

static func populate_banner_portraits(host: Control) -> void:
	if host == null:
		return
	for child in host.get_children():
		child.queue_free()
	var textures: Array[Texture2D] = banner_portrait_textures()
	if textures.is_empty():
		return
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(row)
	for tex in textures:
		var frame := PanelContainer.new()
		frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
		frame.custom_minimum_size = Vector2(BANNER_PORTRAIT_MIN_W, 0)
		frame.add_theme_stylebox_override("panel", GachaUiTokens.lineup_cell_style())
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := TextureRect.new()
		icon.texture = tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 6
		icon.offset_top = 6
		icon.offset_right = -6
		icon.offset_bottom = -6
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(icon)
		row.add_child(frame)

static func setup_pull_button(btn: Button, pulls: int, enabled: bool, is_ten_pull: bool = false) -> void:
	if btn == null:
		return
	GachaUiTokens.apply_pull_button(btn, enabled, is_ten_pull)
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
	title.text = pull_title(pulls)
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
	cost.text = str(pull_cost_amount(pulls))
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
