# エルディオン開幕同席＋耐性／解呪（P3-BAL-ELDION-OPENING-001）

**日付:** 2026-08-09  
**状態:** 承認（オーナー指示＝弱体感の是正 → 案A改訂 → 火力増 → **開幕同席撤廃＋半減時全回復**）

## 要旨

⑤ボス エルディオンの圧力を本体側で確保する。開幕ストーム同席は撤廃。  
HP≤50%（第2形態）到達時に **一度だけ全回復**する。

## 決定

| ID | 決定 | 理由 |
|---|---|---|
| P3-BAL-ELDION-OPENING-001-1 | **開幕同席なし**（`opening_companion_ids` 空。旧×2→×1→撤廃） | オーナー指示 |
| P3-BAL-ELDION-OPENING-001-2 | **状態異常耐性** — `incoming_status_chance_mult=0.55` | 付与成功率減衰 |
| P3-BAL-ELDION-OPENING-001-3 | **バフ剥がし** — `boss_buff_break_all` | 他本編ボスと同解呪 |
| P3-BAL-ELDION-OPENING-001-4 | **本体火力** — HP2550／ATK220／skill0.65／技・位相倍率 | 同席なしでも圧力 |
| P3-BAL-ELDION-OPENING-001-5 | **HP≤50% で一度全回復** — 第2形態 `full_heal_on_enter`。位相スキップ時も適用 | オーナー指示 |
| P3-BAL-ELDION-OPENING-001-5b | **全回復カットイン** — 技名「氷河の再誕」／効果「自身のHPを全回復する」。ボス必殺帯と同演出 | オーナー指示 |
| P3-BAL-ELDION-OPENING-001-6 | **SSOT** — 本 Decision | — |

## 非スコープ

- ストームジョー自体のステ変更
- 他ボスへの全回復横展開
