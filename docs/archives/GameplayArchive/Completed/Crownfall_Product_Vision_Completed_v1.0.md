# Crownfall Product Vision — Completed v1.0

**Status:** Completed (Design Vision Reference)  
**Version:** v1.0 (merged with v1.1 revision)  
**Approved By:** DevelopmentHQ  
**Date:** 2026-06-21  
**Supersedes:** `docs/archives/GameplayArchive/Proposal/Crownfall_Product_Vision_v1.1.md` (revision patch)

---

## Document Status — Read First

| Item | Statement |
|---|---|
| Document type | **Design Vision reference** — not gameplay spec |
| SSOT | **`docs/specs/` remains the only implementation SSOT** |
| Override rule | This document **does not override** specs, Decision Log, or MVP decisions |
| Implementation | New features still require **DevelopmentHQ Decision** before SSOT merge |
| Evaluation | Future UI / UX / Game Design / Art systems should be **evaluated against this vision** |
| Code impact | Approved vision does not, by itself, authorize gameplay or balance changes |

---

## Reconstruction Note

Standalone `Crownfall_Product_Vision_v1.0` full text was not archived in the repository prior to this Completed merge. Sections **1–7, 9** below reconstruct the approved v1.0 body from:

- Project Charter / README product identity
- UI mockup reference (`docs/art/reference/UI_Reference_001.png`) and `UI_Reference_Notes.md`
- Current implementation trajectory (Phase2-M4, 2026-06-21)

Sections **3.8** and **§10 (Exploration rhythm candidate)** are merged verbatim from **Product Vision v1.1**.

---

# 1. Purpose

This document defines the **long-term product vision** for Crownfall.

It answers:

- What kind of game Crownfall is meant to become
- Which experiences must remain central as content and systems grow
- How to judge future proposals without rewriting specs ad hoc

It does **not** replace Task specs, Resource schemas, or combat numbers.

---

# 2. Product Identity

**Working title:** Crownfall  
**Tagline:** *An Auto-Exploration RPG seeking the Heritage of the Nine Kings*

Crownfall is a mobile-first, top-down auto-exploration loot RPG set in a fallen civilization. The player is **not** a direct-action avatar. The player is the **commander** of an expedition: choosing dungeons, equipment, and party direction while exploration and combat proceed automatically.

The fantasy is not “clear this stage once.” It is **return to the ruins, learn the world, improve the build, and chase the next legendary find.**

---

# 3. Core Experience Pillars

## 3.1 Commander Fantasy

The player makes **preparation and policy decisions**, not frame-by-frame combat inputs.

- Choose where to explore
- Choose how to equip and appraise
- Choose when to push deeper vs return to base
- Read logs and outcomes to refine the next run

Direct avatar control is out of vision scope.

## 3.2 Auto-Exploration & Auto-Battle

Exploration and combat should feel **continuous and low-friction** on mobile.

- The party advances through danger without manual steering
- Combat resolves automatically with readable feedback
- The player stays engaged through **decisions, rewards, and build impact** — not mechanical spam

**Implementation note:** MVP/Phase2 uses **room-step progression** (see `docs/specs/decisions/01_MVP方針決定.md`). The vision allows richer presentation later (see UI Reference) without requiring real-time scroll in current SSOT.

## 3.3 Weapon-Centric Builds

**Weapons are the primary expression of build identity.**

- Weapon type and stats shape playstyle
- Loot, appraisal, and equipment selection are core pleasures
- Armor and accessories support the weapon build; they do not replace it

Future Job and Skill layers should **amplify** weapon identity, not flatten it.

## 3.4 Appraisal & Loot Identity

A major emotional peak is **turning unknown loot into understood power**.

- Unidentified drops create anticipation
- Appraisal reveals value and enables meaningful equip/skip choices
- Legendary-tier items should feel like **discoveries**, not checklist rewards

Gold spent on appraisal is part of the intended tension/reward loop in MVP scope.

## 3.5 Multi-Dungeon World Expansion

Crownfall grows by **adding places worth returning to**, not one infinite corridor.

- Each dungeon has its own enemy identity, pressure, and discovery hooks
- Base selection makes the world feel larger than a single route
- Difficulty and branch variety differentiate runs across dungeons

M4 established the **two-dungeon foundation** (王都跡 / 白骸墓地). Further regions extend this pattern.

## 3.6 Discovery & Collection

Exploration is also about **learning the fallen world**.

- Register discoveries (rooms, enemies, events, lore, materials)
- Eventually surface them in Codex / map UI (Beta target)
- Collection supports replay motivation beyond raw power gain

Discovery should reward curiosity, not require wiki reading.

## 3.7 The Nine Kings' Heritage

The narrative north star is the **Heritage of the Nine Kings** — legendary weapons, ruins, and truths buried in a collapsed age.

- Dungeons are fragments of a lost civilization
- Rare equipment carries historical weight
- Long-term fantasy: assemble understanding of the Nine Kings through play

Lore depth lives in World/History bibles. This vision only fixes **why** exploration and collection matter.

## 3.8 Exploration Rhythm

Each run should maintain a satisfying rhythm of:

* Battle
* Decision
* Reward
* Preparation

Special Rooms, Branch Routes, Bosses, and Appraisal should create alternating moments of tension and relief.

The player should always feel that another meaningful decision is only a few moments away.

The rhythm of exploration is one of Crownfall's defining characteristics and should remain consistent as new systems are added.

### Rhythm mapping (illustrative — not SSOT)

| Phase | Vision | Current Crownfall examples |
|---|---|---|
| Battle | Combat pressure | COMBAT / ELITE / MID_BOSS / BOSS |
| Decision | Meaningful choice | Branch Route; Event 2-choice; Merchant buy/skip |
| Reward | Payoff | TREASURE; EXP/Gold; run loot; materials |
| Preparation | Reset & optimize | Base; Appraisal; Equipment |

---

# 4. Target Platform & Session Shape

| Item | Vision |
|---|---|
| Platform | Mobile-first (iOS priority, Android supported) |
| Orientation | Landscape fixed |
| Resolution target | 1280×720 |
| Session | Short runs compatible with **~5 minute loop** validation (MVP goal) |
| Input | Tap-first UI; minimal cognitive load between runs |

---

# 5. Core Loop Vision

```text
Base (prepare & choose dungeon)
  → Explore (auto progression + decisions)
  → Result (run payoff)
  → Appraisal (reveal loot)
  → Equipment (apply build)
  → Base
```

Within exploration, the loop should repeatedly express:

**Battle → Decision → Reward → Preparation**

Systems that break this cadence (long blocking menus, mandatory manual grind, opaque downtime) require explicit HQ justification.

---

# 6. Visual & UX North Star

Primary visual reference: `docs/art/reference/UI_Reference_001.png`  
Interpretation guide: `docs/art/reference/UI_Reference_Notes.md`

### Long-term UX targets

- **Base hub** that expands into armory, forge, heritage room, codex, merchant
- **Exploration screen** with party/enemy readability and run feedback
- **Loot & item detail** screens that sell rarity and build fantasy
- **Collection UI** (bestiary, discovery map) for long-term engagement

### Adopted with current constraints

Vision accepts **simplified MVP/Phase2 presentation** where SSOT already decided otherwise (room-step exploration, 3-party, 3 equipment slots, minimal Base UI). Polish catches up in Beta; mechanics do not silently change via this document.

---

# 7. What Crownfall Is Not (Vision Boundaries)

This vision explicitly excludes as **primary identity**:

- Action RPG manual dodging/combos as core loop
- MMO-style always-online social dependency
- Gacha-only power without exploration payoff
- Narrative visual novel replacing dungeon runs
- Systems that replace weapon/build identity with pure stat inflation

Individual features may borrow ideas from these genres only if they reinforce §3 pillars.

---

# 8. Relationship to ProjectDocs

| Layer | Role |
|---|---|
| `docs/specs/` | **Implementation SSOT** — tasks implement from here |
| `docs/specs/decisions/` | MVP overrides and approved HQ decisions |
| `docs/project/CurrentState.md` | Current task reality |
| **This document** | **Design Vision** — evaluates proposals; does not authorize code |

When vision and SSOT conflict, **SSOT wins until DevelopmentHQ explicitly revises SSOT**.

When a proposal aligns with vision but lacks SSOT detail, **create Decision + spec update** before implementation.

---

# 9. How Future Systems Should Be Evaluated

Before approving a new system, ask:

1. Does it reinforce **commander fantasy** (§3.1)?
2. Does it respect **auto-exploration** friction targets (§3.2)?
3. Does it strengthen **weapon/build identity** (§3.3)?
4. Does it improve **appraisal/loot payoff** (§3.4)?
5. Does it expand **world/dungeon value** (§3.5)?
6. Does it support **discovery/collection** (§3.6)?
7. Does it connect to **Nine Kings heritage fantasy** (§3.7)?
8. Does it preserve **Exploration Rhythm** (§3.8)?

If multiple answers are “no,” the proposal likely belongs in a different game or a later phase.

---

# 10. Decision Candidates

The following are **vision-level candidates**. They are not implemented decisions until recorded in `docs/specs/core/03_Decision_Log.md`.

### From v1.1 (approved merge)

* **Exploration rhythm is a core design pillar.** Future systems should reinforce the cadence of **Battle → Decision → Reward → Preparation**, rather than interrupt or replace it.

### Additional vision candidates (from UI / product review)

| ID | Candidate |
|---|---|
| PV-D001 | Base hub expands to multi-menu Avalon-style hub in Beta, not Phase2 minimal Base |
| PV-D002 | Codex UI is a first-class collection endpoint, fed by `discovery_registry` |
| PV-D003 | Legendary weapons receive dedicated reveal/detail presentation |
| PV-D004 | Exploration presentation may gain visual depth while retaining room-step SSOT unless HQ revises D-003 |
| PV-D005 | Fourth equipment slot (Royal Heritage) remains formal-edition scope, not MVP |

---

## Related References (non-SSOT)

| Document | Path |
|---|---|
| UI mockup | `docs/art/reference/UI_Reference_001.png` |
| UI adoption notes | `docs/art/reference/UI_Reference_Notes.md` |
| Project charter | `docs/specs/core/00_Project_Charter.md` |
| Game loop spec | `docs/specs/game/04_ゲームループ.md` |
| Proposal revision | `docs/archives/GameplayArchive/Proposal/Crownfall_Product_Vision_v1.1.md` |

---

## Change Log (Vision Document)

| Version | Change |
|---|---|
| v1.0 base | Initial Product Vision (DevelopmentHQ) |
| v1.1 | Added §3.8 Exploration Rhythm + rhythm Decision Candidate |
| Completed v1.0 | Merged v1.0 + v1.1 into this archive |

---

**End of Document**
