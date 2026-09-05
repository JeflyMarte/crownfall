# エンシェント装備 地力＋単品小効果（P3-EQ-ANCIENT-POWER-D-001）

**Status:** Decision **承認済**（2026-08-31 — オーナー「DでGo」）  
**親:** `19_EventDescentSets`／`131`／`136`  
**目的:** エンシェント3点がレジェンド3点に汎用で負ける体感を緩和。**地力を軽く上げ＋単品に小効果**。3部位加護は据置。L帯の天井は超えない。

---

## 1. 方針

| # | 決定 |
|---|---|
| P3-EQ-ANCIENT-POWER-D-001-1 | **地力**を中L手前まで引き上げ（武器ATK目安 **×約2.2**） |
| P3-EQ-ANCIENT-POWER-D-001-2 | 各部位に **薄い固有パッシブ**（テーマ一致・加護と重複可） |
| P3-EQ-ANCIENT-POWER-D-001-3 | **3部位加護の数値は据置**（時環／アンティーク／名拒み／星炉） |
| P3-EQ-ANCIENT-POWER-D-001-4 | 単品だけでビルドL一式を超えない。揃えたらニッチで競合できる |

---

## 2. 地力（確定）

### 2.1 武器 `base_attack`（時環／名拒み／星炉）

| 型 | 旧 | 新 |
|---|---|---|
| sword | 110 | **242** |
| dual_blades | 102 | **224** |
| bow | 100 | **220** |
| staff | 98 | **216** |
| hammer | 118 | **260** |

### 2.2 武器（アンティーク・やや低め据置）

| 型 | 旧 | 新 |
|---|---|---|
| sword | 100 | **220** |
| dual_blades | 92 | **202** |
| bow | 90 | **198** |
| staff | 88 | **194** |

### 2.3 防具

| セット | DEF 旧→新 | HP 旧→新 |
|---|---|---|
| chronos_toki | 96→**210** | 160→**350** |
| valgard_antique | 88→**195** | 140→**310** |
| albark_namerefuse | 92→**200** | 150→**330** |
| forge_slag | 92→**200** | 150→**330** |

### 2.4 装飾

| セット | ATK+ | DEF+ | HP+ |
|---|---|---|---|
| chronos_toki | 12→**24** | 0→**8** | 56→**110** |
| valgard_antique | 0→**10** | 16→**28** | 48→**96** |
| albark_namerefuse | 8→**16** | 8→**16** | 40→**80** |
| forge_slag | 8→**16** | 8→**16** | 40→**80** |

---

## 3. 単品パッシブ（確定）

武器はセット内で **同一 id**（剣／双／弓／杖／鎚で共有）。

| セット | 部位 | passive id | 効果（平易） |
|---|---|---|---|
| 時環 | 武器 | `eq_set_chronos_weapon` | スキルCD ×**0.94** |
| 時環 | 防具 | `eq_set_chronos_armor` | 被ダメ ×**0.97** |
| 時環 | 装飾 | `eq_set_chronos_acc` | スキルCD ×**0.97** |
| アンティーク | 武器 | `eq_set_valgard_weapon` | 与ダメ ×**1.06** |
| アンティーク | 防具 | `eq_set_valgard_armor` | 被ダメ ×**0.95** |
| アンティーク | 装飾 | `eq_set_valgard_acc` | 与ダメ ×**1.04** |
| 名拒み | 武器 | `eq_set_namerefuse_weapon` | デバフ付与 ×**1.10** |
| 名拒み | 防具 | `eq_set_namerefuse_armor` | 被ダメ ×**0.97** |
| 名拒み | 装飾 | `eq_set_namerefuse_acc` | デバフ付与 ×**1.06** |
| 星炉 | 武器 | `eq_set_forge_weapon` | 炎上中与 ×**1.08**／スキル命中15%炎上 |
| 星炉 | 防具 | `eq_set_forge_armor` | 被ダメ ×**0.97** |
| 星炉 | 装飾 | `eq_set_forge_acc` | 炎上中与 ×**1.05** |

### 実装メモ

- `status_chance_mult` は装備パッシブからも乗算（`EvolutionTraits.member_status_chance_mult`）
- 既存フック: `skill_cd_mult`／`outgoing_mult`／`incoming_mult`／`outgoing_vs_status_*`／`on_skill_hit`+`ignite`

---

## 4. やらないこと

- 2部位ボーナス
- 加護数値の大幅強化
- エンシェントを通常ドロップ／灰冠へ混入
- 地力を⑤章L・深層L帯まで上げること

---

## 5. SSOT

| 層 | ファイル |
|---|---|
| 本決定 | `docs/specs/decisions/139_AncientSetPowerPass.md` |
| セット枠 | `19_EventDescentSets.md`／`131`／`136` |
| Decision Log | `03_Decision_Log.md` |
