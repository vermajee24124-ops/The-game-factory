# Bolt & Board Puzzle — gameplay specification

## Startup flow
1. Show an original studio splash and local asset-loading screen.
2. On first launch, explain exposed screws, board clearing and layer reveal in a short tutorial.
3. Open the menu and level selection before gameplay.

The loading screen does not claim to download online content. Ads, online rankings and purchases are not implemented; they need separate SDK, privacy and consent work.

## Core loop
1. Inspect a stack of interlocked wooden beams from a readable portrait top-down camera.
2. Tap an exposed, coloured screw. The screw animates into a five-slot spare tray.
3. Tap the matching Coral, Ocean or Gold toolbox to sort every stored screw of that colour.
4. Each beam falls away after all its screws are extracted, revealing beams below it.
5. Clear every beam and sort every screw to complete the level.

## Current prototype
- Two to five stacked layers, each built from two to four separate wooden plates.
- Four deterministic plate-layout families: paired horizontal planks, three vertical planks, a three-piece side-and-center layout and three horizontal strips.
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
- More authored level definitions and solver-validated colour-sorting sequences.
- Authored and solver-validated campaign levels.
- First-run tutorial, accessibility settings and save migration.
- Android performance and touch testing on physical devices.
- Release AAB and secure release signing; never store a release key in the public repository.
- Monetization, ads consent/privacy and Play policy checks only after core gameplay QA.
