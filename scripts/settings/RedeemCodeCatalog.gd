class_name RedeemCodeCatalog
extends RefCounted

## 特典コード固定表（オフライン・P3-UX-REDEEM-001）。
## キーは normalize 後（大文字・空白/ハイフン除去）。


static func normalize(raw: String) -> String:
	var s: String = raw.strip_edges().to_upper()
	s = s.replace(" ", "").replace("　", "")
	s = s.replace("-", "").replace("ー", "").replace("_", "")
	return s


## { code_key: { id, display_name, gold, gacha_token, tickets:{id:qty} } }
static func entries() -> Dictionary:
	return {
		"CROWNFALLBETA": {
			"id": "crownfall_beta",
			"display_name": "βテスター特典",
			"gold": 5000,
			"gacha_token": 30,
			"tickets": {TicketIds.GACHA_FREE: 1},
		},
	}


static func find(raw_code: String) -> Dictionary:
	var key: String = normalize(raw_code)
	if key.is_empty():
		return {}
	var all: Dictionary = entries()
	if not all.has(key):
		return {}
	return (all[key] as Dictionary).duplicate(true)
