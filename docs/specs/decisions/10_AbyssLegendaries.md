# 深層限定レジェンド5（P3-DG-ABYSS-LEG-001）

**Status:** SSOT（Decision 承認済）  
**Approved:** 2026-07-25  
**Parent:** `09_BiomeAbyss.md`（P3-DG-ABYSS-001）  
**Impl:** P3-DG-ABYSS-001-C 完了（数値・固有パッシブ確定）

## 方針（案C）

- **武器5本**（防具／装飾は本 Decision 外）
- 固有効果を **攻撃特化3／生存特化2** に振り分ける
- 既存ボス由来★3（シルヴァリア／ネレイダス／エルディオン等）と **名称を被らせない**
- rarity = Legendary（3）。Mythic 枠には入れない
- 深層ドロップ専用（通常DG・鍛冶通常産出の対象外）。放浪★3プールからも除外

## 確定5本

| Biome | id | 表示名 | `weapon_type` | 役割 | `fixed_passive_id` | 固有効果（Impl 数値） |
|---|---|---|---|---|---|---|
| モーンゲート | `abyss_veinblade` | **虚脈の大剣** | greatsword | **攻撃** | `eq_abyss_veinblade` | 欠損HP比で与ダメ最大+40%。撃破時 AoE（与ダメ40%） |
| ウィスパーウッド | `abyss_rootfang` | **根葬の双刃** | dual_blades | **攻撃** | `eq_abyss_rootfang` | 同一敵連続ヒット +8%/最大5。対象変更でリセット |
| ミストフェン | `abyss_mirestaff` | **澱みの封杖** | staff | **生存** | `eq_abyss_mirestaff` | 被弾時 guard（被ダメ半減）CD8秒 |
| ブラックショア | `abyss_netherbow` | **虚潮の長弓** | bow | **攻撃** | `eq_abyss_netherbow` | 潮汐印4で爆発（ヒット150%追撃） |
| フロストリッジ | `abyss_riftclaw` | **裂氷の双爪** | dual_blades | **生存** | `eq_abyss_riftclaw` | 被弾またはHP40%未満で氷殻（被ダメ×0.65・4秒）＋反撃 CD6秒 |

## 職カバー

| 職 | 装備可能な深層武器 |
|---|---|
| swordsman / vanguard | 虚脈の大剣／根葬の双刃／裂氷の双爪 |
| ranger | 虚潮の長弓 |
| alchemist | 澱みの封杖 |
| beast_tamer | 虚潮の長弓／澱みの封杖 |

## 付与

- **99F初回**: `AbyssMilestoneRewards` → `AbyssLegendaryWeapons.grant_for_abyss`
- 低確率ドロップ＋ソフト天井: **未実装**（後続 Task）

## SSOT 実装

- `resources/weapons/abyss_*.tres`
- `CombatPassives` `eq_abyss_*`
- `scripts/combat/AbyssWeaponEffects.gd`
- `scripts/dungeon/AbyssLegendaryWeapons.gd`

## 非要件

- Mythic 昇格
- 防具／装飾の深層限定（必要なら別 Decision）
- セットボーナス（5本同時）
