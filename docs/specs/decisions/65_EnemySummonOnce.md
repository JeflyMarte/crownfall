# 敵招集スキルは戦闘中1回（P3-BAL-SUMMON-ONCE-001）

**Status:** Decision 承認済（2026-08-04 — オーナー指示）  
**上書き:** 雑魚招集の CD10 再発動余地。ボス招集の一度限り方針を全招集へ拡張

---

## 1. 方針

| # | 項目 | 確定 |
|---|---|---|
| 1 | 対象 | `effect_type=summon` すべて（ボス指定召喚＋雑魚同種クローン） |
| 2 | 回数 | **戦闘中1回**／召喚者 |
| 3 | 消費 | **発動時点**で消費（失敗しても再抽選不可） |
| 4 | CD | **9999** ＋ `once_per_combat` タグ（二重止め） |
| 5 | 鍵 | 指定召喚＝`skill_id`／同種クローン＝`slot` |

---

## 2. SSOT

- `DungeonScene._execute_enemy_summon` / `_enemy_summon_used`
- スキル: `enemy_crown_call`／`enemy_boar_call`／既存ボス call_*
