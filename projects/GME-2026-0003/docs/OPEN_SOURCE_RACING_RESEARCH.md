# Turbo Rush 1.9.0 — Open-Source Racing Research

## What was researched

The update was compared against current Godot racing examples and Godot Asset Library entries that are MIT or otherwise permissively licensed.

### Useful patterns adopted

- **Race HUD + minimap + checkpoints:** the MIT-licensed Godot 4 racing-game example by chukfinley separates race management, checkpoint handling, HUD and minimap into focused systems. Turbo Rush keeps its own level-based race architecture but now adds a lightweight minimap and checkpoint markers. Source: https://github.com/chukfinley/racing-game
- **Composable vehicle presentation:** the MIT-licensed Godot starter racing kit pattern keeps vehicle logic separate from swappable visual models. Turbo Rush now keeps the existing race/collision logic while using real CC0 car GLBs as the visual layer when available. Source: https://github.com/KenneyNL/Starter-Kit-Racing
- **Vehicle controller and terrain addons:** current Godot Asset Library listings include MIT-licensed Vehicle Controller templates and Terrain3D. They were reviewed as development references, but are not forced into the shipping build because Turbo Rush already has a deterministic procedural track system and a mobile renderer. This avoids adding an unnecessary native/GDExtension dependency to the release APK.

## Asset policy

No source game's code, UI artwork, track layout, or proprietary assets are copied into Turbo Rush. The research is used only for architecture and gameplay patterns.

The supplied asset package was audited separately. The verified CC0 packages are the runtime asset pool. The supplied Ignition Labs package was intentionally excluded because the provided package did not contain license evidence.

## Turbo Rush-specific direction

Turbo Rush remains a finite, level-based racer, not an endless runner. The update prioritizes:

1. reliable boot to the playable menu;
2. visible real 3D car models;
3. richer racing HUD with a track map;
4. more varied scenery and track dressing;
5. offline-first gameplay with optional ads only;
6. no Aptoide, billing, or IAP features.
