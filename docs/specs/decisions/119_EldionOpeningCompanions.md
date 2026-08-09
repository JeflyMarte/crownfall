# エルディオン開幕同席＋耐性／解呪（P3-BAL-ELDION-OPENING-001）

**日付:** 2026-08-09  
**状態:** 承認（オーナー指示＝弱体感の是正）

## 要旨

⑤ボス エルディオンが単体だと圧力不足。開幕からストームジョー2体を同席させ、状態異常耐性とバフ剥がしを付与する。

## 決定

| ID | 決定 | 理由 |
|---|---|---|
| P3-BAL-ELDION-OPENING-001-1 | **開幕 `storm_joe`×2** — `EnemyData.opening_companion_ids` で本編 BOSS 編成に追加。入場着地後に表示 | 「最初から一緒に」＝途中召喚ではない |
| P3-BAL-ELDION-OPENING-001-2 | **状態異常耐性** — `incoming_status_chance_mult=0.55`（ミスト帯と同帯） | 付与成功率減衰。SKIP耐性（Decision 97）とは別枠 |
| P3-BAL-ELDION-OPENING-001-3 | **バフ剥がし** — `boss_buff_break_all` を skill_ids＋位相重みへ | 他本編ボスと同スキル |

## 非スコープ

- エルディオン本体の HP／ATK 再調整
- ストームジョー自体のステ変更
- 他ボスへの開幕同席の横展開（フィールドは汎用だがデータは eldion のみ）
