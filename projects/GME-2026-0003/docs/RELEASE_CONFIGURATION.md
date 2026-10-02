# Turbo Rush Release Configuration

## Canonical identity
- App name: Turbo Rush
- Android package: com.vermajeeverma.turborush
- Support: vermagamestudios@gmail.com
- Engine: Godot 4.7.2
- Release version: 1.7.0
- Android architecture: arm64-v8a
- Orientation: landscape
- Core mode: offline-first finite level racing
- Billing: disabled and removed

## Android advertising
Unity Ads Android SDK target: 4.20.1.

Configured Android placements:
- Banner_Android
- Rewarded_Android
- Interstitial_Android

Behavior:
- Banner top + bottom only on the startup/loading screen.
- Rewarded ad only after an explicit player action.
- Interstitial only at the results/menu break and subject to the in-game frequency gate.
- Ad failure never blocks gameplay.

The native bridge is packaged as the Godot v2 Android plugin TurboUnityAds. The project uses the Gradle-based Godot Android plugin architecture.

## Web advertising
The Web export is host-aware:
- CrazyGames SDK can be enabled by the custom HTML shell.
- GameDistribution can be enabled when its game ID is configured.
- A normal generic WebGL host remains playable without an external advertising SDK.
- Startup banner placements never overlap the race HUD.

## Payments and external billing
Turbo Rush 1.7 contains:
- no in-app purchase product catalog
- no billing manager
- no external billing SDK
- no purchase restore flow
- no paid-content entitlement system

All cars, wheels, skins, cards, currencies, upgrades and progression are earned through gameplay.

## Signing
A release keystore should be persistent for all future updates. GitHub Actions uses the publisher keystore secrets when configured; otherwise CI can create a temporary verification signer, which must not be treated as the long-term update key.

## Final release evidence
The CI artifact must include:
- signed release APK
- release AAB
- Web package
- APK signing verification
- APK/AAB hashes
- import log
- smoke-test log
- export logs
- build information
