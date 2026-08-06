# ヴァンガードキット調整（ドレインスラッシュ・威嚇全体・突撃破砕）

**ID:** P3-SKILL-VG-TUNE-001  
**日付:** 2026-08-07  
**状態:** 承認（オーナー指示＋推奨補完）  
**Overrides:** `62_VanguardSkillTriad.md` の該当行

## 要旨

1. Lv40 `shield_quake`（盾撃波）→ **`drain_slash` ドレインスラッシュ**（単体・power **1.4**・与ダメ**50%**自己回復）  
2. `assault_shatter` 威力 **3.0**＋**自己**防御DOWN **30%**（敵甲砕は外す）  
3. `menace_strike` を **敵全体**・威力 **1.0**（挑発維持・CD3.0）

## 確定

| スキル | 値 |
|---|---|
| `drain_slash` | damage／enemy／**1.4**／CD **5.5**／tags `drain`（`SKILL_DRAIN_HEAL_RATIO=0.5`） |
| `assault_shatter` | power **3.0**／tag `self_armor_break_on_hit` → status `armor_break_light`（DEF−30%・3tick） |
| `menace_strike` | `all_enemies`／power **1.0**／`taunt`／CD **3.0** |

## SSOT

- `resources/skills/{drain_slash,assault_shatter,menace_strike}.tres`
- `resources/status/armor_break_light.tres`
- `resources/jobs/vanguard.tres`／`SkillProgression` remap
- `62_VanguardSkillTriad.md`（上書き反映）
