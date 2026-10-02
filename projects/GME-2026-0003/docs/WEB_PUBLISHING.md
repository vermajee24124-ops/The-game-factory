# Turbo Rush Web Publishing

## Targets
- Godot 4.7.2 Web export
- CrazyGames
- GameDistribution
- itch.io

## Export
Use the Web export preset and keep the output file named index.html. Godot exports the HTML, JavaScript, WebAssembly and PCK files together.

The Turbo Rush shell uses Godot's JavaScriptBridge-compatible web integration and loads the CrazyGames v3 SDK on CrazyGames/local development hosts. It exposes a small adapter for startup banners, midgame ads and opt-in rewarded ads.

### CrazyGames
The SDK is loaded and initialized by the custom shell. Startup banners are requested only during the loading/startup window and cleared before the lobby. Midgame ads are requested after a race result, outside active gameplay.

### GameDistribution
A GameDistribution game ID is required before enabling its live SDK. The repository intentionally leaves the game ID empty until the publisher supplies the real ID. This avoids inventing a production identifier. Once supplied, the shell can load the current GameDistribution SDK and use its ad lifecycle.

### itch.io
itch.io does not provide a universal first-party ad SDK for arbitrary embedded Godot games. The exported game therefore remains fully playable without an ad service there.

## Web threading choice
Turbo Rush uses the normal single-threaded Web export path. Godot documents single-threaded Web exports as the more compatible choice for web publishers because multithreaded exports require cross-origin isolation headers and can conflict with third-party integrations.

## QA
A web export is generated in CI. Final publisher-side QA must still be performed on the target host because the host controls SDK availability, iframe policy, CSP and ad fill.
