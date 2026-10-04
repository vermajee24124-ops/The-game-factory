# Turbo Rush Startup / Loading / Advertising UX

## Monetization policy (1.8.0)
Turbo Rush is ads-only. Aptoide Connect, in-app purchases, billing SDKs, purchase restore and paid-content entitlements are not part of the game.

## Source reference
The supplied reference video is used only for startup pacing and presentation ideas.

Observed flow:
- Turbo Rush logo appears immediately.
- A short loading/startup presentation follows.
- The player reaches the main lobby/home screen before normal gameplay controls are enabled.
- Two small promotional placements can appear only during the non-gameplay startup window.

## Turbo Rush implementation
1. Native Godot boot splash uses the Turbo Rush logo.
2. The in-game loading screen repeats the same branding.
3. Loading status progresses through: LOADING TURBO RUSH, PREPARING GARAGE, PREPARING CAMPAIGN, CHECKING LOCAL SAVE, READY TO RACE.
4. Android Unity Ads banners are optional and non-blocking.
5. Two 320x50 banner instances may be shown at the top and bottom while the startup screen is visible.
6. Both banners are removed before the main menu becomes interactive.
7. No banner is shown during an active race.
8. Fullscreen ads are used only at natural breaks and are disabled when no valid placement is available.
9. Rewarded ads are opt-in and grant only the specific gameplay reward requested by the player.
10. Core racing, progression, garage and saves remain fully usable offline.
11. Ad initialization or ad loading never blocks the player from reaching the lobby.

## Web builds
The Web build uses the browser JavaScript bridge. CrazyGames and GameDistribution integrations are host-aware; generic hosts such as an ordinary Itch.io page fall back to a clean WebGL build when no approved SDK configuration is present.

## Privacy
Turbo Rush uses non-personalized advertising mode in the Android bridge by default. Platform/store privacy and consent requirements must still be reviewed before each public release.

## Logo asset
The canonical Turbo Rush logo is res://assets/turbo_rush_logo.svg. It is used for Android splash, startup loading screen and application branding.

## Release gate
A production build must verify:
- no external billing/IAP code or manifest dependency
- Android Unity Ads bridge present
- required ad placement configuration present when ads are enabled
- Web export opens without external SDKs when no host configuration exists
- signed release artifact
- import and smoke tests pass
- store metadata and privacy/compliance review complete

## Web ad lifecycle
CrazyGames uses the official `midgame` and `rewarded` ad types. Rewarded offers are opt-in and never appear on the active race screen. The game continues normally when an ad is unfilled or unavailable.
