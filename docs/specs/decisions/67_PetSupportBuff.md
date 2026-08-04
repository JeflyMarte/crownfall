# ペット強化＋ジャックサポート化（P3-BAL-PET-SUPPORT-001）

**Status:** Decision 承認済（2026-08-04 — オーナー案A）  
**上書き:** `P3-PET-VARIANT-001-2` のジャック＝火力、基礎ステ420/70/35  
**習得表の後続上書き:** `69_PetTriangleSkills.md`（P3-BAL-PET-TRIANGLE-001）

---

## 1. 方針

| # | 項目 | 確定 |
|---|---|---|
| 1 | 基礎ステ | 3体とも **×1.5** → HP**630**／ATK**105**／DEF**53** |
| 2 | ジャック役割 | **サポート**（介抱・鼓舞） |
| 3 | ジャックキット（旧） | → **P3-BAL-PET-TRIANGLE-001** で Lv1全体鼓舞ほかへ再編 |
| 4 | アッシュ／インク | → 同 Decision で火力／状態異常へ再編 |
| 5 | セーブ | `sync_pet_runtime` で基礎ステを PetData から再適用 |

---

## 2. SSOT

- `resources/pets/pet_*.tres`
- `resources/skills/pet_nibble`／`pet_pounce`／`pet_jack_*`
- `PetSystem.create_pet_adventurer`／`sync_pet_runtime`
