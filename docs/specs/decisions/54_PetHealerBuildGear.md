# ペット／ヒーラービルド装備（規模M）

**Status:** Decision 承認済（2026-08-02 — オーナー「GOで」＝推奨規模M）  
**Task:** `P3-EQ-PET-HEAL-BUILD-001`  
**関連:** `50_BuildLegendaries.md`（AL／BT専用の後続）／`52_EarlyMidEquipFill.md` 案C／`43_BtRgSupportHeal.md`

---

## 1. 方針

ペット・ヒーラーを **装備セットとして成立**させる。スキル差し替え・灰冠枯翠配線は同梱しない。

| 軸 | L（ビルド拡張プール） | 中盤E（通常プール） |
|---|---|---|
| ペット | 防具1（指揮外套） | 装飾1（弱いペット与） |
| ヒーラー | 杖1＋防具1 | 装飾1（弱い回復） |

既存: `packbond_staff`／`beastlord_fang`／`apothecary_vial`／軍旗レリックは据置。

---

## 2. 品目と効果

### L

| id | 部位 | 表示名 | パッシブ | 効果 |
|---|---|---|---|---|
| `beastcall_mantle` | 防 | 獣呼びの指揮外套 | `eq_beastcall_mantle` | ペット与+18%／防+10%。自身与-6% |
| `mendweaver_staff` | 杖 | 癒織の杖 | `eq_wpn_mendweaver_staff` | 回復+22%。自身与-8% |
| `field_salve_robe` | 防 | 野戦調剤の法衣 | `eq_field_salve_robe` | 回復+15%。自身与-10% |

### E（中盤階段）

| id | 部位 | 表示名 | パッシブ | 効果 |
|---|---|---|---|---|
| `pack_whistle_charm` | 飾 | 群れ笛の護符 | `eq_pack_whistle_charm` | ペット与+8% |
| `salve_band` | 飾 | 軟膏の腕輪 | `eq_salve_band` | 回復+8% |

---

## 3. 入手

- **L3点:** `BuildLegendaryLoot` に追加（x-5初回の未所持1点）。武器カテゴリを許可
- **E2点:** 通常 `accessory_pool`（ペット＝②③系、ヒーラー＝①④系）
- 封蔵ガチャ・神話枠には載せない

---

## 4. 完成形（目安）

| ビルド | 武 | 防 | 飾 | 任意 |
|---|---|---|---|---|
| ペット | 絆笛杖 | 獣呼び外套 | 獣牙 | 軍旗／群れ笛E |
| ヒーラー | 癒織杖 | 野戦調剤衣 | 調剤瓶 | 軟膏E |

---

## 5. アイコン

| id | ファイル |
|---|---|
| beastcall_mantle | `ICO_ARM_BeastcallMantle.png` |
| field_salve_robe | `ICO_ARM_FieldSalveRobe.png` |
| mendweaver_staff | `ICO_WPN_MendweaverStaff.png` |

- 64×64 RGBA・`IconPaths` 登録・`LEGENDARY_HAND_DRAWN_*` で再生成スキップ
- 取込: `tools/import_build_legendary_icons.py`
- 中盤E（群れ笛／軟膏）は Generic 形のまま

## 6. スコープ外

- AL／BTスキルキット差し替え（Dec48後続）
- 灰冠枯翠パッシブ配線
- ペット弓L第2ルート／ヒーラー飾第2
