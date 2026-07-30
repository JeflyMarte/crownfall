# 招待状煽り文のプレイ目線化（P3-GACHA-TEASE-PLAYSTYLE-001）

**Status:** Decision 承認済（2026-07-30 オーナー「案A」GO）  
**前提:** `P3-GACHA-FEATURE-TEASE-001`（左煽り・`！`止め）  
**修正:** 2026-07-30 — helper id と表示名／パッシブの対応ズレを修正（DOC-CHAR-PASSIVE-SYNC-001）  
**修正:** 2026-07-30 — 案B 短文化＋1行UI（オーナー文面 GO）

---

## 1. 方針

Featured 左の `origin_note` を、出身・物語調ではなく **ユーザー目線で役割／戦い方が分かる一行** にする。  
**正は各 helper の `passive_id`（CombatPassives）**。名前と煽りを取り違えない。

---

## 2. 確定

| # | 項目 | 決定 |
|---|---|---|
| 1 | トーン | プレイ目線（役割・トリガー・リスクが一目） |
| 2 | 形式 | 本文のみ・末尾 `！`（`！！` 可。既存 TEASE 規約） |
| 3 | 対象 | プール11体のみ（`helper_a/b/c/e/f/i/k/m/n/o/p`） |
| 4 | UI | **1行固定**（折り返しOFF・字16・幅420・溢れたら…） |
| 5 | スコープ外 | `_omitted` 助っ人／パッシブ数値変更 |

---

## 3. 確定文面（案B・オーナー GO）

| ID | 名前 | passive_id | origin_note |
|---|---|---|---|
| helper_a | ヴァルデン | valden_iron_oath | 鉄壁の守りを誇る、頼れる守護神！！ |
| helper_b | イヴァル | ivar_trail_sight | 罠ダメを半減し、自分は無効。探索向き狩人！ |
| helper_c | セリン | serin_quick_mend | 長期戦ダンジョンが得意なヒーラー！ |
| helper_e | ミラ | mira_beast_call | 敵を拘束するデバフが得意な弓使い！ |
| helper_f | カイダ | kaida_arena_edge | ピンチになれば火力が上がるベテラン剣士！ |
| helper_i | ガルム | garm_caravan_guard | 根性でピンチを凌ぐ、不屈のタンク！ |
| helper_k | レノール | lenore_seal_echo | 高火力、低耐久の火力特化遠距離砲台！ |
| helper_m | シアン | sian_silent_line | 味方全体にバフをかける遠距離サポーター！ |
| helper_n | ボルグ | borg_gate_voice | 攻撃を華麗にかわし続ける、華麗な回避系タンク！ |
| helper_o | ネリ | neri_waterfowl_call | ペットサポートに特化した、サポーター！ |
| helper_p | 火鷹 | hodaka_blood_price | 超高ステータスだがたまに動けないピーキーな剣士！！ |
