class_name RedeemCodeCatalog
extends RefCounted

## オフライン調査許可コード辞書（P3-CODE-REDEEM-001）。
## キーは `RedeemCodeSystem.normalize()` 後（英数のみ・大文字）。

## code → gift payload（CommanderGiftBox.enqueue 互換＋ helpers / tickets）
const CODES: Dictionary = {
	## β参加御礼 — 通貨＋招待無料券
	"CROWNBETA": {
		"title": "調査補給・β参加",
		"message": "モーンゲート調査への協力に感謝する。補給を配布ボックスへ送った。",
		"gold": 3000,
		"gacha_token": 10,
		"tickets": {"ticket_gacha_free": 3},
	},
	## 助っ人・ヴァルデン
	"CROWNALLY": {
		"title": "助っ人派遣・ヴァルデン",
		"message": "ギルドより重装の助っ人を派遣する。配布ボックスで受取れ。",
		"helpers": ["helper_a"],
	},
	## 助っ人・セリン
	"CROWNSEER": {
		"title": "助っ人派遣・セリン",
		"message": "偵察向きの助っ人を派遣する。",
		"helpers": ["helper_c"],
	},
	## 小補給
	"SUPPLY01": {
		"title": "緊急補給",
		"message": "前線向けの小規模補給。",
		"gold": 1000,
		"gacha_token": 3,
		"tickets": {"ticket_gacha_free": 1},
		"materials": {"base_ore": 5},
	},
}


static func has_code(normalized: String) -> bool:
	return CODES.has(normalized)


static func payload_for(normalized: String) -> Dictionary:
	if not CODES.has(normalized):
		return {}
	var raw: Variant = CODES[normalized]
	if raw is Dictionary:
		return (raw as Dictionary).duplicate(true)
	return {}
