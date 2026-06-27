# CurrentState.md — Crownfall Project Dashboard

---

## Last Update

2026-06-28（**Phase 3-B' システム実装 ほぼ完了**: ガチャ/ロスター・ジョブ進化・スプライト取り込み・ダンジョン全自動化(P3-D053)・中ボス廃止(P3-D054)・敵アニメ配線・助っ人targeting修正・graveyard残骸一掃(P3-Cleanup-001)・残り2ジョブ スキル(P3-D066)・Codex5段階監査・武器クラフト実機能化(P3-D067)。→ Phase 3-A ポリッシュへ）

---

## Project Version

ProjectDocs **v3.6.0**

---

## Current Phase

**Phase3-B — Content Expansion**（**着手** — P3-D025。3-A 全画面 polish は後 Phase）

---

## Current Milestone

**Phase3-B-M2** — **完了**（P3-D023）— 属性5種 + 状態6種

---

## Active Tasks

| ID | 内容 | 状態 |
|---|---|---|
| — | P3-D024 spec 同期 | **完了** |
| P3-TH-001 | 簡易ヘイト | **完了** |
| P3-HW-001 | 聖属性武器 | **完了** |
| P3-D024b | 簡易ヘイト | **完了**（P3-TH-001） |
| P3-D024j | 聖属性武器 | **完了**（P3-HW-001） |
| P3-D024i | 属性 vs 状態チュートリアル | **完了**（P3-CX-001） |
| P3-HW-002 | slash_attack bleed 削除 | **完了** |
| P3-UI2-001 | 戦闘状態テキスト表示 | **完了** |
| P3-APPR-001 | 一括鑑定 | **完了** |
| P3-INIT-001 | イニシアチブ Phase 1 | **完了** |
| P3-EQ-CMP-001 | 装備比較 1 行 | **完了** |
| P3-UI2-002 | 状態ラベル折り返し | **完了** |
| P3-INIT-002 | イニシアチブ Phase 2 | **完了** |
| P3-JOB-001 | preferred_weapon +5% ATK | **完了** |
| P3-EQ-CMP-002 | 防具比較 1 行 | **完了** |
| P3-D024d-001 | 敵 curse エリート限定 | **完了** |
| P3-AFFIX-SPD-001 | Affix 速度 → イニシアチブ | **完了** |
| P3-D024c-001 | stagger_power リネーム | **完了** |
| P3-UI2-003 | viewport 縦長固定 720×1280 | **完了** |
| P3-UI2-004 | 浮動ダメージ数字 | **完了** |
| P3-EQ-CMP-003 | 装飾品比較 1 行 | **完了** |
| P3-UI2-005 | HP バー座標のスプライト追従 | **完了** |
| P3-SPEC-001 | 戦闘 AI spec イニシアチブ同期 | **完了** |
| P3-UI2-006 | バトルログ枠 art / スプライト位置 | **完了** |
| P3-SPEC-002 | UI spec / CODEMAP 同期 | **完了** |
| P3-THEME-001 | Panel 9-slice margin 調整 | **完了** |
| P3-ALPHA-001 | Alpha 5 分周回チェックリスト | **完了** |
| P3-UI2-007 | 浮動ダメージ座標（CanvasLayer） | **完了** |
| P3-UI2-009 | 宝箱中央配置 / 下部テキスト可読性 | **完了** |
| P3-UI2-008 | 戦闘スプライト scale / 遠近配置 | **完了** |
| P3-UI2-BG-001 | 王都跡戦闘 BG v3 差し替え | **完了** |
| P3-ALPHA-002 | 旧セーブ job_id マイグレーション | **完了** |
| P3-UI2-011 | ヘッダー B1 / 部屋表示 | **完了** |
| P3-UI2-012 | バトルログ戦闘限定 / ナレーション Panel | **完了** |
| P3-UI2-013 | 状態異常アイコン（頭上バッジ） | **完了** |
| P3-UI2-014 | エリート/ボス戦闘枠 | **完了** |
| P3-UI2-015 | Codex 初見トースト | **完了** |
| P3-UI2-016 | Build チップ（拠点・装備） | **完了** |
| P3-SPEC-004 | UI-2+ spec / CODEMAP 同期 | **完了** |
| P3-B-001 | 白骸墓地 完走検証・バランス初調整 | **完了**（オーナー GO） |
| P3-B-002 | 王都跡専用イベント 3 件 | **完了**（オーナー GO） |
| P3-B-003 | 地下工廠 Proposal | **完了**（オーナー GO） |
| P3-B-004 | 地下工廠プレイアブル追加 | **完了**（オーナー GO） |
| P3-B-005 | 地下工廠バランス初調整 | **完了**（オーナー GO） |
| P3-D026〜033 | 世界観刷新 Postwar Ecology（文書反映） | **完了**（Bible 29〜36 新設・既存 spec 同期） |
| P3-D035a | レベル制（共有EXP/Lv20/HP+ATK成長/セーブ） | **完了** |
| P3-D036a | 助っ人（戦闘 編成3+助っ人固定枠1 / イベント助っ人） | **完了** |
| P3-D036b | 助っ人ガチャ/ロスター（A〜D・gacha_token・天井・編成入替） | **完了**（smoke PASS） |
| P3-D037/052 | ジョブ進化（is_evolved・ギルド認定Lv10・専門深化×1.3） | **完了** |
| — | 敵6体＋主人公(swordsman)スプライト取り込み（96px/14コマ・LANCZOS） | **完了** |
| P3-D053 | ダンジョン進行 全自動化（分岐撤廃・自動進行・x1/x2/pause・EXIT自動リザルト） | **完了**（承認済） |
| P3-D054 | 中ボス(MID_BOSS)廃止（ROOM_SEQUENCE[7]=COMBAT・列挙値温存） | **完了**（承認済） |
| — | 敵 attack/hurt アニメ配線（idle復帰接続・ボス対応） | **完了** |
| — | 助っ人 targeting 修正（event_helper を狙撃対象外） | **完了** |
| P3-Cleanup-001 | 旧graveyard残骸一掃＋mourngate env改称＋部屋オブジェ修正 | **完了**（HQ巻取り・敵tres6+シート削除/env→mourngate改称/dead branch撤去） |
| P3-D066 | 残り2ジョブ スキル確定（vanguard=守護斬り/stun・beast_tamer=拘束矢/chill・副スキル状態付与有効化） | **完了** |
| P3-CODEX5-AUDIT | Codex 5段階 静的監査（P3-D051 a〜e 充足確認） | **完了**（コード変更不要・軽微な逸脱2件は容認） |
| P3-D067 | 武器クラフト実機能化（codex_materials 実ドロップ化・レシピ新生態素材改訂・apprentice_staff 追加） | **完了** |
| OD-UI-003 | レベル制 | **完了**（P3-D035a） |

### 残スケジュール（Phase 3-B' システム完成まで）

1. ~~P3-Cleanup-001 完了確認（graveyard一掃）~~ **完了**
2. ~~残り2ジョブ（ヴァンガード/ビーストテイマー）~~ **完了**（P3-D066・スキル付与）
3. ~~Ecology Codex 5段階調査（P3-D051 a〜e）完成~~ **完了**（HQ静的監査: データ/トリガー/セーブ/UI段階ゲート/6敵コンテンツ すべて充足）
4. ~~武器クラフト有効化~~ **完了**（機構=P3-CRAFT-001 / 実機能化=P3-D067: 敵 codex_materials 実ドロップ化＋レシピ新生態素材改訂＋apprentice_staff 追加）
5. → **システム完成** → Phase 3-A ポリッシュ（本番UI 003系 / 本番ドット絵量産 C案）← 次フェーズ

> アート並行（オーナーレーン）: 残り4ジョブのドット絵（ranger/alchemist/vanguard/beast_tamer）。swordsman 取り込み済。

### 世界観刷新（Postwar Ecology — 2026-06-26）

世界観を「戦後生態系」へ刷新。世界観 SSOT は **`docs/specs/world/`**（旧 `game/29`〜`37` から移行・統合済み / 2026-06-27 cutover, P3-D041b）。**コード未変更**（既存敵・DG・ジョブの実装移行は将来 Task）。

| world/ 文書 | 内容 |
|---|---|
| 00_Overview | 世界観マスター・三本柱・読み順 |
| 01_History | 歴史・HE エントリ（Codex 解析対象） |
| 02_Relics | 遺産・伝説武器・中核の謎 |
| 03_Ecology | 戦後生態系 総論 |
| 04_Classification | Class I〜VII |
| 05_Biomes | Biome |
| 06_MonsterNaming | 命名ガイド |
| 07_Geography | エルド大陸 |
| 08_SeekersGuild | 探索者ギルド |
| 09_Jobs | ジョブ（世界観面。数値は game/06） |
| 10_LoreDelivery | ロア提示ガイド |
| 11_Glossary | 用語レジストリ |

> 図鑑システム仕様は `game/33_EcologyCodex.md`（存置）。

#### 世界観 深掘り（2026-06-27〜28 / 採番 `P3-W-###`）

world 文書を一通り深掘り・整合済（**P3-W-001〜017**）。採番は world＝`P3-W-###`、HQ＝`P3-D###` に分離（旧 D050〜D066 衝突を改番解消 / `core/03` 末尾注記）。

| # | 確定 | 反映先 |
|---|---|---|
| W-001〜003 | マップ空間構成 / 歴史深化 / 地方誌 | `world/07`,`01` |
| W-004 | 属性=自然力**エルダ**（闇=瘴気・聖=浄化の光・魔法不在） | `world/03 §6`,`game/27`(ポインタ) |
| W-005 | 暦・時間・季節（崩落後 A.F./ギルド暦 G.118・澱みの季） | `world/01 §7` |
| W-006〜008 | ギルド組織/階級・戦後人類社会・経済交易 | `world/08 §8-12` |
| W-009 | 信仰・死生観（神不在・灯火/継承・還りと記録） | `world/08 §13` |
| W-010 | ロア提示の具体運用（Codex文体・HE運用・公開vs内部・新語） | `world/10 §7-10` |
| W-011 | Biome-02 **囁きの森ウィスパーウッド**（共生適応・fire弱点/poison） | `world/05 §3.2`,`04`,`07` |
| W-012 | アイアンヘイブン主要NPC（オーレン他6＋助っ人A/B/C背景） | `world/08 §14` |
| W-013 | 伝説個体（Legendary）/古龍種（カイル盟約↔ビーストテイマー） | `world/04 §5`,`09` |
| W-014 | 現在の情勢（ゲーム開始の"今"・モーンゲート調査契機） | `world/01 §8` |
| W-015 | Relics 深化（王遺産の現状・第十の王 公開断片拡充） | `world/02 §3.5・§4` |
| W-016 | 言語・文字（共通語・三層文字・「ルーン」=生物紋様） | `world/08 §15` |
| W-017 | ジョブの世界観深化（系譜・五部門親和・社会的役割） | `world/09 §5` |
| W-018 | モーンゲート敵6体の Codex 調査記録を改稿（祖先・鉱物化・王都接続） | `world/05 §3`,`resources/enemies/*.tres` |

> モンスター名・ダンジョン名・NPC固有名はオーナー確定済（採用個体の**ゲーム実装は別途選定**）。整合レビュー完了（`world/06` ミラーボア・`game/27` 退役敵参照を修正済）。

**実装移行 整合課題:** 既存敵の生物化 / DG↔Biome 再マッピング / ジョブ 3→5 / Codex 拡張 → 移行 Proposal 待ち。

---

## Known Issues

| 課題 | 詳細 |
|---|---|
| viewport 比率 | **720×1280** ✅。スプライト 720 幅内 ✅（P3-UI2-006） |
| 状態 UI | 頭上アイコン ✅（013）。Codex トースト ✅（015）。Build チップ ✅（016）。PA art は Phase 3-A |
| 聖属性武器 | ~~未実装~~ → **sanctified_dagger**（P3-HW-001） |
| タンク fantasy | ~~ランダム被弾~~ → 簡易ヘイト（P3-TH-001） |
| ラン中介入 | Alpha=準備専用（P3-D024a）。方針切替は Phase 2 |
| 助っ人 targeting | ~~ヘイト優先で狙われ無敵タンク化~~ → **解消**: `pick_enemy_target_member_index` で event_helper を狙撃対象から完全除外（メイン編成のみ標的） |
| mourngate アセット依存 | 敵6体＋swordsman は本番ドット絵取り込み済。残4ジョブは旧32px placeholder（オーナー作画待ち）。環境アート（BG/タイル/オブジェ）は **`assets/dungeon/mourngate/env/` へ改称移設済**（P3-Cleanup-001）。BG/出口は `*_Mourngate` 名 |

---

## Design References

| 文書 | 用途 |
|---|---|
| [28_ゲームデザイン点検.md](../specs/game/28_ゲームデザイン点検.md) | **GD 点検 SSOT** — P3-D024 |
| [27_状態異常と属性.md](../specs/game/27_状態異常と属性.md) | 属性/状態 SSOT v1.1 |
| [03_Decision_Log.md](../specs/core/03_Decision_Log.md) | P3-D016〜024 |
| [05_Backlog.md](../specs/core/05_Backlog.md) | P3-D024 / Initiative |
