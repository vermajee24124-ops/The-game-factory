# Bolt & Board Puzzle — gameplay specification

## Startup flow
1. Show an original studio splash and local asset-loading screen.
2. On first launch, explain exposed screws, board clearing and layer reveal in a short tutorial.
3. Open the menu and level selection before gameplay.

The loading screen does not claim to download online content. Ads, online rankings and purchases are not implemented; they need separate SDK, privacy and consent work.

## Core loop
1. Inspect stacked wooden boards.
2. Tap screws that are not occluded by a board above them. Touch input uses screen-space picking with an accessibility radius, then keeps the board-occlusion rule.
3. Remove every screw holding an exposed wooden plate.
4. That plate animates away independently; other plates in the same layer remain.
5. Clear the upper layer to expose lower plates, then clear every plate to finish.

## Visual quality pass
- Procedural wood grain plus generated normal and roughness maps for wood and brushed steel.
- Procedural sky, filmic tone mapping, warm/cool lighting, soft directional shadows and restrained glow.
- 2x mobile 3D MSAA and non-nearest mipmap filtering.
- Detailed tapered screw head, machined rim and color-coded removal ring feedback.
- Separate original sounds for color match and a full tray.

## Current prototype
- Two to five stacked layers, each built from two to four separate wooden plates.
- Six deterministic plate-layout families: paired horizontal planks, three vertical planks, side-and-center pieces, three horizontal strips, an L-shaped arrangement and four corner plates.
- Six deterministic screw layouts capped at six screws per plate; board placement and size vary with the level number.
- Elapsed-time HUD for active gameplay.
- Board occlusion collision included in the tap ray query, with exposed-screw screen-space touch picking as a reliable mobile fallback.
- Full-screen UI layout passes empty-area touch input through to the 3D board.
- Original branded startup/loading screen and first-run tutorial.
- Individual screw objects with metallic heads, shafts, washers and thread rings.
- Level Select with sequential unlocks and local progress save.
- Pause, resume, restart, return to menu and persistent sound setting.
- Completion summary with elapsed time, hint count and a simple three-star score.

## Important distinction
The current 30 levels combine procedural plate layouts and screw patterns. They are not yet 30 handcrafted, solver-validated commercial levels.

## Production roadmap
- More board silhouettes, angles and genuinely different interlocking layouts.
- Solver-checked color-toolbox sequences, five-slot temporary storage and later booster types.
- Authored and solver-validated campaign levels.
- First-run tutorial, accessibility settings and save migration.
- Android performance and touch testing on physical devices.
- Release AAB and secure release signing; never store a release key in the public repository.
- Monetization, ads consent/privacy and Play policy checks only after core gameplay QA.


## Premium redesign branch

The `premium-screw-puzzle` branch adds:
- PBR wood and brushed-steel materials with generated normal/roughness maps, plus a warm walnut stage and rounded brass-style plate edging.
- Four screw colors, a five-slot temporary tray, active color toolboxes and a retry state when the tray fills.
- More detailed screw threads, washer lips, raised wood tops, edge trim and metallic stage detailing.
- Filmic tone mapping, restrained glow, MSAA and a mobile-first lighting rig.
- Touch drag camera orbit and pinch zoom.
- Stronger screw extraction and board-fall animation timing.

Renderer choice remains the Godot Mobile renderer to balance visual quality with Android device support. The game still requires real-device performance and touch QA before it can be called production-ready.


## Current sorting loop
- Each screw has one of four colors.
- The active toolbox accepts only its target color, in batches of up to three screws.
- Screws of other colors occupy the five temporary slots.
- When the next toolbox becomes active, matching screws already stored in the tray transfer automatically.
- Filling all five temporary slots fails the attempt; all color counts are generated from the level's actual screws.
