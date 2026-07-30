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
		## 累計プレイ時間（秒）。セッション計測は CommanderLifetime が加算する。
		"play_time_sec": 0,
	}


static func default_commander_dict() -> Dictionary:
	return {
		"name": DEFAULT_NAME,
		"equipped_title": "",
		"titles_unlocked": [],
		"lifetime": default_lifetime_dict(),
		"recent_highlights": [],
		"gift_box": [],
		## 拠点ポップアップ表示済みの調査許可等級（P3-CMD-RANKUP-001）。
		"acknowledged_rank": "D",
		## 閾値改定済みセーブ（P3-CMD-RANK-REWARD-001）。新規は true。
		"rank_curve_v2": true,
		## 到達ギフト配布済み等級コード（二重配布防止）。
		"rank_reward_ranks": [],
	}
