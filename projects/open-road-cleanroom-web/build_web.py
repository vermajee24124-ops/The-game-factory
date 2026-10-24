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
    # The dashboard injects the SDK before the first author script. Initialize it in that
    # first script, before the bundled runtime or the engine can invoke any SDK method.
    early_bootstrap = r"""<script id="yes2sdk-early-init">
(function () {
  if (window.__openRoadSdkInitPromise || window.__openRoadSdkInitCalled) return;
  var sdk = window.Yes2SDK;
  if (!sdk || typeof sdk.initializeAsync !== 'function') return;
  window.__openRoadSdkInitCalled = true;
  try {
    var result = sdk.initializeAsync();
    window.__openRoadSdkInitPromise = Promise.resolve(result).then(function () {
      return sdk;
    }).catch(function (error) {
      window.__openRoadSdkInitError = error;
      return null;
    });
  } catch (error) {
    window.__openRoadSdkInitError = error;
    window.__openRoadSdkInitPromise = Promise.resolve(null);
  }
})();
</script>"""
    html = replace_once(
        html,
        '<script src="audio.js"></script>',
        early_bootstrap + '\n<script src="yes2-runtime.js"></script>\n<script src="audio.js"></script>',
        "initialize Yes2SDK exactly once before all game/runtime scripts",
    )
    html = replace_once(
        html,
        '<button id="btn-sound"',
        '<button id="btn-pause" aria-label="pause game" title="Pause">&#9208;</button>\n    <button id="btn-sound"',
        "add a dedicated pause/resume button to the HUD",
    )
    html = replace_once(
        html,
        '<table id="results-table"></table>',
        '<div id="reward-points" class="reward-points hidden">SPRINT POINTS: <b id="sprint-points">0</b> <span id="reward-status"></span></div>\n    <div id="reward-actions" class="reward-actions hidden"><button class="go" id="reward-ad">Watch ad for +500 Sprint Points</button><button class="go" id="skip-reward">Continue without ad</button></div>\n    <table id="results-table"></table>',
        "add an opt-in rewarded bonus with a clear no-ad choice",
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
    script_tail = early_bootstrap + '\n<script src="yes2-runtime.js"></script>\n<script src="audio.js"></script>'
    html = replace_once(
        html,
        '</div>\n</div>\n' + script_tail,
        '</div>\n' + orientation_hint + '</div>\n' + script_tail,
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
#topbar #btn-pause {
  border-color: var(--accent);
  font-weight: 900;
  font-size: 21px;
  opacity: 1;
}
#topbar #btn-pause.paused {
  background: var(--accent);
  color: #141414;
}
.reward-points { text-align: center; font-size: 14px; font-weight: 800; color: var(--accent); letter-spacing: .04em; }
.reward-points b { font-size: 20px; margin: 0 4px; }
#reward-status { display: block; margin-top: 4px; font-size: 13px; font-weight: 600; color: var(--fg); letter-spacing: 0; }
.reward-actions { display: flex; flex-wrap: wrap; gap: 10px; width: min(100%, 560px); }
.reward-actions button { flex: 1 1 200px; min-height: 44px; font-size: 14px; line-height: 1.25; touch-action: manipulation; }
"""
    if "Open Road portal build: prevent long-press selection" not in css:
        css += additions
    write_text(path, css)


def patch_audio(site: Path) -> None:
    path = site / "audio.js"
    audio = read_text(path)
    audio = replace_once(
        audio,
        "var muted = false, active = false, lastSpeed = 0, lastT = 0;",
        "var muted = false, platformMuted = false, active = false, lastSpeed = 0, lastT = 0;",
        "track a portal-mandated mute separately from the player's sound preference",
    )
    audio = replace_once(
        audio,
        "master.gain.value = muted ? 0 : 0.9;",
        "master.gain.value = (muted || platformMuted) ? 0 : 0.9;",
        "honor platform mute when creating audio",
    )
    audio = replace_once(
        audio,
        "if (ctx) master.gain.setTargetAtTime(muted ? 0 : 0.9, ctx.currentTime, 0.05);",
        "if (ctx) master.gain.setTargetAtTime((muted || platformMuted) ? 0 : 0.9, ctx.currentTime, 0.05);",
        "preserve platform mute when the player toggles sound",
    )
    setter = """  function setPlatformMuted(on) {
    platformMuted = !!on;
    if (ctx) master.gain.setTargetAtTime((muted || platformMuted) ? 0 : 0.9, ctx.currentTime, 0.03);
  }
"""
    audio = replace_once(
        audio,
        "  function update(s) {",
        setter + "  function update(s) {",
        "add platform audio mute setter",
    )
    audio = replace_once(
        audio,
        "return { unlock: unlock, setActive: setActive, toggleMute: toggleMute, update: update, beep: beep, fanfare: fanfare, isMuted: function () { return muted; } };",
        "return { unlock: unlock, setActive: setActive, toggleMute: toggleMute, setPlatformMuted: setPlatformMuted, update: update, beep: beep, fanfare: fanfare, isMuted: function () { return muted; } };",
        "expose platform mute setter",
    )
    write_text(path, audio)


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

    # Keep quick-sprint length fixed at one lap even when older browser storage has a longer setting.
    js, lap_count = re.subn(
        r"laps:\s*\+\(Q\.get\('laps'\)\s*\|\|\s*localStorage\.getItem\('or\.laps'\)\s*\|\|\s*3\)",
        "laps: 1",
        js,
        count=1,
    )
    if lap_count != 1:
        raise RuntimeError("Could not find the upstream lap default. Refusing a partial build.")

    helpers = r"""
// ---------------------------------------------------------------- Yes2SDK lifecycle, ads, orientation and input guards
var yes2ReadyPromise = null;
var yes2Cached = null;
var yes2GameplayActive = false;
var yes2StartComplete = false;
var yes2StartInProgress = false;
var yes2StartRetries = 0;
var yes2SdkEventsBound = false;
var yes2LastProgress = 0;
var yes2LastProgressSent = -1;
var yes2LastProgressSentAt = 0;
var yes2ProgressTimer = null;
var yes2LastProgressSdk = null;
var yes2LoggedWarnings = Object.create(null);
var yes2ReplayBusy = false;
var yes2BannerVisible = false;
var yes2HappyTimeSent = false;
var yes2RewardBusy = false;
var yes2RewardChoiceMade = false;
var yes2RewardedOnThisResult = false;
var yes2PlatformPaused = false;
var yes2AdActive = false;
var yes2HostAudioEnabled = true;
var yes2ResumeAdDone = false;

function yes2Sleep(ms) {
  return new Promise(function (resolve) { setTimeout(resolve, ms); });
}

function yes2LogOnce(key, message, error) {
  if (!Q.has('debug') || yes2LoggedWarnings[key]) return;
  yes2LoggedWarnings[key] = true;
  if (window.console && typeof window.console.warn === 'function') {
    window.console.warn(message, error || '');
  }
}

function yes2SdkReady() {
  if (yes2Cached) return Promise.resolve(yes2Cached);
  if (!yes2ReadyPromise) {
    yes2ReadyPromise = (async function () {
      var sdk = null;
      // The dashboard may inject its platform adapter asynchronously. Start polling as early as this script loads.
      for (var i = 0; i < 150; i++) {
        if (window.Yes2SDK && typeof window.Yes2SDK.initializeAsync === 'function') {
          sdk = window.Yes2SDK;
          break;
        }
        await yes2Sleep(100);
      }
      if (!sdk) {
        yes2LogOnce('sdk-missing', 'Yes2SDK is not injected yet; gameplay remains available.');
        return null;
      }
      try {
        await sdk.initializeAsync();
        yes2Cached = sdk;
        yes2BindPlatformEvents(sdk);
        // Send only the latest known loading value when initialization is complete.
        yes2LastProgressSent = -1;
        yes2LastProgressSdk = sdk;
        yes2SendProgress(yes2LastProgress, true);
        return sdk;
      } catch (e) {
        yes2LogOnce('sdk-init', 'Yes2SDK initialization failed; gameplay remains available.', e);
        return null;
      }
    })().finally(function () {
      if (!yes2Cached) yes2ReadyPromise = null;
    });
  }
  return yes2ReadyPromise;
}

function yes2AdsRuntime() {
  // The official @yes2games/js wrapper handles portal adapters, no-fill and stale callbacks.
  return window.Yes2Runtime && window.Yes2Runtime.ads ? window.Yes2Runtime.ads : null;
}

function yes2SendProgress(value, force) {
  var sdk = yes2Cached;
  if (!sdk || typeof sdk.setLoadingProgress !== 'function') return;
  var n = Math.max(0, Math.min(100, Math.floor(value)));
  if (!force && n === yes2LastProgressSent && sdk === yes2LastProgressSdk) return;

  var now = Date.now();
  // Inspector records every loading-progress event. Cap normal updates to four per second,
  // but send 100 immediately so the host loading screen can dismiss without delay.
  if (!force && n < 100 && yes2LastProgressSentAt && now - yes2LastProgressSentAt < 250) {
    if (!yes2ProgressTimer) {
      yes2ProgressTimer = setTimeout(function () {
        yes2ProgressTimer = null;
        if (yes2Cached) yes2SendProgress(yes2LastProgress, false);
      }, Math.max(10, 250 - (now - yes2LastProgressSentAt)));
    }
    return;
  }

  if (yes2ProgressTimer && (force || n >= 100)) {
    clearTimeout(yes2ProgressTimer);
    yes2ProgressTimer = null;
  }
  yes2LastProgressSent = n;
  yes2LastProgressSentAt = now;
  yes2LastProgressSdk = sdk;
  try { sdk.setLoadingProgress(n); }
  catch (e) { yes2LogOnce('progress-error', 'Yes2SDK rejected a loading-progress update.', e); }
}

function yes2Progress(value) {
  yes2LastProgress = Math.max(0, Math.min(100, Math.floor(value)));
  // Do not start SDK discovery from the per-frame loader callback. Initialization begins once at boot.
  if (yes2Cached) yes2SendProgress(yes2LastProgress, false);
}

function yes2SetPlatformMute() {
  if (window.GameAudio && typeof GameAudio.setPlatformMuted === 'function') {
    GameAudio.setPlatformMuted(!yes2HostAudioEnabled || yes2PlatformPaused || yes2AdActive);
  }
}

function syncPauseButton() {
  var button = $('btn-pause');
  if (!button) return;
  var paused = !!game.userPaused;
  button.textContent = paused ? '▶' : 'Ⅱ';
  button.setAttribute('aria-label', paused ? 'resume game' : 'pause game');
  button.setAttribute('title', paused ? 'Resume' : 'Pause');
  button.classList.toggle('paused', paused);
}

function toggleGamePause() {
  if (!game.ready || !game.loaded || !game.state || game.state.phase === 2 || game.menuOpen) return;
  game.userPaused = !game.userPaused;
  if (game.userPaused) {
    held = {};
    pushInput();
    setPaused(true);
    if (window.GameAudio) GameAudio.setActive(false);
    yes2GameplayStop();
  } else {
    setPaused(false);
    pushInput();
    yes2SetPlatformMute();
    if (window.GameAudio) GameAudio.setActive(true);
    yes2GameplayStart();
    if (window.Module && Module.canvas) Module.canvas.focus();
  }
  syncPauseButton();
}

function yes2GetSprintPoints() {
  try {
    var points = Number(localStorage.getItem('or.sprintPoints') || 0);
    return Number.isFinite(points) && points > 0 ? Math.floor(points) : 0;
  } catch (e) { return 0; }
}

function yes2RenderSprintPoints() {
  var panel = $('reward-points');
  var value = $('sprint-points');
  if (panel) panel.classList.remove('hidden');
  if (value) value.textContent = String(yes2GetSprintPoints());
}

function yes2GrantSprintPoints(amount) {
  var total = yes2GetSprintPoints() + amount;
  try { localStorage.setItem('or.sprintPoints', String(total)); } catch (e) {}
  yes2RenderSprintPoints();
  var status = $('reward-status');
  if (status) status.textContent = '+' + amount + ' points earned!';
}

function yes2PrepareRewardOffer() {
  yes2RewardChoiceMade = false;
  var actions = $('reward-actions');
  var ads = yes2AdsRuntime();
  var supported = !!(ads && typeof ads.showRewarded === 'function');
  try {
    if (supported && typeof ads.isRewardedSupported === 'function') supported = !!ads.isRewardedSupported();
  } catch (e) { supported = false; }
  if (actions) actions.classList.toggle('hidden', !supported);
  yes2RenderSprintPoints();
  var status = $('reward-status');
  if (status) status.textContent = '';
}

async function watchRewardedBonus() {
  if (yes2RewardBusy || yes2RewardChoiceMade) return;
  var ads = yes2AdsRuntime();
  if (!ads || typeof ads.showRewarded !== 'function') return;
  try {
    if (typeof ads.isRewardedSupported === 'function' && !ads.isRewardedSupported()) return;
  } catch (e) { return; }

  yes2RewardBusy = true;
  var rewardGranted = false;
  var restored = false;
  var button = $('reward-ad');
  if (button) button.disabled = true;
  function restoreRewardedAd() {
    if (restored) return;
    restored = true;
    yes2AdActive = false;
    yes2SetPlatformMute();
    if (!yes2PlatformPaused && !game.menuOpen && !game.userPaused) {
      setPaused(false);
      if (window.GameAudio) GameAudio.setActive(true);
    }
  }
  function grantOnce() {
    if (rewardGranted) return;
    rewardGranted = true;
    yes2GrantSprintPoints(500);
    yes2RewardChoiceMade = true;
    var actions = $('reward-actions');
    if (actions) actions.classList.add('hidden');
  }
  try {
    yes2GameplayStop();
    var outcome = await ads.showRewarded('race-bonus-points', {
      beforeAd: function () {
        yes2AdActive = true;
        yes2RewardedOnThisResult = true;
        setPaused(true);
        if (window.GameAudio) GameAudio.setActive(false);
        yes2SetPlatformMute();
      },
      adViewed: grantOnce,
      adDismissed: function () {
        var status = $('reward-status');
        if (status) status.textContent = 'No points awarded because the ad was skipped.';
      },
      noFill: function () {
        var status = $('reward-status');
        if (status) status.textContent = 'No ad is available right now. You can still race.';
      },
      afterAd: restoreRewardedAd
    });
    if (outcome === 'viewed') grantOnce();
  } catch (e) {
    yes2LogOnce('rewarded-error', 'Rewarded ad unavailable; the race remains playable.', e);
    var status = $('reward-status');
    if (status) status.textContent = 'No ad available. You can continue without it.';
  } finally {
    restoreRewardedAd();
    yes2RewardBusy = false;
    if (button) button.disabled = false;
  }
}

function skipRewardedBonus() {
  if (yes2RewardBusy) return;
  yes2RewardChoiceMade = true;
  var actions = $('reward-actions');
  if (actions) actions.classList.add('hidden');
}

function yes2BindPlatformEvents(sdk) {
  if (yes2SdkEventsBound || !sdk || typeof sdk.on !== 'function') return;
  yes2SdkEventsBound = true;
  try {
    sdk.on('pause', function () {
      yes2PlatformPaused = true;
      setPaused(true);
      yes2SetPlatformMute();
      if (window.GameAudio) GameAudio.setActive(false);
      yes2GameplayStop();
    });
    sdk.on('resume', function () {
      yes2PlatformPaused = false;
      yes2SetPlatformMute();
      if (!game.menuOpen && !game.userPaused && !yes2AdActive) {
        setPaused(false);
        if (window.GameAudio) GameAudio.setActive(true);
        yes2GameplayStart();
      }
    });
    sdk.on('audioEnabledChange', function (event) {
      if (event && typeof event.enabled === 'boolean') {
        yes2HostAudioEnabled = event.enabled;
        yes2SetPlatformMute();
      }
    });
    sdk.on('accountDialogOpen', function () {
      yes2PlatformPaused = true;
      setPaused(true);
      yes2SetPlatformMute();
      if (window.GameAudio) GameAudio.setActive(false);
      yes2GameplayStop();
    });
    sdk.on('accountDialogClose', function () {
      yes2PlatformPaused = false;
      yes2SetPlatformMute();
      if (!game.menuOpen && !game.userPaused && !yes2AdActive) {
        setPaused(false);
        if (window.GameAudio) GameAudio.setActive(true);
        yes2GameplayStart();
      }
    });
  } catch (e) {
    yes2SdkEventsBound = false;
    yes2LogOnce('event-bind', 'Some optional Yes2SDK lifecycle events could not be subscribed.', e);
  }
}

function yes2GameplayStart(sdkOverride) {
  if (!yes2StartComplete || yes2GameplayActive || !game.ready ||
      game.menuOpen || game.userPaused || yes2PlatformPaused || yes2AdActive) return;
  var sdk = sdkOverride || yes2Cached;
  if (!sdk || !sdk.game || typeof sdk.game.gameplayStart !== 'function') return;
  try {
    sdk.game.gameplayStart();
    yes2GameplayActive = true;
  } catch (e) {
    yes2LogOnce('gameplay-start', 'Yes2SDK gameplayStart failed; it will retry on the next gameplay transition.', e);
  }
}

function yes2GameplayStop(sdkOverride) {
  if (!yes2GameplayActive) return;
  var sdk = sdkOverride || yes2Cached;
  if (!sdk || !sdk.game || typeof sdk.game.gameplayStop !== 'function') {
    yes2GameplayActive = false;
    return;
  }
  try { sdk.game.gameplayStop(); } catch (e) {}
  yes2GameplayActive = false;
}

function yes2FinishLoading() {
  // Called only from the engine's ready callback, after the WebAssembly game and required assets have loaded.
  if (!game.ready || yes2StartComplete || yes2StartInProgress) return;
  yes2StartInProgress = true;
  yes2SdkReady().then(async function (sdk) {
    if (!sdk || typeof sdk.startGameAsync !== 'function') {
      throw new Error('Yes2SDK is not available yet');
    }
    // Final loading value is sent once, only after the engine reports ready.
    yes2Progress(100);
    yes2BindPlatformEvents(sdk);
    await sdk.startGameAsync();
    yes2StartComplete = true;
    yes2StartRetries = 0;
    yes2GameplayStart(sdk);
  }).catch(function (e) {
    yes2LogOnce('start-game', 'Yes2SDK startGameAsync has not completed yet; the game remains playable.', e);
  }).finally(function () {
    yes2StartInProgress = false;
    if (!yes2StartComplete && yes2StartRetries < 20 && game.ready) {
      yes2StartRetries++;
      setTimeout(yes2FinishLoading, 1000);
    }
  });
}

function yes2HideBanner() {
  var ads = yes2AdsRuntime();
  if (!ads || typeof ads.hideBanner !== 'function') return;
  try { ads.hideBanner(); } catch (e) {}
  yes2BannerVisible = false;
}

async function yes2ShowResultBanner() {
  var ads = yes2AdsRuntime();
  if (!ads || typeof ads.showBanner !== 'function') return;
  try {
    if (typeof ads.isBannerSupported === 'function' && !ads.isBannerSupported()) return;
    await ads.showBanner('bottom');
    yes2BannerVisible = true;
  } catch (e) {
    // Banners are not supported on every portal. Their absence must not block play.
  }
}

function yes2CelebrateWin() {
  if (yes2HappyTimeSent) return;
  yes2HappyTimeSent = true;
  var sdk = yes2Cached;
  if (sdk && sdk.game && typeof sdk.game.happyTime === 'function') {
    try { sdk.game.happyTime(); } catch (e) {}
  }
}

async function raceAgainWithAd() {
  if (yes2ReplayBusy) return;
  yes2ReplayBusy = true;
  var restored = false;
  function restoreFromAd() {
    if (restored) return;
    restored = true;
    yes2AdActive = false;
    yes2SetPlatformMute();
    if (!yes2PlatformPaused && !game.menuOpen && !game.userPaused) {
      setPaused(false);
      if (window.GameAudio) GameAudio.setActive(true);
    }
  }
  try {
    var sdk = yes2Cached;
    var ads = yes2AdsRuntime();
    var canShow = !!(sdk && ads && typeof ads.showInterstitial === 'function');
    if (canShow && typeof ads.isInterstitialSupported === 'function') {
      canShow = !!ads.isInterstitialSupported();
    }
    // Signal every player-chosen between-race break. The portal SDK, not the game,
    // applies its own first-ad delay and frequency caps. This also lets Inspector finish its ad check.
    if (canShow && !yes2PlatformPaused && !yes2RewardedOnThisResult) {
      yes2GameplayStop(sdk);
      yes2HideBanner();
      try {
        await ads.showInterstitial('race-replay', {
          beforeAd: function () {
            yes2AdActive = true;
            setPaused(true);
            if (window.GameAudio) GameAudio.setActive(false);
            yes2SetPlatformMute();
          },
          afterAd: restoreFromAd,
          noFill: restoreFromAd
        });
      } catch (e) {
        restoreFromAd();
        yes2LogOnce('interstitial-error', 'Interstitial was unavailable; continuing without blocking the next race.', e);
      }
    }
  } catch (e) {
    yes2LogOnce('interstitial-runtime', 'Interstitial was skipped because the SDK runtime is not ready.', e);
  } finally {
    if (yes2AdActive) restoreFromAd();
    yes2ReplayBusy = false;
    startRace();
    yes2GameplayStart(sdk);
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

// Refresh steering input while a touch/key is held so high-speed assist pulses are not dependent on pointer events.
setInterval(function () {
  if (game.menuOpen || !game.state || Number(game.state.speed) < 125) return;
  var steeringHeld = false;
  for (var source in held) {
    if (held[source] & (BIT.left | BIT.right)) { steeringHeld = true; break; }
  }
  if (steeringHeld) pushInput();
}, 40);

// Begin SDK initialization before loading the game assets. The ready signal is sent later, after the engine reports ready.
yes2SdkReady();
"""
    js = replace_once(
        js,
        "var catalogue = { cars: [], colours: [], tracks: [] };",
        "var catalogue = { cars: [], colours: [], tracks: [] };\n" + helpers,
        "insert Yes2SDK and mobile helpers",
    )

    js = replace_once(
        js,
        "function pushInput() {\n  var mask = 0;\n  for (var k in held) mask |= held[k];\n  if (game.menuOpen) mask = 0;\n  if (window.Module && Module._web_set_input) Module._web_set_input(mask, 0);\n}",
        "function pushInput() {\n  var mask = 0;\n  for (var k in held) mask |= held[k];\n  if (!game.menuOpen && (mask & (BIT.left | BIT.right)) && game.state && Number(game.state.speed) >= 125) {\n    /* Brief high-speed turn-in assist; normal-speed steering remains unchanged. */\n    if ((Date.now() % 420) < 65) mask |= BIT.hand;\n  }\n  if (game.menuOpen) mask = 0;\n  if (window.Module && Module._web_set_input) Module._web_set_input(mask, 0);\n}",
        "add a brief high-speed turn-in assist without changing normal-speed steering",
    )

    js = replace_once(
        js,
        "function startRace() {\n  saveChoice();",
        "function startRace() {\n  choice.opponents = 5;\n  choice.laps = 1;\n  yes2HappyTimeSent = false;\n  yes2HideBanner();\n  saveChoice();",
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
        "  print: function (t) { console.log(t); },",
        "  print: function (t) { if (Q.has('verbose')) console.log(t); },",
        "suppress routine Emscripten stdout in portal builds",
    )
    # Emscripten can change the exact escaping around the Aborted() matcher between versions.
    # Patch the printErr callback by its stable function signature, preserving fatal error reporting.
    js, err_count = re.subn(
        r"(?m)^[ \t]*printErr:\s*(?:function\s*)?(?:\(\s*t\s*\)|t)\s*(?:=>)?\s*\{[^\n]*$",
        r"  printErr: function (t) { var fatal = /^FATAL|Aborted\(|Assertion/.test(t); if (fatal) { if (window.console && console.error) console.error(t); showError(t); } else if (Q.has('verbose')) console.warn(t); },",
        js,
        count=1,
    )
    if err_count != 1:
        raise RuntimeError("Could not safely patch the Emscripten printErr callback to avoid console flooding.")

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
    # Portal-ready pause/reward wiring. Apply these to the fully patched source so every
    # replacement is checked against the final game.js rather than an earlier intermediate form.
    js = replace_once(
        js,
        "  if (game.menuOpen) mask = 0;",
        "  if (game.menuOpen || game.userPaused) mask = 0;",
        "prevent stuck driving input while manually paused",
    )
    js = replace_once(
        js,
        "  if (!game.menuOpen && (mask & (BIT.left | BIT.right)) && game.state && Number(game.state.speed) >= 125) {",
        "  if (!game.menuOpen && !game.userPaused && (mask & (BIT.left | BIT.right)) && game.state && Number(game.state.speed) >= 125) {",
        "disable steering assist when manually paused",
    )
    js = replace_once(
        js,
        "function openMenu() {\n  if (!game.loaded) return;\n  game.menuOpen = true;\n  yes2GameplayStop();\n  yes2HideBanner();",
        "function openMenu() {\n  if (!game.loaded) return;\n  game.menuOpen = true;\n  game.userPaused = false;\n  syncPauseButton();\n  yes2GameplayStop();\n  yes2HideBanner();",
        "synchronize pause state when opening menu",
    )
    js = replace_once(
        js,
        "function closeMenu() {\n  game.menuOpen = false;\n  yes2HideBanner();",
        "function closeMenu() {\n  game.menuOpen = false;\n  game.userPaused = false;\n  syncPauseButton();\n  yes2HideBanner();",
        "synchronize pause state when closing menu",
    )
    js = replace_once(
        js,
        "function startRace() {\n  choice.opponents = 5;\n  choice.laps = 1;\n  yes2HappyTimeSent = false;\n  yes2HideBanner();",
        "function startRace() {\n  choice.opponents = 5;\n  choice.laps = 1;\n  yes2HappyTimeSent = false;\n  yes2RewardedOnThisResult = false;\n  yes2RewardChoiceMade = false;\n  yes2HideBanner();",
        "reset rewarded state on a new race",
    )
    js = replace_once(
        js,
        "  $('results').classList.remove('hidden');\n  yes2ShowResultBanner();",
        "  $('results').classList.remove('hidden');\n  yes2PrepareRewardOffer();\n  yes2ShowResultBanner();",
        "offer rewarded bonus on the results screen",
    )
    js = replace_once(
        js,
        "    $('topbar').classList.remove('hidden');",
        "    $('topbar').classList.remove('hidden');\n    syncPauseButton();",
        "initialize the pause button after the HUD loads",
    )
    js = replace_once(
        js,
        "$('btn-menu').addEventListener('click', openMenu);",
        "$('btn-menu').addEventListener('click', openMenu);\n$('btn-pause').addEventListener('click', toggleGamePause);\n$('reward-ad').addEventListener('click', watchRewardedBonus);\n$('skip-reward').addEventListener('click', skipRewardedBonus);",
        "wire pause and opt-in rewarded bonus actions",
    )
    js = replace_once(
        js,
        "if (!perf.shadows || game.menuOpen || Q.has('ff'))",
        "if (!perf.shadows || game.menuOpen || game.userPaused || Q.has('ff'))",
        "skip performance logging while game is paused",
    )
    write_text(path, js)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", required=True, help="Output directory for the portal-uploadable web build")
    parser.add_argument("--source", help="Optional prebuilt website directory. If supplied, use these binaries/assets instead of downloading the live release.")
    args = parser.parse_args()
    out = Path(args.out).resolve()
    if out.exists():
        shutil.rmtree(out)
    out.mkdir(parents=True)

    required = [
        "index.html", "style.css", "game.js", "audio.js", "credits.html",
        "cars.json", "assets.js", "assets.bin", "opennfs.js", "opennfs.wasm",
    ]
    source_mode = bool(args.source)
    if source_mode:
        source = Path(args.source).resolve()
        if not source.is_dir():
            raise RuntimeError(f"Prebuilt source directory does not exist: {source}")
        print(f"Using rebuilt Open Road engine and assets from {source}...")
        shutil.copytree(source, out, dirs_exist_ok=True)
        for name in required:
            path = out / name
            if not path.is_file() or path.stat().st_size == 0:
                raise RuntimeError(f"Rebuilt site is missing required file {name}; refusing to package.")
            print(f"  verified {name} ({path.stat().st_size} bytes)")
    else:
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

    if source_mode:
        for track_id in track_ids:
            path = out / "tracks" / f"{track_id}.bin"
            if not path.is_file() or path.stat().st_size == 0:
                raise RuntimeError(f"Rebuilt site is missing track pack {track_id}.bin; refusing an incomplete build.")
        print(f"Verified all {len(track_ids)} rebuilt track packs.")
    else:
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
    patch_audio(out)
    patch_js(out)
    print("Patched: auto-start, five AI opponents, touch safety, landscape prompt, Yes2SDK lifecycle/ads.")
    print(f"Ready: {out}")
    print("No SDK keys are embedded. Live ads require the Yes2Games dashboard to inject its runtime.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:
        print(f"BUILD FAILED: {exc}", file=sys.stderr)
        sys.exit(1)
