# 極限任務10種 制約再設計（P3-DG-EXTREME-002）

**Status:** **Implemented**（2026-09-19／**03・08 再設計** 2026-09-20／**03→skill_resist** 2026-09-20）  
**上書き:** Decision `143` の特殊条件・一部 TUNING／EX-06 指令を本 Decision が正とする  
**目的:** 重複制約を解消し、「編成・装備・ビルドを組み替える高難度」へ寄せる

---

## 0. 一言

極限任務の制約は単純な数値強化ではなく、**任務ごとに異なる攻略軸**を持つ。

---

## 1. 確定制約（EX-01〜10）

| # | 任務 | condition id | 制約 |
|---|---|---|---|
| 01 | 王墓封鎖 | `heal_down` | 味方回復効果50%（据置） |
| 02 | 墓守の包囲 | `swarm_pressure` | **通常 COMBAT は常に群れ**＋群れ時+1体（2026-09-20 強化。旧: 出現率+0.35） |
| 03 | 胞子過密域 | `skill_resist` | **スキル攻撃与ダメ大幅減**（×0.40）。通常攻撃・罠・状態異常は据置（旧 `damage_reflect` 廃止） |
| 04 | 狩人の森 | `rear_pressure` | 後衛被ダメ増（**編成位置**・据置） |
| 05 | 瘴気飽和 | `miasma_saturate` | 敵HP上昇＋敵への poison/bleed/ignite 持続延長 |
| 06 | 感染連鎖 | `status_require` | 状態異常なしの敵への与ダメ低下（旧 `status_empower` 廃止） |
| 07 | 沈船強襲 | `ultimate_suppress` | 必殺チャージ35%（据置） |
| 08 | 潮圧包囲 | `shell_pressure` | 敵障壁で被ダメ軽減。貫通／破甲で無視（旧 `non_crit_pressure` 廃止） |
| 09 | 極冠静寂 | `ultimate_disabled` | 必殺不可（据置） |
| 10 | 白夜決戦 | `element_weakness_pressure` | 非弱点属性与ダメ低下（無属性含む。旧二重 `long_battle_ramp` 廃止） |

---

## 2. 攻略軸

| # | 主軸 |
|---|---|
| 01 | 防御・軽減・キル速度（回復依存を下げる） |
| 02 | 範囲・群れ処理 |
| 03 | 通常攻撃・罠・状態異常（スキルダメ火力は不利） |
| 04 | 前衛厚め・編成位置 |
| 05 | DoT・持続火力 |
| 06 | 状態異常付与 |
| 07 | 通常攻撃・ジョブスキル |
| 08 | 貫通・破甲（障壁無視） |
| 09 | 必殺以外の継続戦力 |
| 10 | 属性・弱点対応 |

---

## 3. 追加 TUNING（初期値・将来調整可）

| キー | 初期値 | 用途 |
|---|---:|---|
| `miasma_enemy_hp_mult` | 1.25 | EX-05 敵HP |
| `miasma_dot_duration_mult` | 1.35 | EX-05 DoT持続 |
| `miasma_dot_status_ids` | poison, bleed, ignite | EX-05 対象 |
| `status_require_outgoing_mult` | 0.70 | EX-06 無状態時与ダメ |
| `skill_resist_outgoing_mult` | 0.40 | EX-03 スキル攻撃与ダメ |
| `shell_incoming_mult` | 0.65 | EX-08 障壁被ダメ倍率 |
| `non_weakness_outgoing_mult` | 0.70 | EX-10 非弱点 |

**互換残置（未使用）:** `long_battle_ramp_*`／`non_crit_hit_outgoing_mult`／`swarm_chance_bonus`／`damage_reflect_*`（API スタブは常に無効／0）。

正本は `ExtremeMissionConfig.TUNING`。極端固定はせず、プレイで推奨ビルドが明確に楽になる範囲を目標とする。

---

## 4. 仕様細則

- **EX-03:** ダメージスキルの与ダメのみ ×`skill_resist_outgoing_mult`（`is_skill=true` 経路）。通常攻撃・罠作動・状態付与／DoT は対象外。旧反射は廃止。
- **EX-03/08 適用経路:** EX-08 障壁は主攻撃・スキルに加え、仕掛け／パッシブ追撃／余波／枯翠／虚潮も `DungeonScene._deal_member_damage_to_enemy` 経由。DoT・戦闘スキップ・敵自爆は対象外。
- **EX-05:** 新状態異常は作らない。永久戦闘化しない（HP は控えめ）。
- **EX-06:** 敵に非有益ステータスが1つでもあればペナルティなし。指令 `no_banned_status` は本任務から除去（`time_limit` に置換）— 状態異常攻略と矛盾するため。
- **EX-08:** 障壁は通常攻撃・スキル・DoT に適用。武器／スキルの `pierce`・`vs_armor_break`、または対象の `armor_break`／`armor_break_light` で無視。
- **EX-10:** 弱点リストが空の敵はペナルティなし（攻略不能回避）。UI tip でボス弱点（炎）を明示。
- **廃止:** `status_empower`／`elite_swarm_up`／EX-05 二重 `heal_down`／EX-10 二重 `long_battle_ramp`／EX-03 `long_battle_ramp`／EX-03 `damage_reflect`／EX-08 `non_crit_pressure`。

---

## 5. 実装アンカー

- `scripts/dungeon/ExtremeMissionConfig.gd`
- Combat: `CombatController`（スキル耐性・状態必須）／`DamageCalculator`（障壁・弱点）／`DungeonScene`（スキル・DoT障壁）
- UI: `special_condition` label/desc/tip と Featured
- テスト: `tests/unit/test_extreme_mission.gd`

---

## 6. 関連

- Decision `143`（基盤・役割四分・指令／★・解放）— 制約表は本 Decision が上書き
- Decision `144`（王痕）— 変更なし
