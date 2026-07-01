# Sprite Production Spec — Crownfall（C案 / モック忠実）

**Status:** Active  
**Decision:** P3-D039 / P3-D039a / P3-D039b（2026-06-26）  
**対象:** オーナー作画用のスプライト制作標準。アートのみ。コードは HQ が対応。

---

## 1. ピクセル基準（1コマあたりの画素数）

| 種別 | セルサイズ | 用途 |
|---|---|---|
| 通常キャラ（味方ジョブ） | **96×96** | swordsman / ranger / alchemist |
| 通常敵 | **96×96** | sepia_hound / rune_roach / crystal_hedgehog / crown_eater_rat |
| エリート敵 | **128×128** | clock_moth |
| ボス | **192×192** | serdion（水晶骸竜） |
| 環境タイル | **48×48** | 床・壁・コーナー等（静止画・1枚） |
| UIアイコン | **64×64** | 武器/防具/素材/通貨（現状維持） |

> 画面論理解像度は 720×1280（縦）。上記は十分な描き込みが効くサイズ。スケールは HQ がシーン側で調整する。

---

## 2. スプライトシート規格（アニメ用）

- **形式:** 透過 PNG（32bit, アルファ付き）
- **レイアウト:** **横1列ストリップ**（高さ＝セル1つ分、幅＝セル×コマ数）
- **コマ間余白:** なし（隙間ゼロで等間隔に並べる）
- **原点/フット位置:** 各コマ内でキャラの足元を下端付近に揃える（コマ間でブレない）
- **背景:** 完全透過（白/単色背景を残さない）

### コマ順（左→右・固定）

| 区間 | コマ数 | 内容 |
|---|---|---|
| idle | 4 | 待機ループ |
| attack | 4 | 攻撃（非ループ） |
| hurt | 2 | 被弾（非ループ） |
| death | 4 | 撃破（非ループ） |
| **合計** | **14** | — |

### シート寸法（幅 = セル×14, 高さ = セル）

| 種別 | シート寸法 |
|---|---|
| 通常キャラ/敵（96） | **1344 × 96** |
| エリート（128） | **1792 × 128** |
| ボス（192） | **2688 × 192** |

> ストリップが横長すぎて描きづらい場合は、HQ に相談（複数行グリッドにも対応可）。ただし**既定は横1列**。

---

## 3. 命名と差し込み先（P3-D034g）

新シート PNG を描いたら、対応する `.tres` の参照シートを差し替える（中身の region/コマは HQ が C 基準へ更新）。

| 対象 | スプライト .tres | 推奨シート PNG 名 |
|---|---|---|
| swordsman | `resources/animation/CHR_Swordsman.tres` | `CHR_Swordsman_Sheet.png` |
| ranger | `resources/animation/CHR_Ranger.tres` | `CHR_Ranger_Sheet.png` |
| alchemist | `resources/animation/CHR_Alchemist.tres` | `CHR_Alchemist_Sheet.png` |
| sepia_hound | `resources/animation/ENM_SepiaHound.tres` | `ENM_SepiaHound_Sheet.png` |
| rune_roach | `resources/animation/ENM_RuneRoach.tres` | `ENM_RuneRoach_Sheet.png` |
| crystal_hedgehog | `resources/animation/ENM_CrystalHedgehog.tres` | `ENM_CrystalHedgehog_Sheet.png` |
| crown_eater_rat | `resources/animation/ENM_CrownEaterRat.tres` | `ENM_CrownEaterRat_Sheet.png` |
| clock_moth（Elite 128） | `resources/animation/ENM_ClockMoth.tres` | `ENM_ClockMoth_Sheet.png` |
| serdion（Boss 192） | `resources/animation/BOSS_Serdion.tres` | `BOSS_Serdion_Sheet.png` |

> 配置先フォルダ（`assets/...`）は納品時に HQ が確定。まずはサイズ・コマ規格に沿って描けば OK。

---

## 4. 制作チェックリスト

- [ ] セルサイズが §1 の規定通り
- [ ] 横1列・14コマ（idle4/attack4/hurt2/death4）
- [ ] コマ間余白ゼロ・等間隔
- [ ] 背景透過
- [ ] 足元位置がコマ間で安定

---

## 5. ガチャ助っ人立ち絵（P3-GACHA-003）

UI 用バスト立ち絵（召喚演出・編成・装備）。戦闘スプライトシートとは別。

| 項目 | 規格 |
|---|---|
| 形式 | 透過 PNG |
| 推奨サイズ | **512×512** 以上（HQ が UI スケール調整） |
| 命名 | `ART_HELPER_{helper_id}.png`（例: `ART_HELPER_helper_a.png`） |
| 配置 | `assets/gacha/portraits/` |
| 差し込み | `resources/gacha_helpers/{helper_id}.tres` の `portrait_resource_path` を更新 |

> 暫定は職バストのコピー。オーナー作画納品時は同名パスへ上書きするだけで反映される。
- [ ] ファイル名が §3 準拠
