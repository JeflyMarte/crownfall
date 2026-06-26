# Phase2 Gameplay Design v1.1

**Status:** Approved  
**Approved By:** DevelopmentHQ  
**Version:** v1.1  
**Source:** Phase2_Gameplay_Design_Proposal_v1.1

---

# 1. Purpose

本書はMVP完成後のPhase2 Gameplay拡張仕様である。

DevelopmentHQレビューにより承認済みの完成版とする。

設計思想：

> **武器がゲーム体験の主役**

MVP仕様との互換性を維持し、その上にゲーム性を拡張する。

---

# 2. Phase2 Design Concept

**テーマ**

「同じダンジョンでも毎回違う攻略になる」

ゲーム性は以下で拡張する。

- 武器性能
- 装備構成
- ダンジョン構造
- プレイヤーの判断

新アクション追加ではなく、既存ゲームループを深化させる。

---

# 3. Weapon Expansion

## 武器種

- Dagger
- Hammer
- Wand
- Crossbow
- Scythe

## 差別化

武器専用アクションスキルはPhase2では追加しない。

差別化要素

- Attack Power
- Attack Speed
- Critical Rate
- Knockback
- Stun Power
- Attack Range
- Weight
- Durability（将来拡張）
- その他固有パラメータ

武器がプレイスタイルを決定する。

---

# 4. Armor

Armor Slot ×1

パラメータ

- Defense
- HP
- Resistance

Weight

- Light
- Medium
- Heavy

重量は

- 移動速度
- 回避性能

へ影響する。

---

# 5. Accessory

補助装備として実装する。

代表パラメータ

- Gold Bonus
- Movement Speed
- HP Recovery
- Critical Rate
- Luck

Luckは将来拡張可能な内部パラメータとする。

---

# 6. Job

ジョブは補助要素。

攻撃主体にならない。

例

- Warrior
- Ranger
- Scholar
- Priest

---

# 7. Dungeon Expansion

Phase2前半

- Branch Routes
- Special Rooms
- Random Events
- Dungeon Gimmicks

Phase2後半

- Frozen Cave
- Volcano
- Royal Garden
- Ancient Cathedral
- Corrupted Forest

---

# 8. Event

- Reward
- Risk
- Choice
- Lore

Lore Eventは短時間で世界観を伝える。

---

# 9. Replayability

- 武器パラメータ
- 分岐
- 特殊部屋
- イベント
- Armor
- Accessory
- Job

---

# 10. Phase3 Backlog

- Weapon Active Skills
- Passive System
- Set Effect
- Advanced Jobs
- Weapon Evolution
- Endless Dungeon
- Seasonal Events
- Boss Rush

---

# 11. Design Principles

1. 武器をゲーム体験の中心とする。
2. 武器パラメータでプレイフィールを差別化する。
3. ジョブは補助要素とする。
4. Armorは重量と防御力のトレードオフを持つ。
5. AccessoryはLuckを含む補助要素とする。
6. ダンジョンは情報付き選択を基本とする。
7. Lore Eventで世界観を補強する。
8. MVPゲームループを維持する。

---

# Approved Decisions

- 武器をPhase2でもゲーム体験の中心とする。
- 武器専用アクションスキルはPhase2では追加しない。
- ArmorにWeightを導入する。
- AccessoryへLuckを導入する。
- 分岐ルートは情報付き選択を採用する。
- Lore Eventを追加する。
- 新ダンジョンより遊び方の拡張を優先する。
- Passive / Set Effect / Weapon Active Skills / Advanced Jobs / Weapon EvolutionはPhase3とする。
