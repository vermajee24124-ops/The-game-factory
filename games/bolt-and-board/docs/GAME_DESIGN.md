# Bolt & Board Puzzle — gameplay specification

## Startup flow

1. Show an original studio splash and local asset-loading screen.
2. On first launch, explain exposed screws, color toolboxes and the five-slot temporary tray.
3. Open the main menu and level select before gameplay.

The loading screen is local. It does not pretend to download remote content. Ads, online rankings and purchases are not implemented.

## Core puzzle loop

1. Inspect stacked wooden plates and their screws.
2. Tap an exposed screw. A plate above it blocks access to hidden screws.
3. If the screw matches the active toolbox color, it fills that toolbox.
4. A different color is stored in the five-slot temporary tray.
5. When the next color toolbox becomes active, matching screws already in the temporary tray transfer automatically.
6. Filling all five temporary slots fails the attempt and opens retry.
7. Each plate falls only after its own screws are removed. Lower screws remain blocked until the fall animation finishes.
8. Clear every plate and complete every toolbox to win.

## Visual and performance pass

- Generated PBR wood and brushed-steel albedo, normal and roughness maps.
- Walnut-style stage, rounded brass-style plate trim and textured wooden plate sides.
- Filmic tone mapping, procedural sky, warm key light, cool fill, directional shadows and restrained glow.
- Mobile 3D MSAA and filtered mipmaps.
- Shared screw meshes to reduce repeated geometry allocation.
- Tapered colored steel screw heads, washer lips, helical threads and recessed drive slots.
- Screw spin/extraction, color pop feedback and plate-fall animation.
- Camera drag-orbit and pinch-to-zoom for mobile inspection.

## Current campaign generator

- 2 to 5 stacked layers.
- 2 to 4 plates per layer, selected from six deterministic layout families.
- Four screw colors.
- Six screw patterns with a maximum of six screws per plate.
- 30 levels use procedural variations; they are not yet 30 hand-designed or solver-validated commercial puzzles.

## Sorting rules

- Each screw has one of four colors.
- The active toolbox accepts its target color in batches of up to three.
- Screws of other colors occupy the five temporary slots.
- When the next toolbox becomes active, matching stored screws transfer automatically.
- Filling all five temporary slots fails the attempt.
- Toolbox batch counts are generated from the actual screw colors in the level.

## Current validation

Godot regression tests and ARM64 debug export both passed on 3 November 2026. See docs/TEST_STATUS.md for run IDs, commit and APK hash.

## Remaining production work

- More obstacle types and carefully balanced puzzle layouts.
- Solver-validated authored levels and difficulty progression.
- Further booster systems and accessible controls.
- Physical Android touch/performance QA.
- Release AAB and secure private signing process.
- Privacy, consent, monetization and store-policy implementation.
