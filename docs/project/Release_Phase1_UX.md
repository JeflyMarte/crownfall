# 第1弾配信 — UX・安定性パッチ

**Status:** オーナー GO（2026-09-01）  
**第2弾:** 征討・機巧士・魔晶石発掘などコンテンツ（`main` 先端）

---

## 1. 第1弾に含める

| 項目 | 内容 | 備考 |
|---|---|---|
| 装備袋上限 | **1000** | `Constants.MAX_EQUIPMENT_INVENTORY` |
| 軽量モード強化 | 30fps・静止天候・VFX 抑止 | `16f48cf1` ほか（1.0.3 後コミット） |
| 通常モード発熱対策 | モバイル 45fps・天候粒子削減 | `90279d59` |
| 無限 11F フリーズ対策 | 明け後処理 2 フレーム分割 | `45f9b6ae` |
| **無限天候削除（案A）** | 抽選・VFX・戦闘補正すべてオフ | **P3-D101-7** |

### 1.0.3 に既に入っていれば再配信不要

- 袋 400・仮想スクロール・N/R 自動分解・保存パーティ（build15 要確認）

---

## 2. 第1弾で **出さない**（第2弾）

- 征討 天望の塔／星炉火口
- 機巧士 3（ドット・肖像・BGM・ガチャ）
- 魔晶石発掘
- 征討セット装備・Boss 新規アート・専用 BGM 大量

---

## 3. ビルド時の Constants 切替（推奨）

第1弾用エクスポート直前に `scripts/core/Constants.gd` を調整する。

```gdscript
## 第1弾: 征討を UI 非表示（データは PCK に含めても可）
const APEX_CONQUEST_PLAYABLE_IDS: Array[String] = []

## 第1弾: 発掘入口を隠す
const CRYSTAL_EXCAVATE_PLAYABLE: bool = false
```

| 定数 | 第1弾 | 第2弾 | 注意 |
|---|---|---|---|
| `APEX_CONQUEST_PLAYABLE_IDS` | `[]` | 天望＋星炉 id | 寄り道オミットは維持 |
| `CRYSTAL_EXCAVATE_PLAYABLE` | `false` | `true` | — |
| `GACHA_HELPERS_PLAYABLE` | **`true` 維持** | `true` | false にするとガチャ全体が消える |
| 機巧士アセット | 第2弾まで `eebc2461` をビルドに含めない **または** 同梱可（プールに出ないよう第2弾まで） | 同梱 | フラグだけでは3人を個別 OFF 不可 |

---

## 4. ブランチ戦略（推奨）

1. **App Store 1.0.3（build15）** を基点に `release/ux-patch-1` を切る  
2. UX コミットのみ cherry-pick ＋ 所持 1000 ＋ 無限天候削除（P3-D101-7）  
3. 上記 Constants を第1弾用にセットしてエクスポート  
4. 第2弾は `main` 先端＋Constants を第2弾値に戻してエクスポート  

`main` 開発中は征討・発掘は **ON** のまま（現行デフォルト）。

---

## 5. 実機確認（第1弾）

- [ ] 軽量 ON/OFF — 発熱・fps  
- [ ] 虚脈 11F 前後 — 暗転固まりなし  
- [ ] 無限 DG — 天候ログ・VFX・HUD 天候アイコンなし  
- [ ] 装備 900 件超 — 一覧スクロール  
- [ ] 征討タブ／発掘入口 — 第1弾ビルドで非表示  

---

## 6. SSOT

- 装備上限: `89_EquipmentInventoryCap.md`（1000）  
- 無限天候: `CombatWeather.gd` ヘッダ／`DungeonController._roll_run_weather`  
- 配信フラグ: `Constants.gd`（本ファイル §3）
