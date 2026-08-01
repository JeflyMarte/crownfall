class_name EquipmentDisplayNames
extends RefCounted

## 装備個体の表示名。MAX到達ランダム数ぶん末尾に ★（武器・防具・装飾共通）。

static func get_instance_name(item: Resource, category: String) -> String:
	if item == null:
		return "—"
	## 武器／防具／装飾の表示名＋MAX ★ は Enhancer に一本化。
	var via_enhancer: String = EquipmentEnhancer.get_display_name(item)
	if not via_enhancer.is_empty():
		return via_enhancer
	return "—"
