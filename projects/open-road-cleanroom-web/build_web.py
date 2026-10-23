#!/usr/bin/env python3
"""Download the published Open Road web build and apply the Yes2Games-ready UX patch.

This deliberately patches only the browser shell. It does not rebuild or alter the
upstream WebAssembly game engine, car physics, tracks, audio, or generated assets.
"""
from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

SITE = "https://andrewnakas.github.io/opennfs-cleanroom/"
RAW = "https://raw.githubusercontent.com/andrewnakas/opennfs-cleanroom/main/"
USER_AGENT = "OpenRoad-Yes2Games-Build/1.0 (GitHub Actions)"


def download(url: str, destination: Path) -> None:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    destination.parent.mkdir(parents=True, exist_ok=True)
    try:
        with urllib.request.urlopen(request, timeout=90) as response, destination.open("wb") as out:
            shutil.copyfileobj(response, out)
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        raise RuntimeError(f"Download failed: {url} ({exc})") from exc
    if destination.stat().st_size == 0:
        raise RuntimeError(f"Downloaded an empty file: {url}")


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def write_text(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8", newline="\n")


def replace_once(source: str, old: str, new: str, label: str) -> str:
    count = source.count(old)
    if count != 1:
        raise RuntimeError(f"Expected exactly one patch point for {label}; found {count}. Upstream changed, so refusing to create a possibly broken build.")
    return source.replace(old, new, 1)


def patch_html(site: Path) -> None:
    path = site / "index.html"
    html = read_text(path)
    html = replace_once(
        html,
        '<canvas id="canvas" tabindex="0"',
        '<canvas id="canvas" tabindex="0" data-yes2-canvas',
        "mark the racing canvas for Yes2Games Inspector",
    )
    html = replace_once(
        html,
        '<script src="audio.js"></script>',
        '<script src="yes2-runtime.js"></script>\n<script src="audio.js"></script>',
        "load the official Yes2Games JavaScript runtime helper",
    )
    html = replace_once(
        html,
        '<div id="menu" class="overlay">',
        '<div id="menu" class="overlay hidden">',
        "hide the setup menu until it is needed",
    )
    html = replace_once(
        html,
        '<div id="loading" class="overlay hidden">',
        '<div id="loading" class="overlay">',
        "show the loading screen immediately",
    )
    orientation_hint = """
  <div id="rotate-hint" class="orientation-hint hidden" role="dialog" aria-labelledby="rotate-title">
    <div class="orientation-card">
      <h2 id="rotate-title">Landscape racing</h2>
      <p>Tap below to try full-screen landscape mode. If your browser blocks auto-rotation, turn your phone sideways.</p>
      <button class="go" id="landscape-go" type="button">Enter full screen</button>
    </div>
  </div>
"""
    html = replace_once(
        html,
        '</div>\n</div>\n<script src="yes2-runtime.js"></script>\n<script src="audio.js"></script>',
        '</div>\n' + orientation_hint + '</div>\n<script src="yes2-runtime.js"></script>\n<script src="audio.js"></script>',
        "insert the mobile landscape gate",
    )
    write_text(path, html)


def patch_css(site: Path) -> None:
    path = site / "style.css"
    css = read_text(path)
    additions = r"""

/* Open Road portal build: prevent long-press selection on racing controls. */
html, body, #stage, #canvas, #touch, #touch *, #topbar, #topbar *,
#hud, #hud *, #results, #results *, #menu, #menu * {
  -webkit-user-select: none !important;
  user-select: none !important;
  -webkit-touch-callout: none !important;
  -webkit-tap-highlight-color: transparent;
}
button, canvas, #stage {
  -webkit-user-drag: none;
  touch-action: none;
}
#touch, #topbar, #hud, #results, #menu {
  -webkit-touch-callout: none;
}
#menu h1, #menu .tag, #menu .panel, #menu #go, #menu .keys,
#menu .credit, #to-menu {
  display: none !important;
}
#menu {
  background: rgba(8, 10, 14, .86);
}
#results {
  padding-bottom: max(84px, calc(env(safe-area-inset-bottom) + 72px));
}
.orientation-hint {
  position: absolute;
  inset: 0;
  z-index: 50;
  display: flex;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: max(20px, env(safe-area-inset-top)) max(20px, env(safe-area-inset-right))
           max(20px, env(safe-area-inset-bottom)) max(20px, env(safe-area-inset-left));
  background: rgba(5, 8, 12, .96);
}
.orientation-hint.hidden { display: none !important; }
.orientation-card {
  width: min(460px, 92vw);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
}
.orientation-card h2 { margin: 0; color: var(--accent); font-size: clamp(25px, 5vw, 38px); }
.orientation-card p { margin: 0; color: var(--fg); max-width: 36ch; }
@media (orientation: landscape) {
  .orientation-hint { display: none !important; }
}
"""
    if "Open Road portal build: prevent long-press selection" not in css:
        css += additions
    write_text(path, css)


def patch_js(site: Path) -> None:
    path = site / "game.js"
    js = read_text(path)

    # Always run against five AI opponents, regardless of a stale localStorage value or URL query.
    js, count = re.subn(
        r"opponents:\s*\+\(Q\.get\('opponents'\)\s*\|\|\s*localStorage\.getItem\('or\.opponents'\)\s*\|\|\s*3\),",
        "opponents: 5,",
        js,
        count=1,
    )
    if count != 1:
        raise RuntimeError("Could not find the upstream opponent default. Refusing a partial build.")

    helpers = r"""
// ---------------------------------------------------------------- Yes2SDK, orientation and input guard
var yes2ReadyPromise = null;
var yes2Cached = null;
var yes2GameplayActive = false;
var yes2LastInterstitial = 0;
var yes2LastProgress = 0;
var yes2ReplayBusy = false;
var yes2BannerVisible = false;
var yes2HappyTimeSent = false;

function yes2Sleep(ms) {
  return new Promise(function (resolve) { setTimeout(resolve, ms); });
}

function yes2SdkReady() {
  if (yes2Cached) return Promise.resolve(yes2Cached);
  if (!yes2ReadyPromise) {
    yes2ReadyPromise = (async function () {
      var sdk = null;
      // The dashboard can inject its runtime asynchronously; wait briefly instead of disabling ads permanently.
      for (var i = 0; i < 80; i++) {
        if (window.Yes2SDK && typeof window.Yes2SDK.initializeAsync === 'function') {
          sdk = window.Yes2SDK;
          break;
        }
        await yes2Sleep(100);
      }
      if (!sdk) {
        console.info('Yes2SDK was not injected. The game continues without ads on this origin.');
        return null;
      }
      try {
        await sdk.initializeAsync();
        yes2Cached = sdk;
        if (typeof sdk.setLoadingProgress === 'function') {
          sdk.setLoadingProgress(Math.max(0, Math.min(100, yes2LastProgress)));
        }
        return sdk;
      } catch (e) {
        console.info('Yes2SDK initialization failed; continuing without ads.', e);
        return null;
      }
    })().finally(function () {
      if (!yes2Cached) yes2ReadyPromise = null;
    });
  }
  return yes2ReadyPromise;
}

function yes2AdsRuntime() {
  // @yes2games/js exposes the guarded ad wrapper as window.Yes2Runtime.ads.
  return window.Yes2Runtime && window.Yes2Runtime.ads ? window.Yes2Runtime.ads : null;
}

function yes2Progress(value) {
  yes2LastProgress = Math.max(0, Math.min(100, Math.floor(value)));
  yes2SdkReady().then(function (sdk) {
    if (sdk && typeof sdk.setLoadingProgress === 'function') {
      try { sdk.setLoadingProgress(yes2LastProgress); } catch (e) {}
    }
  });
}

function yes2GameplayStart() {
  yes2SdkReady().then(function (sdk) {
    if (!sdk || !sdk.game || typeof sdk.game.gameplayStart !== 'function' || yes2GameplayActive) return;
    try { sdk.game.gameplayStart(); yes2GameplayActive = true; } catch (e) {}
  });
}

function yes2GameplayStop() {
  yes2SdkReady().then(function (sdk) {
    if (!sdk || !sdk.game || typeof sdk.game.gameplayStop !== 'function' || !yes2GameplayActive) return;
    try { sdk.game.gameplayStop(); } catch (e) {}
    yes2GameplayActive = false;
  });
}

function yes2FinishLoading() {
  yes2SdkReady().then(async function (sdk) {
    if (!sdk) return;
    try {
      if (typeof sdk.setLoadingProgress === 'function') sdk.setLoadingProgress(100);
      if (typeof sdk.startGameAsync === 'function') await sdk.startGameAsync();
      yes2GameplayStart();
    } catch (e) {
      console.info('Yes2SDK loading lifecycle failed; game continues.', e);
    }
  });
}

function yes2HideBanner() {
  yes2SdkReady().then(function () {
    var ads = yes2AdsRuntime();
    if (!ads || typeof ads.hideBanner !== 'function') return;
    try { ads.hideBanner(); } catch (e) {}
    yes2BannerVisible = false;
  });
}

function yes2ShowResultBanner() {
  yes2SdkReady().then(async function () {
    var ads = yes2AdsRuntime();
    if (!ads || typeof ads.showBanner !== 'function') return;
    try {
      if (typeof ads.isBannerSupported === 'function' && !ads.isBannerSupported()) return;
      await ads.showBanner('bottom');
      yes2BannerVisible = true;
    } catch (e) {
      // Banners are not offered by every portal. Their absence must not block gameplay.
    }
  });
}

function yes2CelebrateWin() {
  if (yes2HappyTimeSent) return;
  yes2HappyTimeSent = true;
  yes2SdkReady().then(function (sdk) {
    if (sdk && sdk.game && typeof sdk.game.happyTime === 'function') {
      try { sdk.game.happyTime(); } catch (e) {}
    }
  });
}

async function raceAgainWithAd() {
  if (yes2ReplayBusy) return;
  yes2ReplayBusy = true;
  try {
    var sdk = await yes2SdkReady();
    var ads = yes2AdsRuntime();
    var canShow = !!(sdk && ads && typeof ads.showInterstitial === 'function');
    if (canShow && typeof ads.isInterstitialSupported === 'function') {
      canShow = !!ads.isInterstitialSupported();
    }
    // Natural break only: player opts to replay; cap this client to one interstitial per 3 minutes.
    var now = Date.now();
    if (canShow && now - yes2LastInterstitial >= 180000) {
      yes2LastInterstitial = now;
      if (sdk.game && typeof sdk.game.gameplayStop === 'function') {
        try { sdk.game.gameplayStop(); } catch (e) {}
        yes2GameplayActive = false;
      }
      yes2HideBanner();
      try {
        await ads.showInterstitial('race-replay', {
          beforeAd: function () {
            setPaused(true);
            if (window.GameAudio) GameAudio.setActive(false);
          },
          afterAd: function () {
            setPaused(false);
            if (window.GameAudio) GameAudio.setActive(true);
          },
          noFill: function () {}
        });
      } catch (e) {
        // Missing or unavailable ads must never prevent the next race.
      }
    }
  } catch (e) {
    // SDK not injected / blocked: leave ads disabled but keep the game playable.
  } finally {
    yes2ReplayBusy = false;
    startRace();
  }
}

function syncLandscapeGate() {
  var gate = $('rotate-hint');
  if (!gate || !game.ready) return;
  var coarse = false, portrait = false;
  try {
    coarse = matchMedia('(pointer: coarse)').matches || Q.has('touch');
    portrait = matchMedia('(orientation: portrait)').matches;
  } catch (e) {}
  gate.classList.toggle('hidden', !(coarse && portrait));
}

function requestImmersiveLandscape() {
  var stage = $('stage');
  var enter = null;
  try {
    if (!document.fullscreenElement && stage && typeof stage.requestFullscreen === 'function') {
      try { enter = stage.requestFullscreen({ navigationUI: 'hide' }); }
      catch (e) { enter = stage.requestFullscreen(); }
    }
  } catch (e) {}
  Promise.resolve(enter).catch(function () {}).then(function () {
    try {
      if (screen.orientation && typeof screen.orientation.lock === 'function') {
        return screen.orientation.lock('landscape');
      }
    } catch (e) {}
    return null;
  }).catch(function () {}).then(function () {
    setTimeout(syncLandscapeGate, 250);
  });
}

// Prevent long-press selection and context menus over the game and driving controls.
document.addEventListener('selectstart', function (e) {
  if (e.target && e.target.closest && e.target.closest('#stage')) e.preventDefault();
}, { passive: false });
document.addEventListener('contextmenu', function (e) {
  if (e.target && e.target.closest && e.target.closest('#stage')) e.preventDefault();
});
window.addEventListener('orientationchange', syncLandscapeGate);
window.addEventListener('resize', syncLandscapeGate);
document.addEventListener('fullscreenchange', syncLandscapeGate);
"""
    js = replace_once(
        js,
        "var catalogue = { cars: [], colours: [], tracks: [] };",
        "var catalogue = { cars: [], colours: [], tracks: [] };\n" + helpers,
        "insert Yes2SDK and mobile helpers",
    )

    js = replace_once(
        js,
        "function startRace() {\n  saveChoice();",
        "function startRace() {\n  choice.opponents = 5;\n  yes2HappyTimeSent = false;\n  yes2HideBanner();\n  saveChoice();",
        "fix opponent count and hide result banner when racing",
    )

    js = replace_once(
        js,
        "  onGameReady: function () {\n    game.ready = true;\n    $('loading').classList.add('hidden');",
        "  onGameReady: function () {\n    game.ready = true;\n    yes2FinishLoading();\n    syncLandscapeGate();\n    $('loading').classList.add('hidden');",
        "notify Yes2SDK when the engine finishes loading",
    )

    js = replace_once(
        js,
        "    if (m) document.querySelector('#bar i').style.width = (100 * m[1] / m[2]).toFixed(1) + '%';",
        "    if (m) {\n      document.querySelector('#bar i').style.width = (100 * m[1] / m[2]).toFixed(1) + '%';\n      yes2Progress(100 * (+m[1]) / (+m[2]));\n    } else { yes2Progress(10); }",
        "forward loading progress to Yes2SDK",
    )

    js = replace_once(
        js,
        "  game.menuOpen = true;\n  $('menu').classList.remove('hidden');",
        "  game.menuOpen = true;\n  yes2GameplayStop();\n  yes2HideBanner();\n  $('menu').classList.remove('hidden');",
        "stop gameplay while paused",
    )

    js = replace_once(
        js,
        "function closeMenu() {\n  game.menuOpen = false;\n  $('menu').classList.add('hidden');\n  setPaused(false);\n  pushInput();\n  if (window.GameAudio) GameAudio.setActive(true);\n  Module.canvas.focus();\n}",
        "function closeMenu() {\n  game.menuOpen = false;\n  yes2HideBanner();\n  $('menu').classList.add('hidden');\n  setPaused(false);\n  pushInput();\n  if (window.GameAudio) GameAudio.setActive(true);\n  yes2GameplayStart();\n  Module.canvas.focus();\n}",
        "resume gameplay and safely hide banners",
    )

    js = replace_once(
        js,
        "function showResults() {\n  if (!game.state || game.state.phase !== 2 || game.menuOpen) return;\n  fillResults(game.state);\n  $('results').classList.remove('hidden');\n}",
        "function showResults() {\n  if (!game.state || game.state.phase !== 2 || game.menuOpen) return;\n  yes2GameplayStop();\n  if (game.state.pos === 1) yes2CelebrateWin();\n  fillResults(game.state);\n  $('results').classList.remove('hidden');\n  yes2ShowResultBanner();\n}",
        "stop play and optionally show a non-blocking result banner",
    )

    js = replace_once(
        js,
        "$('again').addEventListener('click', startRace);",
        "$('again').addEventListener('click', raceAgainWithAd);",
        "show an interstitial only when the player chooses to replay",
    )
    js = replace_once(
        js,
        "$('btn-full').addEventListener('click', function () {\n  if (document.fullscreenElement) document.exitFullscreen(); else if ($('stage').requestFullscreen) $('stage').requestFullscreen();\n});",
        "$('btn-full').addEventListener('click', function () {\n  if (document.fullscreenElement) {\n    try { var exitResult = document.exitFullscreen(); if (exitResult && typeof exitResult.catch === 'function') exitResult.catch(function () {}); } catch (e) {}\n  } else { requestImmersiveLandscape(); }\n});\n$('landscape-go').addEventListener('click', requestImmersiveLandscape);",
        "make full-screen button request landscape when possible",
    )
    js = replace_once(
        js,
        "  if (e.code === 'Enter' && game.ready && game.state && game.state.phase === 2 && !game.menuOpen) startRace();",
        "  if (e.code === 'Enter' && game.ready && game.state && game.state.phase === 2 && !game.menuOpen) raceAgainWithAd();",
        "keep keyboard replay on the same safe ad path",
    )

    # Start immediately after the track/car catalogue is ready. The loading overlay remains visible.
    js = replace_once(
        js,
        "  if (Q.has('autostart') || Q.has('dump')) startRace();",
        "  startRace();",
        "auto-start the default race instead of displaying the setup menu",
    )
    write_text(path, js)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", required=True, help="Output directory for the portal-uploadable web build")
    args = parser.parse_args()
    out = Path(args.out).resolve()
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)

    required = [
        "index.html", "style.css", "game.js", "audio.js", "credits.html",
        "cars.json", "assets.js", "assets.bin", "opennfs.js", "opennfs.wasm",
    ]
    print("Downloading the current published Open Road web build...")
    for name in required:
        download(urllib.parse.urljoin(SITE, name), out / name)
        print(f"  fetched {name}")

    cars_path = out / "cars.json"
    catalogue = json.loads(read_text(cars_path))
    tracks = catalogue.get("tracks")
    if not isinstance(tracks, list) or not tracks:
        raise RuntimeError("cars.json did not contain a non-empty tracks list; refusing an incomplete build.")
    track_ids: list[str] = []
    for entry in tracks:
        track_id = entry.get("id") if isinstance(entry, dict) else None
        if not isinstance(track_id, str) or not re.fullmatch(r"[A-Za-z0-9_-]+", track_id):
            raise RuntimeError(f"Unexpected track id in cars.json: {track_id!r}")
        if track_id not in track_ids:
            track_ids.append(track_id)
    print(f"Downloading {len(track_ids)} track packs...")
    for track_id in track_ids:
        name = f"tracks/{track_id}.bin"
        download(urllib.parse.urljoin(SITE, name), out / name)
        print(f"  fetched {name}")

    # Preserve upstream provenance and the asset licence ledger in the submitted ZIP.
    download(urllib.parse.urljoin(RAW, "README.md"), out / "UPSTREAM-README.md")
    download(urllib.parse.urljoin(RAW, "assets/LICENSES.csv"), out / "UPSTREAM-LICENSES.csv")

    patch_html(out)
    patch_css(out)
    patch_js(out)
    print("Patched: hide setup UI, default to 5 opponents, auto-start, mobile input guard, landscape prompt, Yes2SDK lifecycle/ads.")
    print(f"Ready: {out}")
    print("No SDK keys are embedded. Yes2SDK ads only activate when the Yes2Games dashboard injects its runtime.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:
        print(f"BUILD FAILED: {exc}", file=sys.stderr)
        sys.exit(1)
