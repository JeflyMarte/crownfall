# 序盤防飾N／中盤装飾Eの補充（案A・B）

**Status:** Decision 承認済（2026-08-02 — オーナー「案A、Bを進めて」）  
**Task:** `P3-EQ-EARLY-MID-FILL-001`  
**関連:** 装備カタログ監査（防飾N薄・飾E極薄）

---

## 1. 方針

| 案 | 内容 | 目的 |
|---|---|---|
| **A** | 装飾 **E ×5**（メイン5 Biome各1） | 中盤の装飾ビルド差。既存ボスATK護符とは別軸（HP／DEF／金／レアドロ） |
| **B** | 防具 **N ×5** ＋ 装飾 **N ×5**（各Biome各1） | 序盤の防・飾の選択肢。既存Nと同帯のトレードオフ |

- L／神話／灰冠／降臨／深層は触らない
- 固有パッシブなし（N/Eの通常枠）
- 通常ダンジョンプールへ追加（封蔵・ボス確定★には載せない）

---

## 2. 品目

### A — 装飾 E

| Biome | id | 表示名 | 主軸 |
|---|---|---|---|
| モーン | `ashvault_pendant` | 灰庫のペンダント | HP＋DEF（①に欠けていたE飾） |
| ウィスパー | `canopy_ward_talisman` | 樹冠の護符 | HP＋レアドロ |
| ミストフェン | `mireglass_brooch` | 沼鏡の胸針 | DEF＋レアドロ |
| ブラックショア | `tideledger_charm` | 潮帳の護符 | HP＋ゴールド |
| フロスト | `rimecrown_seal` | 霜冠の印 | HP＋DEF |

### B — 防具 N

| Biome | id | 表示名 | 既存Nとの差 |
|---|---|---|---|
| モーン | `wick_padded_coat` | 芯綿の巡衣 | HP寄り（対 `crypt_weave_cloak`） |
| ウィスパー | `trail_twine_wrap` | 路傍縄の胴巻 | DEF寄り（対 `moss_weave_garb`） |
| ミストフェン | `reedmat_vest` | 葦筵の胴衣 | HP寄り（対 `mire_hide_garb`） |
| ブラックショア | `netter_smock` | 網師の作業着 | HP寄り（対 `tidecloth_garb`） |
| フロスト | `drove_wool_coat` | 移牧の羊毛套 | HP寄り（対 `furline_garb`） |

### B — 装飾 N

| Biome | id | 表示名 | 主軸 |
|---|---|---|---|
| モーン | `copper_bell_ring` | 銅鈴の指輪 | 小DEF |
| ウィスパー | `seed_pouch_charm` | 種袋の護符 | 小HP＋レアドロ |
| ミストフェン | `clay_bead_band` | 土珠の指輪 | HP＋小DEF |
| ブラックショア | `dock_knot_charm` | 波止場の結び | 小HP＋ゴールド |
| フロスト | `mitten_pin` | 手袋留めの飾 | 小DEF＋HP |

---

## 3. プール

各 Biome 系ダンジョンの `armor_pool`／`accessory_pool` に当該品を追加。  
寄り道・深層・降臨で同Biomeプールを継承しているものも同様。

---

## 4. スコープ外

- ~~案C（AL／BT専用ビルドL）~~ → **`54_PetHealerBuildGear.md` で実施**
- 案D（属性防飾ペア）・案E（灰冠パッシブ配線）
- 専用手描きアイコン（飾は Generic 形、防は近縁Biomeアイコン流用可）
