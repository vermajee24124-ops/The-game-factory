# CC0 Runtime Asset Selection

Turbo Rush keeps a curated selection of low-poly models for its Android runtime, to reduce load time, storage use and draw calls on mobile devices. The Android workflow downloads source archives, extracts model/texture files, copies only a selected set into `godot/assets/studio`, imports them with Godot 4.7.2, and emits file hashes and a model index.

## Model sources

- Kenney Car Kit — https://opengameart.org/content/car-kit — documented as CC0-1.0.
- Kenney Racing Kit — https://opengameart.org/content/racing-kit — documented as CC0-1.0.
- Kenney City Kit Roads — https://opengameart.org/content/city-kit-roads — documented as CC0-1.0.
- Kenney City Kit Commercial — https://opengameart.org/content/city-kit-commercial — documented as CC0-1.0.
- Kenney City Kit Suburban — https://opengameart.org/content/city-kit-suburban — documented as CC0-1.0.
- Kenney City Kit Industrial — https://opengameart.org/content/city-kit-industrial — documented as CC0-1.0.

## Runtime selection

The Android workflow curates 29 distinct selectable vehicle models from the Kenney Car Kit and Racing Kit (race cars, sedans/SUVs, karts, vans, delivery vehicles, utility trucks and four racing-colour variants), plus wheel/body textures, racing stands/barriers, roadside lights, buildings and industrial props. Models are selected deterministically from the garage entry ID, and their materials are tinted per instance for paint variation. The core project keeps a procedural visual fallback when optional models aren't present.

The garage catalogue has **100 selectable gameplay/progression car entries**. It does **not** claim to contain 100 individually authored car models: the runtime uses available CC0 vehicle variants and eight lightweight procedural fallback silhouettes. The game also has **48 tyre parameter setups**, not 48 separately sculpted tyre meshes. The **200 track profiles** are seeded procedural archetypes that influence route segment selection, jumps, boosts, traffic, surface and width, not 200 hand-authored track scenes.

## Licence and safety checks

The build process deliberately excludes the supplied file labelled “CAR Model by Ignition Labs” because the supplied archive lacked sufficient licence/readme evidence to verify redistribution rights. Keep source READMEs and any included notices during extraction, inspect downloaded archives for nested third-party assets, and review the generated model hashes before publishing a release.
