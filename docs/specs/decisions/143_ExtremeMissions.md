# 極限任務（P3-DG-EXTREME-001）

**Status:** **Completed**（2026-09-18）  
**実装:** Phase 1＋Phase 2 **IMPLEMENTATION COMPLETE**／main `e35517f7`  
**QA:** Producer iPhone 16e 実機 — EX-01〜10 PASS  
**上書きなし**（役割四分を既存に追加）

---

## 0. 一言

極限任務は **5F 制約攻略**の常設エンドコンテンツ。降臨（時間帯15F）／征討（常設20F）／深層（無限）と役割を分ける。

---

## 1. 役割四分（確定）

| 枠 | 役割 | 長さ | 配信 |
|---|---|---|---|
| **降臨** | 時間帯・Boss・エンシェントセット | **15F** | 出現ウィンドウ |
| **征討** | 常設・固定長長編＋Boss・エンシェント専用 | **20F** | イベントタブ常設 |
| **深層** | 終わりなき到達・マイルストーン | 無限 | 無限タブ |
| **極限任務** | **特殊条件＋極限指令の制約攻略** | **5F** | **極限任務タブ**常設（イベント隣・メイン5 N 全クリア後） |

---

## 2. Phase 1／Phase 2（完了）

| # | 決定 |
|---|---|
| P3-DG-EXTREME-001-1 | `route_type=extreme`。配信は `EXTREME_MISSION_PLAYABLE_IDS` |
| P3-DG-EXTREME-001-2 | 解放＝メイン5 Biome Normal 全クリア後（`DungeonTierConfig.is_main_campaign_tier_cleared(NORMAL)`） |
| P3-DG-EXTREME-001-3 | 1任務＝5F。1〜4F＝通常／群れ／ELITE、5F＝Boss。完全自動戦闘。途中編成変更不可（既存ラン仕様） |
| P3-DG-EXTREME-001-4 | 特殊条件は原則1つ。出撃前（Featured）で表示 |
| P3-DG-EXTREME-001-5 | 極限指令3つ＝任意。★＝1（CLEAR）＋達成指令数（最大★4）。最高★と指令達成を Save |
| P3-DG-EXTREME-001-6 | EX-01「王墓封鎖」＝モーンゲート再利用／Boss=セルディオン／特殊条件=回復効果低下／指令=戦闘不能なし・規定時間以内・回復スキルなし |
| P3-DG-EXTREME-001-7 | 数値は `ExtremeMissionConfig.TUNING` に一元管理（散在禁止）。**初期リリース値として採用**。将来バランス調整は同辞書のみ |
| P3-DG-EXTREME-001-8 | EX-02〜はデータ追加中心（`MISSIONS`＋tres）。任務専用コード横増殖禁止 |
| P3-DG-EXTREME-001-9 | 週次／新Boss／新Biome／新通貨／専用装備／ランキング等は本 Decision スコープ外 |
| P3-DG-EXTREME-001-10 | EX-09「4人全員異なるジョブ」＝人間 `ACTIVE_PARTY_SIZE=4` 必須・全員別職・Jack（`active_pet`）は判定対象外 |
| P3-DG-EXTREME-001-11 | UI＝**極限任務タブ**常設（イベントダンジョンの隣）。イベントタブからは分離（2026-09-18） |

**Phase 1:** 共通基盤＋EX-01 — Completed  
**Phase 2:** EX-02〜EX-10＋共通 modifier／指令 — Completed

---

## 3. 実装アンカー

- `scripts/dungeon/ExtremeMissionConfig.gd`（`MISSIONS`＋`TUNING`＋共通 modifier API）
- `resources/dungeons/ex_*.tres`／`resources/stages/ex_*_1_1.tres`（EX-01〜10）
- Save: `GameState.extreme_mission_progress`
- Heal／敵与ダメ／群れ／後衛／必殺: CombatController／DungeonController／DungeonScene の共通フック
- UI: **極限任務タブ**常設（イベントダンジョンの隣）／Result に★・指令

---

## 4. 初期リリース値（`TUNING`・将来調整可）

| キー | 値 | 用途 |
|---|---|---|
| `heal_effectiveness_mult` | 0.50 | 回復効果低下（heal_down） |
| `order_time_limit_sec` | 600 | 規定時間以内（**ポーズ除外のラン経過秒**・戦闘倍速非連動） |
| `ex01`〜`ex10` enemy/recommended | 55〜64 | 各任務敵／推奨Lv |
| `swarm_chance_bonus` | 0.35 | swarm_pressure / elite_swarm_up |
| `swarm_size_bonus` | 1 | 同上・群れ体数 |
| `long_battle_ramp_start_sec` | 180 | 長期戦強化開始 |
| `long_battle_ramp_per_60sec` | 0.15 | 以降1分あたり +15% |
| `long_battle_ramp_max_mult` | 2.0 | 上限 |
| `rear_incoming_mult` | 1.75 | 後衛圧力（陣形軽減に追加乗算） |
| `status_empower_ids` | poison, bleed | EX-06 対象状態異常 |
| `status_empower_outgoing_mult` | 1.50 | 対象状態中の敵与ダメ |
| `ultimate_charge_suppress_mult` | 0.35 | 必殺チャージ抑制 |
| `ultimate_use_limit` | 3 | 必殺使用回数制限 |

正本は `ExtremeMissionConfig.TUNING`（コード外散在禁止）。
