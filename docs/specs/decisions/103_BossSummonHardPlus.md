# ボス召喚は Hard+ のみ（P3-BAL-BOSS-SUMMON-HARD-PLUS-001）

**Status:** Decision 承認済（2026-08-11 — オーナー指示）  
**上書き:** `P3-BAL-BOSS-SUMMON-REGEN-001` の「ノーマルでも召喚可」前提

---

## 1. 方針

| 難易度 | ボス戦闘中の指定召喚（沼王招来・ドレッド招集等） | 開幕同席 |
|---|---|---|
| ノーマル | **なし** | **なし** |
| ハード／ナイトメア | あり（既存スキル据置） | あり（定義がある場合） |

雑魚の同種クローン／指定召喚（ボア招集等）は対象外。

## 2. SSOT

- `DungeonTierConfig.boss_midcombat_summon_allowed`
- `DungeonScene._is_boss_designated_summon_blocked` / `_enemy_tricky_skill_allowed`
- `DungeonController._append_boss_opening_companions`
