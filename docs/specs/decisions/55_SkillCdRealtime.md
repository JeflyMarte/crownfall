# スキルCD＝戦闘クロック（必殺と同型）

**Status:** Decision 承認済（2026-08-02 — オーナー「必殺ゲージ同様に時間で徐々に伸びる」）  
**Impl:** `P3-BAL-SKILL-CD-TIME-001`  
**関連:** P3-COMBAT-GAUGE-001-2／P3-BAL-ULTIMATE-TIME-001／`46_UltimateChargeTime.md`

---

## 1. 方針

装備スキルの再使用待ちは **CT 進行ではなく、必殺と同じ戦闘クロック**で減らす。

| 原則 | 内容 |
|---|---|
| 溜まり方 | 戦闘中・生存表示。実秒 × 戦闘速度。一時停止中は止まる |
| 満タン秒 | 既存 `SkillData.cooldown`（× `skill_cd_mult`）を据置 |
| ゲージ | 残りCDから 0→1 へ滑らかに伸びる（必殺ゲージと同感覚） |
| 発動後 | CD をセットして再カウント |

---

## 2. 上書き

| 旧 | 新 |
|---|---|
| P3-D084「スキルCDは進行 CT 量で減算」 | 本 Decision（戦闘クロック） |
| 実装の CT 連動 `_skill_executor.tick(ct_delta)` | `_process` で `delta × 戦闘速度` |

---

## 3. 据置

- スキル1本装備・戦術即発動
- レリック／セットの `skill_cd_mult`
- 敵スキルも同一 `SkillExecutor` のため同じクロック（個体キーは据置）
