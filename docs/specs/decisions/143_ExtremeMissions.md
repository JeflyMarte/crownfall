# 極限任務 Phase 1（P3-DG-EXTREME-001）

**Status:** Decision **承認済**（2026-09-17 — Phase 1 実装依頼）  
**実装:** Phase 1 本線反映済／**Phase 2（EX-02〜10＋EX-09 4人判定）APPROVED・本線反映**  
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
| **極限任務** | **特殊条件＋極限指令の制約攻略** | **5F** | イベントタブ常設（メイン5 N 全クリア後） |

---

## 2. Phase 1 確定

| # | 決定 |
|---|---|
| P3-DG-EXTREME-001-1 | `route_type=extreme`。配信は `EXTREME_MISSION_PLAYABLE_IDS` |
| P3-DG-EXTREME-001-2 | 解放＝メイン5 Biome Normal 全クリア後（`DungeonTierConfig.is_main_campaign_tier_cleared(NORMAL)`） |
| P3-DG-EXTREME-001-3 | 1任務＝5F。1〜4F＝通常／群れ／ELITE、5F＝Boss。完全自動戦闘。途中編成変更不可（既存ラン仕様） |
| P3-DG-EXTREME-001-4 | 特殊条件は原則1つ。出撃前（Featured）で表示 |
| P3-DG-EXTREME-001-5 | 極限指令3つ＝任意。★＝1（CLEAR）＋達成指令数（最大★4）。最高★と指令達成を Save |
| P3-DG-EXTREME-001-6 | EX-01「王墓封鎖」＝モーンゲート再利用／Boss=セルディオン／特殊条件=回復効果低下／指令=戦闘不能なし・規定時間以内・回復スキルなし |
| P3-DG-EXTREME-001-7 | 未確定数値は `ExtremeMissionConfig.TUNING` に provisional 集約（散在禁止） |
| P3-DG-EXTREME-001-8 | EX-02〜はデータ追加中心（`MISSIONS`＋tres）。任務専用コード横増殖禁止 |
| P3-DG-EXTREME-001-9 | Phase 1 では週次／新Boss／新Biome／新通貨／専用装備／ランキング等は実装しない |

---

## 3. 実装アンカー

- `scripts/dungeon/ExtremeMissionConfig.gd`
- `resources/dungeons/ex_tomb_seal.tres` / `resources/stages/ex_tomb_seal_1_1.tres`
- Save: `GameState.extreme_mission_progress`
- Heal: `CombatController.heal_member` × TUNING heal mult
- UI: イベントタブ常設（征討と同型）／Result に★・指令

---

## 4. 仮値（provisional）

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

正本は `ExtremeMissionConfig.TUNING`。