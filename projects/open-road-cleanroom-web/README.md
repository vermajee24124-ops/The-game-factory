# Open Road: Yes2Games-ready web build

This folder builds a standalone ZIP for the browser version of **Open Road: Cleanroom Edition**. It downloads the currently published web build from the upstream game, then patches only the HTML/CSS/JavaScript shell. The original WebAssembly engine, physics, tracks, generated cars and audio are not rebuilt or edited.

## Changes in this build

- Shows the loading screen immediately and starts the default race automatically after the car/track catalogue loads.
- Removes the player setup screen from startup. The car and track use the game's defaults.
- Forces **5 AI opponents** on every race, even if an old browser setting or URL parameter says otherwise.
- Hides the change-car action and keeps the pause menu to a simple **Back to race** action.
- Prevents ordinary browser selection, long-press context menus and text dragging over the game area and driving controls.
- Requests full-screen and landscape orientation from a user gesture. Mobile browsers and embedded game portals can deny orientation locking; when that happens, a small prompt asks the player to rotate the device.
- Bundles the official `yes2-runtime.js` helper from `@yes2games/js` and its MIT licence file. The dashboard injects the real `window.Yes2SDK` runtime when it bundles the uploaded game; we do **not** add or copy platform SDKs or keys into the ZIP.
- Initializes Yes2SDK, reports loading progress, calls `startGameAsync()`, and tracks `gameplayStart()` / `gameplayStop()`.
- Uses the official `window.Yes2Runtime.ads` wrapper for interstitials. The ad is requested only when the player chooses **Race again**, never during a race, and the build also applies a local three-minute cooldown. Audio is stopped while an ad is up. The game continues on a missing SDK, unsupported format or no-fill.
- Shows a bottom banner on the results screen only when the active platform reports banner support; hides it before a race begins.
- Signals Yes2SDK's optional `game.happyTime()` hook after a first-place finish, when the host supports it.
- Preserves the upstream credits and downloads the upstream README and asset licence ledger into the ZIP.

No API keys or other secrets are embedded. This does not add a rewarded-video button because the game currently has no real reward/inventory mechanic; granting a pretend reward would be misleading.

## Build it on GitHub

1. Open the **Actions** tab in this repository.
2. Choose **Build Open Road for Yes2Games**.
3. Press **Run workflow** on branch `open-road-yes2games-web-build`.
4. When the workflow succeeds, open that run and download the `Open-Road-Yes2Games-WebBuild` artifact.
5. Extract the artifact ZIP if needed. The game archive inside has `index.html` at its root, along with the WebAssembly files and track packs.

The workflow also runs `node --check` against the patched game script and verifies that required build files and track packs are present. It deliberately stops if a required upstream patch point is missing, instead of generating a half-patched ZIP.

## Upload to Yes2Games

Upload the ZIP containing `index.html` from the Yes2Games dashboard as an HTML5 / JavaScript web game. Select the Yes2SDK integration for the build/platform where the dashboard offers it, then use the dashboard preview/QA checks to verify loading, gameplay lifecycle, interstitials and banners.

The ZIP includes the official JavaScript runtime helper, but it does not contain the platform's real SDK. Real ads require the Yes2Games dashboard to inject `window.Yes2SDK` for an approved platform. Opening the ZIP locally is expected to run without paid ads. The code is defensive when the runtime is absent, an ad has no fill, or that platform doesn't support a format. Actual earnings are never guaranteed.

## Important limits

- This build downloads the **published upstream web build at build time**, not a pinned source revision. If upstream changes file names or structure, the workflow may stop at its safety checks. The ZIP includes the upstream README and asset licence ledger; keep those notices when distributing the game.
- Landscape orientation cannot be forced on every phone/browser/embedded portal. The game asks for full-screen + orientation lock from a player gesture. If the browser denies it, the player must turn the device sideways.
- Test the artifact in the Yes2Games Inspector/preview first. This workflow does not submit the game to portals, approve monetization, or claim that live-platform QA passed.
