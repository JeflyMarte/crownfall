# ペット三角スキル再編（P3-BAL-PET-TRIANGLE-001）

**Status:** Decision 承認済（2026-08-04 — オーナー案A改 GO）  
**上書き:** `P3-PET-VARIANT-001-2` の役割三角（火力／守り／崩し）、`P3-BAL-PET-SUPPORT-001` のジャック習得表

---

## 1. 方針

| # | 項目 | 確定 |
|---|---|---|
| 1 | 役割三角 | **ジャック＝サポート／アッシュ＝火力／インク＝状態異常** |
| 2 | Lv1強度 | Lv1スキルは後半も選択肢になり得る本線（上位は別状況の道具） |
| 3 | ジャック | Lv1 **群れの士気（全体鼓舞）**／8 つつき介抱／16 応援の遠吠え／24 癒やしの寄り添い／32 かじりつき |
| 4 | アッシュ | Lv1 灰牙（主力ダメ）／8 連撃爪／16 追い灰（vs出血）／24 標的裂き（vs標的）／32 灰裂 |
| 5 | インク | Lv1 影毒（毒）／8 墨の足止め／16 影噛み／24 **麻痺牙（stun）**／32 呪影（標的＋毒副次） |
| 6 | 行動方針 | ジャック `support_focus`／アッシュ `aggressive`／インク `balanced` |

---

## 2. SSOT

- `resources/pets/pet_*.tres`
- `resources/skills/pet_*`
- `PetSystem.create_pet_adventurer`／`sync_pet_runtime`
- `docs/specs/decisions/67_PetSupportBuff.md`（基礎ステ×1.5は維持）
