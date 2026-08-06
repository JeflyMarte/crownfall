# BT／RG 支援スキル（Lv15）

**Status:** Decision 承認済（2026-08-02）→ **2026-08-06 上書き**（`82_RgBtSkillOrder.md`）→ **2026-08-07 上書き**（`83_BtRgKitTune.md`）  
**Impl:** `P3-BAL-HEAL-BT-RG-001` → 順入替は ORDER-001 → キット調整は TUNE-001

---

## 確定（現行）

全体の厚い回復は AL。BT／RG の支援枠は **Lv15（3つ目）**。Lv50 は極意到達技（`82`）。

| 職 | スキル ID | 表示名 | 対象 | 効果 | CD／詠唱 | 解放 |
|---|---|---|---|---|---|---|
| BT | `beast_vet_care` | 獣医の手当て | 敵1 | 攻撃 **×1.1**＋自己回復＝与ダメ**50%**（`drain`） | 9.5s／1.0s | **Lv15** |
| RG | `camp_draught` | 野営の一滴 | **味方全体** | 各 **8%** | 10.0s／0s | **Lv15** |

> 2026-08-07: 獣医はドレイン攻撃へ。野営は全体薄回復（`83`）。  
> 旧「Lv50差し替えで apex を外す」は **撤回**。apex は Lv50 復帰（CD24）。

- `hunting_ground_mark`／`venom_spray` は 7本枠のため習得外（tres 残置）
- セーブ装備は既存 `normalize_equipped_skills` で unlock 外なら付け替え
