# ロード時レリック装備消失修正（P3-FIX-RELIC-LOAD-ORDER-001）

**日付:** 2026-08-09  
**状態:** 承認（オーナー報告＝編成変更で全員のレリックが外れる）

## 要旨

編成変更そのものはレリックを触らない。真因は **Continue ロードで `owned_relics` 復元前に `normalize_all_equipped_passives` が走り、未所持扱いで装備レリックを全捨て**すること。その後の編成保存が空状態を永続化し、「編成を変えたら消えた」に見える。

## 決定

| ID | 決定 | 理由 |
|---|---|---|
| P3-FIX-RELIC-LOAD-ORDER-001-1 | `_apply_save_data` で **`owned_relics` を `_apply_roster_save` より先に復元** | normalize の `has_relic` ゲートを満たす |
| P3-FIX-RELIC-LOAD-ORDER-001-2 | `set_member_relic` は toggle せず **set 意味**（同一ID再適用で外れない） | プリセット再適用の副因を潰す |

## 非スコープ

- 未所持レリックを装備のまま残す（所持チェック自体は維持）
