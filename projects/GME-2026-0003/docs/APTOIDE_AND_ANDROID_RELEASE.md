# Turbo Rush Android + Aptoide Release Setup

## 1. Build baseline

The supplied Skyloom build record documents a successful signed Android build using Godot 4.7.2, Temurin JDK 17.0.12+7, Android SDK platforms 34/36, build-tools 34.0.0/36.1.0, and RSA-2048 release signing.

Turbo Rush keeps the same core toolchain family. Unlike the Skyloom build, Turbo Rush is configured for the Gradle Android build because the final target uses native third-party Android SDK integrations.

## 2. Turbo Rush package

- Application: Turbo Rush
- Package: com.vermajeeverma.turborush
- Version: 1.0.0
- ABI: arm64-v8a
- Orientation: landscape

## 3. Aptoide product catalog

Create these product IDs exactly in Aptoide Connect:

| Product ID | Type | Reference price USD | Coins | Diamonds | Skins | Cards | Cars | Wheels |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| starter_garage | consumable | 0.99 | 1,200 | 60 | 2 | 3 | 2 | 3 |
| racer_bundle | consumable | 2.99 | 5,000 | 180 | 4 | 6 | 4 | 4 |
| pro_garage | consumable | 4.99 | 11,000 | 450 | 7 | 10 | 6 | 6 |
| skin_vault_01 | consumable | 3.49 | 2,500 | 120 | 8 | 2 | 6 | 6 |
| skin_vault_02 | consumable | 4.99 | 4,000 | 200 | 10 | 4 | 7 | 8 |
| card_vault_01 | consumable | 5.99 | 5,000 | 220 | 4 | 10 | 8 | 8 |
| card_vault_02 | consumable | 7.99 | 7,500 | 320 | 6 | 8 | 8 | 8 |
| mega_rush | consumable | 9.99 | 15,000 | 700 | 6 | 3 | 7 | 7 |
| ultimate_garage | consumable | 14.99 | 30,000 | 1,500 | 7 | 2 | 5 | 8 |
| remove_ads | non_consumable | 2.99 | 0 | 0 | 0 | 0 | 0 | 0 |

All paid bundles are fixed-content. There are no paid random loot boxes.

Reference prices are configuration anchors only. The shipped store UI must use product details/prices returned by Aptoide Connect rather than treating these USD values as final localized prices.

## 4. Content catalog

- 54 cars: Rookie GT plus 53 additional vehicles, each with a gameplay ability
- 60 wheels, each with a small gameplay ability
- 54 cosmetic skins: skin_01 through skin_54
- 48 collectible cards: card_01 through card_48
- One skin can be equipped.
- Up to three cards can be equipped.
- Cards provide small passive modifiers to racing stats/rewards.
- Duplicate paid skins convert to 250 Coins.
- Duplicate paid cards convert to 120 Coins.

## 5. Rewarded ads

- Startup banners: top + bottom while logo/loading screen is visible, then hidden before lobby.
- Race revive: optional rewarded ad.
- Daily rewards: 3 optional rewarded claims/day.
- Daily reward pool is coin-first with uncommon diamonds.
- Interstitial behavior remains separately gated and must not be spammed.

## 6. Live integration gates

These are intentionally not faked in the client:

- exact Unity Ads Android ad-unit IDs
- native Unity Ads Android bridge
- native Aptoide Billing bridge
- server-side purchase validation
- publisher-controlled production keystore/signing credentials
- real-device acceptance test

Do not ship a production purchase button as though a purchase was verified solely because the local client received a callback. Aptoide's current integration guidance requires server-side validation before delivering paid content, then consumption for consumables or acknowledgement for non-consumables.

## 7. Android build

The committed export preset uses Gradle Build = true. That is required for the native Android plugin path. The CI workflow installs JDK 17, Android platform/build tools, Godot 4.7.2 and its export templates, runs headless import and smoke tests, exports the Android debug APK, and validates its signature and SHA-256.

A production signed APK/AAB still requires the publisher's persistent release keystore. The Skyloom keystore from the supplied document must not be assumed to be the Turbo Rush publisher key.
