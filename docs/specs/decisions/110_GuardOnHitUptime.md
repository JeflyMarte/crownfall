# 被弾ガード半永久化の抑制（P3-BAL-GUARD-ONHIT-UPTIME-001）

**日付:** 2026-08-09  
**状態:** 承認（オーナー＝案A・パッシブ側調整）

## 要旨

被弾で `guard`（被ダメ×0.5）を付与する装備が、再付与による持続リセット＋短い CD でほぼ常時半減になっていた。敵ディスペルより先にパッシブ側で uptime を制限する。

## 決定

| ID | 決定 | 理由 |
|---|---|---|
| P3-BAL-GUARD-ONHIT-UPTIME-001-1 | **盾役の構え** CD 5→**12**。`skip_if_status_active`（guard 中は不発） | 主因のタンク防具 |
| P3-BAL-GUARD-ONHIT-UPTIME-001-2 | **霊廟の守護** CD 6→**10**＋同 skip | 同型の被弾ガード |
| P3-BAL-GUARD-ONHIT-UPTIME-001-3 | **澱みの霧ガード** CD 8→**14**＋同 skip | 武器だが同機構 |
| P3-BAL-GUARD-ONHIT-UPTIME-001-4 | **`guard` の ×0.5 / 2tick は据置** | 瞬間の半減感は残す |
| P3-BAL-GUARD-ONHIT-UPTIME-001-5 | **敵バフ剥がしは非スコープ**（必要なら別GO） | 案Bは後回し |

## 非スコープ

- 戦闘開始／味方死亡のパーティ `guard`（単発）
- 防御スロット行動の `guard`（既に重ね掛けガードあり）
