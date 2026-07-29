extends Control

## 隊長台帳（マイページ）— モック寄せの1スクロール構成。既存素材のみ使用。

const _CommanderProfile = preload("res://scripts/commander/CommanderProfile.gd")
const _CommanderTitles = preload("res://scripts/commander/CommanderTitles.gd")
const _CommanderLifetime = preload("res://scripts/commander/CommanderLifetime.gd")
const _CommanderGiftBox = preload("res://scripts/commander/CommanderGiftBox.gd")
const _CommanderUiTokens = preload("res://scripts/commander/CommanderUiTokens.gd")
const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const BLACKSMITH_SCENE: String = "res://scenes/blacksmith/BlacksmithScene.tscn"
const CODEX_SCENE: String = "res://scenes/codex/CodexScene.tscn"
const SHOWCASE_SCENE: String = "res://scenes/showcase/ShowcaseScene.tscn"
const GOLD_ICON: String = "res://assets/ui/batch2/ICO_Gold.png"

const COLOR_GOLD: Color = Color(0.86, 0.74, 0.45)
const COLOR_SUB: Color = Color(0.72, 0.69, 0.62)
const COLOR_RANK: Color = Color(0.55, 0.78, 0.95)
const COLOR_MUTED: Color = Color(0.55, 0.52, 0.48)

const PORTRAIT_PX: int = 96
const MEMBER_PORTRAIT_PX: int = 72
const MAT_CELL_PX: int = 64
const TITLE_CHIP_PX: int = 56
const MEMBER_SHOW_LIMIT: int = 3
const SECTION_GAP: int = 16
const CARD_PAD: int = 12
const BODY_SEP: int = 8
const INNER_PAD: int = 10
const HEADING_ROW_H: int = 36
const HEADING_ICON_PX: int = 32
const CHIP_LONG_PRESS_SEC: float = 0.45
const CHIP_PRESS_MOVE_CANCEL_PX: float = 20.0

@onready var _label_title: Label = $Header/HeaderRow/LabelTitle
@onready var _btn_back: Button = $Header/HeaderRow/ButtonBack
@onready var _bg_texture: TextureRect = $BgTexture
@onready var _content_host: VBoxContainer = $MainScroll/MainVBox/ContentHost
var _name_edit_dialog: ConfirmationDialog
var _chip_pointer_down: bool = false
var _chip_long_press_fired: bool = false
var _chip_press_timer: SceneTreeTimer = null
var _chip_press_name: String = ""
var _chip_press_origin: Vector2 = Vector2.ZERO
var _name_toast: Label = null
var _name_toast_tween: Tween = null


func _ready() -> void:
	_setup_commander_chrome()
	_label_title.text = _CommanderUiTokens.SCREEN_TITLE
	UiTypography.apply_screen_title(_label_title)
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.MYPAGE)
	_btn_back.pressed.connect(_on_back_pressed)
	_content_host.add_theme_constant_override("separation", SECTION_GAP)
	_setup_name_edit_dialog()
	_rebuild_page()
	ScrollTouchHelper.enable($MainScroll as ScrollContainer)


func _setup_commander_chrome() -> void:
	var bg_tex: Texture2D = _CommanderUiTokens.load_tex(_CommanderUiTokens.BG)
	if bg_tex != null:
		_bg_texture.texture = bg_tex
	UiTypography.apply_button(_btn_back, false)


func _setup_name_edit_dialog() -> void:
	_name_edit_dialog = ConfirmationDialog.new()
	_name_edit_dialog.title = "指揮官名の変更"
	_name_edit_dialog.ok_button_text = "変更する"
	_name_edit_dialog.cancel_button_text = "やめる"
	_name_edit_dialog.dialog_text = "新しい指揮官名を入力してください"
	var field := LineEdit.new()
	field.name = "NameField"
	field.placeholder_text = "指揮官名（16文字まで）"
	field.custom_minimum_size = Vector2(280, 36)
	_name_edit_dialog.add_child(field)
	_name_edit_dialog.confirmed.connect(_on_name_edit_confirmed)
	add_child(_name_edit_dialog)


func _rebuild_page() -> void:
	for child in _content_host.get_children():
		child.queue_free()
	_content_host.add_child(_build_overview_section())
	var gift_section: Control = _build_gift_box_section()
	if gift_section != null:
		_content_host.add_child(gift_section)
	_content_host.add_child(_build_showcase_section())
	_content_host.add_child(_build_assets_section())
	_content_host.add_child(_build_members_section())
	_content_host.add_child(_build_records_section())
	_content_host.add_child(_build_titles_section())
	## rebuild 後に Button が STOP のままだと実機で縦スクロール不能になる。
	ScrollTouchHelper.enable($MainScroll as ScrollContainer)


# ---- 展示室 ----
func _build_showcase_section() -> Control:
	var sec: Dictionary = _begin_section("showcase", "展示室")
	var body: VBoxContainer = sec["body"]
	var blurb := Label.new()
	blurb.text = "自慢の仲間を一枚で飾れます。スタッフ作例も閲覧できます。"
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_caption(blurb, COLOR_SUB)
	body.add_child(blurb)
	var showcase_member: Resource = GameState.find_showcase_member()
	var status := Label.new()
	if showcase_member != null:
		status.text = "展示中: %s  Lv.%d" % [
			str(showcase_member.display_name),
			int(showcase_member.level),
		]
	else:
		status.text = "展示中: （未設定）"
	UiTypography.apply_body(status, UiTypography.SIZE_BODY_SMALL, COLOR_GOLD)
	body.add_child(status)
	var go_btn := Button.new()
	go_btn.text = "展示室を開く"
	UiTypography.apply_menu_button(go_btn, false)
	go_btn.pressed.connect(func(): SceneRouter.change_scene(SHOWCASE_SCENE))
	body.add_child(go_btn)
	return sec["panel"]


# ---- 概要 ----
func _build_overview_section() -> Control:
	var sec: Dictionary = _begin_section("overview", "概要")
	var body: VBoxContainer = sec["body"]
	var profile := _make_inner_block()
	body.add_child(profile["panel"])
	var profile_body: VBoxContainer = profile["body"]
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	profile_body.add_child(top)
	top.add_child(_make_rank_portrait())
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 6)
	top.add_child(info)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	info.add_child(name_row)
	var name_lbl := Label.new()
	name_lbl.text = _CommanderProfile.get_commander_name()
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_display(name_lbl, UiTypography.SIZE_BODY, COLOR_GOLD)
	name_row.add_child(name_lbl)
	name_row.add_child(_make_name_change_button())
	var rank_lbl := Label.new()
	rank_lbl.text = _CommanderProfile.rank_display(false)
	UiTypography.apply_display(rank_lbl, UiTypography.SIZE_BODY, COLOR_RANK)
	info.add_child(rank_lbl)
	var progress: Dictionary = _CommanderProfile.progress_to_next_rank()
	var bar := ProgressBar.new()
	bar.max_value = 1.0
	bar.value = float(progress.get("progress", 0.0))
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 14)
	info.add_child(bar)
	_add_caption(info, str(progress.get("label", "")))
	_add_subheading(body, "最近のハイライト")
	var highlights_block := _make_inner_block()
	body.add_child(highlights_block["panel"])
	var highlights_body: VBoxContainer = highlights_block["body"]
	var highlights: Array = _CommanderProfile.get_recent_highlights()
	if highlights.is_empty():
		_add_caption(highlights_body, "まだ記録がありません")
	else:
		for entry: Variant in highlights:
			if entry is Dictionary:
				_add_caption(highlights_body, "・%s" % str(entry.get("text", "")))
	return sec["panel"]


func _make_rank_portrait() -> PanelContainer:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(PORTRAIT_PX, PORTRAIT_PX)
	var tier: String = CombatUiFrames.TIER_CARD_ACTIVE \
		if _CommanderProfile.is_rank_at_least(_CommanderProfile.GOLD_SEAL_RANK) \
		else CombatUiFrames.TIER_CARD
	frame.add_theme_stylebox_override("panel", CombatUiFrames.panel_style(tier))
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(center)
	var rank_tex: Texture2D = _CommanderProfile.rank_icon_texture()
	if rank_tex != null:
		var art := TextureRect.new()
		art.texture = rank_tex
		art.custom_minimum_size = Vector2(PORTRAIT_PX - 12, PORTRAIT_PX - 12)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.add_child(art)
	else:
		var glyph := Label.new()
		glyph.text = _CommanderProfile.rank_glyph()
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UiTypography.apply_display(glyph, UiTypography.SIZE_DISPLAY_TITLE, COLOR_GOLD)
		center.add_child(glyph)
	return frame


func _make_title_banner(label_text: String) -> PanelContainer:
	var banner := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.10, 0.07, 0.92)
	sb.set_border_width_all(2)
	sb.border_color = COLOR_GOLD
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 4.0
	sb.content_margin_bottom = 4.0
	banner.add_theme_stylebox_override("panel", sb)
	var lbl := Label.new()
	lbl.text = "◆ %s" % label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(lbl, UiTypography.SIZE_CAPTION, COLOR_GOLD)
	banner.add_child(lbl)
	return banner


func _make_name_change_button() -> Button:
	var btn := Button.new()
	btn.text = "名前変更"
	UiTypography.apply_menu_button(btn, false)
	btn.pressed.connect(_open_name_edit_dialog)
	return btn


func _open_name_edit_dialog() -> void:
	var field: LineEdit = _name_edit_dialog.get_node_or_null("NameField") as LineEdit
	if field != null:
		field.text = _CommanderProfile.get_commander_name()
	_name_edit_dialog.popup_centered()


func _on_name_edit_confirmed() -> void:
	var field: LineEdit = _name_edit_dialog.get_node_or_null("NameField") as LineEdit
	if field == null:
		return
	if _CommanderProfile.set_commander_name(field.text):
		SaveManager.save_game()
		_rebuild_page()


# ---- 配布ボックス ----
func _build_gift_box_section() -> Control:
	var pending: Array = _CommanderGiftBox.get_pending_entries()
	if pending.is_empty():
		return null
	var sec: Dictionary = _begin_section("gift_box", "配布ボックス（%d）" % pending.size())
	var body: VBoxContainer = sec["body"]
	_add_caption(body, "ギルドから届いた配布物を受け取れます。")
	if pending.size() > 1:
		var claim_all_row := HBoxContainer.new()
		claim_all_row.alignment = BoxContainer.ALIGNMENT_END
		claim_all_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body.add_child(claim_all_row)
		var claim_all_btn := Button.new()
		claim_all_btn.text = "すべて受け取る"
		UiTypography.apply_menu_button(claim_all_btn, false)
		claim_all_btn.pressed.connect(_on_gift_claim_all_pressed)
		claim_all_row.add_child(claim_all_btn)
	for entry: Dictionary in pending:
		body.add_child(_make_gift_row(entry))
	return sec["panel"]


func _make_gift_row(entry: Dictionary) -> PanelContainer:
	var block := PanelContainer.new()
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block.add_theme_stylebox_override("panel", _inner_panel_style())
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", INNER_PAD)
	margin.add_theme_constant_override("margin_right", INNER_PAD)
	margin.add_theme_constant_override("margin_top", INNER_PAD - 2)
	margin.add_theme_constant_override("margin_bottom", INNER_PAD - 2)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(row)
	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 4)
	row.add_child(text_col)
	var title_lbl := Label.new()
	title_lbl.text = str(entry.get("title", "ギルド配布"))
	UiTypography.apply_body(title_lbl, UiTypography.SIZE_BODY_SMALL, COLOR_GOLD)
	text_col.add_child(title_lbl)
	var message: String = str(entry.get("message", "")).strip_edges()
	if not message.is_empty():
		_add_caption(text_col, message)
	_add_caption(text_col, _CommanderGiftBox.reward_summary(entry))
	var claim_btn := Button.new()
	claim_btn.text = "受け取る"
	UiTypography.apply_menu_button(claim_btn, false)
	claim_btn.pressed.connect(_on_gift_claim_pressed.bind(str(entry.get("id", ""))))
	row.add_child(claim_btn)
	return block


func _on_gift_claim_pressed(entry_id: String) -> void:
	var result: Dictionary = _CommanderGiftBox.claim(entry_id)
	if not bool(result.get("ok", false)):
		return
	SaveManager.save_game()
	_rebuild_page()


func _on_gift_claim_all_pressed() -> void:
	var result: Dictionary = _CommanderGiftBox.claim_all()
	if not bool(result.get("ok", false)):
		return
	SaveManager.save_game()
	_rebuild_page()


# ---- 資産 ----
func _build_assets_section() -> Control:
	var sec: Dictionary = _begin_section("assets", "資産")
	var body: VBoxContainer = sec["body"]
	var currency_block := _make_inner_block()
	body.add_child(currency_block["panel"])
	var currency_body: VBoxContainer = currency_block["body"]
	var currency := HBoxContainer.new()
	currency.add_theme_constant_override("separation", 16)
	currency.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	currency_body.add_child(currency)
	currency.add_child(_make_currency_chip(GOLD_ICON, "%d" % GameState.gold))
	currency.add_child(_make_currency_chip(
		CurrencyHelper.ICON_PATH,
		CurrencyHelper.format_amount()
	))
	_add_subheading(body, "所持チケット")
	var tickets: Array = _owned_ticket_rows()
	if tickets.is_empty():
		_add_caption(body, "所持チケットなし")
	else:
		var ticket_block := _make_inner_block()
		body.add_child(ticket_block["panel"])
		var ticket_scroll := ScrollContainer.new()
		ticket_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		ticket_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		ticket_scroll.custom_minimum_size = Vector2(0, MAT_CELL_PX + 28)
		ticket_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ticket_block["body"].add_child(ticket_scroll)
		var ticket_grid := HBoxContainer.new()
		ticket_grid.add_theme_constant_override("separation", 8)
		ticket_scroll.add_child(ticket_grid)
		for row_data: Dictionary in tickets:
			ticket_grid.add_child(_make_ticket_chip(
				str(row_data.get("id", "")),
				int(row_data.get("qty", 0))
			))
	_add_subheading(body, "所持素材")
	var mats: Array = _CommanderProfile.top_materials(8)
	if mats.is_empty():
		_add_caption(body, "所持素材なし")
	else:
		var mat_block := _make_inner_block()
		body.add_child(mat_block["panel"])
		var mat_scroll := ScrollContainer.new()
		mat_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		mat_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		mat_scroll.custom_minimum_size = Vector2(0, MAT_CELL_PX + 28)
		mat_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mat_block["body"].add_child(mat_scroll)
		var grid := HBoxContainer.new()
		grid.add_theme_constant_override("separation", 8)
		mat_scroll.add_child(grid)
		for row_data: Dictionary in mats:
			grid.add_child(_make_material_chip(
				str(row_data.get("id", "")),
				int(row_data.get("qty", 0))
			))
	var shortcuts := HBoxContainer.new()
	shortcuts.add_theme_constant_override("separation", 8)
	shortcuts.alignment = BoxContainer.ALIGNMENT_END
	shortcuts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(shortcuts)
	var forge_btn := Button.new()
	forge_btn.text = "鍛冶屋へ"
	UiTypography.apply_menu_button(forge_btn, false)
	forge_btn.pressed.connect(func(): SceneRouter.change_scene(BLACKSMITH_SCENE))
	shortcuts.add_child(forge_btn)
	var codex_btn := Button.new()
	codex_btn.text = "図鑑へ"
	UiTypography.apply_menu_button(codex_btn, false)
	codex_btn.pressed.connect(func(): SceneRouter.change_scene(CODEX_SCENE))
	shortcuts.add_child(codex_btn)
	return sec["panel"]


func _make_currency_chip(icon_path: String, amount_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	if ResourceLoader.exists(icon_path):
		var icon := TextureRect.new()
		icon.texture = load(icon_path) as Texture2D
		icon.custom_minimum_size = Vector2(28, 28)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
	var lbl := Label.new()
	lbl.text = amount_text
	UiTypography.apply_body(lbl, UiTypography.SIZE_BODY_SMALL, COLOR_GOLD)
	row.add_child(lbl)
	return row


func _make_material_chip(material_id: String, qty: int) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	var cell: Control = MaterialUiTokens.make_icon_cell(material_id, MAT_CELL_PX, true)
	## 子 STOP だと長押し gui_input が親に届かない。
	_set_mouse_filter_tree(cell, Control.MOUSE_FILTER_IGNORE)
	col.add_child(cell)
	var qty_lbl := Label.new()
	qty_lbl.text = "x%d" % qty
	qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qty_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_caption(qty_lbl, COLOR_SUB)
	col.add_child(qty_lbl)
	var mat_name: String = DataRegistry.get_material_name(material_id)
	col.tooltip_text = mat_name
	_bind_chip_long_press(col, mat_name)
	return col


func _owned_ticket_rows() -> Array:
	var rows: Array = []
	for tid in TicketIds.ALL:
		var qty: int = TicketInventory.get_qty(tid)
		if qty <= 0:
			continue
		rows.append({"id": tid, "qty": qty})
	return rows


func _make_ticket_chip(ticket_id: String, qty: int) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	var ticket_name: String = TicketSystem.display_name(ticket_id)
	col.tooltip_text = ticket_name
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(MAT_CELL_PX, MAT_CELL_PX)
	var rarity: int = 0
	var ticket: Resource = DataRegistry.get_ticket_data(ticket_id)
	if ticket != null and int(ticket.target_rarity) > 0:
		# ★帯チケットは見た目枠をレア帯に寄せる（N=0 … SSR=3）
		rarity = clampi(int(ticket.target_rarity) - 1, 0, 3)
	# テーマ既定パネルは不透明板になるため、素材セルと同様の rarity 枠のみにする。
	frame.add_theme_stylebox_override(
		"panel",
		EquipmentUiTokens.rarity_slot_style(rarity, false, MAT_CELL_PX)
	)
	## 長押しは親 col で受ける（frame が STOP だとイベントを奪う）。
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var host := Control.new()
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.add_child(host)
	var tex: Texture2D = IconPaths.get_icon_texture(ticket_id, "ticket")
	if tex != null:
		var inset: int = EquipmentUiTokens.icon_inset_px(MAT_CELL_PX, EquipmentUiTokens.INV_CELL_DESIGN_PX)
		var icon := TextureRect.new()
		icon.texture = tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = inset
		icon.offset_top = inset
		icon.offset_right = -inset
		icon.offset_bottom = -inset
		host.add_child(icon)
	else:
		var glyph := Label.new()
		glyph.text = "?"
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		UiTypography.apply_caption(glyph, COLOR_MUTED)
		host.add_child(glyph)
	col.add_child(frame)
	var qty_lbl := Label.new()
	qty_lbl.text = "x%d" % qty
	qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qty_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_caption(qty_lbl, COLOR_GOLD)
	col.add_child(qty_lbl)
	_bind_chip_long_press(col, ticket_name)
	return col


# ---- 仲間 ----
func _build_members_section() -> Control:
	var sec: Dictionary = _begin_section("members", "よく使う仲間")
	var body: VBoxContainer = sec["body"]
	var rows: Array = _CommanderProfile.top_deployed_members(MEMBER_SHOW_LIMIT)
	if rows.is_empty():
		_add_caption(body, "まだ出撃記録がありません")
		return sec["panel"]
	var members_block := _make_inner_block()
	body.add_child(members_block["panel"])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	members_block["body"].add_child(row)
	var rank: int = 1
	for row_data: Dictionary in rows:
		row.add_child(_make_member_card(row_data, rank))
		rank += 1
	return sec["panel"]


func _make_member_card(row_data: Dictionary, rank: int) -> PanelContainer:
	var member: Resource = _find_member(str(row_data.get("member_id", "")))
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override(
		"panel",
		RosterUiHelper.card_panel_style(true, rank == 1)
	)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	card.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)
	var rank_lbl := Label.new()
	rank_lbl.text = "#%d" % rank
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(rank_lbl, COLOR_GOLD)
	vbox.add_child(rank_lbl)
	var portrait_tex: Texture2D = RosterUiHelper.get_member_portrait_texture(member) \
		if member != null else null
	if portrait_tex != null:
		var portrait := TextureRect.new()
		portrait.texture = portrait_tex
		portrait.custom_minimum_size = Vector2(MEMBER_PORTRAIT_PX, MEMBER_PORTRAIT_PX)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vbox.add_child(portrait)
	var name_lbl := Label.new()
	name_lbl.text = RosterUiHelper.short_display_name(str(row_data.get("display_name", "")))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(name_lbl, UiTypography.SIZE_CAPTION, UiTypography.COLOR_BODY)
	vbox.add_child(name_lbl)
	var job_lbl := Label.new()
	job_lbl.text = RosterUiHelper.job_display_name(member) if member != null else "—"
	job_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(job_lbl, COLOR_SUB)
	vbox.add_child(job_lbl)
	var stats_lbl := Label.new()
	stats_lbl.text = "出撃%d\nMVP%d" % [
		int(row_data.get("count", 0)),
		int(row_data.get("mvp_count", 0)),
	]
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(stats_lbl, COLOR_SUB)
	vbox.add_child(stats_lbl)
	return card


func _find_member(member_id: String) -> Resource:
	if member_id.is_empty():
		return null
	for adv: Resource in GameState.roster:
		if adv != null and str(adv.id) == member_id:
			return adv
	return null


# ---- 記録 ----
func _build_records_section() -> Control:
	var sec: Dictionary = _begin_section("records", "記録")
	var body: VBoxContainer = sec["body"]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(grid)
	var lifetime: Dictionary = _CommanderProfile.get_lifetime()
	grid.add_child(_make_record_block("戦闘記録", _battle_record_lines(lifetime)))
	grid.add_child(_make_record_block("調査記録", [
		"完走 %d" % int(lifetime.get("runs_cleared", 0)),
		"撤退 %d" % int(lifetime.get("runs_retired", 0)),
		"全滅 %d" % int(lifetime.get("runs_wiped", 0)),
	]))
	var rates: Dictionary = _CommanderProfile.codex_rates()
	var codex_lines: PackedStringArray = []
	for key in ["enemy", "material", "weapon"]:
		var row: Dictionary = rates.get(key, {})
		var label: String = {"enemy": "モンスター", "material": "素材", "weapon": "武器"}.get(key, key)
		codex_lines.append("%s %d/%d（%d%%）" % [
			label,
			int(row.get("discovered", 0)),
			int(row.get("total", 0)),
			int(row.get("percent", 0)),
		])
	grid.add_child(_make_record_block("図鑑進捗", codex_lines))
	## 詳細（SP／発見件数）はオミット。代わりに累計プレイ時間を出す。
	var play_sec: int = _CommanderLifetime.total_play_time_sec()
	grid.add_child(_make_record_block("プレイ時間", [
		_CommanderLifetime.format_play_time(play_sec),
	]))
	return sec["panel"]


func _set_mouse_filter_tree(node: Node, filter: Control.MouseFilter) -> void:
	if node is Control:
		(node as Control).mouse_filter = filter
	for child in node.get_children():
		_set_mouse_filter_tree(child, filter)


func _bind_chip_long_press(host: Control, display_name: String) -> void:
	if host == null or display_name.is_empty():
		return
	## ScrollTouch 後も PASS 経由で gui_input を受け取る（装備所持と同方針）。
	host.mouse_filter = Control.MOUSE_FILTER_STOP
	host.gui_input.connect(_on_chip_gui_input.bind(display_name))


func _on_chip_gui_input(event: InputEvent, display_name: String) -> void:
	if _chip_pointer_down and _should_cancel_chip_press_for_move(event):
		_cancel_chip_press()
		return
	if not _is_chip_pointer_event(event):
		return
	if event.pressed:
		_chip_press_origin = _chip_event_position(event)
		_begin_chip_press(display_name)
	else:
		_end_chip_press()


func _is_chip_pointer_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		return true
	return false


func _chip_event_position(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).position
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).position
	if event is InputEventMouseMotion:
		return (event as InputEventMouseMotion).position
	return Vector2.ZERO


func _should_cancel_chip_press_for_move(event: InputEvent) -> bool:
	if event is InputEventScreenDrag:
		return (
			_chip_press_origin.distance_to((event as InputEventScreenDrag).position)
			>= CHIP_PRESS_MOVE_CANCEL_PX
		)
	if event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		if (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			return false
		return _chip_press_origin.distance_to(motion.position) >= CHIP_PRESS_MOVE_CANCEL_PX
	return false


func _begin_chip_press(display_name: String) -> void:
	_cancel_chip_press()
	_chip_pointer_down = true
	_chip_long_press_fired = false
	_chip_press_name = display_name
	_chip_press_timer = get_tree().create_timer(CHIP_LONG_PRESS_SEC)
	_chip_press_timer.timeout.connect(_on_chip_long_press_timeout)


func _on_chip_long_press_timeout() -> void:
	if not _chip_pointer_down:
		return
	_chip_long_press_fired = true
	_show_chip_name(_chip_press_name)


func _end_chip_press() -> void:
	if not _chip_pointer_down:
		return
	_chip_pointer_down = false
	_cancel_chip_press_timer_only()
	_chip_press_name = ""


func _cancel_chip_press_timer_only() -> void:
	if _chip_press_timer != null:
		if _chip_press_timer.timeout.is_connected(_on_chip_long_press_timeout):
			_chip_press_timer.timeout.disconnect(_on_chip_long_press_timeout)
		_chip_press_timer = null


func _cancel_chip_press() -> void:
	_chip_pointer_down = false
	_chip_long_press_fired = false
	_cancel_chip_press_timer_only()
	_chip_press_name = ""


func _ensure_name_toast() -> void:
	if _name_toast != null and is_instance_valid(_name_toast):
		return
	_name_toast = Label.new()
	_name_toast.name = "ChipNameToast"
	_name_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_toast.z_index = 60
	_name_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_toast.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_name_toast.offset_left = 24.0
	_name_toast.offset_right = -24.0
	_name_toast.offset_top = -168.0
	_name_toast.offset_bottom = -120.0
	_name_toast.visible = false
	UiTypography.apply_body(_name_toast, UiTypography.SIZE_BODY, COLOR_GOLD)
	add_child(_name_toast)


func _show_chip_name(name_text: String) -> void:
	if name_text.is_empty():
		return
	_ensure_name_toast()
	_name_toast.text = name_text
	_name_toast.visible = true
	if _name_toast_tween != null and is_instance_valid(_name_toast_tween):
		_name_toast_tween.kill()
	_name_toast_tween = create_tween()
	_name_toast_tween.tween_interval(1.6)
	_name_toast_tween.tween_callback(func() -> void:
		if _name_toast != null and is_instance_valid(_name_toast) and _name_toast.text == name_text:
			_name_toast.visible = false
	)


func _battle_record_lines(lifetime: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	var max_hit: int = int(lifetime.get("damage_max_hit", 0))
	if max_hit <= 0:
		lines.append("最大一撃: —")
	else:
		var skill_name: String = str(lifetime.get("damage_max_hit_skill_name", ""))
		var line: String = "最大一撃: %s" % _CommanderLifetime._format_int(max_hit)
		if not skill_name.is_empty():
			line += "（%s）" % skill_name
		lines.append(line)
	lines.append("単ラン与ダメ: %s" % _fmt_or_dash(int(lifetime.get("damage_max_run_total", 0))))
	lines.append("単ラン回復: %s" % _fmt_or_dash(int(lifetime.get("heal_max_run_total", 0))))
	return lines


func _make_record_block(title: String, lines: Array) -> PanelContainer:
	var block := PanelContainer.new()
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block.size_flags_vertical = Control.SIZE_EXPAND_FILL
	block.add_theme_stylebox_override("panel", _inner_panel_style())
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", INNER_PAD)
	margin.add_theme_constant_override("margin_right", INNER_PAD)
	margin.add_theme_constant_override("margin_top", INNER_PAD - 2)
	margin.add_theme_constant_override("margin_bottom", INNER_PAD - 2)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)
	_add_subheading(vbox, title)
	for line: Variant in lines:
		_add_caption(vbox, str(line))
	return block


# ---- 称号 ----
func _build_titles_section() -> Control:
	var sec: Dictionary = _begin_section("titles", "称号（%d枠）" % _CommanderProfile.title_slot_limit())
	var body: VBoxContainer = sec["body"]
	var equipped_block := _make_inner_block()
	body.add_child(equipped_block["panel"])
	var equipped_body: VBoxContainer = equipped_block["body"]
	var equipped: String = _CommanderProfile.get_equipped_title()
	if equipped.is_empty():
		_add_caption(equipped_body, "装備中: なし")
	else:
		equipped_body.add_child(_make_title_banner(_CommanderTitles.get_label(equipped)))
	var clear_row := HBoxContainer.new()
	clear_row.alignment = BoxContainer.ALIGNMENT_END
	clear_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipped_body.add_child(clear_row)
	var clear_btn := Button.new()
	clear_btn.text = "称号を外す"
	clear_btn.disabled = equipped.is_empty()
	UiTypography.apply_menu_button(clear_btn, false)
	clear_btn.pressed.connect(func():
		_CommanderProfile.equip_title("")
		SaveManager.save_game()
		_rebuild_page()
	)
	clear_row.add_child(clear_btn)
	_add_subheading(body, "獲得称号一覧")
	var unlocked: Array = _CommanderProfile.get_unlocked_titles()
	if unlocked.is_empty():
		_add_caption(body, "未獲得")
	else:
		var list_block := _make_inner_block()
		body.add_child(list_block["panel"])
		var wrap := HFlowContainer.new()
		wrap.add_theme_constant_override("h_separation", 8)
		wrap.add_theme_constant_override("v_separation", 8)
		wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list_block["body"].add_child(wrap)
		for title_id: Variant in unlocked:
			wrap.add_child(_make_title_chip(str(title_id), str(title_id) == equipped))
	_add_caption(body, "称号は見た目のみで、戦闘力には影響しません。")
	return sec["panel"]


func _make_title_chip(title_id: String, is_equipped: bool) -> Button:
	var btn := Button.new()
	btn.text = _CommanderTitles.get_label(title_id)
	btn.toggle_mode = true
	btn.button_pressed = is_equipped
	btn.disabled = is_equipped
	btn.custom_minimum_size = Vector2(TITLE_CHIP_PX * 2, TITLE_CHIP_PX)
	btn.tooltip_text = _CommanderTitles.get_label(title_id)
	UiTypography.apply_menu_button(btn, is_equipped)
	if is_equipped:
		btn.add_theme_color_override("font_color", COLOR_GOLD)
	else:
		btn.pressed.connect(_equip_title.bind(title_id))
	return btn


func _equip_title(title_id: String) -> void:
	if _CommanderProfile.equip_title(title_id):
		SaveManager.save_game()
		_rebuild_page()


# ---- 共通 UI ----
func _make_card() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	return panel


func _begin_section(icon_id: String, title: String) -> Dictionary:
	var panel := _make_card()
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", BODY_SEP)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", CARD_PAD)
	margin.add_theme_constant_override("margin_right", CARD_PAD)
	margin.add_theme_constant_override("margin_top", CARD_PAD)
	margin.add_theme_constant_override("margin_bottom", CARD_PAD)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(margin)
	margin.add_child(root)
	root.add_child(_make_section_header(icon_id, title))
	root.add_child(_make_section_rule())
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", BODY_SEP)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	return {"panel": panel, "body": body}


func _make_section_header(icon_id: String, title: String) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = HEADING_ROW_H
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not icon_id.is_empty():
		var tex: Texture2D = IconPaths.get_icon_texture(icon_id, "commander")
		if tex != null:
			var icon := TextureRect.new()
			icon.texture = tex
			icon.custom_minimum_size = Vector2(HEADING_ICON_PX, HEADING_ICON_PX)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			row.add_child(icon)
	var lbl := Label.new()
	lbl.text = title
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiTypography.apply_display(lbl, UiTypography.SIZE_BODY_SMALL, COLOR_GOLD)
	row.add_child(lbl)
	return row


func _make_section_rule() -> Control:
	var rule_tex: Texture2D = _CommanderUiTokens.load_tex(_CommanderUiTokens.SECTION_RULE)
	if rule_tex != null:
		var rule := TextureRect.new()
		rule.texture = rule_tex
		rule.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		rule.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rule.custom_minimum_size = Vector2(0, 8)
		rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return rule
	var sep := HSeparator.new()
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sep.modulate = Color(0.55, 0.45, 0.18, 0.55)
	return sep


func _make_inner_block() -> Dictionary:
	var block := PanelContainer.new()
	block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block.add_theme_stylebox_override("panel", _inner_panel_style())
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", INNER_PAD)
	margin.add_theme_constant_override("margin_right", INNER_PAD)
	margin.add_theme_constant_override("margin_top", INNER_PAD - 2)
	margin.add_theme_constant_override("margin_bottom", INNER_PAD - 2)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	block.add_child(margin)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(body)
	return {"panel": block, "body": body}


func _inner_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.07, 0.05, 0.72)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.45, 0.38, 0.22, 0.7)
	sb.set_corner_radius_all(6)
	return sb


func _add_subheading(vbox: VBoxContainer, text: String) -> void:
	var wrap := MarginContainer.new()
	wrap.add_theme_constant_override("margin_top", 4)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lbl := Label.new()
	lbl.text = text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_body(lbl, UiTypography.SIZE_BODY_SMALL, COLOR_GOLD)
	wrap.add_child(lbl)
	vbox.add_child(wrap)


func _add_caption(vbox: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_caption(lbl)
	vbox.add_child(lbl)


func _fmt_or_dash(value: int) -> String:
	if value <= 0:
		return "—"
	return _CommanderLifetime._format_int(value)


func _on_back_pressed() -> void:
	SceneRouter.change_scene(HOME_SCENE)
