# 在野助っ人 staged → プール昇格（P3-GACHA-STAGED / P3-GACHA-PROMOTE-001）

**Status:** プール昇格 GO（2026-07-26 オーナー）  
**経緯:** STAGED-001/002 で `_omitted` に追加 → PROMOTE-001 で k/m/n/o を排出へ投入し数値再設計。トルヴァ（l）は `_omitted` 残置。

---

## 1. 現行排出プール（直下 11 体）

| ★ | 人数 | id |
|---|---|---|
| 2 | 5 | helper_b／f／i／**k（レノール）**／**o（ネリ）** |
| 3 | 4 | helper_c／e／**m（シアン）**／**n（ボルグ）** |
| 4 | 2 | helper_a／helper_p（火鷹） |

排出率・天井・`GachaRarityConfig` は据置（個体数増のみ）。

---

## 2. `_omitted` 残置

| id | 名前 | ★ | 職 | 備考 |
|---|---|---|---|---|
| `helper_l` | トルヴァ（Torva） | 3 | swordsman | staged 据置（昇格未） |
| 旧退避 | レオン／シルヴィ等 | — | — | データ残置 |

---

## 3. 昇格4体のステ・パッシブ（PROMOTE-001／現行正）

固有スキルは新設しない。差別化は **個人ステ＋固有パッシブ1本**。

| id | ★ | 個人ステ `{hp,atk,def}` | パッシブ id | 効果 |
|---|---|---|---|---|
| helper_k レノール | 2 | `{-30, 270, -20}` | `lenore_seal_echo`（呪印の増幅） | 状態異常敵への与ダメ＋45%（P3-BAL-PASSIVE-EKREWC-001） |
| helper_m シアン | 3 | `{40, 80, 60}` | `sian_silent_line`（静寂の構え） | 後列回避＋初撃標的 |
| helper_n ボルグ | 3 | `{100, 60, 100}` | `borg_gate_voice`（門前の残像） | **開幕回避 +22%**（戦闘中） |
| helper_o ネリ | 2 | `{-50, 40, 30}` | `neri_waterfowl_call`（水鳥の指揮） | ペットステ **×1.2**／戦闘終了時 **30%** 蘇生 |

トルヴァ（l）は STAGED-002 数値のまま `_omitted`（初撃×1.5／ステ `{-40, 205, 28}`）。

---

## 4. 同期先

- `13_Characters`／`08 §14`／`11_Glossary` — 昇格4＋火鷹を本載せ
- 図鑑人物録 — `GachaHelperData` プロフィール（P3-CODEX-CHAR-001）
- アート — 立ち絵／戦闘シート／`CHR_Helper_*`
