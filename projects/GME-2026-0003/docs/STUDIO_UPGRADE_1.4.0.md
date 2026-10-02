# Turbo Rush Studio Upgrade 1.4.0

## Completed in this pass
- Added a dedicated StudioPolish runtime layer without replacing the existing game architecture.
- Added a premium showroom enhancement: illuminated turntable ring, side pillars and accent lighting.
- Added race-world enhancement hooks using the existing generated route: roadside lighting, banners, a start arch and distant skyline blocks.
- Added speed/boost camera feedback on top of the existing chase camera.
- Kept the game finite and level-based, not endless.
- Kept the existing economy, progression, garage, cars, wheels, skins, cards, rewards, save system and offline-first race flow.
- Bumped the project/export version to 1.4.0 (Android version code 8).
- Added a third-party asset/license record based on the supplied asset archive.

## Asset audit
The supplied archive contains Kenney Car Kit, Racing Kit, City Kit Roads, City Kit Commercial, City Kit Suburban, City Kit Industrial, Modular Racetrack CC0, Racing Cars Mega Pack, and an Ignition Labs Lamborghini package. The Ignition Labs package is excluded from runtime use until its license is verified.

## Verification
The GitHub Android pipeline remains the source of build verification. The release pipeline must pass headless import, smoke tests, APK signing validation, AAB structure validation and SHA-256 generation before a release artifact is considered build-valid.

## Important publishing status
A non-debug release build is not the same as a production publishing build when a persistent signing key, live ad units, and live billing/receipt validation are not configured. Do not claim Unity Ads or Aptoide purchases are live unless their native Android bridges and live dashboard/account configuration are verified.
