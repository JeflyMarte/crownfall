# BT／RG 支援回復（Lv15 前倒し）

**Status:** Decision 承認済（2026-08-02）→ **2026-08-06 上書き**（`82_RgBtSkillOrder.md`／P3-SKILL-RG-BT-ORDER-001）  
**Impl:** `P3-BAL-HEAL-BT-RG-001` → 順入替は ORDER-001

---

## 確定（現行）

全体回復は AL のみ。BT／RG の薄い回復は **Lv15（3つ目）**。Lv50 は極意到達技（`82`）。

| 職 | スキル ID | 表示名 | 対象 | 割合 | CD／詠唱 | 解放 |
|---|---|---|---|---|---|---|
| BT | `beast_vet_care` | 獣医の手当て | 最傷1体（ペット厚め） | 人 **10%**／ペット **14%** | 9.5s／1.0s | **Lv15** |
| RG | `camp_draught` | 野営の一滴 | **自己のみ** | **10%** | 10.0s／0s | **Lv15** |

> 2026-08-06: AL 治癒（20%/CD8）より低く保つ（`78_HealHierarchy.md`）。  
> 旧「Lv50差し替えで apex を外す」は **撤回**。apex は Lv50 復帰（CD24）。

- `hunting_ground_mark`／`venom_spray` は 7本枠のため習得外（tres 残置）
- セーブ装備は既存 `normalize_equipped_skills` で unlock 外なら付け替え
