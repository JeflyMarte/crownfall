class_name NinaRareAcquireGuide
extends RefCounted

## 初回レリック／レジェンド／ミシック入手時のニーナ祝福＋説明（拠点オーバーレイ）。
## 2回目以降は拠点メニュー吹き出し（HubNinaNavHelper）へ通知。

const KIND_RELIC: String = "relic"
const KIND_LEGENDARY: String = "legendary"
const KIND_MYTHIC: String = "mythic"

const FLAG_RELIC: String = "nina_guide_relic_done"
const FLAG_LEGENDARY: String = "nina_guide_legendary_done"
const FLAG_MYTHIC: String = "nina_guide_mythic_done"

const _FLAG_BY_KIND: Dictionary = {
	KIND_RELIC: FLAG_RELIC,
	KIND_LEGENDARY: FLAG_LEGENDARY,
	KIND_MYTHIC: FLAG_MYTHIC,
}


static func flag_for(kind: String) -> String:
	return str(_FLAG_BY_KIND.get(kind, ""))


static func is_guide_done(kind: String) -> bool:
	var key: String = flag_for(kind)
	if key.is_empty():
		return true
	return bool(GameState.tutorial_flags.get(key, false))


static func mark_guide_done(kind: String) -> void:
	var key: String = flag_for(kind)
	if key.is_empty():
		return
	GameState.tutorial_flags[key] = true


static func has_pending_guide() -> bool:
	return not GameState.pending_nina_rare_guides.is_empty()


static func peek_pending_guide_kind() -> String:
	if GameState.pending_nina_rare_guides.is_empty():
		return ""
	return str(GameState.pending_nina_rare_guides[0])


static func pop_pending_guide_kind() -> String:
	if GameState.pending_nina_rare_guides.is_empty():
		return ""
	return str(GameState.pending_nina_rare_guides.pop_front())


static func guide_lines_for(kind: String) -> Array[String]:
	match kind:
		KIND_RELIC:
			return [
				"祝福です、隊長！初めてのレリックですね！",
				"レリックは、仲間に1つ付けられる特別な加護です。パッシブみたいに、ずっと効きますよ！",
				"付け替えはキャラ画面のレリック枠から。詳細は図鑑の手引きにも残しておきますね！",
			]
		KIND_LEGENDARY:
			return [
				"すごい…初のレジェンド装備です！祝福を！",
				"レジェンドは★の装備。固有効果や、武器なら専用スキルが付くことがあります！",
				"鍛冶屋でさらに伸ばせます。大事に使ってくださいね！",
			]
		KIND_MYTHIC:
			return [
				"……神話装備！記録官として震えます。祝福を！",
				"ミシックはレジェンドの上位。ふつうの抽選にはほとんど出ず、特別な経路でしか手に入りません！",
				"錬成できない貴重品です。大切に、そして誇らしく使ってくださいね！",
			]
		_:
			return ["祝福です！"]


static func on_relic_unlocked(relic_id: String) -> void:
	var rid: String = str(relic_id).strip_edges()
	if rid.is_empty():
		return
	var display: String = _relic_display_name(rid)
	_notify(KIND_RELIC, display)


static func on_equipment_obtained(instance: Resource) -> void:
	if instance == null:
		return
	const _EquipmentEnhancer := preload("res://scripts/equipment/EquipmentEnhancer.gd")
	var rarity: int = _EquipmentEnhancer.item_rarity(instance)
	var display: String = _EquipmentEnhancer.get_display_name(instance)
	if display.is_empty():
		display = "装備"
	if rarity == Enums.Rarity.MYTHIC:
		_notify(KIND_MYTHIC, display)
	elif rarity == Enums.Rarity.LEGENDARY:
		_notify(KIND_LEGENDARY, display)


static func _notify(kind: String, item_display_name: String) -> void:
	if kind.is_empty():
		return
	if not is_guide_done(kind):
		_queue_guide(kind)
		return
	_queue_nav_notice(kind, item_display_name)


static func _queue_guide(kind: String) -> void:
	for raw in GameState.pending_nina_rare_guides:
		if str(raw) == kind:
			return
	GameState.pending_nina_rare_guides.append(kind)


static func _queue_nav_notice(kind: String, item_display_name: String) -> void:
	var name_str: String = item_display_name.strip_edges()
	if name_str.is_empty():
		name_str = "それ"
	var text: String = ""
	match kind:
		KIND_RELIC:
			text = "祝福です！レリック「%s」を入手しましたね！装備画面で付けられますよ！" % name_str
		KIND_LEGENDARY:
			text = "祝福です！レジェンド「%s」を記録しました！大事に使ってくださいね！" % name_str
		KIND_MYTHIC:
			text = "神話「%s」……！祝福を！記録に残します！" % name_str
		_:
			text = "祝福です！「%s」を入手しましたね！" % name_str
	GameState.pending_nina_nav_notices.append(text)


static func consume_nav_notices() -> Array[String]:
	var out: Array[String] = []
	for raw in GameState.pending_nina_nav_notices:
		var text: String = str(raw).strip_edges()
		if not text.is_empty():
			out.append(text)
	GameState.pending_nina_nav_notices.clear()
	return out


static func _relic_display_name(relic_id: String) -> String:
	var def: Dictionary = CombatPassives.get_def(relic_id)
	var name_str: String = str(def.get("display_name", "")).strip_edges()
	if name_str.is_empty():
		return relic_id
	return name_str


## 既存セーブが既に該当レアを持っている場合、初回ガイドを再表示しない。
static func heal_flags_from_progress() -> void:
	if not GameState.owned_relics.is_empty() and not is_guide_done(KIND_RELIC):
		mark_guide_done(KIND_RELIC)
	if _inventory_has_rarity(Enums.Rarity.LEGENDARY) and not is_guide_done(KIND_LEGENDARY):
		mark_guide_done(KIND_LEGENDARY)
	if _inventory_has_rarity(Enums.Rarity.MYTHIC) and not is_guide_done(KIND_MYTHIC):
		mark_guide_done(KIND_MYTHIC)


static func _inventory_has_rarity(rarity: int) -> bool:
	const _EquipmentEnhancer := preload("res://scripts/equipment/EquipmentEnhancer.gd")
	for bag in [GameState.inventory, GameState.armor_inventory, GameState.accessory_inventory]:
		for item in bag:
			if item != null and _EquipmentEnhancer.item_rarity(item) == rarity:
				return true
	return false
