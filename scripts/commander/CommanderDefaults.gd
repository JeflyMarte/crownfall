class_name CommanderDefaults
extends RefCounted

## 指揮官データのデフォルト値（循環参照回避 / P3-CMD-001）。

const DEFAULT_NAME: String = "無名の隊長"


static func default_lifetime_dict() -> Dictionary:
	return {
		"runs_started": 0,
		"runs_cleared": 0,
		"runs_retired": 0,
		"runs_wiped": 0,
		"damage_max_hit": 0,
		"damage_max_hit_member_id": "",
		"damage_max_hit_skill_name": "",
		"damage_max_hit_context": "",
		"damage_max_run_total": 0,
		"heal_max_run_total": 0,
		"mvp_counts": {},
		"deployment_counts": {},
	}


static func default_commander_dict() -> Dictionary:
	return {
		"name": DEFAULT_NAME,
		"equipped_title": "",
		"titles_unlocked": [],
		"lifetime": default_lifetime_dict(),
		"recent_highlights": [],
		"gift_box": [],
		## 調査許可コード使用済み（正規化キー配列 / P3-CODE-REDEEM-001）。
		"redeemed_codes": [],
		## 拠点ポップアップ表示済みの調査許可等級（P3-CMD-RANKUP-001）。
		"acknowledged_rank": "D",
	}
