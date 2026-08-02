# エリート護衛＋ボス個別デバフ圧力

**Status:** Decision 承認済（2026-08-02 — オーナー「AでGo」／個別デバフ「Goで」）  
**Impl:** `P3-BAL-ELITE-BOSS-PRESSURE-001`  
**関連:** P3-BAL-BOSS-PRESSURE-001／P3-BAL-SWARM-001／37_SwarmDensitySoloPressure／**開幕オーラは `45_BossOpeningAura`（上書き）**

---

## 1. 方針

ELITE／BOSS が単体火力頼りで薄く感じる問題を、**数値の大幅ブーストではなく技と編成**で圧を足す。

| 対象 | 確定 |
|---|---|
| ボス | **ボスごと**の全体デバフ／状態異常1枠＋ F1 全体の章テーマ状態を厚く |
| エリート | 入場時に章雑魚 **1〜2** 体を護衛。本体は列／全体を最低1つ |
| 人数連動 | ELITE／BOSS は引き続き適用外（護衛雑魚も密度スケールなし） |
| グローバル ATK | 据置 |

---

## 2. ボス（個別全体デバフ）

共通 `boss_party_curse` は使わない。各ボスに `boss_*_hex`（全体・軽ダメ・状態必中・即時・CD8）。

| ボス | スキル | 状態 |
|---|---|---|
| serdion | `boss_serdion_hex` | fear |
| granvel | `boss_granvel_hex` | slow |
| moldgar | `boss_moldgar_hex` | slow |
| nereion | `boss_nereion_hex` | mark |
| eldion | `boss_eldion_hex` | vulnerable |
| chronos_wave | `boss_chronos_wave_hex` | slow |
| valgard | `boss_valgard_hex` | vulnerable |
| skarpedion | `boss_skarpedion_hex` | armor_break |
| mycolga_ancient | `boss_mycolga_hex` | fear |
| karna_smoke | `boss_karna_hex` | mark |
| nereion_depths | `boss_nereion_depths_hex` | slow |
| forgedormient | `boss_forgedormient_hex` | vulnerable |
| albark | `boss_albark_hex` | fear |

| 項目 | 確定 |
|---|---|
| 重み | 激昂＜個別hex＜即時全体 |
| F1 状態 | 章テーマ異常を付与／確率をおおよそ 0.35〜0.45 へ（hex と被らないよう選定） |
| 開幕／CD／速度／火力 | **`45_BossOpeningAura` を正**（開幕付与・CD6・人数速度・ATK↑） |

---

## 3. エリート

| 項目 | 確定 |
|---|---|
| 護衛数 | `randi_range(1, 2)`（雑魚プール空なら単体のまま） |
| 例外 | **モーンゲート・ノーマル**は護衛0（単体エリートのみ）。ウィスパーウッド以降・H/NMは据置 |
| 雑魚源 | 既存 `_swarm_minion_enemies`（`can_swarm` かつ非護衛リーダー） |
| キャップ | `swarm_size_cap` を超えない |
| キット穴 | `polar_tricera` に前列 AoE を追加 |

---

## 4. スコープ外

- ボスへの大量召集
- ELITE／BOSS への群れ人数連動
- `ENEMY_GLOBAL_*_MULT` の再変更
- 全ボス共通の同一デバフ技
