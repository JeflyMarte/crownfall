# Combat Band VFX（本番シート）

P3-UX-COMBAT-BAND-ART-001。ColorRect 仮置きは廃止済み。ここに PNG を置き、`resources/animation/FX_Band_*.tres` を作ると再生される。

## P0（優先）

| ファイル | スタイル | 用途 |
|---|---|---|
| `FX_Band_Breath.png` | breath | 敵吐息・列攻撃の帯 |
| `FX_Band_Pulse.png` | pulse | 敵波動・詠唱全体 |
| `FX_Band_Slash.png` | slash | 必殺斬 |

## 仕様（発注用）

| 項目 | 値 |
|---|---|
| 形式 | 横長スプライトシート（1行・6〜8フレーム） |
| 推奨フレーム | **128×128**（帯が足りなければ 160×128） |
| 背景 | 完全透過。暗縁・マット禁止（Hit VFX と同じ落とし穴） |
| 色 | ニュートラル白〜薄い色。属性はゲーム側ティント |
| ループ | なし（ワンショット） |

## 取込後

1. PNG を本ディレクトリへ
2. Godot で `SpriteFrames` → `res://resources/animation/FX_Band_{Style}.tres`（anim=`default`）
3. 暗縁があれば `tools/generate_env_and_vfx.py` の `clean_vfx_image` 相当で再処理
4. `.godot/imported` の該当を消して再インポート
5. 戦闘でボス詠唱／必殺を実機確認

未配置のスタイルは **無演出**（四角に戻さない）。
