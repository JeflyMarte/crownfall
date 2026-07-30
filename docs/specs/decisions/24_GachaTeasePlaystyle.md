# 招待状煽り文のプレイ目線化（P3-GACHA-TEASE-PLAYSTYLE-001）

**Status:** Decision 承認済（2026-07-30 オーナー「案A」GO）  
**前提:** `P3-GACHA-FEATURE-TEASE-001`（左煽り・`！`止め）  
**修正:** 2026-07-30 — helper id と表示名／パッシブの対応ズレを修正（DOC-CHAR-PASSIVE-SYNC-001）

---

## 1. 方針

Featured 左の `origin_note` を、出身・物語調ではなく **ユーザー目線で役割／戦い方が分かる一行** にする。  
**正は各 helper の `passive_id`（CombatPassives）**。名前と煽りを取り違えない。

---

## 2. 確定

| # | 項目 | 決定 |
|---|---|---|
| 1 | トーン | プレイ目線（役割・トリガー・リスクが一目） |
| 2 | 形式 | 本文のみ・末尾 `！`（既存 TEASE 規約） |
| 3 | 対象 | プール11体のみ（`helper_a/b/c/e/f/i/k/m/n/o/p`） |
| 4 | スコープ外 | `_omitted` 助っ人／パッシブ数値変更／煽りUIレイアウト |

---

## 3. 確定文面（案A・id／パッシブ対応済み）

| ID | 名前 | passive_id | origin_note |
|---|---|---|---|
| helper_a | ヴァルデン | valden_iron_oath | 被ダメを抑え、ピンチで味方全体も守る盾役！ |
| helper_b | イヴァル | ivar_trail_sight | 罠などの探索ダメージを受けない、探索向き狩人！ |
| helper_c | セリン | serin_quick_mend | 探索に入るたび味方をまとめて回復するサポ錬金！ |
| helper_e | ミラ | mira_beast_call | 攻撃で敵を遅くする、妨害寄りの獣使い！ |
| helper_f | カイダ | kaida_arena_edge | HPが減るほど火力が上がる、追い込み型の剣士！ |
| helper_i | ガルム | garm_caravan_guard | たまに致死を耐える、粘り強い盾役！ |
| helper_k | レノール | lenore_seal_echo | 与ダメは高いが被ダメも増える、攻めの錬金！ |
| helper_m | シアン | sian_silent_line | 戦闘開始で味方全体を少し強化する開幕バッファー！ |
| helper_n | ボルグ | borg_gate_voice | 回避が高めの、かわして立つ盾役！ |
| helper_o | ネリ | neri_waterfowl_call | オトモが生きている間、オトモを強化する指揮型！ |
| helper_p | 火鷹 | hodaka_blood_price | 撃破するたび強くなる高火力。たまに動かないリスクあり！ |
