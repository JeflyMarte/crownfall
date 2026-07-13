# CurrentSprint.md — Sprint Dashboard

---

## Sprint Name

**Beta コンテンツ拡張**（メイン5 Biome 完遂後）

---

## Goal

メイン5 Biome（①〜⑤）＋サブステージ有効化済みを前提に、**装備レジェンド横展開**と**敵プール拡充**で周回密度を上げる。

---

## スコープ

| 領域 | 内容 | 状態 |
|---|---|---|
| メイン DG | ①モーンゲート〜⑤フロストリッジ（各敵6+装備20・解放直列） | ✅ 完了（P3-D154〜161） |
| サブステージ | メイン5×5章・`SUB_STAGES_PLAYABLE=true` | ✅ 完了（P3-DG-STG-ENABLE） |
| 寄り道 | broken_marsh パイロット | ✅ 完了（P3-D159・side 表示は OMIT 中可） |
| 戦闘/メタ | Combat v1.0・Lv99・危険度ティア・遍在希少種・昇格特質・装備Lv | ✅ 完了 |
| UI | 拠点/戦闘/召喚所モック寄せ・結果ウィザード・行動ルールUI | ✅ 主要 Closeout |
| UI chrome | ボタン画像化フェーズ2〜4（DG入場/結果/隊長台帳） | ✅ 完了 |
| 戦闘演出 | 必殺 resolve カット（P3-UX-ULTIMATE-001 案A） | ✅ Closeout（要実機） |
| メタ拡張 | 指揮官・調査許可等級・6週「野外の変化」 | ✅ 完了（P3-CMD-001 / P3-EVT-WEEK-002） |
| **次** | **実機確認** — 必殺演出・VFX透過 | オーナー |
| **次** | **P3-UI-BTN-005** 装備・編成ボタン画像化 | STOP |
| **次** | **P3-EQ-LEG-002** 防具・装飾★ ②〜⑤横展開 | 未着手 |
| **次** | **P3-ENEMY-002** 新雑魚残り（②+4種済） | 部分着手 |

---

## 優先 Task

| 順 | ID | 内容 | 状態 |
|---|---|---|---|
| 0 | 実機確認 | 必殺 resolve 演出・VFX透過・ボタン chrome（DG/結果/隊長） | **オーナー** |
| 1 | P3-UI-BTN-005 | ボタン画像化フェーズ5（装備・編成） | **STOP** |
| 2 | P3-EQ-LEG-002 | 防具・装飾レジェンド ②〜⑤（① PoC=P3-EQ-LEG-001 済） | 未着手 |
| 3 | P3-ENEMY-002 | 新雑魚残り（② whisperwood +4種済） | 部分着手 |
| — | P3-DAILY-B | 日課 UI polish | 任意 |
| — | オーナー作画 | env（5職ドットは P3-ART-CHR-002 差替済・助っ人は OMIT） | 並行レーン |
| — | P3-ART-CHR-002 | メイン5職ダンジョンドット差替 | ✅ |
| — | P3-CHR-OMIT-001 | メイン5以外オミット | ✅ |

**凍結（Decision まで着手しない）:** 天候本格 / 週間日課 / 10連ガチャ / 6装備枠 / Affix本格 / 位置AI本格 / 探索手動+CD。

---

## Notes

- 正の進捗・完了履歴は `docs/project/CurrentState.md`（Last Update / Next Implementation Queue）
- 受理ゲート: `bash tools/smoke_test.sh` PASS。実機一括確認は Defer（P3-ALPHA-003）
- 世界観 SSOT: `docs/specs/world/`（旧 `game/29`〜`37` は移行済）
- ProjectDocs v3.6.0
- 詳細 Decision / 完了 Task は `CurrentState.md` と `docs/specs/core/03_Decision_Log.md` を参照（本ファイルに履歴を複製しない）
