# ペット強化＋ジャックサポート化（P3-BAL-PET-SUPPORT-001）

**Status:** Decision 承認済（2026-08-04 — オーナー案A）  
**上書き:** `P3-PET-VARIANT-001-2` のジャック＝火力、基礎ステ420/70/35  
**習得表の後続上書き:** `69_PetTriangleSkills.md`（P3-BAL-PET-TRIANGLE-001）  
**基礎ステの後続上書き:** `88_PetStatDiverge.md`（P3-BAL-PET-STAT-DIVERGE-001）— 3体同一は廃止

---

## 1. 方針

| # | 項目 | 確定 |
|---|---|---|
| 1 | 基礎ステ | （旧）3体とも **×1.5** → 630/105/53。**現行** → `88_PetStatDiverge.md` |
| 2 | ジャック役割 | **サポート**（指揮・介抱・守り） |
| 3 | ジャックキット | → **P3-BAL-PET-JACK-KIT-001**（`87_JackSkillKit.md`） |
| 4 | アッシュ／インク | → 同 Decision で火力／状態異常へ再編 |
| 5 | セーブ | `sync_pet_runtime` で基礎ステを PetData から再適用 |

---

## 2. SSOT

- `resources/pets/pet_*.tres`
- `resources/skills/pet_pounce`／`pet_jack_*`
- `PetSystem.create_pet_adventurer`／`sync_pet_runtime`
