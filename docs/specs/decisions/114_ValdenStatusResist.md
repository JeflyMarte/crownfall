# ヴァルデン：鉄誓を状態異常耐性へ（P3-BAL-VALDEN-STATUS-RESIST-001）

**日付:** 2026-08-09  
**状態:** 承認（オーナー＝被ダメ軽減が過強のため状態異常耐性へ変更）

## 要旨

`鉄誓の壁` の常時パーティ被ダメ×0.90 を廃止し、**味方全体の状態異常付与率減衰**に差し替える。有益バフ（guard 等）は対象外。

## 決定

| ID | 決定 | 理由 |
|---|---|---|
| P3-BAL-VALDEN-STATUS-RESIST-001-1 | `party_incoming_mult` を削除 | タンク覇権の過強を解消 |
| P3-BAL-VALDEN-STATUS-RESIST-001-2 | **`party_incoming_status_chance_mult=0.60`**（付与成功率×0.6＝耐性40%） | ミスト異常帯などで差別化。完全無効ではない |
| P3-BAL-VALDEN-STATUS-RESIST-001-3 | 有益バフは減衰しない | 味方の防御／鼓舞を阻害しない |
| P3-BAL-VALDEN-STATUS-RESIST-001-4 | 限凸は被ダメ軽減と同型に耐性幅を拡大 | 既存 LB 規約 |

## 上書き

- `93_JobBuildThemesPassives` のヴァルデン行
- `P3-BAL-VALDEN-NO-HEAL-001` の「被ダメ軽減据置」
