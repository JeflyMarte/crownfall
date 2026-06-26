# Phase3-A Scope Adoption Proposal v1.1

**Status:** Approved（Completed）
**Type:** Scope Adoption
**Phase:** Phase3-A Visual Production
**Created:** 2026-06-24
**Approved:** 2026-06-24
**Decisions:** P3-D001〜P3-D007
**Based on:** Phase3A_Visual_Production_Proposal_v1.0.md / Pixel_Apprentice_Initial_Asset_Request_Pack_v1.0.md
**Approved By:** DevelopmentHQ / オーナー承認

---

## 0. 前提

Phase3-A は **ビジュアルアセット本番化フェーズ**。  
**gameplay 仕様・ゲームルール・数値は一切変更しない。**

- v1.0 の Visual Style Guide / 命名規則 / パイプラインをすべて継承する
- 本 Proposal は v1.0 をスコープ採用文書としてまとめたもの（仕様は v1.0 が正）
- 承認済み → 本ファイル（`ArtArchive/Completed/`）

---

## 1. IN / OUT スコープ

### IN スコープ（Phase3-A で実施）

| カテゴリ | 内容 |
|---|---|
| UI Theme | `production_theme.tres` 新規作成（mvp_theme.tres を置き換え） |
| UI Frames / Buttons | `UI_Frame_Panel`・`UI_Btn_*`・`UI_BG_Dark` |
| 武器アイコン | `ICO_WPN_*`（未鑑定含む） |
| 防具アイコン | `ICO_ARM_*`（未鑑定含む） |
| 装飾品アイコン | `ICO_ACC_*`（未鑑定含む） |
| 素材アイコン | `ICO_MAT_*` |
| UI アイコン | `ICO_Gold`・`ICO_HP`・`ICO_ATK`・`ICO_DEF`・`ICO_CRT` |
| 敵スプライト | 王都跡 4 種 + 白骸墓地 4 種 + Elite 1 種（SpriteSheet） |
| ボススプライト | 王都守護兵長 / 千鐘の墓守（64×64 SpriteSheet） |
| 冒険者スプライト | warrior / guardian / scout（SpriteSheet） |
| NPC スプライト | `NPC_Merchant`（立ち絵） |
| ダンジョン Tileset | 王都跡（P0）/ 白骸墓地（P1）|
| Objects / Props | TreasureChest / ExitGate / Altar / Bell など |
| VFX | Hit / Heal / Treasure_Open など（P1/P2） |
| Scene 接続実装 | アセット完成後に AnimatedSprite2D / GPUParticles2D 接続（Task 別途） |

### OUT スコープ（Phase3-A では実施しない）

| 項目 | 対象フェーズ | 理由 |
|---|---|---|
| 地下工廠 Tileset | Phase3-B | 3 ダンジョン目はコンテンツ追加フェーズ |
| 状態異常 VFX / 属性演出 | Phase3-B | gameplay システム未実装 |
| Legendary 発光エフェクト | Phase3-B | Legendary 演出 Decision 未確定 |
| ボス固有演出 VFX | Phase3-B | Phase3-A ではボス Idle/Attack アニメのみ |
| Job 別 Attack アニメ差分 | Phase3-B | Phase3-A は汎用 Attack 1 種 |
| Codex カテゴリアイコン | Phase3-B 以降 | UI 設計と連動 |
| 拠点 UI 拡張 | Beta | 武器庫・遺産の間等 |
| 遺産の地図（ノード UI） | Beta | History / World Lore と連動 |
| UI フルリデザイン | Phase4 Polish | – |
| BGM / SE | Phase4 以降 | – |
| gameplay ロジック変更 | 禁止（Phase3-A 全期間） | CombatVision 原則維持 |

---

## 2. Exit Criteria

| # | 条件 | 確認方法 |
|---|---|---|
| EC-1 | P0 アセット全点が `assets/` に配置され Godot インポートエラーなし | Godot Editor でインポート確認 |
| EC-2 | `production_theme.tres` が作成され、既存シーン（BaseScene / DungeonScene）に適用されている | Godot 実行・目視 |
| EC-3 | 王都跡を完走したとき、全敵・ボスが production スプライトで表示される | プレイテスト |
| EC-4 | 装備 UI（AppraisalScene / EquipmentScene）で production アイコンが表示される | プレイテスト |
| EC-5 | 未鑑定アイテムに Unidentified アイコンが表示される | AppraisalScene 確認 |
| EC-6 | 王都跡 Tileset が DungeonScene に適用されている | 目視 |
| EC-7 | VFX（FX_Hit_Normal / FX_Heal）が戦闘中に再生される | プレイテスト |
| EC-8 | P1 アセット（白骸墓地・冒険者）の制作が完了している | アセット一覧照合 |

Phase3-A 完了 = EC-1〜EC-7 が **全 PASS**。  
EC-8 は P1 完了タイミングで別途確認。

---

## 3. Pixel Apprentice 向けアセット要求リスト

### 3-1. 優先定義

| 優先 | 意味 |
|---|---|
| **P0** | Phase3-A 開始に必須。P0 全点承認前に P1 着手禁止 |
| **P1** | P0 承認後に着手。Phase3-A 完了条件 |
| **P2** | P1 完了後。Phase3-A 内で余力があれば制作 |

### 3-2. アセットリスト（優先順）

#### P0 — UI 基盤（全シーンに影響）

| ファイル名 | 種別 | Canvas | 担当 | 期限目安 |
|---|---|---|---|---|
| `UI_Frame_Panel_Base.png` | UI Frame（9-slice） | 48×48 以上 | Pixel Apprentice | P0 Batch 優先 |
| `UI_Btn_Normal.png` | Button | 128×32 | Pixel Apprentice | P0 Batch 優先 |
| `UI_Btn_Pressed.png` | Button | 128×32 | Pixel Apprentice | P0 Batch 優先 |
| `UI_BG_Dark.png` | Scene 背景 | 1280×720 | Pixel Apprentice | P0 Batch 優先 |

#### P0 — アイコン類

| ファイル名 | 種別 | Canvas | 担当 | 期限目安 |
|---|---|---|---|---|
| `ICO_WPN_IronSword.png` | 武器アイコン | 64×64 | Pixel Apprentice | P0 Batch |
| `ICO_WPN_RustedBlade.png` | 武器アイコン | 64×64 | Pixel Apprentice | P0 Batch |
| `ICO_WPN_Unidentified.png` | 武器未鑑定 | 64×64 | Pixel Apprentice | P0 Batch |
| `ICO_ARM_LeatherArmor.png` | 防具アイコン | 64×64 | Pixel Apprentice | P0 Batch |
| `ICO_ARM_Unidentified.png` | 防具未鑑定 | 64×64 | Pixel Apprentice | P0 Batch |
| `ICO_ACC_SilverRing.png` | 装飾品アイコン | 64×64 | Pixel Apprentice | P0 Batch |
| `ICO_ACC_Unidentified.png` | 装飾品未鑑定 | 64×64 | Pixel Apprentice | P0 Batch |
| `ICO_Gold.png` | UI アイコン | 32×32 | Pixel Apprentice | P0 Batch |
| `ICO_HP.png` | UI アイコン | 32×32 | Pixel Apprentice | P0 Batch |
| `ICO_MAT_RelicShard.png` | 素材アイコン | 64×64 | Pixel Apprentice | P0 Batch |

#### P0 — ダンジョン王都跡 Tileset（コア）

| ファイル名 | 種別 | Canvas | 担当 | 期限目安 |
|---|---|---|---|---|
| `TILE_RoyalRuins_Floor_01.png` | Tile | 32×32 | Pixel Apprentice | P0 Batch |
| `TILE_RoyalRuins_Wall_01.png` | Tile | 32×32 | Pixel Apprentice | P0 Batch |
| `TILE_RoyalRuins_Corner_Inner.png` | Tile | 32×32 | Pixel Apprentice | P0 Batch |
| `TILE_RoyalRuins_Corner_Outer.png` | Tile | 32×32 | Pixel Apprentice | P0 Batch |
| `OBJ_TreasureChest_Closed.png` | Object | 32×32 | Pixel Apprentice | P0 Batch |
| `OBJ_ExitGate_RoyalRuins.png` | Object | 32×32 | Pixel Apprentice | P0 Batch |

#### P0 — ボス（王都跡完走体験）

| ファイル名 | 種別 | Canvas | SpriteSheet 構成 | 担当 | 期限目安 |
|---|---|---|---|---|---|
| `BOSS_RoyalGuardCaptain_Sheet.png` | Boss SpriteSheet | 64×64 / frame | Idle×6, Attack×8, Hurt×3, Death×8 | Pixel Apprentice | P0 Batch |

#### P1 — 敵スプライト

| ファイル名 | 対応ダンジョン | Canvas/frame | SpriteSheet 構成 | 担当 |
|---|---|---|---|---|
| `ENM_FallenSoldier_Sheet.png` | 王都跡 | 32×32 | Idle×4, Attack×4, Hurt×2, Death×4 | Pixel Apprentice |
| `ENM_RuinedGuard_Sheet.png` | 王都跡 | 32×32 | 同上 | Pixel Apprentice |
| `ENM_RuinsLooter_Sheet.png` | 王都跡 | 32×32 | 同上 | Pixel Apprentice |
| `ENM_RustedKnight_Sheet.png` | 王都跡（elite 兼用） | 32×32 | 同上 | Pixel Apprentice |
| `ENM_BoneWalker_Sheet.png` | 白骸墓地 | 32×32 | 同上 | Pixel Apprentice |
| `ENM_GraveBat_Sheet.png` | 白骸墓地 | 32×32 | 同上 | Pixel Apprentice |
| `ENM_HollowGravedigger_Sheet.png` | 白骸墓地 | 32×32 | 同上 | Pixel Apprentice |
| `ENM_PaleHound_Sheet.png` | 白骸墓地 | 32×32 | 同上 | Pixel Apprentice |
| `ENM_OssuaryKnight_Sheet.png` | 白骸墓地（elite 専用） | 32×32 | 同上 | Pixel Apprentice |

#### P1 — ボス（白骸墓地）・冒険者

| ファイル名 | 種別 | Canvas/frame | SpriteSheet 構成 | 担当 |
|---|---|---|---|---|
| `BOSS_Gravekeeper_Sheet.png` | Boss | 64×64 | Idle×6, Attack×8, Hurt×3, Death×8 | Pixel Apprentice |
| `CHR_Warrior_Sheet.png` | 冒険者 | 32×32 | Idle×4, Attack×6, Hurt×3, Death×6 | Pixel Apprentice |
| `CHR_Guardian_Sheet.png` | 冒険者 | 32×32 | 同上 | Pixel Apprentice |
| `CHR_Scout_Sheet.png` | 冒険者 | 32×32 | 同上 | Pixel Apprentice |

#### P1 — ダンジョン王都跡 Tileset（補完）・白骸墓地 Tileset

| ファイル名 | 種別 | Canvas | 担当 |
|---|---|---|---|
| `TILE_RoyalRuins_Floor_02.png` | Tile | 32×32 | Pixel Apprentice |
| `TILE_RoyalRuins_Floor_Cracked.png` | Tile | 32×32 | Pixel Apprentice |
| `TILE_RoyalRuins_Wall_02.png` | Tile | 32×32 | Pixel Apprentice |
| `TILE_Graveyard_Floor_01.png` | Tile | 32×32 | Pixel Apprentice |
| `TILE_Graveyard_Floor_02.png` | Tile | 32×32 | Pixel Apprentice |
| `TILE_Graveyard_Wall_01.png` | Tile | 32×32 | Pixel Apprentice |
| `TILE_Graveyard_Wall_Tombstone.png` | Tile | 32×32 | Pixel Apprentice |
| `TILE_Graveyard_Corner_Inner.png` | Tile | 32×32 | Pixel Apprentice |
| `TILE_Graveyard_Corner_Outer.png` | Tile | 32×32 | Pixel Apprentice |
| `OBJ_TreasureChest_Open.png` | Object | 32×32 | Pixel Apprentice |
| `OBJ_ExitGate_Graveyard.png` | Object | 32×32 | Pixel Apprentice |
| `OBJ_Altar_Ruined.png` | Object | 32×32 | Pixel Apprentice |
| `ICO_MAT_EliteRelicShard.png` | 素材アイコン | 64×64 | Pixel Apprentice |
| `ICO_MAT_AncientBone.png` | 素材アイコン | 64×64 | Pixel Apprentice |
| `ICO_ATK.png` | UI アイコン | 32×32 | Pixel Apprentice |
| `ICO_DEF.png` | UI アイコン | 32×32 | Pixel Apprentice |
| `ICO_CRT.png` | UI アイコン | 32×32 | Pixel Apprentice |
| `UI_Btn_Disabled.png` | Button | 128×32 | Pixel Apprentice |
| `FX_Hit_Normal.png` | VFX SpriteSheet | 32×32 | Pixel Apprentice |
| `FX_Hit_Critical.png` | VFX SpriteSheet | 32×32 | Pixel Apprentice |
| `FX_Heal.png` | VFX SpriteSheet | 32×32 | Pixel Apprentice |

#### P2 — 余力対応

| ファイル名 | 種別 | Canvas | 担当 |
|---|---|---|---|
| `TILE_RoyalRuins_Wall_Pillar.png` | Tile | 32×32 | Pixel Apprentice |
| `ICO_MAT_CursedIron.png` | 素材アイコン | 64×64 | Pixel Apprentice |
| `NPC_Merchant.png` | NPC 立ち絵 | 32×32 | Pixel Apprentice |
| `FX_Hit_Bleed.png` | VFX SpriteSheet | 32×32 | Pixel Apprentice |
| `FX_Buff_Attack.png` | VFX SpriteSheet | 32×32 | Pixel Apprentice |
| `FX_Treasure_Open.png` | VFX SpriteSheet | 64×32 | Pixel Apprentice |
| `TILE_RoyalRuins_Wall_Arch.png` | Tile | 32×32 | Pixel Apprentice |

---

## 4. mvp_theme.tres → production_theme.tres 移行方針

**実装はしない（方針のみ）。**

### 4-1. 現行 mvp_theme.tres の状態

| 設定 | 現行値 | 目標値 |
|---|---|---|
| Button 角丸 | 3px | 0〜2px（ハードエッジ優先） |
| Border 色（Normal） | `#727283`（Stone Mid 系） | `#7a5c28`（Bronze） |
| BG 色（Normal） | `#262633` | `#12121a`（より暗く） |
| Label font_color | `#ebebeb` | Bone White `#d4cbb8` |
| Pressed 状態 BG | `#141420` | 維持可（暗め） |
| Disabled BG | `#141419` | 維持可 |

### 4-2. 移行アプローチ

1. `assets/ui/production_theme.tres` を新規作成（mvp_theme.tres をコピーして差分のみ更新）
2. 各 Scene の Theme プロパティを production_theme.tres に差し替える
3. mvp_theme.tres は Phase3-A 完了まで保持（ロールバック用）
4. Phase3-A EC-2 確認後に mvp_theme.tres を廃止

### 4-3. 実装 Task 化が必要な作業

| 作業 | 担当 | 備考 |
|---|---|---|
| production_theme.tres 作成 | Impl（CC） | UI Frames 完成後に実施 |
| 各 Scene へのテーマ適用 | Impl（CC） | StyleBoxTexture の 9-slice 設定含む |
| Font 設定（Bitmap Font 導入） | Impl（CC） | 要 HQ Decision（§5 参照） |

---

## 5. Phase3-A / Phase3-B の境界

| 項目 | Phase3-A | Phase3-B |
|---|---|---|
| gameplay ロジック | **変更禁止** | 状態異常・属性・Combat Depth |
| アセット | 本番化（全カテゴリ） | 追加アセット（工廠・新敵・固有演出） |
| Scene 接続 | AnimatedSprite2D / GPUParticles2D 接続のみ | 新 Scene / システム追加 |
| VFX | Hit / Heal / Treasure の基本 FX のみ | 状態異常 FX・ボス固有演出 |
| ダンジョン Tileset | 王都跡（P0）・白骸墓地（P1） | 地下工廠（3 DG 目） |
| スクリプト変更 | **原則禁止**（バグ修正のみ HQ 判断） | Phase3-B Task で指定 |

---

## 6. 確定 Decision（P3-D002〜P3-D007）

| # | 論点 | **確定** |
|---|---|---|
| **P3-D002** | 素材アイコンサイズ | **全アイコン 64×64 キャンバス**（素材含む。表示は UI でスケール） |
| **P3-D003** | サイズサフィックス | **なし**（`ICO_WPN_IronSword.png` 形式） |
| **P3-D004** | Bone Walker 命名 | **`ENM_BoneWalker_Sheet`**（`ENM_Skeleton` 不採用） |
| **P3-D005** | Bitmap Font | **Phase3-A 開始時はシステムフォント**。UI Frame 承認後 Batch 2 で検討 |
| **P3-D006** | TileSet | **手動マッピング**（AutoTile は Phase3-B 工廠 DG で検討） |
| **P3-D007** | P0 Batch 分割 | **3 段階** — (1) UI Frame → (2) Icons → (3) Tileset+Sprites |

### P0 発注順（P3-D007）

| Batch | 内容 | 承認ゲート |
|---|---|---|
| **Batch 1** | `UI_Frame_Panel_Base`・`UI_Btn_*`・`UI_BG_Dark` | HQ 目視承認後 Batch 2 へ |
| **Batch 2** | P0 アイコン全点（`ICO_*`） | HQ 承認後 Batch 3 へ |
| **Batch 3** | 王都跡 Tileset・Objects・`BOSS_RoyalGuardCaptain_Sheet` | Phase3-A P0 完了判定 |

---

## 7. 変更履歴

| 版 | 日付 | 内容 |
|---|---|---|
| v1.1 | 2026-06-24 | Proposal 起票（P3-Prep-001） |
| v1.1 Completed | 2026-06-24 | Scope Adoption 承認（P3-D001〜007） |
