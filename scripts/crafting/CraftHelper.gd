class_name CraftHelper
extends RefCounted

## unlock_condition 形式:
## - 空: 常時解放
## - "stage_cleared:<stage_id>": 当該ステージのクリア（ノーマル相当・legacy cleared）

static func craft_output_exists(craft: Resource) -> bool:
	if craft == null:
		return false
	match craft.output_type:
		"armor":
			return DataRegistry.get_armor_data(craft.output_id) != null
		"accessory":
			return DataRegistry.get_accessory_data(craft.output_id) != null
		"weapon":
			return DataRegistry.get_weapon_data(craft.output_id) != null
		_:
			return false

static func has_enough_materials(required: Dictionary) -> bool:
	for mat_id in required:
		if GameState.get_material_quantity(str(mat_id)) < int(required[mat_id]):
			return false
	return true


static func is_craft_unlocked(craft: Resource) -> bool:
	return craft_lock_reason(craft).is_empty()


static func craft_lock_reason(craft: Resource) -> String:
	if craft == null:
		return "レシピが不正です"
	var cond: String = str(craft.unlock_condition).strip_edges()
	if cond.is_empty():
		return ""
	if cond.begins_with("stage_cleared:"):
		var stage_id: String = cond.trim_prefix("stage_cleared:").strip_edges()
		if stage_id.is_empty():
			return "解放条件が不正です"
		if GameState.is_stage_cleared(stage_id):
			return ""
		var stage: Resource = DataRegistry.get_stage_data(stage_id)
		var stage_name: String = str(stage.display_name) if stage != null and "display_name" in stage else stage_id
		return "%s クリアで解放" % stage_name
	return "未対応の解放条件です"


static func can_craft(craft: Resource, gold: int = -1) -> bool:
	if craft == null:
		return false
	if not is_craft_unlocked(craft):
		return false
	if craft.output_type != "armor" and craft.output_type != "accessory" and craft.output_type != "weapon":
		return false
	if craft.output_id.is_empty() or not craft_output_exists(craft):
		return false
	var available_gold: int = GameState.gold if gold < 0 else gold
	if available_gold < int(craft.gold_cost):
		return false
	return has_enough_materials(craft.required_materials)

static func get_craftable_recipes(gold: int = -1) -> Array:
	var out: Array = []
	for craft in DataRegistry.get_all_craft_data():
		if can_craft(craft, gold):
			out.append(craft)
	out.sort_custom(func(a: Resource, b: Resource) -> bool:
		return str(a.display_name) < str(b.display_name)
	)
	return out
