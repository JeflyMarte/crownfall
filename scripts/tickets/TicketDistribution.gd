class_name TicketDistribution
extends RefCounted

## チケット配布テーブル（ストップデータ）。
## `Constants.TICKET_DISTRIBUTION_ENABLED=false` の間は付与しない。再有効化用に定義のみ残置。

const SOURCE_DAILY: String = "daily"
const SOURCE_EVENT: String = "event"
const SOURCE_LOGIN: String = "login"

## 各エントリ: { source, ticket_id, amount, note, enabled }
## enabled=false でもデータとして残す（本番配布オフ）。
const GRANT_TABLE: Array[Dictionary] = [
	{
		"source": SOURCE_DAILY,
		"ticket_id": "ticket_gacha_free",
		"amount": 1,
		"note": "日課クリア報酬（停止中）",
		"enabled": false,
	},
	{
		"source": SOURCE_EVENT,
		"ticket_id": "ticket_lb_star3",
		"amount": 1,
		"note": "期間イベント（停止中）",
		"enabled": false,
	},
	{
		"source": SOURCE_LOGIN,
		"ticket_id": "ticket_lb_star4",
		"amount": 1,
		"note": "ログインボーナス想定（停止中）",
		"enabled": false,
	},
]


static func is_distribution_enabled() -> bool:
	return Constants.TICKET_DISTRIBUTION_ENABLED


## ソース別の有効エントリを返す。全体オフ時は常に空。
static func active_grants_for(source: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not is_distribution_enabled():
		return out
	for entry in GRANT_TABLE:
		if not bool(entry.get("enabled", false)):
			continue
		if str(entry.get("source", "")) != source:
			continue
		out.append(entry)
	return out


## 配布が有効なときのみ付与。停止中は false。
static func try_grant_from(source: String) -> bool:
	var grants: Array[Dictionary] = active_grants_for(source)
	if grants.is_empty():
		return false
	for entry in grants:
		TicketInventory.add(str(entry.get("ticket_id", "")), int(entry.get("amount", 0)))
	return true
