# Turbo Rush

Godot 4.7.2-first mobile 3D arcade racing game built from the six canonical specification documents.

## Current integrated build

This branch contains a playable, asset-light core implementation designed to validate the complete race loop before native store SDKs are attached.

Implemented:
- finite level-based races
- 1 player + 5 AI racers
- deterministic procedural tracks
- Standard / Sprint / Endurance / Elite race types
- traffic, obstacles, coins, boost pickups and rare diamonds
- damage / wreck / revive flow
- rank rewards, bounded reward chests, random bonus, stars
- top-5 next-level unlock rule
- assist mode after repeated failures
- local JSON save with backup and SHA-256 integrity check
- global performance upgrades
- car unlock and selection
- paints and wheels catalog/equipment
- landscape UI with touch controls
- offline-safe optional ads with platform-specific adapters
- 10,000-level deterministic smoke-test coverage

## Release-stage adapters

Billing and Aptoide Connect integration are intentionally removed from Turbo Rush 1.6.0. The game has no in-app purchase path.

Native ads, native store billing, purchase validation, consent/ATT, production assets and device-matrix profiling are intentionally adapter points. The base build never invents a successful purchase or ad reward.

## Run

Open godot/project.godot with Godot 4.7.2 and run.
