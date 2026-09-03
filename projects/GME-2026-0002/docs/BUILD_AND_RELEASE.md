# Pocket Board 3D Release Checklist

## Runtime contract

- Offline only.
- No account or login.
- No backend or database.
- No analytics SDK.
- No advertising SDK.
- No in-app purchase SDK.
- No runtime network dependency.

## Before a release

1. Run the Godot headless import check.
2. Run `tests/smoke_test.gd`.
3. Run repository dependency and secret scans.
4. Verify the app launches into the main scene.
5. Verify touch and mouse aiming/shooting.
6. Verify pocket detection, scoring, reset, round progression, and local save.
7. Verify that the package declares only permissions actually used.
8. Generate release manifest and checksum.
9. Keep the prior stable Git tag as the rollback point.

## Store builds

Android: configure signing in the release environment and export APK/AAB with the current supported Godot export templates and Android toolchain.

Desktop: export the platform-specific build from the same Git tag used for the release candidate.

iOS: export/archive through a macOS/Xcode signing environment when required.

This repository does not contain signing keys, keystores, provisioning profiles, or service credentials.
