# Crownfall 攻略Wiki

> 世界は一度滅びた。滅びたのは人類の文明であり、自然そのものではなかった。

**Crownfall（クラウンフォール）** は、2Dの自動探索ハクスラRPG。プレイヤーは冒険者を直接操作せず、**探索隊の指揮官**として方針・装備・編成を決め、滅びた王国の地下へ調査隊を送り込む。

このWikiは、ゲームの **世界観**・**攻略**・**データ** をまとめた事典です（App Store 公開に向けた現行バージョン準拠）。

---

## まずはここ（プレイヤー向け）

<div class="grid cards" markdown>

- :material-gamepad-variant: **どんなゲーム？**

    一言でいうと「自分では殴らないハクスラ」。向き不向きもここ。

    [→ どんなゲーム？](guide/what-is.md)

- :material-frequently-asked-questions: **よくある質問**

    動かない？②開かない？装備できない？あるある集。

    [→ FAQ](guide/faq.md)

- :material-school: **初心者向けガイド**

    起動したあとに何するか。序盤ルート雑まとめ。

    [→ 初心者向け](guide/beginner.md)

- :material-sword-up: **キャラを強くするには**

    鍛冶が本体。属性・炉研ぎ・限界突破の優先度。

    [→ 強くする](guide/power-up.md)

- :material-podium-gold: **Tier／敵／ビルド**

    キャラ評価、ウザい敵、キャラ単位のゴールビルド、残すべき装備。

    [→ Tier](guide/tier.md) · [要注意敵](guide/threats.md) · [ビルド例](guide/builds.md) · [装備](guide/recommended-gear.md)

- :material-cash: **稼ぎ・招待・ペット**

    石の貯め方、ガチャの使いどき、ジャック達の切替。

    [→ 稼ぎ方](guide/farming.md) · [招待状](guide/gacha.md) · [ペット](guide/pets.md)

- :material-map-search: **Hard／Boss／放浪／UI**

    危険度の違い、ボス横断、放浪、画面の見方。

    [→ Hard/NM](guide/hard-nightmare.md) · [Boss](guide/bosses.md) · [放浪](guide/wandering.md) · [UI](guide/ui-guide.md)

</div>

---

## 仕様寄りの攻略・データ

<div class="grid cards" markdown>

- :material-compass-outline: **はじめに（仕様）**

    導入フロー、コアループ、指揮官としての要点。

    [→ はじめに](guide/getting-started.md)

- :material-home-map-marker: **拠点と進行**

    鍛冶・招待状・調査室、メイン5 Biome、イベント、深層。

    [→ 拠点ガイド](guide/hub.md) · [進行とダンジョン](guide/progression.md)

- :material-sword-cross: **戦闘と装備**

    自動戦闘、属性、職制限、鍛冶。

    [→ 戦闘](guide/combat.md) · [装備と鍛冶](guide/equipment.md)

- :material-calendar-star: **イベント／深層**

    曜日短編と時間帯降臨（セット装備）、無限エンドの深層。

    [→ イベント](guide/events.md) · [深層](guide/abyss.md)

- :material-book-open-variant: **世界観**

    九王戦争後の大陸と生態系の物語。

    [→ 世界観の概要](world/overview.md)

</div>

---

## データ事典

| ページ | 内容 |
|---|---|
| [モンスター図鑑](data/monsters.md) | 弱点・基礎ステ・調査記録 |
| [武器一覧](data/weapons.md) | 種別・レア・属性・固有効果 |
| [防具・装飾品](data/equipment.md) | 基礎防御・ボーナス |
| [ジョブ](data/jobs.md) | 装備可能武器・スキル |
| [ダンジョンデータ](data/dungeons.md) | メイン／イベント／深層 |

メイン攻略 →[①](guide/mourngate.md) · [②](guide/whisperwood.md) · [③](guide/mistfen.md) · [④](guide/blackshore.md) · [⑤](guide/frostridge.md)  
イベント／深層 →[イベントDG](guide/events.md) · [深層](guide/abyss.md)

---

## このゲームについて

| 項目 | 内容 |
|---|---|
| ジャンル | 2D 自動探索ハクスラRPG（戦闘は横並びスロット） |
| プレイヤーの役割 | 探索隊の指揮官（直接操作なし） |
| 舞台 | 九王戦争後のエルド大陸／王都地下モーンゲートほか |
| コアループ | 編成・装備 → 自動探索 → 戦闘 → 報酬 → 強化 → 再探索 |
| 現行の探索範囲 | メイン①〜⑤、曜日イベント、時間帯降臨、Biome深層（寄り道・征討は未解放） |

!!! note "ネタバレ方針"
    この世界の真実は一度に語られません。**確かな記録**と**推測**が共存し、あえて答えを残さない「余白」もまた世界の一部です。本Wikiの[断片ロア](world/fragments.md)は、その問いをそのまま掲載しています。

!!! tip "データの更新"
    数値ページの多くはゲームのリソースから生成しています。バランス変更後は `wiki/generate.py` で再生成できます。
