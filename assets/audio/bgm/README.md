# BGM（オーナー制作）

Suno AI などで作成した BGM をここに配置する。

想定ファイル名（`BgmCatalog` 追加時に対応）:

- `hub.ogg` — 拠点
- `dungeon_explore.ogg` — 探索
- `battle.ogg` — 戦闘
- `boss.ogg` — ボス
- `result.ogg` — リザルト

再生は `AudioManager.play_bgm(id)`（BGM バス）経由にする。
