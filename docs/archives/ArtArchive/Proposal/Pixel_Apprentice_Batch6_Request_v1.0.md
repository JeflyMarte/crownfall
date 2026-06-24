# Crownfall — Pixel Apprentice Asset Request: Batch 6 (VFX)

**Status:** Ready to Send
**Batch:** 6 (P1 — VFX)
**Created:** 2026-06-24
**Revised:** 2026-06-24（P3-Prep-009 — フレーム数・シートサイズ修正）
**Based on:** Phase3A_Scope_Adoption_Completed_v1.1.md §3-2 P1
**Impl Task:** P3-A-006（EC-7）
**Next batch:** Batch 7 (Graveyard Tileset + Boss + CHR)

---

## Overview

Batch 6 covers **2 VFX sprite sheets** used during combat. These are the only assets needed to complete EC-7 (VFX in combat).

The two assets have **different frame counts and sheet sizes** — see the summary table below.

If anything is unclear, ask before producing.

---

## Style Reference

Same as all prior batches. Key points for VFX:

| Name | Hex | Use |
|---|---|---|
| Void Black | `#0d0d0d` | Outline, impact shadow |
| Bone White | `#d4cbb8` | Light burst, heal glow center |
| Bronze | `#7a5c28` | Accent flash |
| Stone Light | `#4a4a5e` | Smoke / fade particles |

VFX color direction:
- **Hit:** Hard impact — Void Black outline, white/bone center flash, brief orange-amber spark (`#c8781e`)
- **Heal:** Soft radiance — pale green-gold (`#8ab87a`) glow rising upward, Bone White center

No pure white, no bright red, no neon colors.

---

## Production Rules

| Rule | Requirement |
|---|---|
| File format | PNG |
| Color mode | RGB / 8-bit |
| Compression | Lossless |
| Anti-aliasing | None (hard pixel edges) |
| Background | Transparent (all frames) |
| Filter (Godot) | Nearest / Pixel |
| Filename | Exactly as specified. No size suffix. |

---

## Batch 6 — Asset Specifications

### Summary Table

| File | Canvas per frame | Frames | Sheet size | Loop |
|---|---|---|---|---|
| `FX_Hit_Normal.png` | 32×32 px | **4** | **128×32 px** | No |
| `FX_Heal.png` | 32×32 px | **5** | **160×32 px** | No |

SpriteSheet layout: **horizontal strip**, left to right, frame 0 → N-1.

> **Note:** The two assets intentionally have different frame counts. Do not pad either sheet to match the other.

---

### Asset 1 — `FX_Hit_Normal.png`

**Purpose:** Played on the enemy sprite when the party deals damage. Small, fast, punchy.

| Property | Value |
|---|---|
| Canvas per frame | 32×32 px |
| Total frames | **4** |
| Sheet dimensions | **128×32 px**（4 × 32 = 128 wide） |
| Background | Transparent |
| Playback speed | 12 fps（4 frames ≈ 0.33 秒で完了） |
| Loop | No |

**Frame-by-frame description:**

| Frame | x offset | Description |
|---|---|---|
| 0 | 0 | Blank — no pixels (pre-impact blank) |
| 1 | 32 | Small white-bone cross or star burst at center — impact point, 6–8 px |
| 2 | 64 | Burst at maximum size — 12–16 px across, Void Black outline, amber edges |
| 3 | 96 | Fragments fading outward — reduced pixel count, near blank |

Design notes:
- Should feel like a sharp physical strike — no magical softness
- Peak size (frame 2) should fill 40–60% of the 32×32 canvas
- Color: bone-white center (`#d4cbb8`), optional amber edge (`#c8781e`), Void Black outline
- Must read clearly when overlaid on a 32×32 enemy sprite scaled 3× in game

---

### Asset 2 — `FX_Heal.png`

**Purpose:** Played on a party member when healing is applied (Heal room, Merchant, Event). Soft and brief.

| Property | Value |
|---|---|
| Canvas per frame | 32×32 px |
| Total frames | **5** |
| Sheet dimensions | **160×32 px**（5 × 32 = 160 wide） |
| Background | Transparent |
| Playback speed | 10 fps（5 frames = 0.5 秒で完了） |
| Loop | No |

**Frame-by-frame description:**

| Frame | x offset | Description |
|---|---|---|
| 0 | 0 | Small pale green-gold spark at center base (`#8ab87a`), 2–4 px |
| 1 | 32 | 2–3 rising droplets / sparkles beginning to move upward |
| 2 | 64 | Droplets mid-rise, slight spread outward, Bone White tips |
| 3 | 96 | Droplets near top of canvas, fading to Bone White, nearly gone |
| 4 | 128 | Final fade — 1–2 px residual pixels or blank |

Design notes:
- Heal should feel gentle and upward — opposite energy from Hit's downward impact
- Avoid bright green (`#00ff00`) — use muted green-gold (`#8ab87a` or similar)
- Should read as "something good happening" even at small scale

---

## Delivery

| File | Sheet size |
|---|---|
| `FX_Hit_Normal.png` | 128×32 px, 4 frames |
| `FX_Heal.png` | 160×32 px, 5 frames |

Folder: `batch6_vfx/`

---

## Acceptance Criteria

### FX_Hit_Normal.png

| Criterion | Requirement |
|---|---|
| Format | PNG, **128×32 px** |
| Frames | Exactly **4** frames, each 32×32 px, left-to-right |
| Transparency | Fully transparent background in all frames |
| No anti-aliasing | Hard pixel edges only |
| Peak size | Frame 2 impact fills 40–60% of canvas |
| Naming | `FX_Hit_Normal.png` (exact, no suffix) |

### FX_Heal.png

| Criterion | Requirement |
|---|---|
| Format | PNG, **160×32 px** |
| Frames | Exactly **5** frames, each 32×32 px, left-to-right |
| Transparency | Fully transparent background in all frames |
| No anti-aliasing | Hard pixel edges only |
| Color | Muted green-gold palette, no pure green |
| Naming | `FX_Heal.png` (exact, no suffix) |

---

## Revision Policy

One revision cycle included. If an asset fails Acceptance Criteria, specific feedback will be provided.

---

## Notes for Pixel Apprentice

- Batch 5（白骸墓地通常敵 5 体）は受領済み。ありがとうございます。
- Batch 6 = VFX 2 点のみ。フレーム数が異なる点に注意してください（Hit: 4f / Heal: 5f）。
- 次の Batch 7 は白骸墓地 Tileset / ボス / 冒険者スプライトです。
- Full scope: `docs/archives/ArtArchive/Completed/Phase3A_Scope_Adoption_Completed_v1.1.md`
