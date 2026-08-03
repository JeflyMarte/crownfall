extends GutTest

## 図鑑案B — 世界観（WORLD＋LF）／キャラ人物録。


func test_worldview_entries_merge_world_and_fragments() -> void:
	var entries: Array = CatalogHelper.get_worldview_entries()
	assert_gt(entries.size(), 50, "WORLD50＋断片がある")
	var world_n: int = 0
	var frag_n: int = 0
	for e: Dictionary in entries:
		var section: String = str(e.get("section", ""))
		if section == "world":
			world_n += 1
			assert_true(bool(e.get("discovered", false)), "WORLDは常時開示")
			assert_eq(str(e.get("list_prefix", "")), "【解説】")
		elif section == "fragment":
			frag_n += 1
			assert_eq(str(e.get("list_prefix", "")), "【断片】")
	assert_eq(world_n, 50)
	assert_gt(frag_n, 0)


func test_character_entries_include_starters_and_helpers() -> void:
	GameState.seed_all_starters_unlocked()
	GameState.owned_helpers.clear()
	var entries: Array = CatalogHelper.get_character_entries()
	assert_gte(entries.size(), 5, "初期5＋助っ人")
	var by_id: Dictionary = {}
	for e: Dictionary in entries:
		by_id[str(e.get("id", ""))] = e
	assert_true(by_id.has("adventurer_0"), "アルド")
	assert_true(bool(by_id["adventurer_0"].get("discovered", false)), "初期は開示")
	assert_true(str(by_id["adventurer_0"].get("list_label", "")).contains("アルド"))
	var ald_body: String = str(by_id["adventurer_0"].get("description", ""))
	assert_true(ald_body.contains("出身地"), "初期もプロフィール表")
	assert_true(ald_body.contains("生い立ち"), "生い立ち見出し")
	assert_true(ald_body.contains("固有:"), "スターターも固有パッシブ行")
	assert_true(ald_body.contains("王炎の覇気") or ald_body.contains("出血"), "アルド固有")
	assert_eq(int(by_id["adventurer_0"].get("height_cm", 0)), 182)
	var riva_body: String = str(by_id["adventurer_1"].get("description", ""))
	assert_false(riva_body.contains("毒薬"), "リーヴァ人物録は標的核へ追随")
	assert_true(riva_body.contains("標") or riva_body.contains("狙"), "リーヴァは標／狙い")
	assert_true(riva_body.contains("狙印の刻") or riva_body.contains("標的"), "リーヴァ固有行")
	var galen_body: String = str(by_id["adventurer_3"].get("description", ""))
	assert_false(galen_body.contains("反撃の間合い"), "ガレン人物録は聖盾核へ追随")
	assert_true(galen_body.contains("聖盾") or galen_body.contains("注目"), "ガレンは聖盾／注目")
	assert_true(galen_body.contains("聖盾の砦") or galen_body.contains("軽減"), "ガレン固有行")
	## 未所持助っ人は ???。
	var helper_found: bool = false
	for e: Dictionary in entries:
		if str(e.get("kind", "")) != "helper":
			continue
		helper_found = true
		assert_false(bool(e.get("discovered", true)), "未所持は未開示")
		assert_eq(str(e.get("display_name", "")), "???")
	assert_true(helper_found, "助っ人が人物録に並ぶ")


func test_nina_and_pets_in_character_codex() -> void:
	GameState.seed_all_starters_unlocked()
	const _PetSystem := preload("res://scripts/pets/PetSystem.gd")
	_PetSystem.ensure_owned_pets_seeded()
	var by_id: Dictionary = {}
	for e: Dictionary in CatalogHelper.get_character_entries():
		by_id[str(e.get("id", ""))] = e
	assert_true(by_id.has("npc_nina"), "ニーナ")
	assert_true(bool(by_id["npc_nina"].get("discovered", false)), "ニーナは開示")
	assert_eq(str(by_id["npc_nina"].get("list_label", "")), "ニーナ", "一覧は名前のみ")
	assert_true(str(by_id["npc_nina"].get("portrait_path", "")).contains("Nina_Dialogue"), "セリフ用アイコン")
	assert_true(by_id.has("npc_nonoka"), "ノノカ")
	assert_true(bool(by_id["npc_nonoka"].get("discovered", false)), "ノノカは開示")
	assert_eq(str(by_id["npc_nonoka"].get("list_label", "")), "ノノカ")
	assert_true(str(by_id["npc_nonoka"].get("portrait_path", "")).contains("Nonoka"))
	assert_true(str(by_id["npc_nina"].get("description", "")).contains("出身地"))
	assert_true(by_id.has("pet_jack"), "ジャック")
	assert_true(bool(by_id["pet_jack"].get("discovered", false)), "ジャックは貸与済で開示")
	assert_eq(str(by_id["pet_jack"].get("list_label", "")), str(by_id["pet_jack"].get("display_name", "")))
	assert_true(str(by_id["pet_jack"].get("description", "")).contains("体高") or str(by_id["pet_jack"].get("description", "")).contains("随伴"))
	assert_true(by_id.has("pet_ash") and by_id.has("pet_ink"), "色変えペットも枠あり")
	if not _PetSystem.owns_pet("pet_ash"):
		assert_false(bool(by_id["pet_ash"].get("discovered", true)), "未所持アッシュは???")
	_PetSystem.unlock_pet("pet_ash", false)
	by_id.clear()
	for e: Dictionary in CatalogHelper.get_character_entries():
		by_id[str(e.get("id", ""))] = e
	assert_true(bool(by_id["pet_ash"].get("discovered", false)), "解放後は開示")
	assert_true(str(by_id["pet_ash"].get("display_name", "")).contains("アッシュ"))


func test_hub_npcs_and_legends_in_character_codex() -> void:
	const _Profiles := preload("res://scripts/codex/CharacterCodexProfiles.gd")
	var by_id: Dictionary = {}
	for e: Dictionary in CatalogHelper.get_character_entries():
		by_id[str(e.get("id", ""))] = e
	## 実装済み NPC は開示。
	for npc_id: String in ["npc_nina", "npc_nonoka"]:
		assert_true(by_id.has(npc_id), npc_id)
		assert_true(bool(by_id[npc_id].get("discovered", false)), "%s 開示" % npc_id)
		assert_false(str(by_id[npc_id].get("description", "")).is_empty(), "%s 本文" % npc_id)
	## 未実装拠点NPC／伝承は枠のみ（???）。
	for npc_id: String in ["npc_oren", "npc_galo", "npc_selma", "npc_tobias", "npc_mael"]:
		assert_true(by_id.has(npc_id), npc_id)
		assert_false(bool(by_id[npc_id].get("discovered", true)), "%s は未実装で???" % npc_id)
		assert_eq(str(by_id[npc_id].get("list_label", "")), "???")
	assert_eq(_Profiles.LEGEND_KING_ORDER.size(), 9)
	assert_eq(_Profiles.LEGEND_HERO_ORDER.size(), 9)
	for kid: String in _Profiles.LEGEND_KING_ORDER:
		assert_true(by_id.has(kid), kid)
		assert_false(bool(by_id[kid].get("discovered", true)), "%s 伝承未実装" % kid)
	for hid: String in _Profiles.LEGEND_HERO_ORDER:
		assert_true(by_id.has(hid), hid)
		assert_false(bool(by_id[hid].get("discovered", true)), "%s 伝承未実装" % hid)


func test_implemented_character_list_label_is_name_only() -> void:
	GameState.seed_all_starters_unlocked()
	var ald: Dictionary = {}
	for e: Dictionary in CatalogHelper.get_character_entries():
		if str(e.get("id", "")) == "adventurer_0":
			ald = e
			break
	assert_false(ald.is_empty())
	var label: String = str(ald.get("list_label", ""))
	assert_eq(label, "アルド")
	assert_false(label.contains("★"))
	assert_false(label.contains("ソード"))


func test_helper_profiles_filled_when_owned() -> void:
	GameState.owned_helpers["helper_p"] = 1
	var by_id: Dictionary = {}
	for e: Dictionary in CatalogHelper.get_character_entries():
		by_id[str(e.get("id", ""))] = e
	var hodaka: Dictionary = by_id.get("helper_p", {})
	assert_true(bool(hodaka.get("discovered", false)))
	var body: String = str(hodaka.get("description", ""))
	assert_true(body.contains("出身地"))
	assert_true(body.contains("好きなもの"))
	assert_true(body.contains("苦手なもの"))
	assert_true(body.contains("生い立ち"))
	assert_true(body.contains("記録メモ"))
	assert_true(int(hodaka.get("height_cm", 0)) > 0)
	## 全排出助っ人にプロフィール必須欄がある。
	for helper: Resource in DataRegistry.get_all_gacha_helper_data():
		assert_false(str(helper.hometown).is_empty(), "%s hometown" % helper.id)
		assert_gt(int(helper.height_cm), 0, "%s height" % helper.id)
		assert_false(str(helper.likes).is_empty(), "%s likes" % helper.id)
		assert_false(str(helper.dislikes).is_empty(), "%s dislikes" % helper.id)
		assert_false(str(helper.backstory).is_empty(), "%s backstory" % helper.id)
		assert_false(str(helper.record_note).is_empty(), "%s record_note" % helper.id)
