# Bolt & Board Puzzle — gameplay specification

## Core loop
1. Inspect stacked wooden boards.
2. Tap screws that are not occluded by a board above them.
3. Remove every screw from the currently accessible board.
4. The cleared board animates down and away, revealing the next board.
5. Clear all boards to finish the level.

## Current prototype
- Two to five stacked board layers.
- Four corner screws per layer, with more screws on later levels.
- Deterministic board placement based on the level number.
- Board occlusion collision included in the tap ray query.
- Individual screw objects with metallic heads, shafts, washers and thread rings.
- Hint, restart, level progression and local progress save.

## Important distinction
The current 30 levels are procedural variations of the same core board stack. They are not yet 30 handcrafted, professionally balanced commercial levels.

## Production roadmap
- More board silhouettes, angles and interlocking layouts.
- Optional screw tray capacity and color-match modes.
- Authored and solver-validated levels.
- Tutorial, accessibility settings and save migration.
- Monetization, ads consent/privacy and Play policy checks only after core gameplay QA.
- Android performance and touch testing on physical devices.
