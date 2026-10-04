# Turbo Rush Studio Upgrade

## Completed in this pass
- Dedicated StudioPolish runtime layer added without replacing the existing game architecture.
- Premium showroom enhancement with illuminated turntable ring, side pillars and accent lighting.
- Race-world enhancement hooks using the generated route: roadside lighting, banners, start arch and distant skyline blocks.
- Speed/boost camera feedback added on top of the existing chase camera.
- Game remains finite and level-based, not endless.
- Existing economy, progression, garage, cars, wheels, skins, cards, rewards, save system and offline-first race flow preserved.
- Third-party asset/license record created from the supplied archive.
- Native Android ad bridge isolated behind the Godot v2 plugin adapter.
- No paid purchase or external billing runtime is included.

## Asset audit
The supplied archive contains Kenney Car Kit, Racing Kit, City Kit Roads, City Kit Commercial, City Kit Suburban, City Kit Industrial, Modular Racetrack CC0, Racing Cars Mega Pack, and an Ignition Labs vehicle package. The Ignition Labs package is excluded from runtime use until its license is independently verified.

## Verification
The GitHub Android pipeline is the source of build verification. The release pipeline must pass headless import, smoke tests, APK signature validation, AAB structure validation, hashes and Web export generation before an artifact is considered build-valid.

## Publishing note
A release artifact is only store-ready after the publisher confirms live ad dashboard configuration, privacy/consent setup and a persistent signing key for future updates.
