# Open Road: Yes2Games-ready web build

This folder builds a standalone ZIP for the browser version of **Open Road: Cleanroom Edition**. GitHub Actions rebuilds its WebAssembly engine from pinned upstream source commits, applies the steering tune, then patches the HTML/CSS/JavaScript shell and packages the generated tracks.

## Changes in this build

- Shows the loading screen immediately and starts the default race automatically after the car/track catalogue loads.
- Removes the player setup screen from startup. The car and track use the game's defaults.
- Forces **5 AI opponents** on every race, even if an old browser setting or URL parameter says otherwise.
- Hides the change-car action and keeps the pause menu to a simple **Back to race** action.
- Prevents ordinary browser selection, long-press context menus and text dragging over the game area and driving controls.
- Requests full-screen and landscape orientation from a user gesture. Mobile browsers and embedded game portals can deny orientation locking; when that happens, a small prompt asks the player to rotate the device.
- Uses the Yes2Games dashboard-injected `window.Yes2SDK` global directly. The browser game initializes the SDK, reports loading progress, calls `startGameAsync()`, and tracks gameplay lifecycle events. The platform SDK itself is supplied by the dashboard, not copied into the ZIP.
- Starts SDK initialization early, retries `startGameAsync()` if the injected adapter arrives late, reports loading progress, and tracks `gameplayStart()` / `gameplayStop()`.
- Uses `Yes2SDK.ads.showInterstitial()` only when the player chooses **Race again**, not during a race or in the first three minutes of a session, with at least three minutes between interstitials. The game pauses and audio is muted during the ad. A missing SDK, unsupported format or no-fill does not block the next race.
- Handles Yes2SDK `pause`, `resume`, `audioEnabledChange`, and account-dialog events, including a separate platform audio-mute state that preserves the player's own sound preference.
- Uses `Yes2SDK.banners.showBanner()` for a small results-screen banner where the host supports it; hides the banner before a race starts.
- Signals the optional `Yes2SDK.game.happyTime()` hook after a first-place finish when supported.
- Rebuilds the actual WebAssembly engine with a modest high-speed steering tune: the speed-sensitive steering lock is increased slightly, its high-speed minimum is raised, and steering-angle response is 20% faster. The steering lock still decreases with speed instead of being forced to maximum at all speeds.
- Preserves the upstream credits and downloads the upstream README and asset licence ledger into the ZIP.

No API keys or other secrets are embedded. This does not add a rewarded-video button because the game currently has no real reward/inventory mechanic; granting a pretend reward would be misleading.

## Build it on GitHub

1. Open the **Actions** tab in this repository.
2. Choose **Build Open Road for Yes2Games**.
3. Press **Run workflow** on branch `open-road-yes2games-web-build`.
4. When the workflow succeeds, open that run and download the `Open-Road-Yes2Games-WebBuild` artifact.
5. Extract the artifact ZIP if needed. The game archive inside has `index.html` at its root, along with the WebAssembly files and track packs.

The workflow rebuilds the Open Road WebAssembly engine, verifies that the three steering-tuning source changes were applied, runs `node --check` on the game and SDK smoke test, and tests the start handshake, gameplay lifecycle, pause/resume, platform audio mute, the early-ad gate, and ad audio restoration using a mock SDK. It also verifies required files and ZIP structure. The mock test is not a substitute for certification in your Yes2Games account.

## Upload to Yes2Games

Upload the ZIP containing `index.html` from the Yes2Games dashboard as an HTML5 / JavaScript web game. Select the Yes2SDK integration for the build/platform where the dashboard offers it, then use the dashboard preview/QA checks to verify loading, gameplay lifecycle, interstitials and banners.

The ZIP does not contain the platform's real SDK. Real ads require the Yes2Games dashboard to inject `window.Yes2SDK` for an approved platform. Opening the ZIP locally is expected to run without paid ads. The code is defensive when the runtime is absent, an ad has no fill, or that platform doesn't support a format. Actual earnings are never guaranteed.

## Important limits

- The workflow pins upstream source commits for repeatable engine builds. If upstream files or expected patch points change, the workflow deliberately stops rather than packaging an incomplete or untuned build. The ZIP includes the upstream README and asset licence ledger; keep those notices when distributing the game.
- Landscape orientation cannot be forced on every phone/browser/embedded portal. The game asks for full-screen + orientation lock from a player gesture. If the browser denies it, the player must turn the device sideways.
- Test the artifact in the Yes2Games Inspector/preview first. This workflow does not submit the game to portals, approve monetization, or claim that live-platform QA passed.
