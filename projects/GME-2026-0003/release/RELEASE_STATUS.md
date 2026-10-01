# Turbo Rush Release Status

## Standalone 1.0 target

The current 1.0 target is a standalone, offline-first racing game. CodeCraft is not required and is not used by the game runtime.

## Core completed
- Godot 4.7.2 pinned
- finite level-based racing
- 1 player + 5 AI
- deterministic procedural level generation
- Standard / Sprint / Endurance / Elite races
- traffic, obstacles, coins, diamonds and boost
- damage, wreck and revive flow
- rank/chest/bonus/star rewards
- level unlock and repeat-failure assist
- six cars, seven upgrade stats, paints and wheels
- local JSON save, backup and SHA-256 integrity check
- landscape mobile UI and touch controls
- 10,000-level smoke test coverage

## Deferred to future updates
- Epic/online services and global leaderboards
- Native Unity Ads integration
- Native Aptoide billing and purchase validation
- remote analytics/live services
- additional online events

These features are intentionally not required for the standalone core game.

## Remaining release gates
- Godot Android export completes successfully
- install/test the APK on a real Android device
- real-device performance check
- final store metadata/compliance check
- production signing key for the final release build

The current repository includes an Android build workflow for a signed debug APK suitable for device testing. A production-store release must use the publisher's own release keystore and should not ship with the debug signing key.
