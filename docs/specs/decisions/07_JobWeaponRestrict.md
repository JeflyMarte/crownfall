# 職別武器種制限（P3-EQ-JOB-WPN-001）

**Status:** Decision 承認済（2026-07-24）／**各職2種へ更新（2026-07-26 オーナー指定）**／**greatsword→sword 統一（同日）**／**機巧士追記（2026-08-25 — P3-JOB-ENGINEER-001）**  
**上書き:** `06_キャラクター_ジョブ.md` Alpha「武器種制限なし」（P3-D024e）および旧 preferred＝ボーナスのみの前提。

---

## 1. 方針（厳格）

- 各職の `JobData.preferred_weapon_types` を **装備可能リスト** とする
- リスト外の武器種は **装備不可**（UI で区別＋装備時拒否）
- 適合ボーナス（ATK ×1.05）は従来どおり維持
- **防具／装飾は制限しない**

---

## 2. 許可表（オーナー指定）

表示「剣」＝データ `sword`（旧 `greatsword` は `sword` に統一済み）。

| 職 | 表示 | 許可 `weapon_type` |
|---|---|---|
| swordsman | 剣・双剣 | `sword`, `dual_blades` |
| vanguard | 剣・杖 | `sword`, `staff` |
| beast_tamer | 杖・弓 | `staff`, `bow` |
| alchemist | 杖・双剣 | `staff`, `dual_blades` |
| ranger | 弓・剣 | `bow`, `sword` |
| engineer | 双剣・弓 | `dual_blades`, `bow` |

`weapon_type` 空の武器は装備不可。

> **機巧士:** P3-JOB-ENGINEER-001（2026-08-25）。JobData 実装時に `preferred_weapon_types` を接続。

---

## 3. セーブ互換

ロード後、非適合の装備中武器は **外して所持のまま**（inventory に既にある前提）。自動付け替えはしない。

---

## 4. UI

- 非適合セルは暗色＋ tooltip「この職では装備できません」
- 短押し装備・詳細の「装備する」は無効／拒否（長押し詳細は可）
- 拒否時は `ui_error` SE
