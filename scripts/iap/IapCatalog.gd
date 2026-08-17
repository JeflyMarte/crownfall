class_name IapCatalog
extends RefCounted

## 魔晶石消耗型 IAP 商品表（P3-MONET-IAP-001）。価格は日本円アンカー。
## Connect の Product ID を変えるときは本表と Decision 125 を同時更新する。

const PRODUCT_S: String = "iap.arcanite.s"
const PRODUCT_M: String = "iap.arcanite.m"
const PRODUCT_L: String = "iap.arcanite.l"
const PRODUCT_XL: String = "iap.arcanite.xl"
const PRODUCT_XXL: String = "iap.arcanite.xxl"
const PRODUCT_MAX: String = "iap.arcanite.max"

## { id, tokens, price_jpy, title }
const PRODUCTS: Array[Dictionary] = [
	{"id": PRODUCT_S, "tokens": 80, "price_jpy": 120, "title": "魔晶石 80"},
	{"id": PRODUCT_M, "tokens": 500, "price_jpy": 610, "title": "魔晶石 500"},
	{"id": PRODUCT_L, "tokens": 1100, "price_jpy": 1220, "title": "魔晶石 1,100"},
	{"id": PRODUCT_XL, "tokens": 2400, "price_jpy": 2440, "title": "魔晶石 2,400"},
	{"id": PRODUCT_XXL, "tokens": 5200, "price_jpy": 4900, "title": "魔晶石 5,200"},
	{"id": PRODUCT_MAX, "tokens": 11200, "price_jpy": 9800, "title": "魔晶石 11,200"},
]


static func all_products() -> Array[Dictionary]:
	return PRODUCTS


static func product_ids() -> Array:
	var ids: Array = []
	for raw: Dictionary in PRODUCTS:
		ids.append(str(raw.get("id", "")))
	return ids


static func by_id(product_id: String) -> Dictionary:
	for raw: Dictionary in PRODUCTS:
		if str(raw.get("id", "")) == product_id:
			return raw
	return {}


static func tokens_for(product_id: String) -> int:
	return int(by_id(product_id).get("tokens", 0))


static func price_jpy_for(product_id: String) -> int:
	return int(by_id(product_id).get("price_jpy", 0))


static func title_for(product_id: String) -> String:
	return str(by_id(product_id).get("title", ""))


static func fallback_price_text(product_id: String) -> String:
	var yen: int = price_jpy_for(product_id)
	if yen <= 0:
		return ""
	return "¥%d" % yen
