# Legendary Weapon Icon Brief — レジェンド武器アイコン作画指示

**Status:** Phase B 初版納品済（2026-07-09）— WIP 原画 → `import_legendary_weapon_icons.py` で 64×64 取り込み  
**対象:** ★レジェンド武器 UI アイコン（Biome 10 本＋天候シンクロ 3 本）  
**SSOT 命名:** `docs/specs/implementation/12_AssetPipeline.md` / P3-D003

---

## 1. 納品仕様

| 項目 | 規格 |
|---|---|
| キャンバス | **64×64** px |
| 形式 | PNG（RGBA・完全透過背景） |
| 配置先 | `assets/ui/equipment/ICO_WPN_{PascalName}.png` |
| 安全域 | 中央 **44×44** 以内に武器主体 |
| 焼き込み禁止 | レアリティ枠・★マーク・文字 |
| スタイル | 既存 `assets/ui/batch2/ICO_WPN_*.png` と同系ピクセル密度 |

WIP（任意）: `assets/ui/equipment/_wip/ICO_WPN_*.png`  
完成後は本番パスへ上書き。

---

## 2. 作画リスト（10 本）

| # | Biome | weapon_id | 出力ファイル | 表示名 | 型 | element | 作画の軸（フレーバー） |
|---|---|---|---|---|---|---|---|
| 1 | ① mourngate | `sanctified_dagger` | `ICO_WPN_SanctifiedDagger.png` | 霊廟の聖別刃 | dagger | holy | 霊廟の聖別・細身の儀式短刃・淡い金属光 |
| 2 | ① mourngate | `consecrated_maul` | `ICO_WPN_ConsecratedMaul.png` | 祝聖の大槌 | greatsword | holy | 王都祭祀の大槌・重厚・祝福の刻印 |
| 3 | ② whisperwood | `silvaria_oathblade` | `ICO_WPN_SilvariaOathblade.png` | 森護王の誓剣シルヴァリア | greatsword | fire | 森護王の誓い・蔦/花弁が巻き付く大剣 |
| 4 | ② whisperwood | `veld_branch_staff` | `ICO_WPN_VeldBranchStaff.png` | 翠杖ヴェルドの枝 | staff | fire | 生命の枝・胞子の微光・自然の曲線 |
| 5 | ③ mistfen | `volgrave_thunderblade` | `ICO_WPN_VolgraveThunderblade.png` | 沼王断ちの雷剣ヴォルグレイヴ | greatsword | thunder | 沼王を断つ雷刃・鱗/泥と稲妻の筋 |
| 6 | ③ mistfen | `seradion_storm_staff` | `ICO_WPN_SeradionStormStaff.png` | 学識王の雷典杖セラディオン | staff | thunder | 沈没書庫・封印誌・雷の導体 |
| 7 | ④ blackshore | `nereidas_tideblade` | `ICO_WPN_NereidasTideblade.png` | 海統王の潮汐刃ネレイダス | dual_blades | holy | 潮汐の双剣・潮目・潮沫の弧 |
| 8 | ④ blackshore | `pharoslight_staff` | `ICO_WPN_PharoslightStaff.png` | 灯守の聖杖ファロスライト | staff | holy | 灯台の光・潮灯・聖なる灯芯 |
| 9 | ⑤ frostridge | `eldion_frostbrand` | `ICO_WPN_EldionFrostbrand.png` | 始祖竜の氷焔剣エルディオン・ブランド | greatsword | ice | 氷河晶の刃・古龍の冷炎・霜の欠片 |
| 10 | ⑤ frostridge | `umbra_terminus_staff` | `ICO_WPN_UmbraTerminusStaff.png` | 終末の闇杖ウンブラ・テルミナス | staff | dark | 極寒の終末・闇と氷晶・不気味な先端 |

**差別化の目安:** ✦ より装飾 1 段増・Biome モチーフ 1 点・発光/二色。同型（大剣×4 等）でも **シルエットと装飾** で区別すること。

---

## 3. コード側（実装済み）

- `scripts/ui/IconPaths.gd` — 10 本とも専用パス登録済み（作画後も変更不要）
- `tools/generate_equipment_icons.py` — `LEGENDARY_HAND_DRAWN_WEAPON_IDS` で再生成スキップ
- 検証: `python3 tools/verify_icon_paths.py`

---

## 4. 取り込み手順（作画完了後）

```bash
# 1. 原画を WIP へ（ファイル名は ICO_WPN_{PascalName}.png）
# 2. 64×64 透過へ正規化して本番へ
python3 tools/import_legendary_weapon_icons.py
# 3. Godot import
# godot4 --headless --editor --quit
# 4. 検証・目視（装備/鍛冶/図鑑/ドロップ）
python3 tools/verify_icon_paths.py
```

---

## 5. 作画状況

| 状態 | 本数 |
|---|---|
| 初版納品済（2026-07-09） | 10/10 |
| 天候シンクロ（2026-07-19） | +3（`stormveil_needle` / `noctumbra_fang` / `mistpierce_halberd`） |

差し替え時は WIP 上書き → `import_legendary_weapon_icons.py` 再実行。

---

## 6. 関連（別 Task）

- レジェンド防具・装飾 10 点: P3-ART-LEG-EQ-001（未着手）
- インベントリ★枠グロー: P3-UI-LEG-FRAME（任意）
