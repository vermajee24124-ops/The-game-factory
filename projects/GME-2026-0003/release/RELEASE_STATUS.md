# Turbo Rush Release Status

## Current release

Turbo Rush is a standalone, offline-first level-based racing game. CodeCraft is not required and is not used by the game runtime.

## Core game implemented

- Godot 4.7.2 pinned
- finite level-based racing
- 1 player + 5 AI
- deterministic procedural level generation
- Standard / Sprint / Endurance / Elite races
- traffic, obstacles, coins, diamonds and boost
- damage, wreck and revive flow
- rank / chest / bonus / star rewards
- level unlock and repeat-failure assist
- 54 cars, 60 wheels, seven upgrade stats, paints and wheels
- 54 cosmetic skins and 48 collectible cards
- local JSON save, backup and SHA-256 integrity check
- landscape mobile UI and touch controls
- 10,000-level smoke-test coverage

## Monetization status

- No in-app purchase catalog
- No billing manager
- No external payment SDK
- No paid-content entitlement system
- Optional rewarded/interstitial/banner advertising only when the applicable platform integration and user choice allow it
- Core racing and progression remain playable offline

## Web release

- Godot 4.7.2 Web export
- Single-threaded Web preset for broad host compatibility
- Custom HTML shell supports host-aware CrazyGames integration
- GameDistribution adapter activates only when a real publisher game ID is configured
- Generic hosts such as itch.io receive a clean playable Web build without a forced external ad SDK

## Android release

- Package: `com.vermajeeverma.turborush`
- arm64-v8a
- landscape
- release APK and AAB presets
- Unity Ads Android bridge packaged through the Godot v2 Android plugin architecture
- Unity Ads Game ID configured
- Banner, rewarded and interstitial placements configured as release identifiers in the project
- consent choice is required before native ads initialize
- no advertising failure blocks gameplay

## Production gates

1. Build/import/smoke tests pass.
2. Release APK/AAB are signed.
3. APK signature, package, version and hashes are validated.
4. Web export is generated and structurally validated.
5. Live ad account/placement configuration is confirmed in the relevant dashboards.
6. The publisher uses a persistent production signing key for future updates.
7. Real-device installation and touch/performance testing is completed before public store submission.

The CI workflow does not export a generated signing key or password.
