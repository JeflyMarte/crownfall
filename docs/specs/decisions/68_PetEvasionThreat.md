# ペット回避＋狙われ率（P3-BAL-PET-EVADE-THREAT-001）

**Status:** Decision 承認済（2026-08-04 — オーナー案C）  
**上書き:** `PET_THREAT_BASE` 旧 1.35（雑魚職より高く狙われる設定）

---

## 1. 方針

| # | 項目 | 確定 |
|---|---|---|
| 1 | 既定回避 | **20%**（`PET_BASE_EVASION_RATE`。装備不可の穴埋め） |
| 2 | Threat | **0.6**（後列雑魚職＝`FORMATION_BACK_THREAT×1.0` 相当＝後列以下） |
| 3 | 据置 | 人間の装備回避・陣形倍率・回避上限50% |

---

## 2. SSOT

- `PetSystem.PET_BASE_EVASION_RATE`／`PET_THREAT_BASE`
- `DamageCalculator.member_evasion_rate`
- `CombatController._job_threat_base`
