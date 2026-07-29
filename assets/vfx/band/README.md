# Combat Band VFX（本番シート）

P3-UX-COMBAT-BAND-ART-001。ColorRect 仮置きは廃止済み。ここに PNG を置き、`resources/animation/FX_Band_*.tres` を作ると再生される。

## P0

| ファイル | スタイル | 用途 |
|---|---|---|
| `FX_Band_Breath.png` | breath | 敵吐息・列攻撃の帯 |
| `FX_Band_Pulse.png` | pulse | 敵波動・詠唱全体 |
| `FX_Band_Slash.png` | slash | 必殺斬 |

## P1

| ファイル | スタイル | 用途 |
|---|---|---|
| `FX_Band_Tide.png` | tide | 泥潮・深淵サージ |
| `FX_Band_Mist.png` | mist | 霧・墨煙・瘴気 |
| `FX_Band_Fan.png` | fan | 剣嵐など味方全体斬 |
| `FX_Band_Volley.png` | volley | 斉射 |
| `FX_Band_Quake.png` | quake | 盾撃波 |
| `FX_Band_Shot.png` | shot | 必殺狙撃 |
| `FX_Band_Roar.png` | roar | 必殺咆哮 |

## 仕様

| 項目 | 値 |
|---|---|
| 形式 | 個別フレーム 4 枚／スタイル（または横長シート） |
| 推奨フレーム | **128×128** |
| 背景 | 完全透過。暗縁・マット禁止 |
| 色 | ニュートラル白〜薄い色。属性はゲーム側ティント |
| ループ | なし（ワンショット） |

## 現状（Cursor 試作）

- P0+P1 全スタイルを `frames/{style}/*_0..3.png` + `FX_Band_*.tres` で配置済み
- AI 生成 → 緑クロマキー → 128²。合わなければシート／tres を外して無演出に戻す
