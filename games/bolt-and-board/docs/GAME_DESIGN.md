# Bolt & Board Puzzle — gameplay specification

## Core loop
1. Inspect stacked wooden boards.
2. Tap screws that are not occluded by a board above them.
3. Remove every screw from the currently accessible board.
4. The cleared board animates down and away, revealing the next board.
5. Clear all boards to finish the level.

## Current prototype
- Two to five stacked board layers.
- Six deterministic screw layouts selected by level and board layer.
- Board placement and board size vary deterministically with the level number.
- Board occlusion collision included in the tap ray query.
- Individual screw objects with metallic heads, shafts, washers and thread rings.
- Level Select with sequential unlocks and local progress save.
- Pause, resume, restart, return to menu and persistent sound setting.
- Completion summary with elapsed time, hint count and a simple three-star score.

## Important distinction
The current 30 levels are procedural variations of the same core board stack. They are not yet 30 handcrafted, professionally balanced commercial levels.

## Production roadmap
- More board silhouettes, angles and genuinely different interlocking layouts.
- Optional screw tray capacity and color-match modes.
- Authored and solver-validated campaign levels.
- First-run tutorial, accessibility settings and save migration.
- Android performance and touch testing on physical devices.
- Release AAB and secure release signing; never store a release key in the public repository.
- Monetization, ads consent/privacy and Play policy checks only after core gameplay QA.
