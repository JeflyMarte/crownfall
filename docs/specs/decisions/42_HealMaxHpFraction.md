# 味方回復＝対象 maxHP 割合

**Status:** Decision 承認済（2026-08-02 — オーナー「推奨でGo」）  
**Impl:** `P3-BAL-HEAL-MAXHP-001`  
**追記（2026-08-05）:** `salve_burst` は全体12%へ（`77_AlchemistHealNerf.md` / P3-BAL-ALCHEMIST-HEAL-001）

---

## 確定

味方 `effect_type=heal` の `power_multiplier` は **対象 maxHP 割合**（敵healと同型）。

| スキル | 割合 |
|---|---|
| `mend` | **20%**（単体・最傷）／CD **8.0** |
| `salve_burst` | **12%**（全体・各員）／CD **12.0** |
| `grand_elixir` | **20%**（全体・各員）＋状態異常解除・詠唱なし |
| `beast_vet_care` | **12%**（単体・最傷）／ペット **18%**（`pet_heal_bonus`） |
| `camp_draught` | **12%**（自己のみ） |

装備 `healing_bonus` は算出後に平坦加算。役割／進化の heal 倍率は従来どおり乗算。  
BT／RG 追加の詳細: `43_BtRgSupportHeal.md`。
