# クラシックL装飾の補充（案A）

**Status:** Decision 承認済（2026-08-02 — オーナー「案Aでgo」）  
**Task:** `P3-EQ-CLASSIC-L-ACC-001`  
**関連:** 装備カタログ監査（通常ドロップL飾が5点のみ）／`50_BuildLegendaries.md`（ビルド枠とは別）／`95_JobThemeLegendaryCoverage.md`

---

## 1. 方針

- **通常レジェンド抽選**に載るクラシックL装飾を **+4**（母数 5→9）
- Biome固定★（x-5）の差し替えはしない。ビルドL枠・封蔵には載せない
- 固有パッシブは既存フックのみ（与／被／スキルCD／開幕鼓舞）→ **2026-08-08:** 職テーマ網羅のため効果差し替え可（ID・入手維持）

---

## 2. 品目

| id | 表示名 | パッシブ | 効果 |
|---|---|---|---|
| `bloodvein_signet` | 血脈の印環 | `eq_bloodvein_signet` | 与ダメの10%吸収（BT吸血） |
| `ironvow_amulet` | 行路の護符 | `eq_ironvow_amulet` | パーティ探索・罠ダメ×0.75（RG探索） |
| `quicksigil_charm` | 霜印の護符 | `eq_quicksigil_charm` | 冷却／鈍化敵与+15%、攻撃25%冷却（RG拘束） |
| `dawnrally_brooch` | 暁鼓舞の胸針 | `eq_dawnrally_brooch` | 戦闘開始時、味方全体に empower（VG味方バフ） |

---

## 3. 入手

- `DungeonController._all_legendary_ids("accessory")` に自動参入（ビルドL／灰冠／SET／神話除外のまま）
- x-5 確定★・封蔵・BuildLegendaryLoot には載せない

---

## 4. アイコン

64×64 専用。`LEGENDARY_HAND_DRAWN_ACCESSORY_IDS` 登録。

| id | ファイル |
|---|---|
| bloodvein_signet | `ICO_ACC_BloodveinSignet.png` |
| ironvow_amulet | `ICO_ACC_IronvowAmulet.png` |
| quicksigil_charm | `ICO_ACC_QuicksigilCharm.png` |
| dawnrally_brooch | `ICO_ACC_DawnrallyBrooch.png` |
