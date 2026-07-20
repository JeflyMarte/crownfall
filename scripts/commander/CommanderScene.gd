extends Control

## 隊長台帳（マイページ）— モック寄せの1スクロール構成。既存素材のみ使用。

const _CommanderProfile = preload("res://scripts/commander/CommanderProfile.gd")
const _CommanderTitles = preload("res://scripts/commander/CommanderTitles.gd")
const _CommanderLifetime = preload("res://scripts/commander/CommanderLifetime.gd")
const _CommanderSurveyPoints = preload("res://scripts/commander/CommanderSurveyPoints.gd")
const _CommanderGiftBox = preload("res://scripts/commander/CommanderGiftBox.gd")
const _RedeemCodeSystem = preload("res://scripts/commander/RedeemCodeSystem.gd")
const _CommanderUiTokens = preload("res://scripts/commander/CommanderUiTokens.gd")
const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const BLACKSMITH_SCENE: String = "res://scenes/blacksmith/BlacksmithScene.tscn"
const CODEX_SCENE: String = "res://scenes/codex/CodexScene.tscn"
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

@onready var _label_title: Label = $Header/HeaderRow/LabelTitle
@onready var _btn_back: Button = $Header/HeaderRow/ButtonBack
@onready var _bg_texture: TextureRect = $BgTexture
@onready var _content_host: VBoxContainer = $MainScroll/MainVBox/ContentHost
var _name_edit_dialog: ConfirmationDialog
var _redeem_feedback: AcceptDialog
var _redeem_field: LineEdit


func _ready() -> void:
	_setup_commander_chrome()
	_label_title.text = _CommanderUiTokens.SCREEN_TITLE
	UiTypography.apply_screen_title(_label_title)
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.MYPAGE)
	_btn_back.pressed.connect(_on_back_pressed)
	_content_host.add_theme_constant_override("separation", SECTION_GAP)
	_setup_name_edit_dialog()
	_setup_redeem_feedback()
	_rebuild_page()


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


func _setup_redeem_feedback() -> void:
	_redeem_feedback = AcceptDialog.new()
	_redeem_feedback.title = "調査許可コード"
	_redeem_feedback.ok_button_text = "閉じる"
	add_child(_redeem_feedback)


func _rebuild_page() -> void:
	for child in _content_host.get_children():
		child.queue_free()
	_content_host.add_child(_build_overview_section())
	_content_host.add_child(_build_redeem_section())
	var gift_section: Control = _build_gift_box_section()
	if gift_section != null:
		_content_host.add_child(gift_section)
	_content_host.add_child(_build_assets_section())
	_content_host.add_child(_build_members_section())
	_content_host.add_child(_build_records_section())
	_content_host.add_child(_build_titles_section())


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


# ---- 調査許可コード ----
func _build_redeem_section() -> Control:
	var sec: Dictionary = _begin_section("redeem", "調査許可コード")
	var body: VBoxContainer = sec["body"]
	_add_caption(body, "ギルドから受け取った許可コードを入力すると、配布ボックスへ補給が届きます。")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(row)
	_redeem_field = LineEdit.new()
	_redeem_field.placeholder_text = "コードを入力"
	_redeem_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_redeem_field.custom_minimum_size = Vector2(0, 40)
	_redeem_field.max_length = 32
	row.add_child(_redeem_field)
	var btn := Button.new()
	btn.text = "送信"
	btn.custom_minimum_size = Vector2(96, 40)
	UiTypography.apply_menu_button(btn, false)
	btn.pressed.connect(_on_redeem_pressed)
	row.add_child(btn)
	return sec["panel"]


func _on_redeem_pressed() -> void:
	var raw: String = ""
	if _redeem_field != null:
		raw = _redeem_field.text
	var result: Dictionary = _RedeemCodeSystem.redeem(raw)
	if bool(result.get("ok", false)):
		AudioManager.play_sfx("ui_confirm")
		if _redeem_field != null:
			_redeem_field.text = ""
		SaveManager.save_game()
		_rebuild_page()
		_show_redeem_feedback(
			"配布ボックスへ届きました。\n「%s」\n%s"
			% [str(result.get("title", "")), str(result.get("summary", ""))]
		)
		return
	AudioManager.play_sfx("ui_error")
	var reason: String = str(result.get("reason", ""))
	var msg: String = "コードを確認してください。"
	match reason:
		"empty":
			msg = "コードを入力してください。"
		"invalid":
			msg = "無効なコードです。"
		"used":
			msg = "このコードは既に使用済みです。"
		"enqueue_failed":
			msg = "配布の登録に失敗しました。"
	_show_redeem_feedback(msg)


func _show_redeem_feedback(message: String) -> void:
	if _redeem_feedback == null:
		return
	_redeem_feedback.dialog_text = message
	_redeem_feedback.popup_centered()


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
	col.add_child(MaterialUiTokens.make_icon_cell(material_id, MAT_CELL_PX, true))
	var qty_lbl := Label.new()
	qty_lbl.text = "x%d" % qty
	qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(qty_lbl, COLOR_SUB)
	col.add_child(qty_lbl)
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
	col.tooltip_text = TicketSystem.display_name(ticket_id)
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
	UiTypography.apply_caption(qty_lbl, COLOR_GOLD)
	col.add_child(qty_lbl)
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
		var label: String = {"enemy": "敵", "material": "素材", "weapon": "武器"}.get(key, key)
		codex_lines.append("%s %d/%d（%d%%）" % [
			label,
			int(row.get("discovered", 0)),
			int(row.get("total", 0)),
			int(row.get("percent", 0)),
		])
	grid.add_child(_make_record_block("図鑑進捗", codex_lines))
	var detail_lines: PackedStringArray = []
	if _CommanderProfile.is_rank_at_least(_CommanderProfile.EXTENDED_RECORDS_UNLOCK_RANK):
		detail_lines.append("調査点 %d SP" % _CommanderProfile.survey_points())
		detail_lines.append("発見登録 %d 件" % _CommanderSurveyPoints.discovery_count())
	else:
		detail_lines.append("A級で詳細解放")
	grid.add_child(_make_record_block("詳細", detail_lines))
	return sec["panel"]


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
