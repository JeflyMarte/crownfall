# Phase2_Accessory_Loot_Appraisal_v1.0

**Status:** Completed
**Task:** P2-Task011
**Approved By:** DevelopmentHQ
**Version:** v1.0

---

## 概要

Accessory を Dungeon Loot および Appraisal システムへ統合。
Weapon / Armor と同じフローで取得 → 鑑定 → 装備が可能になった。

---

## 実装内容

### Dungeon Loot

DungeonController に `_generate_accessory_loot()` を追加。

```
generate_run_loot():
  Weapon: 毎回 (100%)
  Armor:  30%確率
  Accessory: 20%確率
```

ACCESSORY_POOL = ["silver_ring"]

### Result

ResultScene `_update_loot_label()` に Accessory 表示追加。
例: `入手  武器: iron_sword  /  装飾品: silver_ring`

### Appraisal

- AppraisalController: `has_unappraised()` / `_find_first_unappraised()` が accessory_inventory 走査（weapon → armor → accessory 優先順）
- AppraisalScene: 未鑑定装飾品リスト表示 / 鑑定ログ `鑑定完了: silver_ring`
- 空メッセージ: 「未鑑定アイテムがありません」へ統一

### 追加リソース

```
resources/accessories/silver_ring.tres
  id: silver_ring / rarity: 0
  hp_bonus: 5, crit_rate_bonus: 0.02, luck_bonus: 0.1
```

---

## 変更ファイル

```
resources/accessories/silver_ring.tres     新規
scripts/dungeon/DungeonController.gd
scripts/autoload/GameState.gd
scripts/dungeon/DungeonScene.gd
scripts/result/ResultScene.gd
scripts/appraisal/AppraisalController.gd
scripts/appraisal/AppraisalScene.gd
```
