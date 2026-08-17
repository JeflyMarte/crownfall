class_name IapLegalText
extends RefCounted

## 設定画面の課金まわり表示（P3-MONET-IAP-001-C）。事業者住所は App Store 販売者情報に委ねる。


static func settings_body() -> String:
	return "\n".join([
		"魔晶石パックの販売は App Store（Apple）経由です。決済・領収書・払戻しは Apple の手続きに従います。",
		"入手した魔晶石は本ゲーム内でのみ使えます。現金や他社サービスへの交換、アプリ側での払戻しは行いません。",
		"召喚の排出割合は召喚画面に表示しています。",
	])
