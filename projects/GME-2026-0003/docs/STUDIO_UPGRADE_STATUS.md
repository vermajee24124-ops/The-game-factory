# Turbo Rush 2.0.0 Upgrade Status

## Implemented on the feature branch

- Increased the selectable vehicle catalogue to 100 entries while preserving existing car IDs for saves.
- Added eight lightweight procedural vehicle body silhouettes for the fallback renderer.
- Kept the 60 existing wheel/rim options and added 48 tyre setups with compound, surface, grip, acceleration, braking, cost and level data.
- Added tyre purchase/equip logic, save migration and garage selection UI.
- Tyre settings affect player acceleration, braking and steering grip. Rain, snow, ice and sand-type conditions provide surface-match adjustments.
- Added 200 unique, named procedural track blueprints. The selected blueprint affects surface material, route width and track-module distribution for curves, jumps, boosts and traffic.
- Expanded headless smoke-test assertions to cover the catalogue and 200 track profiles plus deterministic generation across 10,000 levels.
- Updated project version and manifest. Build/tests/security/compliance release gates are deliberately pending, not marked as passed.
- Kept the CC0 model workflow and excluded the unverified Ignition Labs car asset.

## Honest content limits

- The 100 vehicle items are garage/progression entries, not 100 individually sculpted vehicle meshes. They share eight procedural fallback silhouettes and can use the curated CC0 GLB variants supplied by the Android workflow.
- The 200 track items are deterministic named blueprints that produce seeded layouts, not 200 unique hand-authored track scenes.
- The 48 tyre setups have distinct gameplay parameters; they do not imply 48 separately modelled 3D tyre meshes.
- An entry in source code or a passing catalogue test does not alone establish visual quality, safe performance, or store readiness.

## Remaining release gates

1. Run Godot 4.7.2 headless import and the updated smoke-test workflow; fix any parser, type or runtime errors found.
2. Complete an Android release export and check artifact size, signatures and install/launch.
3. Play through races on physical devices, including a lower-memory phone; verify controls, collisions, AI, race completion, tyre selection and save migration.
4. Profile frame rate, loading, memory and thermal behaviour; tune art and effects for mobile.
5. Audit CC0 source archives, hashes and included notices.
6. Complete security, privacy/consent, advertising and store-policy review.

**Status: validation required. This is not yet certified studio/production-ready until those checks are complete.**
