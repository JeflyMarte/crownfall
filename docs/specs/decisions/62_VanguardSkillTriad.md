# ヴァンガード技能三軸再編（P3-SKILL-VG-TRIAD-001）

**Status:** Decision 承認済（2026-08-06 — オーナー GO）  
**Impl:** `P3-SKILL-VG-TRIAD-001`  
**関連:** P3-SKILL-KIT-001／P3-SKILL-KIT-DIVERGE-001／必殺据置

---

## 1. 方針

装備枠1本で **味方バフ／ヘイト集め／攻撃** の三ビルドが組めるようVGキットを再編する。  
守る手段の二重（自己guard×2・味方guard×2）をやめ、攻めビルドを正式に立てる。  
必殺タイタンロアは据置（全体guard＋empower＋taunt）。

---

## 2. 習得7本

| Lv | ID | 表示名 | 軸 | 効果 |
|---|---|---|---|---|
| 1 | `guard_strike` | 衛士斬り | 攻撃 | 単ダメ＋硬直（据置） |
| 8 | `offensive_stance` | 攻勢の構え | 味方バフ | 味全 **empower**（旧鉄盾斬を置換） |
| 15 | `menace_strike` | 威嚇斬 | ヘイト | 低威力＋挑発（据置） |
| 22 | `bulwark_aura` | 壁守り | 味方バフ | 味全 **guard**（据置） |
| 30 | `shield_crush` | 砕盾斬 | 攻撃 | 単ダメ＋甲砕（旧庇護を置換） |
| 40 | `shield_quake` | 盾撃波 | ヘイト混成 | 敵全弱ダメ＋甲砕＋**taunt** |
| 50 | `assault_shatter` | 突撃破砕 | 攻撃 | 高威力単＋甲砕。自己guardなし |

---

## 3. ビルド例

| ビルド | 主装備 | プレイ感 |
|---|---|---|
| 味方バフ | 攻勢の構え／壁守り | 与ダメ支援 or 被ダメ軽減 |
| ヘイト集め | 威嚇斬／盾撃波 | 矢面タンク |
| 攻撃 | 衛士斬り／砕盾斬／突撃破砕 | 硬直・甲砕付き前衛アタッカー |

---

## 4. セーブ移行

`SkillProgression.EQUIPPED_SKILL_REMAP`:

- `iron_guard` → `offensive_stance`
- `cover_guard` / `shield_ram` → `shield_crush`
- `apex_guard` → `assault_shatter`

旧 tres は残置。
