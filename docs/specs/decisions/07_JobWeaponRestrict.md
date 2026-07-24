# 職別武器種制限（P3-EQ-JOB-WPN-001）

**Status:** Decision 承認済（2026-07-24 オーナー GO・推奨案A）  
**上書き:** `06_キャラクター_ジョブ.md` Alpha「武器種制限なし」（P3-D024e）および `preferred`＝ボーナスのみの前提。

---

## 1. 方針（案A・厳格）

- 各職の `JobData.preferred_weapon_types` を **装備可能リスト** とする
- リスト外の武器種は **装備不可**（UI で区別＋サーバ側でも拒否）
- 適合ボーナス（ATK ×1.05）は従来どおり維持（装備できた時点で適合）
- **防具／装飾は制限しない**（今回スコープ外）

---

## 2. 許可表（現行 JobData）

| 職 | 許可 `weapon_type` |
|---|---|
| swordsman / vanguard | `sword`, `greatsword`, `dual_blades` |
| ranger | `bow` |
| alchemist | `staff` |
| beast_tamer | `bow`, `staff` |

`weapon_type` 空の武器は装備不可。

---

## 3. セーブ互換

ロード後、非適合の装備中武器は **外して所持のまま**（inventory に既にある前提）。自動付け替えはしない。

---

## 4. UI

- 非適合セルは暗色＋ tooltip「この職では装備できません」
- 短押し装備・詳細の「装備する」は無効／拒否（長押し詳細は可）
- 拒否時は `ui_error` SE
