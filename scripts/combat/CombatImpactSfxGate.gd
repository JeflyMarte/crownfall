class_name CombatImpactSfxGate
extends RefCounted

## 戦闘ヒット／クリ／回復フィードバック SE の再生可否。
## CT 開始前（入場遅延・ボス／エリート導入）や戦闘外では鳴らさない。
## 前戦闘の遅延ヒットが次フロアに食い込む幽霊 SE 防止の SSOT。


static func allow(
	impact_sfx_enabled: bool,
	is_in_combat: bool,
	boss_intro_active: bool = false,
	elite_intro_active: bool = false
) -> bool:
	return (
		impact_sfx_enabled
		and is_in_combat
		and not boss_intro_active
		and not elite_intro_active
	)
