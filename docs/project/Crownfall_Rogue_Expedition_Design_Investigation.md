# Crownfall 遺跡遠征 — 設計調査・草案

**Document type:** Design investigation（実装前調査）  
**Date:** 2026-09-02  
**SSOT references（読取のみ・本書は ProjectDocs を変更しない）:**  
- `docs/specs/decisions/137_RoguelikeExpedition.md`（草案 v2）  
- `docs/specs/core/01_Design_Principles.md`  
- `docs/specs/game/05_ダンジョン.md`  

**Scope:** 調査・設計草案のみ。**コード変更なし／ProjectDocs 変更なし。**

---

## 1. Executive Summary

**遺跡遠征**（内部候補 `rogue_expedition`）は、Crownfall の既存 **DungeonScene + DungeonController + CombatController** スタック上に、**IntroTutorialConfig 型の専用 Config + ラン専用 RunState** を足す形が最も再利用率が高い。

| 領域 | 結論 |
|---|---|
| ダンジョン進行 | **高再利用** — 50F ランダム列生成・部屋遷移・自動戦闘・Result 遷移は既存流用可 |
| route_type | **`rogue` 未実装** — `DungeonData.route_type` に文字列追加 + `Constants.is_playable_dungeon_route` 拡張が必要 |
| 装備 | **Instance/Resolver パイプライン再利用** — ただし **恒久 inventory とは分離必須** |
| タグ／シナジー | **`WeaponData.tags` + `CombatSynergy` + `CombatCombos` 拡張** が最小変更 |
| 武器進化 | **既存進化ツリーなし** — `rogue_*` id の段階別マスタ＋RunState 上の `evolution_tier` が安全 |
| 遠征特性 | **`CombatPassives` 相当のラン専用 Modifier 辞書** — 恒久パッシブと分離 |
| 5F 装備ステーション | **FloorChoiceOverlay の停止 UX を参考** — 装備本体は EquipmentScene ロジックの data-source 注入 |
| F30 CP | **ラン途中セーブは既存に無い** — SaveManager 新キー + シリアライズ helper 流用が必要 |
| F50 持ち帰り | **`AbyssLegendaryWeapons.grant_weapon()` パターン** — 選択 UI のみ新規 |
| ボス適応 | **`CombatBossPhases` + `CombatEnemyTraits` 拡張** — ラン seed から Modifier 抽選 |
| ビンゴ | **`hub_survey_achievements_claimed` 型の Dictionary** — キャラ id × 25 bool |

**MVP 推奨:** RunState + 5F 装備（専売プール・高 L/M）+ F30/F50 ボス + F50 持ち帰り1 + 簡易タグシナジー。**武器進化・特殊ステーション・ボス適応・ビンゴ完全版は Phase 2。**

**推測と既存の区別:** 本文で **【既存】** / **【草案】** / **【Unknown】** を明示。

---

## 2. Existing Systems Reusable

### 2.1 ダンジョン進行【既存】

| コンポーネント | パス | 再利用内容 |
|---|---|---|
| 部屋列生成 | `scripts/dungeon/DungeonController.gd` — `_generate_random_sequence()` | F1  opener COMBAT、重み付き中間部屋、BOSS 末尾。50F + F30/F50 強制 BOSS 差し込みは **生成後の patch** で足せる |
| ラン進行 | `advance_room()`, `current_room_index`, `room_sequence` | 深層と違い **50F で `is_completed=true`**（abyss の `_extend_abyss_chunk` は使わない） |
| シーン配線 | `scripts/dungeon/DungeonScene.gd` | 入室・戦闘・暗転・結果遷移。Tutorial と同様 **floor 境界で `is_run()` 分岐** |
| 敵 Lv | `DungeonController.get_enemy_level()` | apex/abyss 分岐あり。**rogue 用 floor→Lv カーブ分岐を追加**する余地 |
| Result | `ResultScene` + `GameState.last_run_*` | 到達 F・ドロップ・ outcome スナップショット |

**参照:** abyss = 無限延長・finish 不可。rogue = **固定 50F・finish 可** — abyss の「逆パターン」。

### 2.2 route_type / ダンジョン種別【既存】

```gdscript
# scripts/data/DungeonData.gd
@export var route_type: String = "main"  # main|side|apex|event|abyss（コメント）
```

| route_type | プレイ制御 | 備考 |
|---|---|---|
| main | 常時 | SUB_STAGES_PLAYABLE で章分割 |
| event | EVENT_DUNGEONS_PLAYABLE | 日次回数・スケジュール |
| abyss | ABYSS_DUNGEONS_PLAYABLE | 無限・マイルストーン |
| side/apex | SUB_DUNGEONS_PLAYABLE（現 false） | apex パイロット例外あり |
| tutorial | **playable=false** | IntroTutorialConfig |

**【既存】** `Constants.is_playable_dungeon_route()` — `rogue` は **未登録**（tutorial と同様ブロックされる）。

**【既存】** 解鎖: `GameState.is_dungeon_unlocked()` — main 直列 / abyss=親 biome クリア / event=unlock_after。

### 2.3 キャラ・装備・レアリティ・スキル【既存】

| 層 | 型 | 永続 |
|---|---|---|
| キャラ | `Adventurer` — Lv, stats, `equipped_*` Resource 参照 | roster |
| 武器マスタ | `WeaponData` — rarity, tags, fixed_skill_id, fixed_passive_id, set_id | .tres |
| インスタンス | `WeaponInstance` / `ArmorInstance` / `AccessoryInstance` | inventory 配列 |
| ロール | `JobStatCalculator`, `SkillData`, `CombatPassives` | — |
| レア | `Enums.Rarity` COMMON→SET | — |

装備付与パイプライン【既存】:
`DungeonController._spawn_weapon()` → `WeaponStatResolver.apply_drop_stats()` → `GameState.try_add_*_instance()`

隔離プール先例【既存】:
- `AbyssLegendaryWeapons.grant_weapon()` — abyss id のみ、恒久 inventory へ
- `EventExclusiveRewards` — 降臨 SET、他経路ガード
- `MythicLoot` — 通常レア抽選外の 1% 別枠

### 2.4 UI / 停止オーバーレイ【既存】

| 参照 | 用途 |
|---|---|
| `FloorChoiceOverlay.gd` | 戦闘後停止・三択・自動確定タイマー — **遠征ピック／特殊ステーションの UX 骨格** |
| `EquipmentScene.gd` + `EquipmentController.gd` | 装備比較・着脱 — **inventory 注入で再利用** |
| `IntroTutorialConfig.gd` | 専用 Config + `is_run()` ガード + 固定 sequence 上書き |

### 2.5 タグ・シナジー【既存】

| システム | パス | 内容 |
|---|---|---|
| `CombatTags` | `scripts/combat/CombatTags.gd` | slash/pierce/blunt, fire/ice/thunder/… |
| `WeaponData.tags` | 武器マスタ | コンボ起爆・シナジー集計 |
| `CombatSynergy` | 2人/3人同一属性 +10/+15%、物理タグ +5/+8%、ロールボーナス | **パーティ全員の装備武器 tags を見る** |
| `CombatCombos` | `require_tag` で状態コンボ | 例: bleed←slash, shock←lightning |
| `EquipmentSetBonuses` | 3 部位 set_id | 降臨 SET 加護 — **rogue 専用 set_id を新設可能** |
| `BuildTagHelper` | affix 由来 UI タグ | 表示専用、戦闘非連動 |

**【既存】** 「タグ3個=攻撃+20%」のような単純閾値シナジーは **未実装**。遠征で追加するなら **新規 `RoguelikeTagSynergy.gd`** が本編への影響が最小。

### 2.6 ボス Modifier【既存】

| システム | 内容 |
|---|---|
| `CombatBossPhases` | HP 閾値フェーズ、skill  weight、attack_mult |
| `CombatEnemyTraits` | 雑魚/elite 向け thorns, lifesteal 等 |
| `enemy_codex.phases_seen` | フェーズ発見の永続記録 |

---

## 3. Existing Systems Requiring Extension

| システム | 必要な拡張 | 理由 |
|---|---|---|
| `Constants.gd` | `ROGUE_EXPEDITION_PLAYABLE`, route `"rogue"` | 選択 UI 表示 |
| `GameState.is_dungeon_unlocked()` | main5 N 全クリア条件 | Decision 137 |
| `DungeonController` | `_is_rogue_run()`, 戦闘装備ドロップ抑制, floor→Lv | 遠征専用ルール |
| `DungeonScene` | F5/10/… 境界フック、オーバーレイ待ち | 自動進行停止 |
| `GameState` / 新 RunState | ラン inventory・ラン party・ラン Lv | 恒久と分離 |
| `SaveManager` | `rogue_checkpoint` キー（任意） | F30 CP【Unknown: GO 確定】 |
| `DataRegistry` / pool | `rogue_*` .tres 群 + pool クラス | 専売 |
| `CombatPassives` or parallel | `rogue_trait_*` ラン Modifier | 遠征特性 |
| `ResultScene` | 持ち帰り選択分岐 | F50 |
| `DungeonSelectScene` | 新タブ or イベント横入口 | 導線 |

**変更しない（触らない）:** 本編 roster Lv、恒久 inventory 中身（ラン中）、深層無限ロジック、転生/許可点。

---

## 4. Proposed Run-State Architecture

### 4.1 設計原則【草案】

- **単一 RunState オブジェクト**（`RoguelikeRunState.gd` RefCounted または GameState 内 Dictionary）
- ラン開始時に **hub 状態から fork**、ラン終了時に **破棄**（CP 時のみ部分 serialize）
- `DungeonController` は従来どおり volatile；**装備・party の正は RunState**

### 4.2 提案フィールド【草案】

```text
RoguelikeRunState
├── active: bool
├── seed: int
├── leader_character_id: String
├── floor_index: int                    # 1..50
├── checkpoint_floor: int               # 0 or 30
├── party_members: Array[Adventurer]    # ラン Lv/HP（clone or snapshot）
├── inventories
│   ├── weapons: Array[WeaponInstance]
│   ├── armors: Array[ArmorInstance]
│   └── accessories: Array[AccessoryInstance]
├── equipped_by_member_id: Dictionary   # member_id → {w,a,acc instance_id}
├── allies_added: Array[String]         # ラン助っ人 ids
├── traits: Array[String]               # 遠征特性 ids（F10/20/40）
├── weapon_evolution: Dictionary        # instance_id or base_id → tier int
├── station_history: Array              # 取得ログ・ビンゴ用
├── pity: { legendary_stations: int, mythic_runs: int }
├── boss_modifiers: Array[String]       # F30/F50 用（ラン開始 or ボス前抽選）
└── pick_flags: Dictionary              # 回復回数等
```

### 4.3 戦闘への接続【草案】

1. ラン開始: RunState から **一時的に** `GameState.party_members` を差し替え（Tutorial と同型）
2. 戦闘: `CombatController.reset_party_hp_for_run()` — ラン HP
3. EXP: **hub roster に書かない** — RunState 内 Adventurer のみ Lv 更新
4. 終了: party_members を hub に **復元**、RunState 破棄

**【Unknown】** party 差し替え中の SaveManager debounce が hub 装備を誤保存しないか — **ラン中は request_save を抑制 or RunState 専用フラグ** が必要（要 Decision）。

### 4.4 先例【既存】

- `IntroTutorialConfig.begin_run()` — id/tier 設定
- `SurveySystem._store_party_backup()` — party id バックアップ（装備なし）
- `GameState.apply_combat_preset()` — instance_id 一括装備

---

## 5. Equipment / Tag / Synergy Architecture

### 5.1 遠征専売装備【草案 — Decision 137 確定済み】

| ルール | 内容 |
|---|---|
| id | `rogue_<theme>_<piece>` |
| 出所 | 5F ステーション / F30 確定 / F50 持ち帰り のみ |
| データ | 通常 `WeaponData` 等と **同スキーマ** の別 .tres |
| ガード | `RoguelikeEquipPool.is_rogue_exclusive(id)` — 本編 `_spawn_*` から除外 |

### 5.2 ビルドタグ設計【草案 — 採用候補】

**既存 `CombatTags` を拡張せず、遠征専用タグ namespace を足す案（本編影響最小）:**

| カテゴリ | 例タグ | 付与先 |
|---|---|---|
| 元素 | fire, ice, thunder, … | 武器（既存 tags 流用可） |
| 効果 | bleed, shock, burn_stack | 武器・装飾 |
| スタイル | rapid, heavy, dual_wield | 武器 |
| 防御 | fortify, thorns_aura | 防具 |

**シナジー実装レイヤ（優先度順）:**

1. **Layer A【既存再利用】** — `CombatSynergy` 属性/物理/ロール（そのまま動く）
2. **Layer B【草案・MVP+】** — `RoguelikeTagSynergy.gd`: タグ組み合わせ **ルール表**（Dictionary of rule_id → {requires, effects}）
3. **Layer C【草案・Phase2】** — 防具「戦い方成立」、装飾「ビルド変質」 — **`fixed_passive_id` を `eq_rogue_*` で追加**（`CombatPassives` 辞書に遠征専用エントリ）

**例ルール【草案】:**

```text
rule: thunder_chain
  requires: weapon.tags has thunder AND accessory.tags has shock_amp
  effect: on_shock_apply → bonus lightning splash (30% ATK)

rule: bleed_rapid
  requires: 2+ weapons/accessories tagged rapid AND 1+ bleed
  effect: bleed tick rate +20%
```

**単純「タグ3=ATK+20%」は採用しない** — オーナー指示どおり **武器核 + 防具成立 + 装飾変質** を Layer B/C で表現。

### 5.3 最小変更案【草案】

| 変更 | ファイル | 内容 |
|---|---|---|
| 必須 | 新 `RoguelikeEquipPool.gd` | id リスト + job 重み + exclusivity |
| 必須 | 新 `RoguelikeDropWeights.gd` | F 帯別 L/M 重み（Decision 137 §5.2） |
| 必須 | `resources/weapons/rogue_*.tres` | tags + fixed_passive_id 設定 |
| MVP+ | 新 `RoguelikeTagSynergy.gd` | ルール表 + combat hook 1 箇所 |
| Phase2 | `CombatPassives.gd` | `eq_rogue_*` 追加（本編パッシブ namespace と id 分離） |
| 不要（初期） | `WeaponData` スキーマ変更 | tags/set_id で足りる |

---

## 6. Weapon Evolution Architecture

### 6.1 現状【既存】

- **武器 A→B 進化ツリーは存在しない**
- `EquipmentEnhancer.enhance_level`（鍛冶 0–5）は **hub 経済**
- `WeaponSkillHelper` — LEGENDARY+ で `fixed_skill_id`
- `JobEvolution` — **`Constants.JOB_EVOLUTION_PLAYABLE = false`**

### 6.2 提案: 段階 id + RunState tier【草案】

**既存マスタを破壊しない方式:**

```text
rogue_blade_t1  →  rogue_blade_t2  →  rogue_blade_t3
     (Rare)            (Epic)           (Legendary)
```

| 要素 | 設計 |
|---|---|
| マスタ | **別 id 3 件**（tres 3 つ）。1 ファイル上書きしない |
| 進化トリガ | ① 同一 `evolution_line` をステーション再取得 ② 特殊ステーション「進化補助」 ③ F30/F50 確定 |
| RunState | `evolution_line: { "rogue_blade": 2 }` — tier 2 なら t2 の stats/skill を参照 |
| 表示 | 同一表示名 + 「II」「III」サフィックス |
| 最終段 | `fixed_skill_id` / `fixed_passive_id` を tier3 で差し替え — **武器固有能力変化** |

**装備ステーション「進化補助"【草案】:** 所持中武器の **次 tier を無料提示**（3 候補の 1 枠を evolution 専用に置換）。低頻度（例: 25% ステーション）。

**【Unknown】** 進化時 instance_id 継続か新 instance か — **instance 継続 + weapon_id 差し替え** が装備参照を簡単に保てる（要 Decision）。

---

## 7. Expedition Trait Architecture

### 7.1 概念【草案 — 採用候補】

**ラン専用パッシブ** — F10/F20/F40 ピックで 1 つ。恒久 `Adventurer` / 装備 passive 枠を消費しない。

### 7.2 管理【草案】

```text
RoguelikeTraitConfig.gd
  TRAITS: Dictionary  # trait_id → { display, tags_boost[], combat_hooks, conflicts[] }
RunState.traits: Array[String]
```

**効果カテゴリ例:**

|  trait  | 効果 | 連動 |
|---|---|---|
| rogue_trait_thunder_heart | thunder タグ武器の shock 確率 + | Layer B ルール unlock |
| rogue_trait_bloodletter | bleed 上限 +1 スタック | CombatDoT |
| rogue_trait_last_stand | HP30%以下 被ダメ-15% | 生存ビルド |

### 7.3 適用【草案】

- 戦闘開始時 `CombatController` または `DamageCalculator` が `RunState.traits` を読む
- 実装軽量案: **traits を `CombatPassives` の一時ラッパ id にマップ**（`rogue_trait_*` を passives 辞書に追加し、**ラン中のみ** member に virtual attach）
- **本編への漏れ防止:** attach は `RoguelikeExpeditionConfig.is_run()` ガード内のみ

**【Unknown】** trait の最大所持数（3? 無制限?）— 採用候補は **F10/20/40 で最大 3**。

---

## 8. Equipment Station Architecture

### 8.1 フロー【草案 — Decision 137 + 採用候補】

```
floor boundary (F5,10,15,20,25,35,40,45)
  → pause auto-advance
  → RoguelikeEquipStationOverlay
       ├─ roll 3 offers (weapon/armor/accessory) via RoguelikeDropWeights
       ├─ [低頻度] special slot: enhance / reroll / evolution assist
       ├─ player picks 1
       └─ RogueEquipScreen (EquipmentScene fork)
  → if F10|20|40: RoguelikePickOverlay (ally/heal/trait)
  → resume dungeon
```

### 8.2 UI 再利用【既存 + 草案】

| 部品 | 再利用 | 新規 |
|---|---|---|
| 停止・暗転 | DungeonScene floor 遷移 | — |
| 三択カード | FloorChoiceOverlay の Rect/タイマー | 文言・コールバック |
| 装備比較 | EquipmentItemDetailHelper | data source = RunState.inventory |
| 着脱 | EquipmentController.equip_* | inventory 引数化（**要 refactor**） |

**EquipmentController  refactor 案【草案】:**

```gdscript
# 現: GameState.inventory 直参照
# 案: equip_weapon_for_member(item, member, inventory: Array)
```

**【Unknown】** EquipmentScene を subscene 化するか Overlay 専用軽量 UI か — **Phase C は軽量 Overlay 推奨**（5F×8 停止のテンポ優先）。

### 8.3 特殊選択【草案 — 採用候補】

| 特殊 | 頻度案 | 効果 |
|---|---|---|
| 強化 | 15% | 所持装備 1 件の random_mod 1 枠 reroll |
| 再抽選 | 10% | 3 候補を引き直し |
| 進化補助 | 8% | 進化可能武器の次 tier を 1 枠に提示 |

**通常ステーションと排他:** 特殊出現時も **最終的に 1 取得** — 判断項目増殖を抑える。

---

## 9. Boss Modifier Architecture

### 9.1 目的【草案】

F30/F50 ボスに **ランごとの Modifier** を付与し、完成ビルドの万能化を防ぐ。

### 9.2 既存再利用【既存】

| 層 | 用法 |
|---|---|
| `CombatBossPhases` | HP フェーズ・skill weight — **rogue 専用 boss id** を `_DEFS` に追加 |
| `CombatEnemyTraits` | `{ "thorns": 0.2, "heal_block": true }` 的 trait — **Modifier を trait id にマップ** |
| 敵 Lv | floor 比例 — 既存 `get_enemy_level` 分岐 |

### 9.3 提案: RogueBossModifiers【草案】

```text
RunState.boss_modifiers: ["rogue_mod_thunder_resist", "rogue_mod_regen"]
```

| modifier | 効果例 | 対策ビルド |
|---|---|---|
| thunder_resist | 雷属性 -50% | コンボ変更 |
| bleed_immune | bleed 不可 | 物理/属性切替 |
| split_on_phase | フェーズ時召喚 | AoE |
| anti_burst | 単発大 dmg -30% | DoT/多hit |

**抽選:** ラン seed + `RunState` の **取得タグ上位 2** を counter weight — **ビルドに「答え」が必要**。

**【Unknown】** Modifier 数（1? 2?）と F30/F50 同一か別抽選か。

---

## 10. Checkpoint / Save Architecture

### 10.1 現状【既存】

- **ダンジョン途中セーブなし** — 全滅/クリアで Result → hub save
- Run ephemeral: `DungeonController._reset_run_state()` on start
- Persistent: `SaveManager.save_game()` — roster, inventories, progress

### 10.2 F30 CP 提案【草案 — Decision 137 Q2】

**新キー（永続 save 内）:**

```json
"rogue_checkpoint": {
  "version": 1,
  "dungeon_id": "rogue_expedition",
  "floor": 30,
  "room_index": 29,
  "seed": 12345,
  "run_state_blob": { ... }
}
```

**serialize 再利用【既存】:**

- `SaveManager._serialize_inventory()` / `_serialize_adventurer()` — **そのまま流用可能**
- ロード時: hub inventory と **マージしない** — `rogue_checkpoint` のみ復元

**クリア/全滅時:** `rogue_checkpoint` 削除

**【Unknown】** CP は F30 **撃破直後** のみか、F31 以降も保持か — 草案は **撃破後に保存、F31–50 再開可**。

---

## 11. Character Bingo Architecture

### 11.1 現状【既存】

- 図鑑「実績」タブ — `SurveyConfig` + `SurveySystem.achieve_entries()` — **CODEX_ACHIEVE_PLAYABLE=false で UI 非表示**
- 保存: `GameState.hub_survey_achievements_claimed: Dictionary` — `{ achieve_id: true }`

### 11.2 提案【草案】

```text
GameState.rogue_bingo: Dictionary
  # character_id → { "cells": bool[25], "rows_claimed": [], "cols_claimed": [] }
GameState.rogue_bingo_rewards_claimed: Dictionary
  # "char_id:cell_3" → true
```

**セル条件例（採用候補）:**

| タイプ | 例 |
|---|---|
| 到達 | F30到達, F50クリア |
| ビルド | thunder タグ 3 以上, bleed ビルドクリア |
| 制限 | 回復ピック 0, ソロ（仲間0） |
| 装備 | L 3 取得, ミシック持ち帰り |
| キャラ固有 | 固有パッシブ活かす / 特定 job 武器 |

**判定タイミング:** ResultScene 表示前に `RoguelikeBingoEvaluator.evaluate(run_state, leader_id)` — **ラン確定データのみ**。

**報酬【Decision 137】:** マス 2 石 / 行列 10 石+称号 / 全 25 → 50 石。**永続戦力バフなし**。

---

## 12. F50 Carry-Out Architecture

### 12.1 採用候補【草案 — オーナー指示】

**F50 クリア時、ランで取得した `rogue_*` 装備から 1 点を選び恒久 inventory へ。**

### 12.2 フロー【草案】

```
F50 clear
  → ResultScene (rogue branch)
  → CarryOutSelectOverlay: RunState inventories から rogue_* のみリスト
  → player picks 1
  → clone instance (新 instance_id prefix "rogue_carry_")
  → GameState.try_add_*_instance(ignore_cap=true)
  → SaveManager.request_save()
  → RunState 破棄（残り装備は消滅）
```

### 12.3 接続【既存パターン】

- `AbyssLegendaryWeapons.grant_weapon()` — 恒久追加 + `note_equipment_obtained`
- **ガード:** `RoguelikeEquipPool.is_rogue_exclusive()` — 本編 drop pool に **絶対混入させない**（grep CI 推奨）
- **codex:** 遠征図鑑 or 装備詳細「遺跡遠征専売」

**全滅:** 持ち帰り **なし**【草案】

**【Unknown】** 同一 `rogue_*` の重複持ち帰り — **許可/禁止**（コンプ目的なら許可、インフレ抑制なら分解石化）。

---

## 13. Risks / Existing-System Conflicts

| # | リスク | 深刻度 | 対策案 |
|---|---|---|---|
| R1 | ラン中 `party_members` 差し替え → hub save 汚染 | **高** | ラン中 save 抑制 / RunState のみ serialize |
| R2 | `EquipmentController` が GameState.inventory 直参照 | **高** | inventory 引数化（Phase C 前提） |
| R3 | 戦闘 EXP が hub roster Lv を上げる | **中** | `grant_party_combat_exp` 分岐 |
| R4 | `_spawn_weapon` 等が誤って rogue id を本編へ | **高** | pool 分離 + unit test |
| R5 | 遠征 L/M 率が本編装備価値を毀損 | **中** | id 完全分離 + 専売 UI |
| R6 | 50F×8 停止で 40 分超 | **中** | 1F 短縮 + 装備 UI 軽量 |
| R7 | タグシナジー複雑化 → 説明不能 | **中** | MVP は Layer A のみ、B は 5 ルール上限 |
| R8 | CP save 破損 | **中** | version + migrate + 破損時 CP 削除 |
| R9 | `route_type=rogue` 未登録 → 選択不可 | **低** | Constants 同時更新 |
| R10 | MID_BOSS enum 未使用 — F30 実装曖昧 | **低** | BOSS room + `is_mid_boss` フラグ |
| R11 | 深層との役割競合 | **低** | 固定 50F・ビルド型 vs 無限到達 — Decision 137 で分離済 |
| R12 | CombatPassives 辞書肥大 | **低** | `eq_rogue_*` namespace 限定 |

---

## 14. Required Decisions Before Implementation

| ID | 項目 | 状態 | 推奨 |
|---|---|---|---|
| D-ROGUE-01 | GO / モード名称 | 【Unknown】 | 遺跡遠征 |
| D-ROGUE-02 | F50 持ち帰り **選択式** 確定 | 【草案・オーナー候補】 | GO |
| D-ROGUE-03 | F30 CP — 撃破後 F31 再開 | 【Unknown】 | GO |
| D-ROGUE-04 | ラン中 hub 自動 save | 【Unknown】 | **禁止** |
| D-ROGUE-05 | タグシナジー Layer B ルール数 MVP 上限 | 【Unknown】 | 5 ルール |
| D-ROGUE-06 | 武器進化 tier 数 | 【Unknown】 | 3 tier |
| D-ROGUE-07 | 特殊ステーション出現率 | 【Unknown】 | 合計 33%、1 種のみ |
| D-ROGUE-08 | ボス Modifier 数 | 【Unknown】 | F30:1, F50:2 |
| D-ROGUE-09 | trait 最大 3（F10/20/40） | 【草案】 | GO |
| D-ROGUE-10 | 重複持ち帰り | 【Unknown】 | 許可（ビンゴコンプ） |
| D-ROGUE-11 | `rogue_*` カタログ初版件数 | 【Decision 137】 | 武器20/防12/飾12 |
| D-ROGUE-12 | 遠征専用 set 2+1 セット | 【Unknown】 | Phase 2 |
| D-ROGUE-13 | ビンゴ 25 マス確定文案 | 【Unknown】 | Impl 前に表固定 |

---

## 15. Recommended MVP Scope

### Phase 1 — MVP（縦切り 1 周）

| 含む | 含まない |
|---|---|
| RunState + route_type rogue + 1 dungeon tres | 武器進化 tier2+ |
| 50F random + F30/F50 boss | ボス Modifier 抽選 |
| 5F 装備ステーション（通常 3 択 1） | 特殊ステーション |
| `rogue_*` pool 最小 15 件 | 全 44 件カタログ |
| L/M 重み（Decision 137 表） | mythic pity 完全 |
| F50 **持ち帰り選択 1** | ビンゴ 25 全マス |
| CombatSynergy Layer A（既存 tags） | Layer B カスタムルール |
| F10/20/40 仲間+回復ピック | 遠征 trait |
| F30 CP save/load | — |
| headless + GUT RunState | 遠征図鑑 UI |

### Phase 2 — 体験深化

- 装備タグシナジー Layer B（5 ルール）
- 遠征 trait 3 枠
- 武器進化 3 tier + 進化補助
- 特殊ステーション 3 種
- ボス Modifier
- ビンゴ 5×5 完全 + UI
- 遠征 set 2+1

### Phase 3 — やり込み polish

- 遠征図鑑コンプ
- キャラ固有ビンゴ 5 マス
- mythic pity / 週替わり偏り（任意）

---

## 16. Estimated Implementation Complexity

| Phase | 領域 | 規模 | 依存 |
|---|---|---|---|
| **A** RunState + entry | GameState, Config, Constants, tres | **M** | — |
| **B** 50F combat | DungeonController/Scene 分岐 | **M** | A |
| **C** 5F station + equip UI | Overlay, EquipController refactor, pools | **L** | A,B |
| **D** F30/F50 + carry-out | Boss defs, Result branch | **M** | C |
| **E** CP save | SaveManager keys, serialize | **M** | A |
| **F** Tag synergy B | RoguelikeTagSynergy, hooks | **M** | C |
| **G** Traits | TraitConfig, combat attach | **M** | A,B |
| **H** Weapon evolution | tier tres, station logic | **M** | C |
| **I** Boss modifiers | Modifier roll, traits | **S–M** | D |
| **J** Bingo full | Evaluator, UI, save | **L** | D |

**総合:**

| スコープ | 目安 | 備考 |
|---|---|---|
| **MVP（Phase 1）** | **L**（1 モード縦切り） | 既存 dungeon shell 再利用で **新規シーン不要** |
| **採用候補全部** | **XL** | EquipController refactor + CP + bingo + evolution |

**S** = Small（1–2 日相当）, **M** = Medium, **L** = Large, **XL** = 複数 Phase

---

## Appendix A — Investigation Checklist（依頼 14 項目への対応）

| # | 質問 | 回答要約 |
|---|---|---|
| 1 | ダンジョン進行再利用 | §2.1 — 高。50F 固定完了。abyss 延長は不使用 |
| 2 | route_type | §2.2 — `rogue` 新設 + Constants 拡張 |
| 3 | データ構造 | §2.3 — Adventurer/Instance/WeaponData そのまま |
| 4 | ラン分離 | §4 — RunState 新設、party 差し替え |
| 5 | 5F UI 再利用 | §8 — FloorChoice + Equipment ロジック、Controller refactor 要 |
| 6 | タグ最小変更 | §5.3 — tags + RoguelikeTagSynergy 新規 |
| 7 | 武器進化 | §6 — 別 id tier、マスタ破壊なし |
| 8 | 遠征特性 | §7 — RunState.traits + CombatPassives ラッパ |
| 9 | F30 CP | §10 — SaveManager 新キー、既存 serialize 流用 |
| 10 | F50 持ち帰り | §12 — Result 選択 → try_add_instance |
| 11 | ボス Modifier | §9 — BossPhases + EnemyTraits 拡張 |
| 12 | ビンゴ save | §11 — `rogue_bingo` Dictionary |
| 13 | 衝突 | §13 |
| 14 | Decision 項目 | §14 |

---

## Appendix B — Key File Index【既存】

| パス | 用途 |
|---|---|
| `scripts/dungeon/DungeonController.gd` | Run progression, drops, sequences |
| `scripts/dungeon/DungeonScene.gd` | Scene lifecycle, combat UI |
| `scripts/data/DungeonData.gd` | route_type |
| `scripts/core/Constants.gd` | Playability flags |
| `scripts/autoload/GameState.gd` | Persistent state |
| `scripts/save/SaveManager.gd` | Save schema v16 |
| `scripts/equipment/EquipmentController.gd` | Equip flow |
| `scripts/equipment/EquipmentScene.gd` | Equip UI |
| `scripts/dungeon/AbyssLegendaryWeapons.gd` | Isolated pool grant |
| `scripts/dungeon/FloorChoiceOverlay.gd` | Pause choice UI |
| `scripts/intro/IntroTutorialConfig.gd` | Alternate run pattern |
| `scripts/combat/CombatSynergy.gd` | Tag synergy |
| `scripts/combat/CombatBossPhases.gd` | Boss phases |
| `scripts/data/WeaponData.gd` | tags, fixed_passive_id |
| `docs/specs/decisions/137_RoguelikeExpedition.md` | Decision 草案 v2 |

---

*End of investigation document.*
