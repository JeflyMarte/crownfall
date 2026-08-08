# ペット基礎ステ差分化（P3-BAL-PET-STAT-DIVERGE-001）

**Status:** Decision 承認済（2026-08-08 — オーナー案B GO）  
**上書き:** `P3-BAL-PET-SUPPORT-001` の「3体同一×1.5」、`P3-PET-VARIANT-001-2` の「HP/ATK/DEF 同一」

---

## 1. 方針

スキルキットは据置。基礎ステだけ役割が分かる差を付ける。

| ペット | HP | ATK | DEF | 狙い |
|---|---:|---:|---:|---|
| ジャック | **750** | **85** | **58** | HP高・ATK低（サポート耐久） |
| アッシュ | **580** | **130** | **42** | ATK高・DEF低（火力） |
| インク | **630** | **105** | **53** | バランス（旧×1.5基準） |

---

## 2. SSOT

- `resources/pets/pet_*.tres`
- `PetSystem.create_pet_adventurer`／`sync_pet_runtime`（PetData 再適用は維持）
