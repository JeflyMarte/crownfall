# 味方回復＝対象 maxHP 割合

**Status:** Decision 承認済（2026-08-02 — オーナー「推奨でGo」）  
**Impl:** `P3-BAL-HEAL-MAXHP-001`

---

## 確定

味方 `effect_type=heal` の `power_multiplier` は **対象 maxHP 割合**（敵healと同型）。

| スキル | 割合 |
|---|---|
| `mend` | **20%**（単体・最傷） |
| `salve_burst` | **32%**（単体・最傷） |
| `grand_elixir` | **16%**（全体・各員） |

装備 `healing_bonus` は算出後に平坦加算。役割／進化の heal 倍率は従来どおり乗算。
