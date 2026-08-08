# 味方回復＝対象 maxHP 割合

**Status:** Decision 承認済（2026-08-02 — オーナー「推奨でGo」）  
**Impl:** `P3-BAL-HEAL-MAXHP-001`  
**追記（2026-08-05）:** `salve_burst` は全体12%へ（`77_AlchemistHealNerf.md` / P3-BAL-ALCHEMIST-HEAL-001）  
**追記（2026-08-06）:** 治癒頂点の階層＋ジャック介抱ナーフ（`78_HealHierarchy.md` / P3-BAL-HEAL-HIERARCHY-001）  
**追記（2026-08-07）:** 獣医ドレイン化・野営全体8%・つつき8%自己除外（`83_BtRgKitTune.md`）

---

## 確定

味方 `effect_type=heal` の `power_multiplier` は **対象 maxHP 割合**（敵healと同型）。

| スキル | 割合 |
|---|---|
| `mend` | **20%**（単体・最傷）／CD **8.0** — **キャラ単体回復の頂点** |
| `salve_burst` | **12%**（全体・各員）／CD **12.0** |
| `grand_elixir` | **20%**（全体・各員）＋状態異常解除・詠唱なし |
| `beast_vet_care` | **ドレイン攻撃**（power **1.1**／自己＝与ダメ**50%**）／CD **9.5** — heal ではない |
| `camp_draught` | **8%**（全体・各員）／CD **10.0** |
| `pet_pounce` | **8%**（単体・最傷・自己除外）／CD **10.0** |
| `pet_jack_ward` | **5%**（味全・バフ付帯）／CD **9.0**（`87_JackSkillKit`・旧寄り添い廃止） |
| `pet_bond_rally` | **10%**（ペット・バフ付帯）／CD **4.0**（`empower_pet` と同時） |

装備 `healing_bonus` は算出後に平坦加算。役割／進化の heal 倍率は従来どおり乗算。  
BT／RG 追加の詳細: `43_BtRgSupportHeal.md`。階層の正: `78_HealHierarchy.md`／`83_BtRgKitTune.md`。
