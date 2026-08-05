# BT／RG 支援回復（Lv50 差し替え）

**Status:** Decision 承認済（2026-08-02 — オーナー「GO」）  
**Impl:** `P3-BAL-HEAL-BT-RG-001`

---

## 確定

全体回復は AL のみ。BT／RG に薄い単体回復を Lv50 到達技として追加（7本キット維持）。

| 職 | スキル ID | 表示名 | 対象 | 割合 | CD／詠唱 | 差し替え |
|---|---|---|---|---|---|---|
| BT | `beast_vet_care` | 獣医の手当て | 最傷1体（ペット厚め） | 人 **10%**／ペット **14%** | 9.5s／1.0s | `apex_tame` |
| RG | `camp_draught` | 野営の一滴 | **自己のみ** | **10%** | 10.0s／0s | `apex_shot` |

> 2026-08-06: AL 治癒（20%/CD8）より低く保つ（`78_HealHierarchy.md`）。

- `apex_tame`／`apex_shot` の tres はデータ残置（習得から外す）
- セーブ装備は既存 `normalize_equipped_skills` で unlock 外なら付け替え
