extends Node

## Phase2-M3 データ参照の正規入口（Autoload）。
## 規約: id に対応する `resources/{category}/{id}.tres` を load する。
## 新規コードは本 Autoload 経由を推奨。既存の inline load() は M3 では一括置換しない。

func get_weapon_data(weapon_id: String) -> Resource:
	return load(Constants.RESOURCE_WEAPONS_PATH + weapon_id + ".tres")

func get_armor_data(armor_id: String) -> Resource:
	return load(Constants.RESOURCE_ARMORS_PATH + armor_id + ".tres")

func get_accessory_data(accessory_id: String) -> Resource:
	return load(Constants.RESOURCE_ACCESSORIES_PATH + accessory_id + ".tres")

func get_enemy_data(enemy_id: String) -> Resource:
	return load(Constants.RESOURCE_ENEMIES_PATH + enemy_id + ".tres")

func get_skill_data(skill_id: String) -> Resource:
	return load(Constants.RESOURCE_SKILLS_PATH + skill_id + ".tres")

func get_dungeon_data(dungeon_id: String) -> Resource:
	return load(Constants.RESOURCE_DUNGEONS_PATH + dungeon_id + ".tres")

func get_material_data(material_id: String) -> Resource:
	return load(Constants.RESOURCE_MATERIALS_PATH + material_id + ".tres")

func get_job_data(job_id: String) -> Resource:
	var path: String = Constants.RESOURCE_JOBS_PATH + job_id + ".tres"
	if not ResourceLoader.exists(path):
		return null
	return load(path)

func get_status_effect(effect_id: String) -> Resource:
	var path: String = Constants.RESOURCE_STATUS_EFFECTS_PATH + effect_id + ".tres"
	if not ResourceLoader.exists(path):
		return null
	return load(path)

func get_affix_data(affix_id: String) -> Resource:
	return load(Constants.RESOURCE_AFFIXES_PATH + affix_id + ".tres")

func get_craft_data(craft_id: String) -> Resource:
	var path: String = Constants.RESOURCE_CRAFTING_PATH + craft_id + ".tres"
	if not ResourceLoader.exists(path):
		return null
	return load(path)

func get_all_craft_data() -> Array:
	var result: Array = []
	var dir := DirAccess.open(Constants.RESOURCE_CRAFTING_PATH)
	if dir == null:
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res: Resource = load(Constants.RESOURCE_CRAFTING_PATH + file_name)
			if res != null:
				result.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()
	return result

func get_recipe_data(recipe_id: String) -> Resource:
	var path: String = Constants.RESOURCE_RECIPES_PATH + recipe_id + ".tres"
	if not ResourceLoader.exists(path):
		return null
	return load(path)

func get_material_shop_items() -> Array:
	var result: Array = []
	var dir := DirAccess.open(Constants.RESOURCE_MATERIAL_SHOP_PATH)
	if dir == null:
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res: Resource = load(Constants.RESOURCE_MATERIAL_SHOP_PATH + file_name)
			if res != null:
				result.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()
	return result

func get_material_price(material_id: String) -> int:
	var path: String = Constants.RESOURCE_MATERIAL_SHOP_PATH + material_id + ".tres"
	if not ResourceLoader.exists(path):
		return -1
	var res: Resource = load(path)
	if res == null:
		return -1
	return res.price

func get_all_enemy_data() -> Array:
	return _load_all_resources(Constants.RESOURCE_ENEMIES_PATH)

func get_all_dungeon_data() -> Array:
	return _load_all_resources(Constants.RESOURCE_DUNGEONS_PATH)

func get_all_material_data() -> Array:
	return _load_all_resources(Constants.RESOURCE_MATERIALS_PATH)

func get_all_weapon_data() -> Array:
	return _load_all_resources(Constants.RESOURCE_WEAPONS_PATH)

func _load_all_resources(dir_path: String) -> Array:
	var result: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res: Resource = load(dir_path + file_name)
			if res != null:
				result.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()
	return result
