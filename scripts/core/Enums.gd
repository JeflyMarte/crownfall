class_name Enums
extends RefCounted

enum Rarity {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY,
}

enum ItemType {
	WEAPON,
	ARMOR,
	ACCESSORY,
}

enum WeaponType {
	GREATSWORD,
	SPEAR,
	DUAL_BLADES,
	BOW,
	STAFF,
}

enum RoomType {
	START,
	COMBAT,
	EVENT,
	TREASURE,
	MID_BOSS,
	BOSS,
	EXIT,
}

enum ExplorationPolicy {
	EXPLORE,
	COMBAT_FIRST,
	COLLECT,
	RETREAT,
}

enum TargetPriority {
	NEAREST,
	BOSS_FIRST,
}
