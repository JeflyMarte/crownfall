# BGM（オーナー制作）

Suno AI などで作成した BGM をここに配置する。

## 現行ファイル（P3-AUDIO-BGM-001）

| ID | ファイル | 用途 | ループ |
|---|---|---|---|
| `hub` | `hub.mp3` | タイトル／拠点 | YES |
| `dungeon_explore` | `dungeon_explore.mp3` | ダンジョン探索（非戦闘） | YES |
| `battle` | `battle.mp3` | 通常・エリート戦闘 | YES |
| `boss` | `boss.mp3` | ボス戦 | YES |
| `result` | `result.mp3` | 戦闘終了／リザルト | YES |

再生は `AudioManager.play_bgm(id)`（BGM バス・設定画面音量連動）。
カタログ SSOT: `scripts/audio/BgmCatalog.gd`。
