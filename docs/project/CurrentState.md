# CurrentState.md — Crownfall Project Dashboard

---

## Last Update

2026-07-01（**P3-ALPHA-005 Alpha Combat Formation ブランチ Closeout**: `cursor/alpha-combat-formation-ui` → `main` マージ。D120〜133 + headless Closeout 一式。smoke PASS）

2026-07-01（**P3-D133 Result 天候表示**: `last_run_weather` スナップショット・Result 情報行）

2026-07-01（**P3-ALPHA-003 Closeout（headless）**: 実機一括確認はオーナー実施困難のため **Defer**。暫定ゲート＝`smoke_test.sh` PASS。開発継続可。**次=Phase 3-A ポリッシュ / Backlog 小タスク**）

2026-07-01（**P3-D130 Result 探索方針表示**: `last_run_exploration_policy` スナップショット・Result 情報行。作戦プリセットサマリーにカスタム戦術数。headless import 検証済 / コミット済）

2026-07-01（**P3-D129 探索方針効果ヒント** + **P3-ALPHA-004 チェックリスト v2.1**: 装備画面ヒント・D120〜128 追検項目。headless import 検証済 / 実機未確認 / コミット済。**次=P3-ALPHA-003 実機**）

2026-07-01（**P3-D128 図鑑調査実利報酬（D2）**: P3-D067 生態素材ドロップ配線復元・図鑑方針×未完了敵でEXP+10%/素材率×1.5・ログ`[図鑑調査]`。headless import 検証済 / 実機未確認 / コミット済。**次=P3-ALPHA-003 実機**）

2026-07-01（**P3-D127 ターゲット条件拡張（A2）**: 条件4種（stun/vulnerable/armor_break/fear）・標的`enemy_with_debuff`・cautious/sweep プリセット反映。headless import 検証済 / 実機未確認 / コミット済）

2026-07-01（**ポリッシュ**: 全滅2秒待機復元・モーンゲートDGサムネイル。コミット済）

2026-07-01（**P3-D125 陣形 B レーン Closeout** + **P3-D126 `cautious`→`self_range=mid`**: B-1〜5 完了宣言・Decision Log 追記。headless import 検証済 / 実機未確認 / コミット済。**次=P3-ALPHA-003 実機**）

2026-07-01（**P3-D124 作戦プリセット名リネーム**: `rename_combat_preset`・装備画面名称入力/名前変更・保存時名称反映。headless import 検証済 / 実機未確認 / コミット済）

2026-07-01（**P3-D123 リタイア Result 差別化**: `last_run_outcome`(clear/retire/wipe)・Result ヘッダー「リタイア帰還」/「探索失敗」/「CLEAR」・探索情報に帰還種別。headless import 検証済 / 実機未確認 / コミット済）

2026-07-01（**P3-D122 カスタム戦術ガンビット MVP（A1 Closeout）**: `tactics_custom_*`・装備画面5行UI・セーブ/作戦プリセット連動。headless import 検証済 / 実機未確認 / コミット済。**次=P3-ALPHA-003 実機 or 小タスク**）

2026-07-01（**P3-BAL-003 4人編成リバランス（G1 Closeout）**: `CombatController` 人数補正（HP×1.28/ATK×1.13 @4人）・群れ率 20%→24%。EXP/ゴールド据置。headless import 検証済 / 実機未確認 / コミット済。**次=P3-ALPHA-003 実機**）

2026-07-01（**P3-D121 作戦プリセット装備セット保存（E1 Closeout）**: `weapon/armor/accessory_instance_id` 保存・適用・競合/欠落スキップ・`find_*_instance`・UIサマリー表示。headless import 検証済 / 実機未確認 / コミット済。**次=P3-ALPHA-003 実機 or G1 バランス**）

2026-07-01（**P3-D120 マーキング状態 MVP（A3 Closeout）**: `mark`（被ダメ×1.15・3tick）・`aimed_shot`副次付与・`enemy_marked`/`enemy_has_mark`・プリセット反映（aggressive/sweep）・`CombatLinks`先頭登録。headless import 検証済 / 実機未確認 / コミット済。**次=E1 装備プリセット**）

2026-07-01（**未コミット整理**: リタイア・A3・CombatGambit を3コミット分割。B-5 コミット済）

2026-07-01（**P3-D106f 陣形 B レーン（B-5）本格射程**: `WeaponInstance`/`WeaponData.base_attack_range`→`CombatRange`（≤1.5 melee/≤2.5 mid/超 long）。スキル range_type 優先維持。`glacier_staff` 2.5 修正。headless import 検証済 / 実機未確認 / コミット済）

2026-07-01（**P3-D106b〜e 陣形 B レーン（B-1〜4）**: 射程×陣形与ダメ/敵AoE列/Threat按分/散開密集。headless import 検証済 / 実機未確認 / コミット済）

2026-07-01（**P3-ALPHA-003 Combat v1.0 実機一括確認チェックリスト**: `AlphaPlaytest_Checklist.md` v2.0 更新（モーンゲート/フルオート/CT/戦闘v1.0 全項目）。**次=オーナー実機実施 → GO/NO-GO 記録**）

2026-07-01（**P3-D119 Combat System v1.0 Closeout**: 残ロードマップ 15/15 完了宣言。`CODEMAP.md` に combat モジュール群（P3-D103〜118）・状態14種・探索/周回配線を同期。Decision Log P3-D119 追記。**次=Phase 3-A ポリッシュ / P3-D103〜118 実機一括確認**）

2026-07-01（**P3-D118 高速周回・戦闘スキップ MVP（フェーズE-15）**: `CombatFastRun`・クリア済みDGのみ「周回」トグル。COMBATのみ即撃破・報酬通常通り。ON時x2自動。ログ`[周回]`。headless import 検証済 / 実機未確認 / 未コミット。**Combat System v1.0 残ロードマップ 全15項目完了**）

2026-07-01（**P3-D117 探索スキル群 MVP（フェーズE-14）**: `ExplorationSkills`5種=採取/採掘/鍵開け/解読/罠解除。ロール連動自動発動(EVENT/TREASURE/COMBAT/ELITE)。罠20%×8ダメ。ログ`[探索]`+装備タブ表示。headless import 検証済 / 実機未確認 / 未コミット。次=フェーズE-15 高速周回）

2026-07-01（**P3-D116 ボスフェーズ移行 MVP（フェーズE-13）**: `CombatBossPhases`静的3段(serdion HP50/25%)。`enemy_phase_index`+移行チェック(与ダメ/DoT)。フェーズでskill率/攻撃力/断罪重み。図鑑=`phases_seen`目撃開示。headless import 検証済 / 実機未確認 / 未コミット。次=フェーズE-14 探索スキル群）

2026-07-01（**P3-D115 パーティシナジー連鎖＋キャラ連携 MVP（フェーズD-12）**: `CombatLinks`3連鎖=挑発連携(防御後他員+25%×3)/デバフ追撃(他員+20%)/治癒連携(回復対象次攻+15%)。`_consume_link_bonus`をコンボ末尾で併用。ログ`[連携]`+装備タブhint。headless import 検証済 / 実機未確認 / 未コミット。**フェーズD完了**→次=フェーズE-13 ボスフェーズ移行）

2026-07-01（**P3-D114 遺物発火型＋種類拡充 MVP（フェーズD-11）**: `CombatRelics`にtrigger定義+`has_trigger/trigger_def`。配線=`DungeonScene._fire_member_relic_triggers`(on_attack every_n/on_hit_taken/on_ally_death)・CD/攻撃カウント。新遺物4種=狩人の印/反応の盾片/弔鐘の指輪/斥候の片眼。ログ`[遺物]`・◈ラベル。headless import 検証済 / 実機未確認 / 未コミット。次=フェーズD-12 パーティシナジー連鎖）

2026-07-01（**P3-D113 スキル予約＋ローテーション MVP（フェーズD-10）**: 装備スキル①②を`member_skill_rot_idx`でローテ（成功時次スキルへ）。温存=`SkillData.reserve_condition/value`+`CombatTactics.skill_reserve_met`（新条件ally_injured）。mend=負傷時のみ/hex_bolt=Elite時のみ。headless import 検証済 / 実機未確認 / 未コミット。次=フェーズD-11 遺物発火型）

2026-07-01（**P3-D112 詠唱＋Action Lock MVP（フェーズD-9）**: `SkillData.cast_time`(0=即時・>0=自分番ロック)。`CombatController._pending_casts`+`_try/_advance_*_cast`で詠唱中は戦術再評価なし(Action Lock)。CDは発動時のみ。ターゲット凍結(D111)。中断=死亡/撃破クリア・敵stun/fearは進行停止。キャリア=ultimate/hex_bolt/mend/boss_decree_waveにcast_time1.0。紫系◆ラベル+ログ。headless import 検証済 / 実機未確認 / 未コミット。次=フェーズD-10 スキル予約/ローテ）

2026-07-01（**P3-D111 個別ターゲット MVP（フェーズC-8）**: D100一括フォーカス廃止→`member_target_slot`+`resolve_member_target`でメンバーごとに戦術target解決。新ルール=enemy_with_status/back（cautious→back/sweep→enemy_with_status）。配線=通常/スキル/状態/コンボ/Threatを`_deal_member_damage_to_enemy`/`_apply_status_to_member_target`経由でスロット別。撃破=非アクティブも`_on_enemy_slot_killed`。ログ群れ時`→敵名`。`CombatController`に`class_name`追加。headless import 検証済 / 実機未確認 / 未コミット。**フェーズC完了**→次=フェーズD-9 詠唱/Action Lock）

2026-06-30（**P3-D110 混成エンカウント＋敵別状態スロット MVP（フェーズC-7）**: 混成=SWARM抽選後追加枠50%で別種(can_swarm池)・ログ【混成】。敵状態=`enemy_<slot>`単位(StatusResolver)・撃破時のみクリア・フォーカス切替可(D100非切替ガード撤去)。配線=CombatController slot API+DoT/バッジ/スキル付与をスロット対応。headless import 検証済 / 実機未確認 / 未コミット）

2026-06-30（**P3-D109 シナジータグ残＋コンボ MVP（フェーズB-6）**: `CombatTags`にshield/heal追加。スキルタグ付与=empower→buff/mend→heal/guard_strike→shield/hex_bolt→debuff。味方バフコンボ=empower+ultimateタグ→「鼓舞必殺」(hit×0.35・empower消費)・1ヒット1コンボは敵側優先。`CombatCombos._ALLY_RULES`+`get/consume_member_status`+`_consume_combo_bonus`配線。headless import 検証済 / 実機未確認 / 未コミット。**フェーズB完了**→次=フェーズC-7 混成エンカウント）

2026-06-30（**P3-D108 Condition拡充 MVP（フェーズB-5）**: 戦術発動条件4種追加＝`enemy_has_bleed`/`enemy_has_poison`/`ultimate_ready`(必殺CT/CD準備完了)/`self_range`(melee|long・装備スキルrange_type/rangedタグ→bow/staff武器種→既定melee)。`_build_tactics_context`に4キー供給。プリセット最小調整=balanced/aggressive/survival必殺→ultimate_ready・aggressive出血時スキル優先・cautious遠隔スキル優先・sweep毒時スキル優先。headless import 検証済 / 実機未確認 / 未コミット。残=フェーズB-6 タグ残＋コンボ）

2026-06-30（**P3-D107 状態異常拡充 MVP（フェーズB-4）**: Control/Debuff 3状態追加＝恐怖fear(行動失敗50%/2t)・脆弱vulnerable(被ダメ×1.25/3t)・防御DOWN armor_break(敵DEF半減/3t)。新field`StatusEffectData.defense_reduction`で防御DOWNを脆弱と作用点分離(DEF逓減前にDEF×(1−r)・上限0.95乗算合成)。`SkillData.apply_status_id2/chance2`(副次状態・主と独立判定)を追加しキャリア＝既存スキル流用: guard_strike+恐怖0.4/hex_bolt+脆弱0.45(主stun/curse温存)・aimed_shot=防御DOWN0.45(空スロット)。頭上バッジ恐/脆/破＋`[防御DOWN]`ログ。headless import 検証済(新規parse error 0・既存CombatController reload警告6件はベースライン同一の良性) / 実機未確認 / 未コミット。残=フェーズB-5 Condition拡充）

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
| P3-BAL-003 | 4人編成リバランス（G1）— 敵HP/ATK 人数補正・群れ率微増 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-W-024 | スキル名 世界観リネーム（ハイブリッド: 基本=和名/属性技・弓・杖=カタカナ・hex_bolt→アンブラボルト＋説明文を闇エルダ整合） | ✅ 完了（HQ実装） |
| P3-A-UI-007 | ホーム(BaseScene)モック準拠リニューアル＋タイトル背景アート(`UI_BG_Title.png`)導入（上部通貨バー/左メニュー/下部タブナビ・中央ロゴのみ・浮遊CTA/肖像撤去・通貨=gold/gacha_token） | ✅ 完了（HQ実装・要実機確認） |
| P3-ALPHA-003 | Combat v1.0 実機一括確認チェックリスト（`AlphaPlaytest_Checklist.md` v2.0） | ✅ 文書完了（**要オーナー実機実施**） |
| P3-D119 | Combat System v1.0 Closeout（CODEMAP 同期・15/15 完了宣言・Decision Log） | ✅ 完了 |
| P3-D120 | マーキング状態 MVP（A3 Closeout） | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D121 | 作戦プリセット装備セット保存（E1 Closeout） | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D122 | カスタム戦術ガンビット MVP（A1 Closeout） | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D123 | リタイア Result 差別化 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D124 | 作戦プリセット名リネーム | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D125 | 陣形 B レーン Closeout（B-1〜5） | ✅ 完了（文書化・要実機確認） |
| P3-D126 | `cautious` 戦術 `self_range=mid` | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D118 | 高速周回・戦闘スキップ MVP（残ロードマップ フェーズE-15）。`CombatFastRun`・クリア済みDGで「周回」トグル・COMBATのみ即撃破（報酬通常）。ON時x2自動。配線=`_try/_execute_combat_skip` | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D117 | 探索スキル群 MVP（残ロードマップ フェーズE-14）。`ExplorationSkills`5種=採取/採掘/鍵開け/解読/罠解除。ロール連動自動発動(EVENT/TREASURE/COMBAT/ELITE)。罠20%×8ダメ・解除で無効。配線=`_apply_exploration_*`/`_try_exploration_trap` | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D116 | ボスフェーズ移行 MVP（残ロードマップ フェーズE-13）。`CombatBossPhases`静的SSOT(serdion3段・HP50/25%)。`enemy_phase_index`+`_check_boss_phase_transition`(与ダメ/DoT)。フェーズでskill率/attack_mult/断罪重み2。図鑑=`phases_seen`目撃開示(stage5) | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D115 | パーティシナジー連鎖＋キャラ連携 MVP（残ロードマップ フェーズD-12）。`CombatLinks`3連鎖=挑発連携(防御後他員+25%×3)/デバフ追撃(他員+20%)/治癒連携(回復次攻+15%)。配線=`_consume_link_bonus`をコンボ末尾・防御/デバフ付与/回復フック。可視化=`[連携]`+装備hint | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D114 | 遺物発火型＋種類拡充 MVP（残ロードマップ フェーズD-11）。`CombatRelics`にtrigger/condition/effect/cooldown+`has_trigger/trigger_def`。配線=`_relic_cd`/`_relic_attack_hits`+`_fire_member_relic_triggers`(on_attack every_n/on_hit_taken/on_ally_death)。新4種=狩人の印(4回追撃30%)/反応の盾片(HP50%未満防御CD8)/弔鐘の指輪(味方戦闘不能鼓舞)/斥候の片眼(速度+5%与+5%)。既存4種+ドロップ`all_ids`追従 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D113 | スキル予約＋ローテーション MVP（残ロードマップ フェーズD-10）。ローテ=`member_skill_rot_idx`で装備スキル巡回・成功時次へ。温存=`reserve_condition/value`+`skill_reserve_met`（ally_injured新設）。mend=ally_injured/hex_bolt=enemy_is_elite | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D112 | 詠唱＋Action Lock MVP（残ロードマップ フェーズD-9）。`SkillData.cast_time`(ceil=詠唱自分番数・CDは発動時)。`CombatController._pending_casts`+味方/敵`_try/_advance_*_cast`でAction Lock(戦術再評価スキップ)。ターゲット凍結・死亡/撃破クリア・敵stun/fearで進行停止。キャリア=ultimate/hex_bolt/mend/boss_decree_wave=1.0 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D111 | 個別ターゲット MVP（残ロードマップ フェーズC-8・D110依存）。D100一括フォーカス廃止→`member_target_slot`+`resolve_member_target`（行動開始時戦術target）。新ルール=enemy_with_status/back（cautious→back/sweep→enemy_with_status）。配線=通常/スキル/状態/コンボ/Threatをスロット別（`_deal_member_damage_to_enemy`/`_apply_status_to_member_target`）。撃破=非アクティブも`_on_enemy_slot_killed`・DoT同。ログ群れ時`→敵名` | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D110 | 混成エンカウント＋敵別状態スロット MVP（残ロードマップ フェーズC-7）。混成=複数体抽選時`MIXED_SWARM_CHANCE0.5`で追加枠を別種(can_swarm池)・【混成】ログ。敵状態=`enemy_<slot>`(CT整合)・個体保持/撃破時クリア・フォーカス切替可。配線=`apply_status_to_active_enemy`/`get_enemy_status_*_at`/DoTスロット別/頭上バッジ`_status_icon_swarm_rows` | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D109 | シナジータグ残＋コンボ MVP（残ロードマップ フェーズB-6・B-4/5依存）。`CombatTags`にshield/heal追加(buff/debuff既存)。スキルタグ=empower/buff・mend/heal・guard_strike/shield・hex_bolt/debuff。味方バフコンボ=`CombatCombos._ALLY_RULES` empower+`ultimate`タグ→鼓舞必殺(hit×0.35・empower消費)・1ヒット1コンボは敵側優先。配線=`get/consume_member_status`+`_consume_combo_bonus`(必殺`slot_type`のみ味方評価) | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D108 | Condition拡充 MVP（残ロードマップ フェーズB-5・B-4依存）。戦術AI発動条件4種=`enemy_has_bleed`/`enemy_has_poison`/`ultimate_ready`(必殺`SkillExecutor.can_cast`) /`self_range`+value melee|long(`_member_combat_range`: skill range_type/rangedタグ→bow/staff→melee)。ctx=`_build_tactics_context`拡張。プリセット調整=balanced/aggressive/survival必殺→ultimate_ready・aggressive出血/sweep毒/cautious遠隔でスキル優先。距離は装備メタ代理(本格射程は後続) | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D107 | 状態異常拡充 MVP（残ロードマップ フェーズB-4）。Control/Debuff 方向へ3状態追加(敵単一スロット維持)。恐怖fear(`skip_action_chance0.5`/2t)・脆弱vulnerable(`incoming×1.25`/3t)・防御DOWN armor_break(`defense_reduction0.5`/3t)。防御DOWNは新field`StatusEffectData.defense_reduction`(0..1・後方互換)で`_apply_enemy_defense`の実効DEFを×(1−r)＝脆弱(最終乗算)と作用点分離(`StatusResolver.get_defense_reduction`→`CombatController.get_enemy_defense_reduction`・乗算合成上限0.95)。キャリア=既存スキル流用＋`SkillData.apply_status_id2/chance2`(副次・独立判定`_apply_skill_secondary_status`)。配分=guard_strike+恐怖0.4/hex_bolt+脆弱0.45(主stun/curse併存)・aimed_shot=防御DOWN0.45(空スロット主付与)。可視化=頭上バッジ恐/脆/破＋`[防御DOWN]`ログ。延長=再付与リセット流用。マーキング/延長機構/敵別スロットは後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D106 | 陣形(前列/後列)MVP（残ロードマップ フェーズA-3）。4人編成(D105)に2列モデル導入・A-2 Threatと直結。行=`Adventurer.formation_row`(0前/1後)・GameState get/set＋プリセット(前衛/均衡=最後尾1後列/後衛=後ろ2後列)・SaveManager直列化。効果=後列:被ダメ×0.85(`FORMATION_BACK_INCOMING`)＋Threat基礎×0.6(`FORMATION_BACK_THREAT`)/前列:等倍＋`war_banner`与ダメ+10%を前列限定に整合。配線=被ダメ`get_member_incoming...`×`formation_incoming_multiplier`/Threat`_job_threat_base`×`formation_threat_multiplier`/war_banner`_member_relic_effects`で後列outgoing無効。UI=スキルタブに陣形行(前列/後列トグル＋プリセット3ボタン)。射程連動近接ペナルティ/AoE列範囲/散開密集は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D105 | 4人編成化（A-3前段）。陣形2×2(前2後2)に合わせアクティブ編成3→4。`GameState.ACTIVE_PARTY_SIZE`3→4(ロスター/装備/戦闘表示はsize駆動で自動追従・装備画面に`ButtonMember3`追加)。助っ人衝突解決=`COMBAT_SLOT_MAX=4`＋`_helper_active()`で満員時はevent_helperを戦闘除外(5体目=枠不足防止・get_combatants系が参照)。Threat(D104)/陣形(A-3)/状態UI/ターンオーダーはsize駆動で非改修。スプライト/HPバーは.tscnに4枠既設。リバランス(アタッカー+1)/レイアウト微調整は実機後 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D104 | Aggro/Threat基盤 MVP（残ロードマップ フェーズA-2）。旧簡易ヘイト(ジョブ優先)を本格Threat値へ置換。`CombatController.party_threat`を各員保持・戦闘開始時ジョブ基礎値で初期化(vanguard4.0/swordsman2.0/他1.0)。敵は最大Threatを狙う(`pick_enemy_target_member_index`書換・助っ人除外維持・同値index昇順)。増加=与ダメ×0.10(`THREAT_DAMAGE_K`)/被ダメ×0.15(`THREAT_TAKEN_K`)/防御スロット=挑発スパイク+40(`apply_taunt`)。減衰=status tickごと基礎値へ×0.90(`decay_threat`)で挑発が時間で薄れる。挑発専用スキル/遺物・Threat可視化・敵別Threatテーブル・キャラ連携は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D103 | 防具の属性耐性 MVP（残ロードマップ フェーズA-1）。攻撃偏重の属性を防御側へ拡張。データ=`ArmorData.resist_elements`/`EnemyData.attack_element`追加(旧base_resistance予約)。効果=敵攻撃属性が防具耐性と一致で被ダメ×0.75(`ARMOR_RESIST_MULTIPLIER`・弱点/耐性と同値)。配線=`_calc_enemy_damage_to_member`に1フック(incoming後・`_member_resists_element`・`[耐性:◯]`ログ)。初期=bone_armor闇/leather_armor氷耐性・crystal_hedgehog氷攻撃/clock_moth雷/serdion闇攻撃・装備一覧に「耐性:◯」表示。数値レア/多段階(半減/無効)/敵スキル別属性は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D100 | AIターゲット選択(パーティ・フォーカス方針)MVP。D086保留のTarget層をフォーカス撃破モデル非破壊で導入。targetルールを`CombatTactics`に追加(front/lowest_hp/highest_hp/highest_atk・balanced/cautious=front・aggressive/survival/sweep=lowest_hp・boss_focus=highest_hp)。選択=単一アクティブの付け替え(`CombatController.set_focus_by_rule`・生存敵からルールで1体選びactiveに設定・全員集中)で既存の被ダメ/状態異常/コンボ/HPバー処理を不変。配線=`_do_member_turn`冒頭で行動メンバーのtarget適用(`_apply_focus_target`・群れ2体以上時のみ＋アクティブ敵に状態異常がある間は非切替＝単一スロット状態の転移防止)。混成エンカウント/敵別状態異常/個別ターゲット/Target条件9種は後続(大物) | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D101 | 環境変化(天候)MVP。run開始時に天候抽選・DG中不変(`CombatWeather.roll()`→`GameState.current_weather`・揮発・晴れ55%/雨夜霧各15%)。効果(属性idはElementResolver準拠)=雨:雷+15%/炎-10%・夜:闇+15%/聖-10%・霧:与ダメ×0.95＋被ダメ×0.95。配線=属性/全体与ダメ→`_apply_enemy_mitigation`(地形隣・`[天候:◯]`ログ)/被ダメ→`get_member_incoming_damage_multiplier`(GameState参照)。可視化=HUDにダンジョン名〔天候〕併記＋ナラティブ＋procedural オーバーレイ(`_setup_weather`・夜=暗青ColorRect/霧=薄灰alphaドリフトTween/雨=CPUParticles2D＋生成雨粒テクスチャ・新規アセット0・CanvasLayer layer3・MOUSE_IGNORE)。増水/落石/フロア毎変化/敵側補正は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D102 | 属性武器拡充 MVP。属性シナジー(D095・同属性2本)/地形相性(D099)を実用域に。各属性1本のみで「2人で同属性」不可だったため各属性2本目を+5追加: 燻る炎牙(fire/dual_blades/pierce)/氷霜の杖(ice/staff/blunt)/雷鳴の大剣(thunder/greatsword/slash)/影喰みの短刃(dark/dual_blades/pierce)/祝聖の大槌(holy/greatsword/slash)。新規アセット0=アイコンは対応属性の既存ICO_WPN流用(`IconPaths`)・`fixed_skill_id`は既存同属性スキル流用(kindling/rime/static/hex・聖=slash_attack)・雷tag=`lightning`(D094感電互換・D099-6正規化でsynergy発火)。流通=`WEAPON_POOL`に5本追加(`DataRegistry`はid→path自動解決で追加コード不要)。専用アート/新規スキルは後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D099 | Biome属性相性 MVP。ダンジョンごとの有利属性。データ=`DungeonData.favored_element`(空=補正なし・MVP有利のみ/不利ペナルティ無し・後方互換)。効果=味方attack_elementが一致で与ダメ×1.15(`BIOME_FAVORED_BONUS`・弱点/特効/シナジーと乗算)。配線=D095同様`_apply_enemy_mitigation`属性段に1フック(`_is_biome_favored`→`current_dungeon_data.favored_element`・`[地形:◯]`ログ)。可視化=ダンジョン選択に「地形相性: ◯有利」(`DungeonSelectScene`)。mourngate(王都地下)=dark初期設定。不利ペナルティ/敵側補正/環境変化/部屋構成変更は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D098 | 探索方針プリセット連動 MVP。作戦プリセット(P3-D091)に「探索方針」を内包。方針=run単位1つ(`GameState.current_exploration_policy`・""/safe/material/relic/codex・DG中不変)。効果(中央フック相乗り)=safe:被ダメ×0.92＋群れ率×0.5/material:gold+15%＋ELITE素材率0.15→0.30/relic:ELITE遺物率0.15→0.25(BOSS据置)/codex:撃破時`add_enemy_kill`二重計上で図鑑段階加速。連動=`combat_presets[slot].exploration_policy`追加・`save/apply_combat_preset`で保存/反映(`SaveManager`は既存deep-duplicateで自動保存・変更不要)。UI=プリセット行直下に探索方針セレクタ(`EquipmentScene`・選択即反映・既定なし)。探索スキル/環境変化/部屋構成変更/高速周回は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D097 | ロールボーナス＋物理タグシナジー MVP。編成(ジョブrole)と物理武器の揃えに報酬。ロール=`CombatSynergy.compute_role_bonuses`がparty role(`JobStatCalculator`経由)を2人以上共有で発火: tank×2=被ダメ-8%/dps×2=与ダメ+6%/support×2=回復+20%/scout×2=会心+8%。物理タグシナジー=`compute_physical_bonus`が物理タグ(slash/pierce/blunt)を2人+5%/3人+8%の与ダメ(最大値・party全体フラット・属性シナジーと別枠乗算)。配線=既存中央倍率に相乗り(与ダメ`get_member_outgoing_damage_multiplier`×(1+物理)×role.outgoing/被ダメ`get_member_incoming...`×role.incoming/回復`_apply_healing_bonus`×role.heal/会心`_calc_attack_base`+role.crit)。可視化=装備スキルタブの情報行に「編成ボーナス」行追加(`_refresh_tag_info`)。陣形/Aggro/scout素材反映は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D095 | 同系統タグ・シナジー＋タグ可視化 MVP。D094タグ基盤を活用。属性シナジー=`CombatSynergy`(静的)がparty装備武器タグを集計し同一属性タグ(fire/ice/lightning/holy/dark)を2人+10%/3人+15%の与ダメ(物理/効果タグ対象外)。配線=`CombatController.get_element_synergy_bonus`→`_apply_enemy_mitigation`属性段に1フック(attack_element一致時×(1+bonus)・弱点/特効と乗算・`[シナジー:◯]`ログ・味方攻撃のみ)。可視化=装備スキルタブに情報行(`EquipmentScene._refresh_tag_info`「武器タグ: 斬撃/炎 ｜ 属性シナジー: 炎+10%」・`CombatTags.display_name`)。物理シナジー/ロールボーナス/図鑑表示は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D094 | シナジータグ正式化 MVP。D089コンボにタグ起爆を追加。タグ正式定義=`CombatTags`(静的SSOT・物理slash/pierce/blunt＋属性fire/ice/lightning/holy/dark＋効果bleed/poison/buff/debuff・未知id無視)。`WeaponData.tags`新設(`SkillData.tags`既存流用)・攻撃タグ=武器∪スキル(`_member_action_tags`正規化)。`CombatCombos`に`require_tag`追加(`tag_eligible`)＝指定タグ保有時のみ起爆。追加コンボ=出血→出血追撃(require slash・per_stack6)/感電→感電(require lightning・hit×0.4)・既存毒爆発/粉砕(無条件)は非回帰維持。武器タグ付与=朽刃slash/燻鉄slash,fire/霜結slash,ice/聖別刃pierce,holy/雷紋pierce,lightning/呪杖blunt,dark。同系統シナジー/タグUI表示は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D092 | 図鑑＝攻略本 拡充 MVP。既存段階開示(stage1-5)に乗せ、敵詳細の弱点/耐性ブロックを「戦闘データ」へ拡張(`CodexScene._apply_enemy_combat_data`・新シーン変更なし)。stage4=弱点/耐性＋行動間隔目安(`attack_speed`→`2.0/spd`秒)＋攻撃付与状態異常(`on_hit_status_id/_chance`)＋特効分類。stage5=使用スキル一覧(`skill_ids`・ボス大技含む)＋有効戦術ヒント(弱点属性＋特効分類から自動生成)。`CatalogHelper`敵エントリに`attack_speed`/`on_hit_status_id`/`on_hit_status_chance`/`skill_ids`追加・表示出し分けはstageで判定。手書きノート不要(派生生成) | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D093 | 遺物 入手導線 MVP（解放型A）。D090の自由選択に「集めて使えるようになる」進行を追加。所持=`GameState.owned_relics`(一度入手で恒久解放・全員装備可・`has_relic/unlock_relic/unowned_relic_ids`)。入手=撃破ドロップ`DungeonController.roll_kill_relic_drop`(未所持から抽選・ボス確定/エリート15%/通常なし/全所持済なし)・即時解放(全滅でも巻戻さず既存ドロップと整合・`last_run_relic_dropped`のみクリア)。装備UI=遺物セレクタを「なし＋所持済みのみ」に制限(`EquipmentScene._refresh_relic_ui`再構築・未所持装備は`(未所持)`参考表示)。表示=戦闘ログ「遺物入手」＋Result報酬セル(グリフ「遺」)。セーブ永続(`owned_relics`)。個数型/売却/アイコンは後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D091 | 作戦プリセット MVP。party全体の「戦術＋遺物」セットを3スロット保存しワンタップ一括適用(武器/防具は競合回避のため除外)。各スロット=`{name, settings:{member_id:{tactics_id,relic_id}}}`・member_idキー保持で編成順変化に頑健。API=`GameState.save_combat_preset/apply_combat_preset/get_combat_presets/has/get_combat_preset_name`(適用は現partyのid一致分のみ既存setter流用)。セーブ=saveルートに`combat_presets`(深複製)。UI=装備スキルタブ最上部「作戦:[▼][適用][保存]」(`EquipmentScene`)。装備セット保存/探索方針連動は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D090 | 遺物（Relics）MVP。第3装備枠「どう戦うか」。1メンバー1遺物(`Adventurer.relic_id`空=なし・セーブ永続/`GameState.get_member_relic_id/set_member_relic`)。カタログ=`CombatRelics`(静的・tres非増設)で常時倍率`outgoing_mult`/`incoming_mult`/`speed_mult`(既定1.0・`effects_for`マージ)。配線=中央3フックのみ(与ダメ`get_member_outgoing_damage_multiplier`/被ダメ`get_member_incoming_damage_multiplier`/速度`get_member_initiative_score`・状態異常倍率と乗算・助っ人除外)。MVP4種=王国軍旗(与ダメ×1.10)/王盾の欠片(被ダメ×0.90)/古い砂時計(速度+10%)/狂戦士の護符(与×1.20・被×1.15)。UI=装備スキルタブ戦術行直下に遺物OptionButton(`EquipmentScene`)。入手/インベントリ/発火型は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D089 | 状態異常コンボ MVP。味方の攻撃ヒット時、アクティブ敵に乗った前提状態を「起爆」＝追加ダメージをヒット値へ上乗せ＋状態消費（1ヒット1コンボ・既存撃破判定をそのまま通す）。ルール=`CombatCombos`(静的・tres非増設)・`bonus=per_stack×stacks+round(hit_fraction×hit_damage)`。MVP2種=毒→毒爆発(per_stack8・毒消費)/冷却→粉砕(hit_fraction0.5・冷却消費)。基盤=`StatusResolver.get_status_stacks/consume_status`＋`CombatController.get_enemy_status_stacks/consume_enemy_status`、`_consume_enemy_combo_bonus`を通常攻撃＋スキル3経路のapply直前に配線。頭上`毒爆発 +N`(橙)＋`[コンボ]`ログ。シナジータグ正式分類は後続 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D088 | パッシブ/リアクション MVP。戦闘中自動発火の常在能力（共通フォーマット Trigger→Condition→Effect→Cooldown）を`CombatPassives`(静的・ジョブ紐付け・tres非増設)で導入。Trigger=on_combat_start/on_hit_taken/on_ally_death・Condition=always/self_hp_below・Effect=apply_status(self\|party)/heal(party)。CD=CT秒管理(`_passive_cd`/`_run_combat_step`減算・発火成功時のみセット・戦闘開始でクリア)。被弾フック`_on_member_damaged`を敵通常`_do_enemy_attack`/敵スキル`_execute_enemy_damage`に挿入(生存=on_hit_taken・死亡=生存者on_ally_death)。頭上`◇名称`＋`[パッシブ]`ログ。初期=vanguard鉄壁(被弾&HP<50%→guard CD6)/swordsman・ranger高揚(開始→empower自己)/alchemist野戦救護(味方死亡→party回復12)/beast_tamer群れの本能(味方死亡→empower全体) | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D087 | 生態特効＋図鑑連動 MVP。武器`bane_class`/`bane_multiplier`(既定×1.3)が敵`codex_class`(獣類/昆虫類/古代種)と一致で与ダメ増幅・属性弱点と乗算併用・`[特効:◯]`タグ。`_apply_enemy_mitigation`にmember_index追加＋`_get_weapon_bane`。図鑑連動=情報表示のみ(特効は常時適用)・Codex敵詳細(stage≥4)に`特効:{codex_class}`併記。初期付与=燻鉄の大剣(獣類)/霜結びの剣(昆虫類)/霊廟の聖別刃(古代種)。敵tres編集不要(codex_class流用) | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D086 | AI設定（Tactics→Condition→Priority）MVP（戦闘v1.0 MVP縦切り③）。メンバー単位の戦術プリセット6種(`CombatTactics`静的: バランス/積極攻撃/慎重/生存優先/ボス集中/雑魚掃討)でスロット選択を優先度＋発動条件駆動に。Condition MVP=always/self_hp_below/enemy_is_boss/enemy_is_elite/enemy_count_gte/ally_dead。`_do_member_turn`を戦術プラン駆動へ置換(`_build_tactics_context`供給・防御条件は戦術へ移譲し二重ガードのみ抑止)。`Adventurer.tactics_id`セーブ永続(`GameState.get/set_member_tactics`)・キャラ管理スキルタブ上部に戦術OptionButton(`EquipmentScene`)。**Target層(敵個体狙い分け)はフォーカス撃破モデルで無効のため別Decisionへ分離** | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D085 | スキルスロット5＋防御＋必殺技（戦闘v1.0 MVP縦切り②）。1行動=5スロットから1手だけ実行(通常攻撃/防御/スキル①②/必殺技)・暫定選択優先度=必殺→防御→スキル①②→通常(D086でAI設定化)。必殺=長CD高威力(`JobData.ultimate_skill_id`/既定`ultimate_strike` power×3/CD30/`slot_type=ultimate`)。防御=自己被ダメ減バフ(新`guard` incoming×0.5/2tick)＋`CombatController.get_member_incoming_damage_multiplier`新設→`_calc_enemy_damage_to_member`配線。防御暫定条件=自HP<30%かつguard未付与。`SkillData`に`slot_type`/`range_type`追加。スキル①②はP3-D077(最大2)流用・必殺/防御は当面ジョブ/既定供給 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D084 | 戦闘 CT/ATB 移行（戦闘v1.0 土台・MVP縦切り①）。ラウンド制(P3-D083)を置換＝各生存ユニット個別CT・`BASE_ACTION_CT/initiative_score`で行動CT・CT0で1体ずつ行動・速度で行動回数差。スケジューラ=`CombatController.advance_to_next_actor()`/`get_ct_order()`（決定的・同時0は味方優先→index昇順）。1パルス1行動（x1=0.55s/x2=0.28s・同期実行で再入なし）。スキルCDは進行CT量・状態異常は`CT_PER_STATUS_TICK=2.0`ごと1tick。スキルは現行CD暫定流用。上部UIを行動順→CTプレビュー(残量昇順)へ転用。3人据置 | ✅ 完了（HQ実装・headless検証・要実機確認） |
| ~~P3-D083~~ | ~~行動順制＋行動順表示~~ → **P3-D084 で置換（CT/ATB 制へ移行）** | 置換 |
| P3-D083 | 行動順制＋行動順表示（ラウンド制・イニシアチブ降順で1体ずつ逐次行動・同時攻撃を解消／速度=initiative_score流用・同値は味方優先／逐次await＋`_round_active`再入防止／上部アイコン列ターンオーダー表示=行動中ハイライト・このラウンドのみ／`does_enemy_act_first`先制ログ廃止・撃破処理を分割） | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D082 | 群れ出現MVP（`EnemyData.can_swarm`/swarm_min/max・COMBATで20%群れ化(2〜3体)・ELITE/BOSS除外・sepia_hound/crown_eater_rat対象・CombatController群れ配列化+アクティブ繰り上げ・先頭フォーカス撃破/敵は各自攻撃・状態異常はアクティブ単一スロット流用・横並びスロットUI/個別HPバー&Lv名・撃破ごと報酬/武器個別ドロップ） | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D081 | 敵レベル制MVP（`DungeonData.enemy_level`でDG単位固定・戦闘開始時確定/DG中不変・HP/ATK×(1+0.10×(Lv−1))/DEF据置・EXP×(1+0.15×(Lv−1))・共有Resource不汚染=CombatControllerの派生スケール値・ネームプレート`Lv{n} 名前`） | ✅ 完了（HQ実装・headless検証・要実機確認） |
| P3-D080 | ダンジョン選択画面新設（ホーム「ダンジョン」→`DungeonSelectScene`→ラン。カード=ボス絵/★(difficulty)/推奨Lv/主なドロップ/CLEARバッジ・難易度タブ(ロック表示)・ロック行3件(仮名)・下部ナビ。`DungeonData.recommended_level`追加・`GameState.mark/is_dungeon_cleared`・完走時マーク） | ✅ 完了（HQ実装・要実機確認） |

### Combat System v1.0 残実装ロードマップ — **完了**（2026-06-30 確定 / 2026-07-01 Closeout P3-D119）

> 提案「Crownfall Combat System v1.0」の未実装/部分要素を、依存関係と費用対効果で並べた実装順序。原則＝土台先行・小さく効くもの先行・大物後段。採番は着手時に P3-Dxxx を付与。**全15項目 = P3-D103〜118 完了。**

**フェーズA：防御と編成の土台（タンクを機能させる）**
1. ✅ 防具の属性耐性 — **P3-D103**
2. ✅ Aggro / Threat 基盤 — **P3-D104**
3. ✅ 陣形 2×2 前後列 — **P3-D106**（4人編成 P3-D105）

**フェーズB：状態異常と条件の解像度**
4. ✅ 状態異常拡充 — **P3-D107**
5. ✅ Condition 拡充 — **P3-D108**
6. ✅ シナジータグ残＋コンボ追加 — **P3-D109**

**フェーズC：戦闘の多様性（Target 本格化）**
7. ✅ 混成エンカウント＋敵別状態異常スロット — **P3-D110**
8. ✅ 個別ターゲット＋Target 条件拡充 — **P3-D111**

**フェーズD：テンポ・AI深化**
9. ✅ Cast/詠唱＋Action Lock — **P3-D112**
10. ✅ スキル予約／ローテーション — **P3-D113**
11. ✅ 遺物：発火型＋種類拡充 — **P3-D114**
12. ✅ パーティシナジー連鎖＋キャラ連携 — **P3-D115**

**フェーズE：コンテンツ・周回**
13. ✅ ボスのフェーズ移行 — **P3-D116**
14. ✅ 探索スキル群 — **P3-D117**
15. ✅ 高速周回（戦闘スキップ） — **P3-D118**

依存固定: 2→3→12 / 4→5→6 / 7→8 — すべて充足。

**Closeout 後の Defer（各 Task スコープ外の集約）:** 敵別 Threat テーブル・探索スキル手動発動/CD・ELITE スキップ・戦闘スキップ敗北シミュ・`CombatWeather` 本格配線・複数 DG 本格コンテンツ。※本格射程/AoE・陣形 B レーン＝**P3-D125 完了**・マーキング＝**P3-D120 完了**。

---

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
