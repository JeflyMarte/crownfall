# Pixel Apprentice — Initial Asset Request Pack v1.0

Status: Proposal
Type: Asset Production Request
Phase: Phase3-A Visual Production
Created: 2026-06-22
Recipient: Pixel Apprentice
Design Basis: Phase3A_Visual_Production_Proposal_v1.0.md

---

## 0. Overview

This document is the first asset batch request for Crownfall Phase3-A Visual Production.
Pixel Apprentice should use this document as the single source of truth for the initial production run.

Do not invent new styles, sizes, or naming patterns.
If anything is unclear, stop and ask before producing assets.

---

## 1. Production Rules

### Canvas & Format

- Character sprites: 32x32 px
- Boss sprites: 64x64 px
- Tile sprites: 32x32 px
- Icons: 64x64 px canvas, 48x48 px safe area (8 px margin on each side)
- UI elements: variable, specified per asset
- All output: PNG, transparent background
- Color mode: RGB / 8-bit

### Pixel Art Rules

- Pixel-perfect. No anti-aliasing. No sub-pixel rendering.
- Filter: Off (Nearest/Pixel only). No bilinear or trilinear.
- Mipmaps: Off.
- 1px outline (dark). Outline must stay inside the canvas boundary.
- Shading: 2-3 levels maximum per element.
- Color count: 8-16 colors per sprite.

### Platform Context

- Target: iOS (Primary), Android (Secondary)
- Display: Landscape fixed, 1280x720 reference resolution
- Sprites are displayed at 1x to 2x scale on device. Must be readable at 1x.

### Palette

Dark fantasy. Low saturation. Dark tones.

Base colors (use these as your anchors):

```
Void Black    #0d0d0d   — outlines, deepest shadow
Stone Dark    #1e1e2a   — dungeon floor, wall shadow
Stone Mid     #2e2e3e   — wall base, mid-tone
Stone Light   #4a4a5e   — highlights, stone edges
Ash           #9a9a8e   — skin, bone, neutral surfaces
Bone White    #d4cbb8   — undead, ancient material, light highlight
```

Accent colors (use sparingly — max 2 per sprite):

```
Gold          #c8a040   — Legendary items, UI border only
Blood Red     #a02020   — HP, bleed effect, danger
Soul Blue     #4060a0   — magic, special FX
Heal Green    #40a060   — recovery FX
```

Rules:
- No pure white (#ffffff). Use Bone White instead.
- No pure black (#000000). Use Void Black instead.
- No high-saturation colors except Gold on Legendary items.
- Light source: top-left 45 degrees, fixed across all assets.

---

## 2. Naming Rules

### Prefix System

```
CHR_    — Adventurer character
ENM_    — Enemy sprite
BOSS_   — Boss sprite
NPC_    — NPC sprite
WPN_    — Weapon sprite (in-world)
ICO_WPN_  — Weapon icon
ICO_ARM_  — Armor icon
ICO_ACC_  — Accessory icon
ICO_MAT_  — Material icon
ICO_      — General UI icon
TILE_   — Dungeon tile
OBJ_    — Object / prop
FX_     — Visual effect
UI_     — UI element (frame, button, panel)
```

### Format

```
{PREFIX}_{SubCategory}_{Variant}_{Size}.png
```

- Words: PascalCase (no spaces, no hyphens)
- Separator: underscore only
- Size suffix: pixel dimension of the canvas (e.g. _32, _64)
- No Japanese characters in filenames

### Examples

```
ICO_WPN_IronSword_64.png         — Iron Sword icon, 64x64 canvas
ICO_ARM_LeatherArmor_64.png      — Leather Armor icon, 64x64 canvas
ICO_ACC_SilverRing_64.png        — Silver Ring icon, 64x64 canvas
ICO_Gold_32.png                  — Gold UI icon, 32x32 canvas
ICO_MAT_RelicShard_32.png        — Relic Shard icon, 32x32 canvas
ICO_MAT_AncientBone_32.png       — Ancient Bone icon, 32x32 canvas
ENM_FallenSoldier_Sheet_32.png   — Fallen Soldier spritesheet
ENM_Skeleton_Sheet_32.png        — Skeleton spritesheet
OBJ_TreasureChest_32.png         — Treasure Chest object
OBJ_ExitGate_32.png              — Exit Gate object
OBJ_Altar_Ruined_32.png          — Ruined Altar object
UI_Frame_Panel_Base.png          — UI panel frame
UI_Btn_Normal.png                — Button normal state
UI_Btn_Pressed.png               — Button pressed state
```

---

## 3. Initial Asset Batch

### Priority Notation

- P0: Required immediately. Do not proceed to P1 until all P0 assets are approved.
- P1: Start after P0 approval.

---

### Batch A — UI Frames (P0)

These are needed first because they affect all scenes.

---

asset_id: UI_Frame_Panel_Base
category: UI
size: flexible (suggest 9-slice: 48x48 px minimum tile)
animation_frames: 1 (static)
intended_scene: All scenes (BaseScene, DungeonScene, ResultScene, AppraisalScene, EquipmentScene)
priority: P0
notes: >
  Dark flat panel background with thin bronze border (1-2px, color ~#7a5c28).
  Used as the base container for all UI panels.
  Must support 9-slice scaling in Godot (StyleBoxTexture).
  Corner radius: 0-2px (hard edge preferred).
  Interior fill: very dark, slightly blue-gray (~#12121a).
  Do not add decorations or icons to the panel itself.

---

asset_id: UI_Btn_Normal
category: UI
size: 128x32 px (standard button)
animation_frames: 1 (static)
intended_scene: All scenes
priority: P0
notes: >
  Normal (unpressed) button state.
  Dark flat with thin bronze border (~#7a5c28).
  Text area must be clearly readable against the button background.
  Must support 9-slice scaling (width varies per scene).
  Match the panel style — same border treatment.

---

asset_id: UI_Btn_Pressed
category: UI
size: 128x32 px
animation_frames: 1 (static)
intended_scene: All scenes
priority: P0
notes: >
  Pressed/active button state.
  Slightly lighter fill or inset shadow to indicate press.
  Border may lighten slightly (#9a7a3a).
  Produce as a companion to UI_Btn_Normal — same dimensions.

---

asset_id: UI_Btn_Disabled
category: UI
size: 128x32 px
animation_frames: 1 (static)
intended_scene: All scenes (Blacksmith, Merchant)
priority: P1
notes: >
  Disabled button state.
  Desaturated and darkened. Border at ~50% opacity.
  Used when a button action is unavailable (e.g. insufficient Gold for crafting).

---

asset_id: UI_BG_Dark
category: UI
size: 1280x720 px
animation_frames: 1 (static)
intended_scene: All scenes (scene background)
priority: P0
notes: >
  Full-screen dark background.
  Near-black with subtle texture or vignette (optional).
  Base color ~#0d0d14. Very subtle noise or grain is acceptable.
  This is the background layer behind all panels and dungeon content.
  Must tile or fill cleanly at 1280x720.

---

### Batch B — Icons (P0)

Icons are 64x64 canvas. Safe area is 48x48 (8px margin each side).
Light source: top-left 45 degrees.

---

asset_id: ICO_WPN_IronSword
category: Icon / Weapon
size: 64x64 px
animation_frames: 1 (static)
intended_scene: AppraisalScene, EquipmentScene, ResultScene
priority: P0
notes: >
  A basic iron longsword.
  Slightly worn, muted iron tone.
  Blade runs roughly top-left to bottom-right at ~45 degrees (conventional icon angle).
  Simple crossguard. No elaborate decorations.
  Rarity: Common. No glow.
  1px dark outline. 2-3 shading levels on blade.

---

asset_id: ICO_ARM_LeatherArmor
category: Icon / Armor
size: 64x64 px
animation_frames: 1 (static)
intended_scene: AppraisalScene, EquipmentScene, ResultScene
priority: P0
notes: >
  Front-facing leather chestplate.
  Brown leather tones, slightly worn.
  Simple strap details. No metal sheen.
  Rarity: Common. No glow.
  Must be clearly distinguishable from the weapon icon.

---

asset_id: ICO_ACC_SilverRing
category: Icon / Accessory
size: 64x64 px
animation_frames: 1 (static)
intended_scene: AppraisalScene, EquipmentScene, ResultScene
priority: P0
notes: >
  A plain silver ring, viewed at slight 3/4 angle.
  Muted silver tone (~#a0a0b0). Single thin highlight on upper edge.
  No gemstone. Simple band.
  Rarity: Common. No glow.
  Must be distinguishable at 16px display size (small UI).

---

asset_id: ICO_Gold
category: Icon / UI
size: 32x32 px
animation_frames: 1 (static)
intended_scene: All scenes (Gold display in HUD, Merchant, Result, Base)
priority: P0
notes: >
  Gold coin icon. Circular shape.
  Gold tone (#c8a040 base) with 1-2 highlight levels.
  Simple face or blank coin (no detailed engraving needed).
  Must be clearly readable at 16px display size.
  This icon appears more frequently than any other — keep it clean and simple.

---

asset_id: ICO_MAT_RelicShard
category: Icon / Material
size: 32x32 px
animation_frames: 1 (static)
intended_scene: DungeonScene (loot log), future BlacksmithScene
priority: P0
notes: >
  A small fragment of ancient stone or crystal.
  Irregular angular shard shape.
  Muted tones — gray-blue or stone-colored (#4a4a5e range).
  Subtle magical shimmer or faint inner glow acceptable (not bright).
  Category: relic. Rarity: Common (rarity 0). No strong glow.

---

asset_id: ICO_MAT_AncientBone
category: Icon / Material
size: 32x32 px
animation_frames: 1 (static)
intended_scene: DungeonScene (loot log), future BlacksmithScene
priority: P1
notes: >
  A single bone fragment, slightly yellowed.
  Bone White base (#d4cbb8). Slight darkening at the ends.
  Clean, simple silhouette. No gory details.
  Category: bone. Rarity: Common (rarity 0).

---

### Batch C — Unidentified Placeholders (P0)

Unidentified item icons are shown before appraisal. They must be visually distinct from identified icons.

---

asset_id: ICO_WPN_Unidentified
category: Icon / Weapon
size: 64x64 px
animation_frames: 1 (static)
intended_scene: AppraisalScene, ResultScene
priority: P0
notes: >
  A silhouette of a sword shape. Filled with dark gray, no detail.
  A faint question mark or shadow pattern is acceptable.
  Must immediately read as "unknown weapon."
  Same canvas dimensions as ICO_WPN_IronSword.

---

asset_id: ICO_ARM_Unidentified
category: Icon / Armor
size: 64x64 px
animation_frames: 1 (static)
intended_scene: AppraisalScene, ResultScene
priority: P0
notes: >
  Silhouette of an armor shape. Dark gray, no detail.
  Must immediately read as "unknown armor."

---

asset_id: ICO_ACC_Unidentified
category: Icon / Accessory
size: 64x64 px
animation_frames: 1 (static)
intended_scene: AppraisalScene, ResultScene
priority: P0
notes: >
  Silhouette of a ring shape. Dark gray, no detail.
  Must immediately read as "unknown accessory."

---

### Batch D — Enemy Sprites (P1)

Sprites are delivered as spritesheets.
Spritesheet layout (row order):

```
Row 0: Idle    (4 frames)
Row 1: Attack  (4 frames)
Row 2: Hurt    (2 frames)
Row 3: Death   (4 frames)
```

Sheet dimensions: canvas_size x (max_frames wide) x (animation_count tall).
For 32x32 / 4 frames / 4 animations: sheet = 128x128 px.

---

asset_id: ENM_FallenSoldier_Sheet
category: Enemy
size: 32x32 px per frame / sheet: 128x128 px
animation_frames: Idle x4 / Attack x4 / Hurt x2 / Death x4
intended_scene: DungeonScene (combat)
priority: P1
notes: >
  Dungeon: royal_ruins (王都跡).
  A former human soldier in rusted, falling-apart armor.
  Wields a corroded sword.
  Posture is slightly hunched — no longer fully upright.
  Color: Iron gray (#4a4a5e), rust accents (#7a3a20), dark leather straps.
  Enemy type: Human. No supernatural features.
  Top-down angled view (consistent with Crownfall dungeon camera).

---

asset_id: ENM_Skeleton_Sheet
category: Enemy
size: 32x32 px per frame / sheet: 128x128 px
animation_frames: Idle x4 / Attack x4 / Hurt x2 / Death x4
intended_scene: DungeonScene (combat)
priority: P1
notes: >
  Dungeon: graveyard (白骸墓地). Corresponds to bone_walker in game data.
  A walking skeleton soldier. Bone structure clearly visible.
  May carry a crude weapon (sword or spear — choose one).
  Color: Bone White (#d4cbb8) with Stone Dark (#1e1e2a) shadows.
  Enemy type: Undead. Hollow eye sockets with faint Soul Blue glow acceptable.
  Top-down angled view.

---

### Batch E — Objects / Props (P1)

---

asset_id: OBJ_TreasureChest_Closed
category: Object
size: 32x32 px
animation_frames: 1 (static)
intended_scene: DungeonScene (Treasure Room)
priority: P1
notes: >
  A closed treasure chest. Wooden with iron bands.
  Muted brown (#5a3a1e) with dark iron fittings (#2e2e3e).
  Gold keyhole detail (small, ~#c8a040).
  Must be readable at 32x32. Keep silhouette clean.

---

asset_id: OBJ_TreasureChest_Open
category: Object
size: 32x32 px
animation_frames: 1 (static)
intended_scene: DungeonScene (post-open state)
priority: P1
notes: >
  Same chest as above with lid open.
  Faint gold shimmer inside is acceptable.
  Must match OBJ_TreasureChest_Closed in style and palette.

---

asset_id: OBJ_ExitGate
category: Object
size: 32x32 px
animation_frames: 1 (static)
intended_scene: DungeonScene (EXIT room)
priority: P1
notes: >
  An archway or gate indicating dungeon exit.
  Royal ruins version: crumbling stone arch, faint light beyond.
  Color: Stone Mid (#2e2e3e) with Bone White (#d4cbb8) highlight on edges.
  Must read as "exit" clearly at 32x32.

---

asset_id: OBJ_Altar_Ruined
category: Object
size: 32x32 px
animation_frames: 1 (static)
intended_scene: DungeonScene (Event Room — fallen altar event)
priority: P1
notes: >
  A crumbled stone altar. Partially collapsed.
  Stone texture, cracks visible.
  A faint residual magical glow (Soul Blue, very subtle) is optional.
  Color: Stone Mid to Stone Light range.

---

## 4. Acceptance Criteria

Each delivered asset must pass all of the following before acceptance.

Format
- PNG file format
- Transparent background (no white or colored fill behind sprite)
- Correct canvas size as specified per asset

Pixel Art Quality
- No anti-aliasing (no semi-transparent pixels on outlines)
- No blur or soft edges
- 1px outline on all character/object sprites
- Readable at 1x display size (no detail lost at native resolution)

Style Consistency
- Matches Crownfall dark fantasy palette (see Section 1)
- No high-saturation colors except Gold on Legendary (none in this batch)
- Light source consistent: top-left 45 degrees
- Outline color: Void Black (#0d0d0d) or Stone Dark (#1e1e2a)

Naming
- File name matches exactly the asset_id in this document with size suffix
- No spaces, no Japanese characters, no hyphens

Delivery
- All assets in a single delivery folder, organized by category:
  ui/ icons/ enemies/ objects/

---

## 5. Revision Policy

- One revision cycle is included per asset.
- If an asset fails Acceptance Criteria, return it with specific feedback (which criteria failed and why).
- If the style direction is unclear from this document, ask before producing — do not guess.

---

## 6. Out of Scope for This Batch

The following are NOT included in this request. Do not produce them.

- Boss sprites (separate request)
- Adventurer sprites (separate request)
- Dungeon tile sets (separate request)
- VFX / FX animations (separate request)
- Audio assets
- 3D assets of any kind
- Animated icons
- Legendary item glow effects
