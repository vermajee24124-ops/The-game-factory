# Turbo Rush 2.0.0

Godot 4.7.2-first, offline-first 3D arcade racing game for Android and iOS, designed around finite level-based races rather than endless running.

## Expanded content

- **100 selectable car entries**, with progressive stats, unlocks and eight procedural fallback body silhouettes.
- **60 wheel/rim styles** and **48 tyre setups** with different surface specialisation, grip, acceleration and braking values.
- **200 named procedural track blueprints** that tune curve, jump, boost, traffic and road-width patterns. Each level builds a seeded route from a blueprint; these are not 200 individually handcrafted track scenes.
- 54 paint/skin choices and 48 collectible cards.
- 1 player versus 5 AI racers; Standard, Sprint, Endurance and Elite races; countdown, traffic, obstacles, coins, boosts, rare diamonds, damage/revive, rank rewards, upgrades and level unlocking.
- Offline local save data with backup/migration, landscape UI and mobile touch controls.
- CC0 vehicle and scenery models are curated from public source packs during the Android build workflow. Procedural visuals remain available if the optional models are absent.

## Art and licence scope

The Android build pipeline packages 29 distinct Kenney CC0 vehicle models, including race cars, sedans, SUVs, karts and utility vehicles, plus curated road-side and city scenery. The 100 garage entries are gameplay/progression variants, not 100 individually bespoke 3D meshes: they use these real model families, colour/skin tinting, unique stats and eight lightweight procedural fallback silhouettes. Similarly, the 200 tracks are seeded generated archetypes, not separate hand-authored maps. This keeps downloads and memory use manageable for mobile devices.

The unverified Ignition Labs car model from the supplied archive is excluded because its package did not provide sufficient licence evidence. See `godot/THIRD_PARTY_NOTICES.md` and `docs/CC0_ASSET_SELECTION.md`.

## Current validation state

The content and code expansion is committed on a feature branch. **Do not treat it as a store-ready release until the Godot 4.7.2 headless import, updated smoke tests, Android export, device launch/playthrough, performance review, security review and store/privacy compliance all pass.** The manifest marks those gates as pending until verified.

## Run

Open `godot/project.godot` in Godot 4.7.2 and run the main scene. The core game uses procedural fallbacks, while the Android build workflow downloads, indexes and imports the curated CC0 models.
