class_name GachaUiHelper
extends RefCounted

const _GachaLimitBreak := preload("res://scripts/gacha/GachaLimitBreak.gd")
const _CharacterStatBonuses := preload("res://scripts/roster/CharacterStatBonuses.gd")
const _ChrIdlePortraitView := preload("res://scripts/ui/ChrIdlePortraitView.gd")

const COLOR_GOLD: Color = Color(0.86, 0.74, 0.45)
const COLOR_SUB: Color = Color(0.72, 0.69, 0.62)
const COLOR_OWNED: Color = Color(0.55, 0.88, 0.5)

const LINEUP_ICON_PX: int = 72
const BANNER_PORTRAIT_MAX: int = 3
const BANNER_PORTRAIT_MIN_W: int = 96
## Featured プレビュー対象の最低★（★4→★3。★2 は出さない / P3-GACHA-FEATURE-IDLE-001）
const FEATURED_MIN_RARITY: int = 3
const FEATURED_IDLE_PX: float = 196.0
const FEATURED_STATS_MIN_W: float = 220.0
## 台座中心向け。実機の短い枠でもキャラ全体が枠内に収まるよう host から算出。
const FEATURED_IDLE_OFFSET_X: float = 0.0
## 【キャラ上下の主操作】大きいほど上へ。MIN/MAX は自動計算の下限／上限なので触っても効きにくい。
const FEATURED_IDLE_LIFT_Y: float = 130.0
const FEATURED_PEDESTAL_FOOT_PAD_MIN: float = 16.0
const FEATURED_PEDESTAL_FOOT_PAD_MAX: float = 98.0
## 後方互換（オーラ初期値など）。実レイアウトは featured_foot_pad() を使う。
const FEATURED_PEDESTAL_FOOT_PAD: float = 48.0


static func featured_idle_px(host_height: float) -> float:
	var h: float = maxf(host_height, 1.0)
	return clampf(minf(FEATURED_IDLE_PX, h * 0.55), 96.0, FEATURED_IDLE_PX)


static func featured_foot_pad(host_height: float) -> float:
	var h: float = maxf(host_height, 1.0)
	var idle_px: float = featured_idle_px(h)
	## 必ず idle 全体が host 内に入る（はみ出しで clip 消滅させない）。
	var max_foot: float = maxf(FEATURED_PEDESTAL_FOOT_PAD_MIN, h - idle_px - 4.0)
	## 枠が高いと preferred が MAX に張り付く → MIN を変えても見た目は変わらない。
	var preferred: float = clampf(h * 0.14, FEATURED_PEDESTAL_FOOT_PAD_MIN, FEATURED_PEDESTAL_FOOT_PAD_MAX)
	return minf(preferred, max_foot)


static func _featured_bottom_offset(foot: float) -> float:
	return -(foot + FEATURED_IDLE_LIFT_Y)


## Featured idle / ビームの足元オフセットを host 高さに合わせて再配置。
static func relayout_featured_shell(shell: Dictionary, host: Control) -> void:
	if shell.is_empty() or host == null:
		return
	var h: float = maxf(host.size.y, 1.0)
	var idle_px: float = featured_idle_px(h)
	var foot: float = featured_foot_pad(h)
	var bottom: float = _featured_bottom_offset(foot)
	var idle: Control = shell.get("idle") as Control
	if idle != null:
		if idle.has_method("set_portrait_size"):
			idle.call("set_portrait_size", idle_px)
		idle.offset_left = -idle_px * 0.5 + FEATURED_IDLE_OFFSET_X
		idle.offset_right = idle_px * 0.5 + FEATURED_IDLE_OFFSET_X
		idle.offset_top = -idle_px + bottom
		idle.offset_bottom = bottom
		idle.visible = true
		idle.modulate = Color.WHITE
		idle.z_index = 5
	var fade: Control = shell.get("fade") as Control
	if fade == null:
		return
	var stage: Control = fade.get_node_or_null("FeaturedStage") as Control
	if stage == null:
		return
	var beam: Control = stage.get_node_or_null("FeaturedBeam") as Control
	if beam != null:
		var beam_h: float = idle_px + foot + FEATURED_IDLE_LIFT_Y + 80.0
		beam.offset_top = -beam_h
		beam.offset_bottom = bottom + 36.0
	var beam_soft: Control = stage.get_node_or_null("FeaturedBeamSoft") as Control
	if beam_soft != null:
		var soft_h: float = idle_px + foot + FEATURED_IDLE_LIFT_Y + 80.0
		beam_soft.offset_top = -soft_h * 0.92
		beam_soft.offset_bottom = bottom + 48.0


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


## VBox 上のタイトル枠（黒余白の原因）を外し、キャッチコピー Label を隠す。
## タイトルロゴ自体は build_featured_shell 内で背景の上にオーバーレイする。
static func setup_banner_header(banner_vbox: VBoxContainer, catchcopy_label: Label) -> void:
	if banner_vbox != null:
		for node_name in ["BannerTitle", "BannerCatchcopyArt"]:
			var stale: Node = banner_vbox.get_node_or_null(node_name)
			if stale != null:
				stale.queue_free()
	if catchcopy_label != null:
		catchcopy_label.visible = false


static func _add_banner_title_overlay(parent: Control) -> void:
	var rect := TextureRect.new()
	rect.name = "BannerTitle"
	rect.texture = GachaUiTokens.load_tex(GachaUiTokens.BANNER_TITLE)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = 8
	rect.set_anchors_preset(Control.PRESET_TOP_WIDE)
	rect.offset_left = 8.0
	rect.offset_right = -8.0
	rect.offset_top = 4.0
	rect.offset_bottom = float(GachaUiTokens.BANNER_TITLE_HEIGHT)
	rect.visible = rect.texture != null
	parent.add_child(rect)
	_add_banner_catchcopy_overlay(parent)


static func _add_banner_catchcopy_overlay(parent: Control) -> void:
	var rect := TextureRect.new()
	rect.name = "BannerCatchcopyArt"
	rect.texture = GachaUiTokens.load_tex(GachaUiTokens.BANNER_CATCHCOPY_ART)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = 8
	rect.set_anchors_preset(Control.PRESET_TOP_WIDE)
	rect.offset_left = 24.0
	rect.offset_right = -24.0
	var top: float = float(GachaUiTokens.BANNER_TITLE_HEIGHT) + 2.0
	rect.offset_top = top
	rect.offset_bottom = top + float(GachaUiTokens.BANNER_CATCHCOPY_HEIGHT)
	rect.visible = rect.texture != null
	parent.add_child(rect)


## モックの紫光柱＋上昇塵。キャラ背後のみ（画面全体の紫モヤではない）。
static func _add_featured_purple_aura(stage: Control, foot_pad: float = FEATURED_PEDESTAL_FOOT_PAD) -> void:
	if stage == null:
		return
	var beam_tex: Texture2D = GachaUiTokens.load_tex(GachaUiTokens.FEATURED_BEAM)
	if beam_tex == null:
		return
	var foot: float = foot_pad

	var beam := TextureRect.new()
	beam.name = "FeaturedBeam"
	beam.texture = beam_tex
	beam.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	beam.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	beam.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	beam.grow_horizontal = Control.GROW_DIRECTION_BOTH
	beam.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var beam_w: float = 220.0
	var beam_h: float = FEATURED_IDLE_PX + foot + 80.0
	beam.offset_left = -beam_w * 0.5 + FEATURED_IDLE_OFFSET_X
	beam.offset_right = beam_w * 0.5 + FEATURED_IDLE_OFFSET_X
	beam.offset_top = -beam_h
	beam.offset_bottom = -foot + 36.0
	beam.modulate = Color(1.15, 1.0, 1.25, 0.52)
	stage.add_child(beam)

	var beam_soft := TextureRect.new()
	beam_soft.name = "FeaturedBeamSoft"
	beam_soft.texture = beam_tex
	beam_soft.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	beam_soft.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	beam_soft.mouse_filter = Control.MOUSE_FILTER_IGNORE
	beam_soft.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	beam_soft.grow_horizontal = Control.GROW_DIRECTION_BOTH
	beam_soft.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var soft_w: float = 300.0
	beam_soft.offset_left = -soft_w * 0.5 + FEATURED_IDLE_OFFSET_X
	beam_soft.offset_right = soft_w * 0.5 + FEATURED_IDLE_OFFSET_X
	beam_soft.offset_top = -beam_h * 0.92
	beam_soft.offset_bottom = -foot + 48.0
	beam_soft.modulate = Color(0.85, 0.55, 1.2, 0.28)
	stage.add_child(beam_soft)
	stage.move_child(beam_soft, 0)
	stage.move_child(beam, 1)

	var mote_tex: Texture2D = GachaUiTokens.load_tex(GachaUiTokens.FEATURED_MOTE)
	if mote_tex != null:
		for i in 7:
			var mote := TextureRect.new()
			mote.name = "FeaturedMote_%d" % i
			mote.texture = mote_tex
			mote.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			mote.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			mote.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mote.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
			var mote_px: float = 10.0 + float(i % 3) * 4.0
			var x_off: float = FEATURED_IDLE_OFFSET_X + float((i % 5) - 2) * 22.0
			var y0: float = -foot - 24.0 - float(i) * 10.0
			mote.offset_left = x_off - mote_px * 0.5
			mote.offset_right = x_off + mote_px * 0.5
			mote.offset_top = y0 - mote_px
			mote.offset_bottom = y0
			mote.modulate = Color(1.1, 0.9, 1.3, 0.0)
			stage.add_child(mote)
			stage.move_child(mote, mini(2 + i, stage.get_child_count() - 1))
			_start_mote_rise(mote, y0, mote_px, 1.8 + float(i) * 0.35)

	_start_beam_pulse(beam, 0.48, 0.78, 1.55)
	_start_beam_pulse(beam_soft, 0.22, 0.42, 2.1)


static func _start_beam_pulse(beam: CanvasItem, a_lo: float, a_hi: float, period: float) -> void:
	if beam == null:
		return
	var start := func() -> void:
		if not is_instance_valid(beam) or not beam.is_inside_tree():
			return
		var tw: Tween = beam.create_tween()
		tw.set_loops()
		tw.tween_property(beam, "modulate:a", a_hi, period).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(beam, "modulate:a", a_lo, period).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if beam.is_inside_tree():
		start.call()
	else:
		beam.tree_entered.connect(start, CONNECT_ONE_SHOT)


static func _start_mote_rise(mote: TextureRect, y0: float, mote_px: float, duration: float) -> void:
	if mote == null:
		return
	var start := func() -> void:
		if not is_instance_valid(mote) or not mote.is_inside_tree():
			return
		var rise: float = 110.0 + mote_px * 2.0
		var tw: Tween = mote.create_tween()
		tw.set_loops()
		tw.tween_property(mote, "modulate:a", 0.7, duration * 0.2)
		tw.parallel().tween_property(mote, "offset_top", y0 - rise - mote_px, duration)
		tw.parallel().tween_property(mote, "offset_bottom", y0 - rise, duration)
		tw.tween_property(mote, "modulate:a", 0.0, duration * 0.25)
		tw.tween_callback(func() -> void:
			if not is_instance_valid(mote):
				return
			mote.offset_top = y0 - mote_px
			mote.offset_bottom = y0
			mote.modulate.a = 0.0
		)
	if mote.is_inside_tree():
		start.call()
	else:
		mote.tree_entered.connect(start, CONNECT_ONE_SHOT)


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
## host（チケット上の招待枠）に聖堂キーアートを敷き、台座上にキャラを乗せる。
static func build_featured_shell(host: Control) -> Dictionary:
	var empty: Dictionary = {}
	if host == null:
		return empty
	for child in host.get_children():
		child.queue_free()
	host.mouse_filter = Control.MOUSE_FILTER_STOP
	## clip すると短い枠で idle が消える。バナーは親 Panel 側で十分。
	host.clip_contents = false

	var fade := Control.new()
	fade.name = "FeaturedFade"
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(fade)

	var banner_bg := TextureRect.new()
	banner_bg.name = "BannerBg"
	banner_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	banner_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	banner_bg.texture = GachaUiTokens.load_tex(GachaUiTokens.BANNER_BG)
	fade.add_child(banner_bg)

	## 台座は枠全体の中央。ステージを全面にしてキャラを台座上へ置く（ステは右オーバーレイ）。
	var stage := Control.new()
	stage.name = "FeaturedStage"
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.add_child(stage)

	var host_h: float = maxf(host.size.y, 280.0)
	var foot: float = featured_foot_pad(host_h)
	var idle_px: float = featured_idle_px(host_h)
	_add_featured_purple_aura(stage, foot)

	var idle: Control = _ChrIdlePortraitView.new()
	idle.name = "FeaturedIdle"
	if idle.has_method("set_portrait_size"):
		idle.call("set_portrait_size", idle_px)
	idle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	idle.z_index = 5
	idle.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	idle.grow_horizontal = Control.GROW_DIRECTION_BOTH
	idle.grow_vertical = Control.GROW_DIRECTION_BEGIN
	idle.offset_left = -idle_px * 0.5 + FEATURED_IDLE_OFFSET_X
	idle.offset_right = idle_px * 0.5 + FEATURED_IDLE_OFFSET_X
	idle.offset_top = -idle_px - foot
	idle.offset_bottom = -foot
	stage.add_child(idle)

	var stats_wrap := PanelContainer.new()
	stats_wrap.name = "StatsWrap"
	## 中央 anchor＋offset 0 は iOS 初回レイアウトで高さ 0 になり説明が消える。右上固定。
	stats_wrap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	stats_wrap.offset_left = -(FEATURED_STATS_MIN_W + 28.0)
	stats_wrap.offset_right = -6.0
	stats_wrap.offset_top = 208.0
	stats_wrap.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	stats_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stats_sb := StyleBoxFlat.new()
	stats_sb.bg_color = Color(0.04, 0.03, 0.05, 0.78)
	stats_sb.set_corner_radius_all(8)
	stats_sb.set_content_margin_all(10.0)
	stats_sb.set_border_width_all(1)
	stats_sb.border_color = Color(0.72, 0.62, 0.38, 0.75)
	stats_wrap.add_theme_stylebox_override("panel", stats_sb)
	fade.add_child(stats_wrap)

	var stats := VBoxContainer.new()
	stats.name = "StatsCol"
	stats.custom_minimum_size = Vector2(FEATURED_STATS_MIN_W, 0)
	stats.add_theme_constant_override("separation", 5)
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_wrap.add_child(stats)

	## モック寄せ: 名前・職・ステは Shippori Mincho（金セリフ見出し）。
	var name_lbl := Label.new()
	name_lbl.name = "LabelName"
	name_lbl.clip_text = false
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	UiTypography.apply_display(name_lbl, UiTypography.SIZE_DISPLAY, UiTypography.COLOR_GOLD)
	stats.add_child(name_lbl)

	var stars_lbl := Label.new()
	stars_lbl.name = "LabelStars"
	UiTypography.apply_display(stars_lbl, UiTypography.SIZE_CAPTION, COLOR_GOLD)
	stats.add_child(stars_lbl)

	var job_lbl := Label.new()
	job_lbl.name = "LabelJob"
	job_lbl.clip_text = false
	job_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	job_lbl.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	UiTypography.apply_display(job_lbl, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	stats.add_child(job_lbl)

	var hp_lbl := Label.new()
	hp_lbl.name = "LabelHp"
	hp_lbl.clip_text = false
	UiTypography.apply_display(hp_lbl, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	stats.add_child(hp_lbl)

	var atk_lbl := Label.new()
	atk_lbl.name = "LabelAtk"
	atk_lbl.clip_text = false
	UiTypography.apply_display(atk_lbl, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	stats.add_child(atk_lbl)

	var def_lbl := Label.new()
	def_lbl.name = "LabelDef"
	def_lbl.clip_text = false
	UiTypography.apply_display(def_lbl, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	stats.add_child(def_lbl)

	var unique_lbl := Label.new()
	unique_lbl.name = "LabelUnique"
	unique_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	unique_lbl.max_lines_visible = 4
	unique_lbl.clip_text = false
	unique_lbl.custom_minimum_size = Vector2(FEATURED_STATS_MIN_W, 0)
	UiTypography.apply_display(unique_lbl, UiTypography.SIZE_CAPTION, COLOR_SUB)
	stats.add_child(unique_lbl)

	_add_banner_title_overlay(fade)

	return {
		"fade": fade,
		"stage": stage,
		"stats_wrap": stats_wrap,
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
		idle.visible = true
		idle.modulate = Color.WHITE
		## Idle が空なら立ち絵／歩行1コマへフォールバック。
		if idle.has_method("has_idle_texture") and not bool(idle.call("has_idle_texture")):
			var fallback: Texture2D = null
			if helper.has_method("get_portrait_texture"):
				fallback = helper.call("get_portrait_texture") as Texture2D
			if fallback == null:
				var walk_path: String = "res://assets/characters/%s/walk_0.png" % str(helper.id)
				if ResourceLoader.exists(walk_path):
					fallback = load(walk_path) as Texture2D
			if fallback != null and idle.has_method("set_static_texture"):
				idle.call("set_static_texture", fallback)
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
	var stats_wrap: Control = shell.get("stats_wrap") as Control
	if stats_wrap != null:
		stats_wrap.visible = true
		stats_wrap.queue_sort()

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
	icon_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	## カルーセル用の下余白付きセルは使わず、枠にアイコンが収まるようタイトな枠にする。
	var icon_sb: StyleBox = GachaUiTokens.texture_stylebox(
		GachaUiTokens.LINEUP_CELL, Vector4i(8, 8, 8, 8)
	)
	if icon_sb is StyleBoxTexture:
		(icon_sb as StyleBoxTexture).set_content_margin_all(4.0)
	icon_box.add_theme_stylebox_override("panel", icon_sb)
	var icon_tex: Texture2D = helper.get_portrait_texture()
	if icon_tex != null:
		var icon := TextureRect.new()
		icon.texture = icon_tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		icon.custom_minimum_size = Vector2(LINEUP_ICON_PX - 12, LINEUP_ICON_PX - 12)
		icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
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
