# CurrentState.md — Crownfall Project Dashboard

---

## Last Update

2026-06-30（**戦闘システム v1.0 MVP縦切り①②③: P3-D084 CT/ATB ＋ P3-D085 5スロット/防御/必殺 ＋ P3-D086 AI設定(戦術)**。①CT/ATB=各ユニット個別CT・速度で行動回数差・1パルス1行動・上部UIをCTプレビュー化。②1行動=5スロットから1手(通常/防御/スキル①②/必殺)・必殺=汎用`ultimate_strike`(×3/CD30)・防御=`guard`(被ダメ0.5/2tick)でメンバー被ダメ補正を実配線。③メンバー単位の戦術プリセット6種(バランス/積極/慎重/生存/ボス集中/掃討)でスロット選択を優先度＋発動条件(always/HP%/Boss/Elite/敵数/味方死亡)駆動に。`CombatTactics`静的＋`Adventurer.tactics_id`セーブ永続＋キャラ管理スキルタブに戦術セレクタ。Target層(敵個体狙い分け)は現行フォーカス撃破で無効のため別Decisionへ分離。headless import 検証済 / 実機未確認 / 未コミット）

2026-06-29（**Phase 3-A UI/バランス ポリッシュ**: ホーム(BaseScene)モック準拠リニューアル＋タイトル背景アート導入(P3-A-UI-007)・ダンジョン選択画面新設(P3-D080)・序盤バランス調整(P3-BAL-001)・死にステ解消=敵DEF/耐性を与ダメ計算へ統合(P3-BAL-002)・スキル名 世界観リネーム(P3-W-024)。鑑定ワード一掃は現行spec/player向けへ反映済）

2026-06-28（**Phase 3-B' システム実装 ほぼ完了**: ガチャ/ロスター・ジョブ進化・スプライト取り込み・ダンジョン全自動化(P3-D053)・中ボス廃止(P3-D054)・敵アニメ配線・助っ人targeting修正・graveyard残骸一掃(P3-Cleanup-001)・残り2ジョブ スキル(P3-D066)・Codex5段階監査・武器クラフト実機能化(P3-D067)。→ Phase 3-A ポリッシュへ）

---

## Project Version

ProjectDocs **v3.6.0**

---

## Current Phase

**Phase3-A — Visual Production 着手**（P3-D069 = 純ポリッシュ/gameplay不変）。Phase 3-B' システム完成リストは全消化（P3-D053〜068）。
- 3-A スコープ: 人数3＋助っ人1 / 装備3枠 / メタ無し は据置（4人・6枠・メタは Beta）
- 起点 A1: BaseScene を 003_01 へ寄せる（テーマ基準づくり）

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
| P3-D068 | 装備ドロップを直ドロップ化（鑑定済み100%・Affix自動付与・鑑定システムは温存） | **完了**（Claude実装・HQ diff承認 `fed5ffd`） |
| P3-D069 | Phase 3-A スコープ確定（純ポリッシュ・人数3/装備3枠/メタ無し据置） | **確定** |
| P3-A-UI-001 | 拠点(BaseScene) を 003_01 へ寄せる（テーマ基準づくり） | ✅ 完了 |
| P3-A-UI-002 | 装備画面をタブ分割（現在の装備／所持一覧） | ✅ 完了 |
| P3-A-UI-003 | 装備名のUI表示をID→display_name（日本語名）へ統一（全画面） | ✅ 完了（Claude実装・HQ承認） |
| P3-D070 | ダンジョン完全フルオート化（商人削除・イベント無選択化・全部屋自動進行） | ✅ 完了（Claude実装・HQ承認） |
| P3-A-UI-004 | 敵スプライト頭上に敵名ネームプレート表示（モック003_07準拠・下部敵名ラベルは集約） | ✅ 完了（HQ実装） |
| P3-D071 | 戦闘 下部パーティパネル（アイコン/HP/武器・MP不採用・CD維持） | ✅ 完了（HQ実装） |
| P3-A-UI-005 | 命中時Hitエフェクト＋ダメージ数値を敵味方両方に適用 | ✅ 完了（HQ実装・要実機確認） |
| P3-D072 | 鑑定機能オミット・退避（導線撤去・クラフト自動鑑定・archive移動） | ✅ 完了（HQ実装） |
| P3-D073 | 部屋移動トランジション演出（暗転＋部屋名・速度連動・軽量） | ✅ 完了（HQ実装・要実機確認） |
| P3-D074 | 撃破演出強化（武器直ドロップ＋取得アニメ・全滅時敵残置・攻撃時間差・素材オミット） | ✅ 完了（HQ実装・要実機確認） |
| P3-ART-001 | レンジャー／アルケミスト専用ドット絵を実装（generic batch7流用を専用SpriteFramesに差替・idle/attack/hurt/death） | ✅ 完了（HQ実装・要実機確認） |
| P3-D075 | 鍛冶屋オミット・退避（BaseScene導線撤去・archive/blacksmithへ移動） | ✅ 完了（HQ実装） |
| P3-A-UI-006 | 戦闘下部パーティパネルに専用キャラアイコン（バスト）。IconPaths chrカテゴリ追加・仮アイコンは正面ドット絵から自動生成 | ✅ 完了（HQ実装・仮アイコン/要差替） |
| P3-FIX-001 | 味方CHRサイズ不揃い修正（フレーム高基準→α実体高基準のfloat正規化・実体140px統一・足元bbox下端整列） | ✅ 完了（HQ実装・要実機確認） |
| P3-D076 | 部屋抽選ランダム化（中間=重み付き戦闘多め60/15/13/12・両端固定・ガード全適用ELITE≤2/連続禁止/COMBAT≥3）＋ダンジョン別`floor_count`（mourngate=7） | ✅ 完了（HQ実装・headless2万試行検証・要実機確認） |
| P3-D077 | スキル装備システム（メニュー「キャラ管理」改称・2スロット・ジョブ別プール・全員が装備スキルのみ発動・武器自動付与廃止・キャラ管理スキルタブ） | ✅ 完了（HQ実装・要実機確認） |
| P3-D072-LORE | 断片ロア実機配信（碑文イベント本文表示＋Codex「記録」カテゴリ・`world/12` LFブロック解析・mourngate碑文イベント拡充） | ✅ 完了（HQクローズ 2026-06-29: LFブロック6件↔碑文イベントID一致・パーサ/表示/Codex記録 配線確認済） |
| P3-D078 | 回復/バフスキルMVP（SkillExecutor heal/buff解禁・`mend`治癒=最負傷者単体回復・`empower`鼓舞=味方与ダメ+30%/3tick・alchemistに付与・回復+/攻アイコン演出） | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D079 | ボススキルMVP（EnemyData `skill_ids`/`skill_use_chance`追加・敵ターンでCD付きスキル発動・Serdionに激昂(自己与ダメ+40%)＋断罪の波動(全体AoE attack×0.7)・赤スキル名ポップ演出） | ✅ 完了（HQ実装・headless検証・要実機確認） |
| OD-UI-003 | レベル制 | **完了**（P3-D035a） |
| P3-BAL-001 | 序盤バランス（武器世界観改名＋レアリティ調整・レア度重み付きドロップ・hunting_bow/apprentice_staff/bone_armor をドロップ追加） | ✅ 完了（HQ実装・要実機確認） |
| P3-BAL-002 | 死にステ解消（敵DEF逓減軽減 `K/(K+DEF)` K=100＋属性耐性0.75x を与ダメ計算 `_apply_enemy_mitigation` へ統合） | ✅ 完了（HQ実装・要実機確認） |
| P3-W-024 | スキル名 世界観リネーム（ハイブリッド: 基本=和名/属性技・弓・杖=カタカナ・hex_bolt→アンブラボルト＋説明文を闇エルダ整合） | ✅ 完了（HQ実装） |
| P3-A-UI-007 | ホーム(BaseScene)モック準拠リニューアル＋タイトル背景アート(`UI_BG_Title.png`)導入（上部通貨バー/左メニュー/下部タブナビ・中央ロゴのみ・浮遊CTA/肖像撤去・通貨=gold/gacha_token） | ✅ 完了（HQ実装・要実機確認） |
| P3-D086 | AI設定（Tactics→Condition→Priority）MVP（戦闘v1.0 MVP縦切り③）。メンバー単位の戦術プリセット6種(`CombatTactics`静的: バランス/積極攻撃/慎重/生存優先/ボス集中/雑魚掃討)でスロット選択を優先度＋発動条件駆動に。Condition MVP=always/self_hp_below/enemy_is_boss/enemy_is_elite/enemy_count_gte/ally_dead。`_do_member_turn`を戦術プラン駆動へ置換(`_build_tactics_context`供給・防御条件は戦術へ移譲し二重ガードのみ抑止)。`Adventurer.tactics_id`セーブ永続(`GameState.get/set_member_tactics`)・キャラ管理スキルタブ上部に戦術OptionButton(`EquipmentScene`)。**Target層(敵個体狙い分け)はフォーカス撃破モデルで無効のため別Decisionへ分離** | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D085 | スキルスロット5＋防御＋必殺技（戦闘v1.0 MVP縦切り②）。1行動=5スロットから1手だけ実行(通常攻撃/防御/スキル①②/必殺技)・暫定選択優先度=必殺→防御→スキル①②→通常(D086でAI設定化)。必殺=長CD高威力(`JobData.ultimate_skill_id`/既定`ultimate_strike` power×3/CD30/`slot_type=ultimate`)。防御=自己被ダメ減バフ(新`guard` incoming×0.5/2tick)＋`CombatController.get_member_incoming_damage_multiplier`新設→`_calc_enemy_damage_to_member`配線。防御暫定条件=自HP<30%かつguard未付与。`SkillData`に`slot_type`/`range_type`追加。スキル①②はP3-D077(最大2)流用・必殺/防御は当面ジョブ/既定供給 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D084 | 戦闘 CT/ATB 移行（戦闘v1.0 土台・MVP縦切り①）。ラウンド制(P3-D083)を置換＝各生存ユニット個別CT・`BASE_ACTION_CT/initiative_score`で行動CT・CT0で1体ずつ行動・速度で行動回数差。スケジューラ=`CombatController.advance_to_next_actor()`/`get_ct_order()`（決定的・同時0は味方優先→index昇順）。1パルス1行動（x1=0.55s/x2=0.28s・同期実行で再入なし）。スキルCDは進行CT量・状態異常は`CT_PER_STATUS_TICK=2.0`ごと1tick。スキルは現行CD暫定流用。上部UIを行動順→CTプレビュー(残量昇順)へ転用。3人据置 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| ~~P3-D083~~ | ~~行動順制＋行動順表示~~ → **P3-D084 で置換（CT/ATB 制へ移行）** | 置換 |
| P3-D083 | 行動順制＋行動順表示（ラウンド制・イニシアチブ降順で1体ずつ逐次行動・同時攻撃を解消／速度=initiative_score流用・同値は味方優先／逐次await＋`_round_active`再入防止／上部アイコン列ターンオーダー表示=行動中ハイライト・このラウンドのみ／`does_enemy_act_first`先制ログ廃止・撃破処理を分割） | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D082 | 群れ出現MVP（`EnemyData.can_swarm`/swarm_min/max・COMBATで20%群れ化(2〜3体)・ELITE/BOSS除外・sepia_hound/crown_eater_rat対象・CombatController群れ配列化+アクティブ繰り上げ・先頭フォーカス撃破/敵は各自攻撃・状態異常はアクティブ単一スロット流用・横並びスロットUI/個別HPバー&Lv名・撃破ごと報酬/武器個別ドロップ） | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D081 | 敵レベル制MVP（`DungeonData.enemy_level`でDG単位固定・戦闘開始時確定/DG中不変・HP/ATK×(1+0.10×(Lv−1))/DEF据置・EXP×(1+0.15×(Lv−1))・共有Resource不汚染=CombatControllerの派生スケール値・ネームプレート`Lv{n} 名前`） | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D080 | ダンジョン選択画面新設（ホーム「ダンジョン」→`DungeonSelectScene`→ラン。カード=ボス絵/★(difficulty)/推奨Lv/主なドロップ/CLEARバッジ・難易度タブ(ロック表示)・ロック行3件(仮名)・下部ナビ。`DungeonData.recommended_level`追加・`GameState.mark/is_dungeon_cleared`・完走時マーク） | ✅ 完了（HQ実装・要実機確認） |

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
| W-019 | HE 拡充（HE-005〜009 で六時代を概説・基幹4本と相互リンク・starter 開示） | `world/01`,`scripts/codex/CatalogHelper.gd` |
| W-020 | 素材21件のロア改稿（由来ベース・超自然語/退役DG名是正・lore_id 注釈） | `world/05 §3`,`resources/materials/*.tres` |
| W-021 | 伝説武器9対の公開断片を執筆（碑文/記録/噂・真相非記載・将来フレーバー素材） | `world/02 §3` |
| W-022 | 断片ロア集「モーンゲートの断章」新設（中核6謎×公開断片 計21点・媒体/出自付き・CANON非転記）＋ Codex調査記録6体を増補（S5稿に中核の謎フック1文追記・実機反映） | `world/12`（新設）,`README`,`world/05 §3`,`resources/enemies/*.tres` |
| W-023 | モーンゲート垂直層位を設計（L0嘆きの門〜L7王家霊廟最深部・L8〜未踏査／旧用途・情景・生息・出土・配置LF）。降下＝王都の過去への遡行。CANON地理フック整合・真相非公開 | `world/05 §3` |

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
