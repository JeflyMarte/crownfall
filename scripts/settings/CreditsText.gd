class_name CreditsText
extends RefCounted

## 設定「クレジット」表示用。SE は ATTRIBUTION.md、BGM はオーナー制作（Suno 等）。


static func settings_body() -> String:
	return "\n".join([
		"【効果音】",
		"Kenney.nl（Interface / RPG / Impact / Digital / Music Jingles）— CC0",
		"TomMusic Free Fantasy 200 SFX Pack — 商用利用可",
		"",
		"【BGM】",
		"Crownfall オリジナル（制作協力: Suno AI）",
		"",
		"【フォント】",
		"Noto Sans JP / Shippori Mincho B1 / Dela Gothic One（OFL）",
		"",
		"詳細な SE 対応表はリポジトリ内 assets/audio/sfx/ATTRIBUTION.md を参照。",
	])
