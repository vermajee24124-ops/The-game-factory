# Turbo Rush Release Status

## Current 1.0 target

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
- local JSON save, backup and SHA-256 integrity check
- landscape mobile UI and touch controls
- 10,000-level smoke-test coverage

## Release configuration now added

- Android package: `com.vermajeeverma.turborush`
- Support email: `vermagamestudios@gmail.com`
- Unity Android Game ID: `6195679`
- Unity iOS Game ID: `6195678`
- Aptoide public key stored in `autoload/ReleaseConfig.gd`
- 54 fixed cosmetic skins, 48 collectible cards, 54 cars and 60 wheels added to the content catalog
- Aptoide catalog expanded to 10 fixed-content products: 9 mixed bundles plus Remove Ads
- Mixed bundles can contain coins, diamonds, skins and cards; paid contents are disclosed, not randomized
- Reference price anchors: $0.99 / $2.99 / $3.49 / $4.99 / $5.99 / $7.99 / $9.99 / $14.99, plus $2.99 Remove Ads
- Final localized storefront prices must be configured and served by Aptoide Connect
- Shared Banner_Android configuration is prepared for top and bottom banner instances during startup/loading only
- Daily Rewards screen now exposes three optional rewarded-ad claims/day; 90% coin outcomes and 10% diamond outcomes in the game-side reward pool
- Player can equip one owned skin and up to three owned cards; cards provide small passive modifiers

## Still not safe to mark live

The content catalog and store mapping are implemented in the Godot client, but Aptoide purchases are not yet a live transaction path until the native billing bridge and verification flow are installed.

The following require exact external values or native runtime wiring and therefore are not claimed as live:

- Native Unity Ads bridge and exact Android Ad Unit IDs
- Native Aptoide Billing bridge and live product registration
- Server-side purchase validation
- Background Android notification scheduler
- Production release signing key

## Release gates

- export the Android APK successfully
- install and play on a real Android device
- verify startup logo/loading/lobby flow
- verify top and bottom banners only during startup/loading
- verify rewarded and interstitial behavior after native bridge integration
- verify Aptoide sandbox purchase, cancellation, failure, restore and entitlement delivery
- verify notification permission/settings behavior
- complete store metadata, privacy and compliance forms
- sign the final production build with the publisher-controlled release keystore

The repository's existing Android workflow is a debug build workflow. A debug-signed APK is suitable for device testing but is not the production-store signing credential.
