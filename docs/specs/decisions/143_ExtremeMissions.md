# 極限任務（P3-DG-EXTREME-001）

**Status:** **Completed**（2026-09-18）／**制約表は Decision `145` が上書き**（2026-09-19）／**フロア長は一律10F**（2026-09-20）  
**実装:** Phase 1＋Phase 2 **IMPLEMENTATION COMPLETE**／main `e35517f7`  
**QA:** Producer iPhone 16e 実機 — EX-01〜10 PASS（Phase 2 時点・当時5F）  
**上書きなし**（役割四分を既存に追加）※特殊条件の中身は `145` 参照／※フロア長は本 Decision 001-3（10F）が正

---

## 0. 一言

極限任務は **10F 制約攻略**の常設エンドコンテンツ。降臨（時間帯15F）／征討（常設20F）／深層（無限）と役割を分ける。

**制約再設計（2026-09-19）:** 重複制約を解消しビルド多様性へ — Decision **`145`**。

**フロア長（2026-09-20）:** 一律 **10F**（末尾 Boss）。旧 5F を上書き。

---

## 1. 役割四分（確定）

| 枠 | 役割 | 長さ | 配信 |
|---|---|---|---|
| **降臨** | 時間帯・Boss・エンシェントセット | **15F** | 出現ウィンドウ |
| **征討** | 常設・固定長長編＋Boss・エンシェント専用 | **20F** | イベントタブ常設 |
| **深層** | 終わりなき到達・マイルストーン | 無限 | 無限タブ |
| **極限任務** | **特殊条件＋極限指令の制約攻略** | **10F** | **極限任務タブ**・**常設（解放後いつでも）**（メイン5 N 全クリア後） |

---

## 2. Phase 1／Phase 2（完了）

| # | 決定 |
|---|---|
| P3-DG-EXTREME-001-1 | `route_type=extreme`。配信は `EXTREME_MISSION_PLAYABLE_IDS` |
| P3-DG-EXTREME-001-2 | 解放＝メイン5 Biome Normal 全クリア後（`DungeonTierConfig.is_main_campaign_tier_cleared(NORMAL)`） |
| P3-DG-EXTREME-001-3 | 1任務＝**10F**。1〜9F＝通常／群れ／ELITE、10F＝Boss。完全自動戦闘。途中編成変更不可（既存ラン仕様）。※旧5F→2026-09-20 オーナー GO で 10F 一律 |
| P3-DG-EXTREME-001-4 | 特殊条件は原則1つ。出撃前（Featured）で表示 |
| P3-DG-EXTREME-001-5 | 極限指令3つ＝任意。★＝1（CLEAR）＋達成指令数（最大★4）。最高★と指令達成を Save |
| P3-DG-EXTREME-001-6 | EX-01「王墓封鎖」＝モーンゲート再利用／Boss=セルディオン／特殊条件=回復効果低下／指令=戦闘不能なし・規定時間以内・回復スキルなし |
| P3-DG-EXTREME-001-7 | 数値は `ExtremeMissionConfig.TUNING` に一元管理（散在禁止）。**初期リリース値として採用**。将来バランス調整は同辞書のみ |
| P3-DG-EXTREME-001-8 | EX-02〜はデータ追加中心（`MISSIONS`＋tres）。任務専用コード横増殖禁止 |
| P3-DG-EXTREME-001-9 | 週次／新Boss／新Biome／新通貨／専用装備／ランキング等は本 Decision スコープ外 |
| P3-DG-EXTREME-001-10 | EX-09「4人全員異なるジョブ」＝人間 `ACTIVE_PARTY_SIZE=4` 必須・全員別職・Jack（`active_pet`）は判定対象外 |
| P3-DG-EXTREME-001-11 | UI＝**極限任務タブ**常設（イベントダンジョンの隣）。イベントタブからは分離（2026-09-18） |
| P3-DG-EXTREME-001-12 | Featured 表示＝制約の具体説明＋指令3＋★ルール（2026-09-18） |
| P3-DG-EXTREME-001-13 | **制約再設計** — 10種の特殊条件をビルド軸ごとに再割当。詳細・TUNING 追加は Decision **`145`**（2026-09-19） |
| P3-DG-EXTREME-001-14 | **常設出現** — 解放条件を満たせば EX-01〜10 をいつでも挑戦可。回数無制限。旧日替わりローテは廃止（2026-09-20） |

**Phase 1:** 共通基盤＋EX-01 — Completed  
**Phase 2:** EX-02〜EX-10＋共通 modifier／指令 — Completed  
**制約再設計:** Decision `145` — Implemented

---

## 3. 実装アンカー

- `scripts/dungeon/ExtremeMissionConfig.gd`（`MISSIONS`＋`TUNING`＋共通 modifier API）
- `resources/dungeons/ex_*.tres`／`resources/stages/ex_*_1_1.tres`（EX-01〜10）
- Save: `GameState.extreme_mission_progress`
- Heal／敵与ダメ／群れ／後衛／必殺／HP・DoT／状態必須／反射／障壁／弱点: CombatController／DamageCalculator／DungeonController／DungeonScene の共通フック
- UI: **極限任務タブ**常設（イベント隣）／Featured＝制約具体文＋指令＋★ルール／Result に★・指令
- 表示文 SSOT: `ExtremeMissionConfig`（`special_condition` label/desc/tip・`ORDER_DISPLAY_LABELS`）

---

## 4. 初期リリース値（`TUNING`・将来調整可）

| キー | 値 | 用途 |
|---|---|---|
| `heal_effectiveness_mult` | 0.50 | 回復効果低下（heal_down） |
| `order_time_limit_sec` | 600 | 規定時間以内（**ポーズ除外のラン経過秒**・戦闘倍速非連動） |
| `ex01`〜`ex10` enemy/recommended | 55〜64 | 各任務敵／推奨Lv |
| `swarm_force_all_combat` | true | swarm_pressure: 通常 COMBAT 常時群れ |
| `swarm_size_bonus` | 1 | 同上・群れ時体数 |
| `swarm_chance_bonus` | 0.0 | 互換残置（未使用。常時群れ化後） |
| `rear_incoming_mult` | 1.75 | 後衛圧力（陣形軽減に追加乗算） |
| `miasma_enemy_hp_mult` | 1.25 | EX-05 敵HP（`145`） |
| `miasma_dot_duration_mult` | 1.35 | EX-05 DoT持続（`145`） |
| `status_require_outgoing_mult` | 0.70 | EX-06 無状態与ダメ（`145`） |
| `skill_resist_outgoing_mult` | 0.40 | EX-03 スキル攻撃与ダメ（`145`） |
| `shell_incoming_mult` | 0.65 | EX-08 障壁被ダメ（`145`） |
| `pet_primary_human_outgoing_mult` | 0.70 | EX-07 人間与ダメ（`145`） |
| `pet_primary_pet_outgoing_mult` | 1.10 | EX-07 ペット与ダメ（`145`） |
| `ultimate_charge_suppress_mult` | 0.35 | 互換残置・未使用（旧 EX-07） |
| `non_weakness_outgoing_mult` | 0.70 | EX-10 非弱点（`145`） |
| `ultimate_use_limit` | 3 | 必殺使用回数制限 |
| `equip_legendary_chance_bonus` | 0.10 | **極限のみ** LEGENDARY 別枠＋10pt（2026-09-20） |
| `boss_mythic_chance_bonus` | 0.10 | **極限のみ** ボス再クリア神話 1%→11%（2026-09-20） |

**廃止（`145`）:** `status_empower_*`／`elite_swarm_up`／EX-05 二重 heal_down／EX-10 二重 long_battle_ramp／EX-03 `long_battle_ramp`／EX-03 `damage_reflect`／EX-08 `non_crit_pressure`／EX-07 `ultimate_suppress`（互換キーはコード残置・未使用）。

正本は `ExtremeMissionConfig.TUNING`（コード外散在禁止）。制約の正は Decision **`145`**。
