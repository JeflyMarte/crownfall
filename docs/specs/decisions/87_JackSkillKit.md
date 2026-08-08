# ジャックスキル再編（重複解消）

**ID:** P3-BAL-PET-JACK-KIT-001  
**日付:** 2026-08-08  
**状態:** 承認（オーナー GO）  
**ファイル:** `87_JackSkillKit.md`  
**上書き:** `69_PetTriangleSkills.md` のジャック習得表／`78_HealHierarchy.md` の寄り添い14%

## 要旨

回復2種・鼓舞2種の重複をやめ、**役割が分かれた5技**にする。三角（ジャック＝サポート）は維持。

## 確定キット

| Lv | id | 表示名 | 効果 | CD |
|---|---|---|---|---|
| 1 | `pet_jack_frenzy` | 群れ指揮 | 味全 `empower` | 7.5 |
| 8 | `pet_pounce` | つつき介抱 | 最傷1（自己除外）maxHP **8%** | 10.0 |
| 16 | `pet_jack_crack` | 砕き牙 | 敵1 ×**1.0**＋`armor_break_light` | 4.5 |
| 24 | `pet_jack_ward` | 守り吠え | 味全 `guard_minor`（被ダメ×0.8）＋各 maxHP **5%** | 9.0 |
| 32 | `pet_jack_bulwark` | 鉄壁の遠吠え | 味全 `guard`（被ダメ×0.5） | **14.0** |

## 付随

| # | 内容 |
|---|---|
| 1 | `guard_minor` 新設（被ダメ×0.8・2tick）。`guard` と相互排他 |
| 2 | タグ `party_maxhp_heal`＝バフ発動時に味全 maxHP 割合回復（`power_multiplier`） |
| 3 | 旧装備 remap: `pet_jack_rend`→`pet_jack_crack`／`pet_jack_savage`→`pet_jack_ward`／`pet_nibble`→`pet_jack_bulwark` |
| 4 | 旧「癒やしの寄り添い」14%は廃止（階層表から削除） |

## SSOT

- `resources/pets/pet_jack.tres`
- `resources/skills/pet_jack_*.tres`／`pet_pounce.tres`
- `resources/status/guard_minor.tres`
- `BalanceConfig.HEAL_FRAC_PET_JACK_WARD`
- `SkillProgression.EQUIPPED_SKILL_REMAP`
