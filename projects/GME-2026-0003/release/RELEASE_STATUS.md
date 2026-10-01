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
- six cars, seven upgrade stats, paints and wheels
- local JSON save, backup and SHA-256 integrity check
- landscape mobile UI and touch controls
- 10,000-level smoke-test coverage

## Release configuration now added

- Android package: `com.vermajeeverma.turborush`
- Support email: `vermagamestudios@gmail.com`
- Unity Android Game ID: `6195679`
- Unity iOS Game ID: `6195678`
- Aptoide public key stored in `autoload/ReleaseConfig.gd`
- Five stable Aptoide product IDs aligned with the current economy model
- Shared Banner_Android configuration is prepared for top and bottom banner instances during startup/loading only

## Still not safe to mark live

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
