# Turbo Rush Startup + Monetization Contract

## Startup experience
1. Android launch uses the Turbo Rush brand/logo.
2. The in-game startup screen shows the supplied Turbo Rush logo centered on a dark racing-themed background.
3. Startup performs local initialization without blocking on network.
4. Loading ads, if eligible, exist only during startup and disappear before the lobby/home screen.
5. The game must never wait for an ad response before entering the lobby.

## Unity Ads
- Android Game ID: 6195679
- iOS Game ID: 6195678
- Two dedicated banner placements are required: top and bottom.
- Placement IDs are configuration values and must come from the Unity Monetization dashboard.
- Do not invent placement IDs.
- Do not initialize/serve ads before the applicable consent state is established.
- If offline, consent disallows ads, the user owns Remove Ads, or a placement is unavailable, no ad is shown.
- The native bridge is optional at editor/runtime; the core game must remain playable without it.

## Supplied logo
Expected runtime asset:
res://assets/turbo_rush_logo.jpg

The asset should be the supplied Turbo Rush logo artwork. A safe UI fallback is used if the asset is not present.

## Privacy
Unity's current Android integration documentation requires consent configuration before or during SDK initialization. The release build must complete the appropriate consent flow for the actual audience and jurisdictions before enabling personalized advertising.
