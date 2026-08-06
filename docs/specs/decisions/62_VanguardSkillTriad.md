# ヴァンガード技能三軸再編（P3-SKILL-VG-TRIAD-001）

**Status:** Decision 承認済（2026-08-06 — オーナー GO）  
**Impl:** `P3-SKILL-VG-TRIAD-001`  
**追記（2026-08-07）:** `84_VanguardKitTune.md` / P3-SKILL-VG-TUNE-001 で Lv15/40/50 を調整  
**関連:** P3-SKILL-KIT-001／P3-SKILL-KIT-DIVERGE-001／必殺据置

---

## 1. 方針

装備枠1本で **味方バフ／ヘイト集め／攻撃** の三ビルドが組めるようVGキットを再編する。  
守る手段の二重（自己guard×2・味方guard×2）をやめ、攻めビルドを正式に立てる。  
必殺タイタンロアは据置（全体guard＋empower＋taunt）。

---

## 2. 習得7本（現行＝TUNE-001 反映）

| Lv | ID | 表示名 | 軸 | 効果 |
|---|---|---|---|---|
| 1 | `guard_strike` | 衛士斬り | 攻撃 | 単ダメ＋硬直（据置） |
| 8 | `offensive_stance` | 攻勢の構え | 味方バフ | 味全 **empower** |
| 15 | `menace_strike` | 威嚇斬 | ヘイト | **敵全** power **1.0**＋挑発 |
| 22 | `bulwark_aura` | 壁守り | 味方バフ | 味全 **guard**（据置） |
| 30 | `shield_crush` | 砕盾斬 | 攻撃 | 単ダメ＋甲砕（据置） |
| 40 | `drain_slash` | ドレインスラッシュ | 攻撃／粘り | 単ダメ **1.4**＋与ダメ**50%**自己回復（`drain`） |
| 50 | `assault_shatter` | 突撃破砕 | 攻撃 | 単 **3.0**＋自己防御DOWN **30%**（敵甲砕なし） |

旧 `shield_quake` は習得外（tres 残置・装備 remap→`drain_slash`）。

---

## 3. ビルド例

| ビルド | 主装備 | プレイ感 |
|---|---|---|
| 味方バフ | 攻勢の構え／壁守り | 与ダメ支援 or 被ダメ軽減 |
| ヘイト集め | 威嚇斬（全体） | 群れの矢面 |
| 攻撃 | 衛士斬り／砕盾斬／突撃破砕／ドレイン | 硬直・甲砕・高威力・吸血 |

---

## 4. セーブ移行

`SkillProgression.EQUIPPED_SKILL_REMAP`:

- `iron_guard` → `offensive_stance`
- `cover_guard` / `shield_ram` → `shield_crush`
- `apex_guard` → `assault_shatter`
- `shield_quake` → `drain_slash`

旧 tres は残置。
