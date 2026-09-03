# Pocket Board 3D

Original offline 3D carrom-style board game inspired by the broad visual category shown in the supplied store screenshot. It does not copy the original app's branding, art, text, or proprietary assets.

## Runtime

- Fully offline.
- No database.
- No account/login.
- No ads.
- No in-app purchases.
- Local JSON save only.
- Two modes: solo practice and local pass-and-play foundation.

## Controls

- Desktop: press and drag with the primary mouse button from the striker direction, then release to shoot.
- Touch: drag from the striker direction and release to shoot.
- `R`: reset the match.
- `N`: start a new round.

## Assets

The board, pieces, lighting, UI, and decorative geometry are generated using Godot primitives. No external asset dependency is required for the base build.

## Engine policy

Godot 4.7.2 stable is pinned in `../engine.lock`. Engine upgrades must be evaluated on an isolated migration branch and pass build, gameplay, performance, security, and release checks before becoming the new stable baseline.
