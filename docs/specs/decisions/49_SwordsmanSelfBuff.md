# ソードマン自己バフ（Lv30 差し替え）

**Status:** Decision 承認済（2026-08-02 — オーナー「推奨案で GO」）  
**Impl:** `P3-SKILL-SW-SELFBUFF-001`  
**Overrides:** `20_SkillKitCompress.md` §4.1 Lv30／`48_SkillKitDiverge.md` の SW Lv30（追勢斬）  
**Maintains:** 習得7／装備枠1／味全バフ主軸は AL・VG・BT／`momentum_slash`・`armor_cleave` データ残置

---

## 確定

ソードマンの攻撃一辺倒を緩和するため、**自己バフ1本**をキットに入れる（案A）。

| 項目 | 内容 |
|---|---|
| スキル ID | `battle_spirit` |
| 表示名 | 闘気 |
| 対象 | **自己のみ**（`target_type=self`） |
| 効果 | `empower`（与ダメ×1.3・3tick） |
| CD | **6.5s** |
| 解放 | **Lv30** |
| 差し替え | `momentum_slash`（追勢斬）を習得から外す |

- 群れ単体火力は剣嵐／血煙で賄う。Lv30は「攻めの波に乗る」自己強化へ
- 一閃⇔極意の並立は維持
- セーブ装備は `EQUIPPED_SKILL_REMAP`（`momentum_slash`／旧`armor_cleave` → `battle_spirit`）＋`normalize_equipped_skills`
