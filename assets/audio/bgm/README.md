# BGM（オーナー制作）

Suno AI などで作成した BGM をここに配置する。

## 現行ファイル（P3-AUDIO-BGM-001）

| ID | ファイル | 用途 | ループ |
|---|---|---|---|
| `title` | `title.mp3` | タイトル（はじめから／つづきから） | YES |
| `introduction` | `introduction.mp3` | 新規導入（世界観〜ニーナ） | YES |
| `hub` | `hub.mp3` | 拠点 | YES |
| `forge` | `forge.mp3` | 鍛冶屋 | YES |
| `survey` | `survey.mp3` | 調査室 | YES |
| `gacha` | `gacha.mp3` | ガチャ（招待状） | YES |
| `dungeon_explore` | `dungeon_explore.mp3` | ダンジョン探索（全ダンジョン共通） | YES |
| `battle` | `battle.mp3` | 通常・エリート戦闘（未登録 Biome の既定） | YES |
| `whisperwood` | `whisperwood.mp3` | ウィスパーウッド系 通常戦闘 | YES |
| `mistfen` | `mistfen.mp3` | ミストフェン系 通常戦闘 | YES |
| `boss` | `boss.mp3` | ボス戦 | YES |
| `result` | `result.mp3` | リザルト（クリア／リタイア） | YES |
| `result_defeat` | `result_defeat.mp3` | リザルト（全滅＝探索失敗） | YES |

再生は `AudioManager.play_bgm(id)`（BGM バス・設定画面音量連動）。
カタログ SSOT: `scripts/audio/BgmCatalog.gd`。
`ResultScene` は勝敗で ID を切り替える（SCENE_BGM 非掲載）。
