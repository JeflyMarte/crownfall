# Crownfall — Pixel Apprentice Asset Request: Batch 7 (Graveyard Tileset + Boss + CHR)

**Status:** Ready to Send
**Batch:** 7 (P1 — Graveyard + Boss + CHR + 補完 Icons)
**Created:** 2026-06-24
**Based on:** Phase3A_Scope_Adoption_Completed_v1.1.md §3-2 P1
**Impl Task:** P3-A-007 Tile, P3-A-008
**Do not start:** until Batch 6 is approved (VFX)

---

## Overview

Batch 7 is the final major asset batch for Phase3-A. It covers four groups:

1. **白骸墓地（Graveyard）Tileset** — floor, wall, objects（Impl Task: P3-A-007 Tile）
2. **Boss: 千鐘の墓守（Gravekeeper）** — boss sprite sheet（Impl Task: P3-A-008）
3. **冒険者（CHR）スプライト × 3** — Warrior / Guardian / Scout（Impl Task: P3-A-008）
4. **補完アイコン** — batch2 で未納の P1 アイコン（Impl: IconPaths.gd に接続済み）

All groups share the same production rules. Deliver all assets in one folder.

---

## Style Reference

Same as all prior batches. Graveyard-specific direction:

**白骸墓地 カラーパレット（追加）:**

| Name | Hex | Use |
|---|---|---|
| Grave Stone | `#3a3a4a` | 墓石・壁タイル |
| Moss Dark | `#2a3a2a` | 苔・床の暗部 |
| Moss Light | `#4a6a4a` | 苔・草の明部 |
| Bone Fragment | `#c8b89a` | 骨・石灰岩アクセント |
| Night Sky | `#1a1a2a` | 空・背景 |

General Crownfall palette（Bronze, Bone White, Void Black など）は全 batch 共通。

---

## Production Rules

| Rule | Requirement |
|---|---|
| File format | PNG |
| Color mode | RGB / 8-bit |
| Compression | Lossless |
| Anti-aliasing | None |
| Filter (Godot) | Nearest / Pixel |
| Filename | Exactly as specified. No size suffix. |

---

## Group 1 — Graveyard Tileset

**配置先:** `assets/dungeon/graveyard/batch7/`

### Summary Table

| File | Canvas | 9-slice | Notes |
|---|---|---|---|
| `TILE_Graveyard_Floor_01.png` | 32×32 | No | 草・土混合床（基本） |
| `TILE_Graveyard_Floor_02.png` | 32×32 | No | 砂利・石畳床（亜種） |
| `TILE_Graveyard_Wall_01.png` | 32×32 | No | 朽ちた石壁 |
| `TILE_Graveyard_Wall_Tombstone.png` | 32×32 | No | 墓石つき壁 |
| `TILE_Graveyard_Corner_Inner.png` | 32×32 | No | 内角 |
| `TILE_Graveyard_Corner_Outer.png` | 32×32 | No | 外角 |
| `OBJ_TreasureChest_Open.png` | 32×32 | No | 開いた宝箱 |
| `OBJ_ExitGate_Graveyard.png` | 32×32 | No | 墓地の出口ゲート |
| `OBJ_Altar_Ruined.png` | 32×32 | No | 崩れた祭壇 |

**Tile design notes:**
- Floor tiles must tile seamlessly（4 方向）— no directional lighting
- Wall tiles: top-down view（見下ろし型）。墓地らしい朽ちた石造り
- TILE_Graveyard_Wall_Tombstone: 壁タイルの中に墓石のシルエットが溶け込んでいる（装飾として）
- OBJ_Altar_Ruined: 宝箱部屋または Special room で配置。祭壇が崩壊している状態
- All objects: transparent background, centered in 32×32 canvas

---

## Group 2 — Boss: 千鐘の墓守（Gravekeeper）

**配置先:** `assets/dungeon/graveyard/batch7/`

| File | Canvas/frame | Sheet size | Frames |
|---|---|---|---|
| `BOSS_Gravekeeper_Sheet.png` | 64×64 | 1600×64 | Idle×6, Attack×8, Hurt×3, Death×8 |

**SpriteSheet layout（横ストリップ、左 → 右）:**

| アニメ | フレーム数 | 列 |
|---|---|---|
| Idle | 6 | 0〜5 |
| Attack | 8 | 6〜13 |
| Hurt | 3 | 14〜16 |
| Death | 8 | 17〜24 |

合計 25 フレーム × 64px = 1600px 幅。

**Character design notes:**
- 千鐘の墓守（Gravekeeper）= 巨大な骸骨の墓守番。古い儀礼の鎧をまとい、鎌または鎖を武器にする
- スタイル: 骨格が露出、朽ちた鎧のパーツが体に付着、空洞の目が暗く光る
- サイズ: 64×64 フレーム内で縦方向にほぼいっぱいに描く（王都守護兵長と同クラス）
- Idle: わずかに揺れる（呼吸のような動き）
- Attack: 武器を振り下ろす or 鎖を投げる（1〜4 フレームで予備動作、5〜8 で攻撃）
- Hurt: のけぞり → 回復体勢（3 フレーム、速め）
- Death: 崩壊・消滅（骨が散らばるまたは霧のように消える、8 フレームで完結）

---

## Group 3 — 冒険者スプライト（CHR）

**配置先:** `assets/characters/batch7/`

| File | Canvas/frame | Sheet size | Frames |
|---|---|---|---|
| `CHR_Warrior_Sheet.png` | 32×32 | 608×32 | Idle×4, Attack×6, Hurt×3, Death×6 |
| `CHR_Guardian_Sheet.png` | 32×32 | 608×32 | 同上 |
| `CHR_Scout_Sheet.png` | 32×32 | 608×32 | 同上 |

**SpriteSheet layout（横ストリップ）:**

| アニメ | フレーム数 | 列 |
|---|---|---|
| Idle | 4 | 0〜3 |
| Attack | 6 | 4〜9 |
| Hurt | 3 | 10〜12 |
| Death | 6 | 13〜18 |

合計 19 フレーム × 32px = 608px 幅。

**Character design notes:**

| キャラ | 武器 | 特徴 |
|---|---|---|
| Warrior（戦士） | 片手剣 + 盾 | 重装甲、力強い動き |
| Guardian（守護者） | 大盾 + 短剣 | 最重装、防御姿勢中心 |
| Scout（斥候） | 短剣 × 2 または弓 | 軽装、素早い動き |

共通:
- 全員 top-down スプライト（見下ろし型）
- Attack は武器を振る → 元の姿勢に戻る、6 フレームで完結
- Death は倒れ込む / 消滅するまで、6 フレームで完結
- 3 キャラは同一シルエット構造でも可（コスト削減）、ただし武器が識別できること

---

## Group 4 — 補完アイコン（batch2 未納分）

**配置先:** `assets/ui/batch7/`

| File | Canvas | 内容 |
|---|---|---|
| `ICO_ARM_BoneArmor.png` | 64×64 | 骨の鎧アイコン |
| `ICO_MAT_EliteRelicShard.png` | 64×64 | 上位遺物の欠片アイコン |
| `ICO_MAT_AncientBone.png` | 64×64 | 古骨アイコン |
| `ICO_MAT_CursedIron.png` | 64×64 | 呪われた鉄アイコン |
| `ICO_MAT_Leather.png` | 64×64 | 革アイコン |
| `ICO_ATK.png` | 32×32 | 攻撃力 UI アイコン（剣 or 拳） |
| `ICO_DEF.png` | 32×32 | 防御力 UI アイコン（盾） |
| `ICO_CRT.png` | 32×32 | クリティカル率 UI アイコン（星 or 閃光） |
| `UI_Btn_Disabled.png` | 128×32 | ボタン無効状態（Btn_Normal より暗い・半透明感） |

Icon design notes:
- 全アイコン: 64×64 キャンバス内 48×48 程度のセーフエリアに収める
- 素材アイコンは入手物の実物イメージ（骨ならば骨片など）
- UI アイコン（ATK/DEF/CRT）は 32×32 キャンバス、シンボル的で読みやすく
- `UI_Btn_Disabled.png`: `UI_Btn_Normal.png` と同構造・同サイズ、Bronze ボーダーをより暗く（`#4a3818`）、内部を半透明感のあるダーク（グレーがかった暗色）に

---

## Delivery

```
batch7/
├── TILE_Graveyard_Floor_01.png
├── TILE_Graveyard_Floor_02.png
├── TILE_Graveyard_Wall_01.png
├── TILE_Graveyard_Wall_Tombstone.png
├── TILE_Graveyard_Corner_Inner.png
├── TILE_Graveyard_Corner_Outer.png
├── OBJ_TreasureChest_Open.png
├── OBJ_ExitGate_Graveyard.png
├── OBJ_Altar_Ruined.png
├── BOSS_Gravekeeper_Sheet.png
├── CHR_Warrior_Sheet.png
├── CHR_Guardian_Sheet.png
├── CHR_Scout_Sheet.png
├── ICO_ARM_BoneArmor.png
├── ICO_MAT_EliteRelicShard.png
├── ICO_MAT_AncientBone.png
├── ICO_MAT_CursedIron.png
├── ICO_MAT_Leather.png
├── ICO_ATK.png
├── ICO_DEF.png
├── ICO_CRT.png
└── UI_Btn_Disabled.png
```

合計 22 ファイル。

---

## Acceptance Criteria

| Criterion | Requirement |
|---|---|
| Tile seamless | TILE_* は 4 方向継ぎ目なし |
| Transparency | OBJ_* / CHR_* / ICO_* / FX_* はすべて透明背景 |
| Boss sheet | 25 フレーム × 64px = 1600×64 px |
| CHR sheets | 19 フレーム × 32px = 608×32 px |
| No anti-aliasing | 全アセット共通 |
| Naming | 上記 22 ファイル名に完全一致 |

---

## Priority Order

大きなバッチなので以下の順で進めてください:

1. **TILE_Graveyard_*** + **OBJ_*** — 白骸墓地 Tileset（P3-A-007 Tile に直接影響）
2. **CHR_*** — 冒険者スプライト（P3-A-008、戦闘 UI に影響）
3. **BOSS_Gravekeeper_Sheet** — ボス（P3-A-008）
4. **ICO_*** / **UI_Btn_Disabled** — アイコン補完（独立して着手可）

---

## Notes for Pixel Apprentice

- Batch 6（VFX 2 点）と並行して本発注書を受け取っていますが、Batch 6 を先に完成させてください。
- Batch 7 は Phase3-A 最終バッチです。これで主要アセット発注が完了します。
- 質問があれば遠慮なく。特に墓守ボスのデザインで不明点があれば事前確認してください。
- Full scope: `docs/archives/ArtArchive/Completed/Phase3A_Scope_Adoption_Completed_v1.1.md`
