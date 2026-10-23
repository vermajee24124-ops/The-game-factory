# Open Road: Yes2Games-ready web build

This folder builds a standalone ZIP for the browser version of **Open Road: Cleanroom Edition**. GitHub Actions rebuilds its WebAssembly engine from pinned upstream source commits, applies a shorter quick-sprint track design and balanced handling tune, patches the HTML/CSS/JavaScript shell, then packages the generated tracks.

## Changes in this build

- Shows the loading screen immediately and starts the default race automatically after the car/track catalogue loads.
- Removes the player setup screen from startup. The car and track use the game's defaults.
- Forces **5 AI opponents** on every race, even if an old browser setting or URL parameter says otherwise.
- Forces a **one-lap quick sprint** by default, including after an older browser has saved a longer lap setting. The three procedural circuits are shortened but retain their different identities and corner styles; their elevations are also softened slightly.
- Hides the change-car action and keeps the pause menu to a simple **Back to race** action.
- Prevents ordinary browser selection, long-press context menus and text dragging over the game area and driving controls.
- Balances the actual WebAssembly car physics: a moderate speed-sensitive cornering limit, gradual high-speed steering response, stronger lateral-slip damping, smoother yaw correction and slightly more downforce for better stability.
- Requests full-screen and landscape orientation from a user gesture. Mobile browsers and embedded game portals can deny orientation locking; when that happens, a small prompt asks the player to rotate the device.
- Includes the official `yes2-runtime.js` helper from `@yes2games/js` plus its licence text. The Dashboard supplies the actual `window.Yes2SDK` platform SDK when bundling a build; no platform SDK or private key is hard-coded into this ZIP.
- Starts SDK initialization early, retries `startGameAsync()` if the injected adapter arrives late, reports loading progress, and tracks `gameplayStart()` / `gameplayStop()`.
- Uses the official JavaScript wrapper `window.Yes2Runtime.ads` for interstitials and simple banners. An interstitial is requested only when the player chooses **Race again** and after the first three minutes of a session. Further natural breaks are signalled to the platform SDK so each portal can apply its own frequency rules. The game pauses and audio is muted during the ad. Missing SDK, unsupported format or no-fill does not block play.
- Handles Yes2SDK `pause`, `resume`, `audioEnabledChange`, and account-dialog events, including a separate platform audio-mute state that preserves the player's own sound preference.
- Shows a bottom banner on the results screen via the wrapper when that format is supported; hides it before a race starts. Banners are not available on every portal.
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

The workflow rebuilds the Open Road WebAssembly engine, checks the track geometry and handling patch points, enforces the one-lap default, records the generated track lengths, checks JavaScript syntax, and tests the Yes2SDK start handshake, gameplay lifecycle, pause/resume, platform audio mute, initial ad gate and ad audio restoration with a mock SDK. It also verifies required files and ZIP structure. The mock test is not a substitute for certification or a real-device handling test.

## Upload to Yes2Games

Upload the ZIP containing `index.html` from the Yes2Games dashboard as an HTML5 / JavaScript web game. Select the Yes2SDK integration for the build/platform where the dashboard offers it, then use the dashboard preview/QA checks to verify loading, gameplay lifecycle, interstitials and banners.

The ZIP includes the small JavaScript helper, not the platform's real SDK. Real ads require the Yes2Games dashboard to inject `window.Yes2SDK` for an approved platform. Opening the ZIP locally is expected to run without paid ads. The code is defensive when the runtime is absent, an ad has no fill, or that platform doesn't support a format. Actual earnings are never guaranteed.

## Important limits

- The workflow pins upstream source commits for repeatable engine builds. If upstream files or expected patch points change, the workflow deliberately stops rather than packaging an incomplete or untuned build. The ZIP includes the upstream README and asset licence ledger; keep those notices when distributing the game.
- Landscape orientation cannot be forced on every phone/browser/embedded portal. The game asks for full-screen + orientation lock from a player gesture. If the browser denies it, the player must turn the device sideways.
- Test the artifact in the Yes2Games Inspector/preview first. This workflow does not submit the game to portals, approve monetization, or claim that live-platform QA passed.
