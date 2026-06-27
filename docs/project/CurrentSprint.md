# CurrentSprint.md — Sprint Dashboard

---

## Sprint Name

**Postwar Ecology MVP 実装移行**（P3-D034）

---

## Goal

1 DG（モーンゲート）+ 3 ジョブ（ソードマン/レンジャー/アルケミスト）+ モックグラフィック。

---

## スコープ

| 領域 | 内容 | 状態 |
|---|---|---|
| ジョブ | ソードマン(剣/前衛)・レンジャー(弓/遠隔)・アルケミスト(杖/魔法+デバフ) | ✅ コード実装（job .tres / 既定パーティ / セーブ移行 / 簡易ヘイト） |
| 武器種 | sword / bow / staff。弓=狩猟弓+狙撃、杖=見習いの杖+呪詛弾 | ✅ 武器+スキル新規 |
| DG | モーンゲート（王都地下）difficulty 1・選択可・専用イベント3件 | ✅ 実装 |
| 敵（生物由来） | 6体: セピアハウンド/ルーンローチ/水晶ハリネズミ/冠喰いネズミ/クロックモス(E)/セルディオン(B) | ✅ 実装 |
| グラフィック | 味方3ジョブ / 敵 / BG / アイコン | **オーナー作画**（C案・高解像度 P3-D039 / 規格 `docs/art/Sprite_Production_Spec.md`） |
| 既定DG | 新規ゲーム初期=モーンゲート（P3-D034f） | ✅ 実装 |

---

## Notes

- ProjectDocs v3.6.0 / Decision P3-D034〜039
- アルケミスト: MVP は回復/バフ無し（魔法ダメージ+デバフ=呪い）
- ドット絵はオーナー作画（C案・高解像度 P3-D039 / `docs/art/Sprite_Production_Spec.md`）。コードのみ着手
- **レベル制 実装済（P3-D035a）**: 共有EXP・Lv20上限・+6HP/+2ATK/Lv・セーブ永続・拠点/Result表示
- 将来システム登録（残）: 助っ人(P3-D036 — **a=戦闘「編成3+助っ人固定枠1」+イベント助っ人 ✅完了**, **b=ガチャ/ロスター A〜D ✅完了/smoke PASS**) / ジョブ進化(P3-D037)
  - P3-D036b: 基本5職初期所持・ロスター編成3選択・gacha_token(★4=20/★3=80・天井30・重複還元)・GachaScene/RosterScene・ラン成功 1〜2 token。セーブ永続化済
  - 助っ人 Known Issue ✅解消: event_helper を敵ターゲティングから完全除外（CombatController.pick_enemy_target_member_index）
- **世界観一本化（P3-D038）進捗:** R1 完了（旧DG UI退役＋セーブ移行 / Claude）・R2 完了（旧16敵/旧3DG/旧3職を `resources/_archive/` 退避＋コード参照除去 / HQ）・**R3 コア完了**（ゲームシステム系 spec=02/05/06/08/12/13/27 と汎用イベントを新世界へ同期 / HQ）。残: B 新Biome追加。※16〜25 の WorldBible 群は「滅びた王都＝歴史上の地名」として正当に残置
- **ダンジョンはモーンゲート1本で凍結**（オーナー決定 2026-06-26）。Biome-02（ウィスパーウッド）以降は保留。以後はシステム実装に注力
- 残り 2 ジョブ（ヴァンガード/ビーストテイマー）は後続
- **ダンジョン進行 全自動化 ✅（P3-D053）**: 分岐(安全/危険/不明)撤廃・部屋自動進行(AutoProgressTimer one_shot, x1=1.2s/x2=0.6s, pause連動)・商人/イベントのみ「出発」手動・EXIT自動リザルト
- **中ボス廃止 ✅（P3-D054）**: ROOM_SEQUENCE index7=COMBAT 化・MID_BOSS固有処理除去（列挙値は温存）・ELITE追加ドロップ維持
- smoke_test PASS（R1/R2/R3 とも）
