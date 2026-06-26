# Crownfall — Pixel Apprentice Asset Request: Batch 1 (UI Frames)

**Status:** Ready to Send
**Batch:** 1 of 3 (P0 — UI Frames)
**Created:** 2026-06-24
**Based on:** Phase3A_Scope_Adoption_Completed_v1.1.md (P3-D001–007)
**Next batch:** Batch 2 (Icons) — sent after Batch 1 is approved

---

## Overview

This is the first production asset request for Crownfall Phase3-A Visual Production.

Batch 1 covers **4 UI assets** that are needed before all other work can proceed — they appear in every scene.

Do not start Batch 2 until Batch 1 is approved by the project lead.

If anything in this document is unclear, ask before producing — do not guess.

---

## Style Reference

Game: Crownfall — auto-exploration dark fantasy RPG (mobile, landscape 1280×720)

Visual direction:
- Dark Flat Design
- Thin Bronze border (1–2 px, color `#7a5c28`)
- 8 px base grid
- High contrast (text and UI elements must be clearly readable against dark backgrounds)
- Hard edges preferred — corner radius 0–2 px maximum
- Minimal decoration — no patterns, no ornaments on UI containers

Color anchors:

| Name | Hex | Use |
|---|---|---|
| Void Black | `#0d0d0d` | Outlines, deepest shadow |
| Stone Dark | `#1e1e2a` | Shadow, background depth |
| Stone Mid | `#2e2e3e` | Mid-tone fills |
| Stone Light | `#4a4a5e` | Highlights, edges |
| Ash | `#9a9a8e` | Neutral surfaces |
| Bone White | `#d4cbb8` | Text, light highlights |
| Bronze | `#7a5c28` | Border color (all UI elements) |

No pure white (`#ffffff`). No pure black (`#000000`). No high-saturation colors in this batch.

---

## Production Rules (apply to all assets in this batch)

| Rule | Requirement |
|---|---|
| File format | PNG |
| Color mode | RGB / 8-bit |
| Compression | Lossless |
| Anti-aliasing | None |
| Sub-pixel rendering | None |
| Filter (Godot import) | Off (Nearest / Pixel) — do not design for bilinear filtering |
| Mipmaps | Off |
| Filename | Exactly as specified below. No size suffix. No spaces. No hyphens. No Japanese characters. |

---

## Batch 1 — Asset Specifications

### Summary Table

| File | Canvas | 9-slice | Transparent BG |
|---|---|---|---|
| `UI_Frame_Panel_Base.png` | 48×48 px (minimum) | Yes | Yes |
| `UI_Btn_Normal.png` | 128×32 px | Yes | Yes |
| `UI_Btn_Pressed.png` | 128×32 px | Yes | Yes |
| `UI_BG_Dark.png` | 1280×720 px | No | No (solid fill) |

---

### Asset 1 — `UI_Frame_Panel_Base.png`

**Purpose:** Base panel background used in all UI screens (inventory, Codex, equipment list, merchant, etc.). Scaled dynamically to fit different container sizes via 9-slice.

| Property | Value |
|---|---|
| Canvas | 48×48 px minimum. Can be larger (e.g. 64×64) if needed for clean 9-slice margins. |
| Background fill | Very dark, slightly blue-gray — approximately `#12121a` |
| Border | 1–2 px solid, Bronze `#7a5c28` |
| Corner radius | 0–2 px (hard edge strongly preferred — 0 px is fine) |
| Interior | Flat, no texture, no decoration |
| 9-slice margins | Border width on all 4 sides. Inner content area must be empty and scalable. |
| Transparent bg | Yes — the area outside the panel shape must be transparent |

Design notes:
- This panel will be scaled up to fill large containers (e.g. 600×400 px). The 9-slice corners must remain crisp at any scale.
- The interior fill should be slightly lighter than the scene background (`UI_BG_Dark.png`) to create depth.
- Do not add any decorative elements (no corner ornaments, no patterns).

---

### Asset 2 — `UI_Btn_Normal.png`

**Purpose:** Default (unpressed) button state. Used for all interactive buttons across all scenes.

| Property | Value |
|---|---|
| Canvas | 128×32 px |
| Background fill | Dark, slightly lighter than the panel interior — approximately `#1e1e2a` |
| Border | 1–2 px solid, Bronze `#7a5c28` |
| Corner radius | 0–2 px |
| Text area | Must be clearly readable — center area must be flat and dark |
| 9-slice margins | Same as `UI_Frame_Panel_Base.png` — button width varies per scene |
| Transparent bg | Yes |

Design notes:
- Match the border style of `UI_Frame_Panel_Base.png` — same bronze color, same thickness.
- The button will display text on top (rendered by Godot, not drawn on the asset). Keep the center area clean and flat.
- At narrow widths (e.g. 80 px), the 9-slice stretch must not distort the corners.

---

### Asset 3 — `UI_Btn_Pressed.png`

**Purpose:** Pressed / active button state. Shown when a button is clicked or held.

| Property | Value |
|---|---|
| Canvas | 128×32 px (same as Normal) |
| Background fill | Darker than Normal — approximately `#08080e` — or use a subtle inset shadow to suggest depth |
| Border | Same bronze `#7a5c28`, or very slightly lighter `#9a7a3a` to indicate activation |
| Corner radius | Same as Normal |
| 9-slice margins | Same as Normal |
| Transparent bg | Yes |

Design notes:
- The pressed state must look visibly different from Normal at a glance — darker fill or slight inset is enough.
- Produce this as a companion to `UI_Btn_Normal.png`. Same dimensions, same structure.
- Do not make the pressed state brighter or more colorful — it should feel like depression, not highlight.

---

### Asset 4 — `UI_BG_Dark.png`

**Purpose:** Full-screen scene background layer, displayed behind all panels and game content.

| Property | Value |
|---|---|
| Canvas | 1280×720 px |
| Fill | Near-black, approximately `#0d0d14` |
| Texture | Flat solid fill preferred. Very subtle noise or grain is acceptable — not required. |
| Vignette | Optional — a very faint darkening toward corners is acceptable |
| Transparent bg | No — this asset has a solid fill (it is the background) |
| 9-slice | No |

Design notes:
- This must be darker than `UI_Frame_Panel_Base.png` interior to create visual depth.
- If you add subtle noise or vignette, keep it very faint — it should not be noticeable at a glance, only felt.
- This is used as a static background layer in Godot via `TextureRect` (no tiling needed).

---

## Acceptance Criteria

Each asset must pass all of the following before acceptance.

**Format**
- PNG file format
- Correct canvas size as specified
- Transparent background where specified; solid fill for `UI_BG_Dark.png`

**Pixel Art Quality**
- No anti-aliasing (no semi-transparent pixels on edges or borders)
- No blur, no soft edges
- Border pixels must be solid and crisp at 1× zoom

**Style Consistency**
- Dark panel fill darker than `Bone White`, lighter than `Void Black`
- Bronze border matches `#7a5c28` (±5 value tolerance)
- No high-saturation colors in this batch

**Naming**
- Filenames match exactly: `UI_Frame_Panel_Base.png`, `UI_Btn_Normal.png`, `UI_Btn_Pressed.png`, `UI_BG_Dark.png`
- No size suffix (e.g. `_48`, `_128`) — filename only (P3-D003)

**9-slice compatibility**
- `UI_Frame_Panel_Base.png` and both button assets must be 9-slice compatible in Godot 4 (`StyleBoxTexture`)
- Corners must remain pixel-perfect when the asset is stretched horizontally or vertically

**Delivery**
- All 4 assets in a single folder named `batch1_ui_frames/`

---

## Revision Policy

- One revision cycle is included per asset.
- If an asset fails Acceptance Criteria, specific feedback will be provided (which criteria failed and why).
- Style direction questions: ask before producing.

---

## Notes for Pixel Apprentice

**Superseded document notice:** The earlier `Pixel_Apprentice_Initial_Asset_Request_Pack_v1.0.md` had some inconsistencies that have since been resolved. Please use **this document and subsequent batch requests** as the authoritative source. Specifically:
- Filenames have **no size suffix** (P3-D003) — ignore the `_64` / `_32` suffixes in the old pack.
- All icon canvases are **64×64** (P3-D002) — this applies to Batch 2, not this batch.
- Enemy sprite filename is `ENM_BoneWalker_Sheet.png` (P3-D004) — not `ENM_Skeleton_Sheet.png`.

**What comes next (Batch 2 — Icons):** After Batch 1 is approved, Batch 2 will cover all P0 icons (`ICO_WPN_*`, `ICO_ARM_*`, `ICO_ACC_*`, `ICO_Gold`, `ICO_HP`, `ICO_MAT_RelicShard`). All icons are 64×64 canvas, 48×48 safe area, no size suffix in filename.

Full scope reference: `docs/archives/ArtArchive/Completed/Phase3A_Scope_Adoption_Completed_v1.1.md`
