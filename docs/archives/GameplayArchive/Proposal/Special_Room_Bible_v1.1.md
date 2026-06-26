# Special_Room_Bible_v1.1

**Status:** Approved
**Approved By:** DevelopmentHQ
**Version:** v1.1（Proposal）
**Date:** 2026-06-22

---

## Design Purpose

- Special Room は探索体験に変化と選択肢を提供する。
- Branch Route と組み合わせ、数秒で判断できる意思決定を提供する。

---

## Phase2-M3 Implementation Targets

| Room | 役割 |
|---|---|
| Heal Room | HP 回復 |
| Treasure Room | Gold・Armor・Accessory・Materials |
| Merchant Room | Armor・Accessory・Recovery・Materials を販売 |
| Elite Room | 高難度戦闘と高報酬 |
| Event Room | 短時間イベント（Gold・Heal・Lore・Materials・Temporary Buff） |

---

## Future Phase

| Room | 備考 |
|---|---|
| Shrine | Lore 拡張・将来 Phase |
| Unknown Route | Discovery System 連携・将来 Phase |

---

## Reward Rules

- Weapon は Special Room から排出しない。
- Weapon は探索終了時に未鑑定武器として生成する。
- Armor は Treasure・Elite・Merchant から取得。
- Accessory は Treasure・Elite・Merchant・Boss Reward から取得。

---

## Spawn Rules

- Special Room は Branch Route へ配置する。
- 出現率・出現回数は Balance Data / DataTable で管理する。
- 固定値は ProjectDocs へ持たない。

---

## Boss Rules

- Boss 直前は Heal Room または Merchant Room を優先候補とする。
- Boss 撃破後は Special Room を生成しない。

---

## Economy

- Treasure・Elite が Gold 供給源。
- Merchant が Gold 消費先。
- Gold 循環を形成する。

---

## Lore

- Phase2 では Event Room から提供する。
- Shrine による Lore 拡張は Future Phase。

---

## Design Principles

- 探索テンポを崩さない。
- 数秒で判断できる。
- リスクとリターンを明確化する。
- Weapon は Special Room から排出しない。
- Balance は DataTable 管理とする。
