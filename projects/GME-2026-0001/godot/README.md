# Blocky Ramp Rush: Stunt Legends

Initial production project for `GME-2026-0001`.

## Runtime goal

- Offline-first 3D low-poly stunt runner.
- Procedurally generated endless ramp track.
- Three-lane auto-run vehicle controller.
- Coins and diamonds.
- Obstacles and ramps.
- Touch gestures plus keyboard fallback.
- Local best-score persistence.

## Controls

- Swipe left/right: change lane.
- Swipe up: jump/flip.
- Tap: boost.
- A/D or Left/Right: lane change.
- Space: jump.
- B: boost.
- P: power-up.

## Asset policy

The first build intentionally uses Godot-generated primitive geometry so that the repository has no third-party asset licensing dependency. Blender/Cosmos/external asset generation can be activated later by the Game Factory only when a richer asset is required.

## Engine

The project is initially pinned to Godot 4.7.2 stable in `engine.lock`. Engine upgrades must happen on a migration branch and pass project, gameplay, performance, security and release checks before becoming the new stable baseline.
