# Crownfall Product Vision

**Status:** Proposal Revision  
**Version:** v1.1  
**Base Document:** Crownfall_Product_Vision_v1.0  
**Target Path:** `docs/archives/GameplayArchive/Proposal/Crownfall_Product_Vision_v1.1.md`  
**Authoring:** DevelopmentHQ  

---

## Revision Summary

| Item | Detail |
|---|---|
| Base | Crownfall_Product_Vision_v1.0 |
| Added | **§3.8 Exploration Rhythm** |
| Added | One **Decision Candidate** (§10) |
| Unchanged | All other sections identical to v1.0 |

> **Archive note:** v1.0 full text is not yet archived in this repository. Until v1.0 is placed alongside this file, treat v1.0 as the authoritative base for sections not reproduced below.

---

# 3.8 Exploration Rhythm

Each run should maintain a satisfying rhythm of:

* Battle
* Decision
* Reward
* Preparation

Special Rooms, Branch Routes, Bosses, and Appraisal should create alternating moments of tension and relief.

The player should always feel that another meaningful decision is only a few moments away.

The rhythm of exploration is one of Crownfall's defining characteristics and should remain consistent as new systems are added.

### Mapping to current implementation (reference only)

| Rhythm phase | Current Crownfall examples |
|---|---|
| Battle | COMBAT / ELITE / MID_BOSS / BOSS rooms |
| Decision | Branch Route choice; Event Room 2-choice; Merchant purchase |
| Reward | TREASURE; combat EXP/Gold; run loot; ResultScene |
| Preparation | BaseScene; EquipmentScene; AppraisalScene |

This mapping is illustrative. It is not SSOT and does not override `docs/specs/`.

---

# 10. Decision Candidates (Additional)

The following Decision Candidate is **appended** to the existing list in Crownfall_Product_Vision_v1.0 §10.

* **Exploration rhythm is a core design pillar.** Future systems should reinforce the cadence of **Battle → Decision → Reward → Preparation**, rather than interrupt or replace it.

---

## Review Status

| Field | Value |
|---|---|
| Review | Pending DevelopmentHQ approval |
| SSOT impact | None until approved and merged into ProjectDocs |
| Implementation | Do not implement from this Proposal alone |

---

## Related

* Game loop: `docs/specs/game/04_ゲームループ.md`
* Dungeon / Special Rooms: `docs/specs/game/05_ダンジョン.md`
* UI reference (non-SSOT): `docs/art/reference/UI_Reference_Notes.md`
