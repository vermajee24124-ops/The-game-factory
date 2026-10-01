# Turbo Rush Startup / Loading / Monetization UX

## Source reference
The supplied reference video is used only for startup pacing and presentation ideas. It is not copied as gameplay or art.

Observed reference sequence:
- opening splash/logo appears immediately
- short engine/startup transition
- loading/promo presentation occupies the early startup period
- the player eventually reaches the main game/lobby UI
- the reference contains top/bottom promotional placements during the non-gameplay portion

## Turbo Rush implementation
1. Native Godot boot splash uses the Turbo Rush logo.
2. The in-game startup screen then shows the same logo prominently.
3. Loading progress is visible and advances through:
   - LOADING TURBO RUSH
   - PREPARING GARAGE
   - PREPARING CAMPAIGN
   - CHECKING LOCAL SAVE
   - READY TO RACE
4. Unity Ads loading banners are allowed ONLY on this startup/loading screen.
5. Two dedicated banner placements are supported:
   - top: 320x50
   - bottom: 320x50
6. Ads are shown only when:
   - the native Unity Ads bridge exists
   - connectivity is available
   - the required banner placement IDs are configured
   - the user's applicable consent state permits ads
   - Remove Ads has not been purchased
7. The loading flow never waits for an ad. If an ad fails or is unavailable, the game continues.
8. Both banners are removed before the main menu becomes interactive.
9. No banner is shown during an active race.
10. No interstitial is inserted into the opening loading sequence.
11. Rewarded ads remain opt-in and are used only for the explicitly defined reward slots.

## Logo asset
The supplied Turbo Rush logo should be stored as:
`projects/GME-2026-0003/godot/assets/turbo_rush_logo.png`

The same asset should be used for:
- Android launch/boot splash
- startup loading logo
- application icon variants after platform-specific cropping/resizing

The current project configuration points the application icon to `res://assets/turbo_rush_logo.svg`.
If the PNG is the canonical publisher asset, the final build step should generate platform-safe icon/splash variants from that source rather than inventing a replacement logo.

## Unity Ads integration requirements
Current Unity Android SDK documentation supports multiple banner views and dedicated banner placements. The integration must use the current BannerAd API and Gradle dependencies rather than deprecated BannerView APIs.

Do not ship with empty placement IDs. The final release build must fail its monetization preflight if Android top/bottom placement IDs are missing.

## Aptoide billing
Aptoide Billing must remain independent from the startup ads. Core gameplay must work offline.
Purchases must be validated before entitlements are granted.
Consumables must be consumed after successful validation and delivery.
Non-consumables such as Remove Ads must be acknowledged after validation.
The public key and real product IDs must come from the publisher's Aptoide Billing Integration configuration.

## Release rule
A build is not marked final merely because the GDScript project imports. Final release requires:
- Android Gradle export
- native Unity Ads plugin present
- native Aptoide Billing plugin present
- real-device test
- purchase validation test
- ad consent test
- signed release artifact
- final store metadata/compliance review