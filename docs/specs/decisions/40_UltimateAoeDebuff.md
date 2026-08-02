# 必殺：全体攻撃＋多重デバフ

**Status:** Decision 承認済（2026-08-02 — オーナー指示）  
**Impl:** `P3-BAL-ULTIMATE-AOE-001`

---

## 確定

| 必殺 | 変更 |
|---|---|
| `titan_roar` | `all_enemies`・威力1.8・スタン40%／恐怖30% |
| `beast_dominion` | `all_enemies`・威力1.35・標的／鈍化必中＋毒85%（`apply_status_id3`） |

必殺全体はカットイン経路（`kind=aoe_damage`）。他職必殺は据置。
