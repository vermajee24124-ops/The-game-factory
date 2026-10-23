#!/usr/bin/env node
'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

const gameJsPath = process.argv[2];
if (!gameJsPath) throw new Error('Usage: node open-road-yes2sdk-smoke.cjs <built-game.js>');
const source = fs.readFileSync(gameJsPath, 'utf8');
const startMark = '// ---------------------------------------------------------------- Yes2SDK lifecycle, ads, orientation and input guards';
const endMark = '// ---------------------------------------------------------------- input';
const start = source.indexOf(startMark);
const end = source.indexOf(endMark, start + startMark.length);
if (start < 0 || end < 0) {
  throw new Error('Could not find the Yes2SDK lifecycle helper block in the built game.');
}
const helper = source.slice(start, end);
const events = [];
const sdkHandlers = Object.create(null);
const pauseFlags = [];
const platformMutes = [];
const activeAudioStates = [];
let interstitialCount = 0;
let mutedDuringInterstitial = false;
let startRaceCount = 0;

const element = {
  classList: {
    add() {},
    remove() {},
    toggle() {},
    contains() { return false; }
  },
  style: {},
  textContent: '',
  disabled: false,
  focus() {}
};
const game = { ready: true, menuOpen: false, state: { phase: 1 }, loaded: true };
const mockAudio = {
  setActive(on) { activeAudioStates.push(!!on); },
  setPlatformMuted(on) { platformMutes.push(!!on); },
  isMuted() { return platformMutes.length ? platformMutes.at(-1) : false; },
  toggleMute() { return true; }
};
const mockSdk = {
  async initializeAsync() { events.push('initializeAsync'); },
  setLoadingProgress(n) { events.push('progress:' + n); },
  async startGameAsync() { events.push('startGameAsync'); },
  on(name, callback) { sdkHandlers[name] = callback; },
  game: {
    gameplayStart() { events.push('gameplayStart'); },
    gameplayStop() { events.push('gameplayStop'); },
    happyTime() { events.push('happyTime'); }
  }
};
const mockAds = {
  isInterstitialSupported() { return true; },
  async showInterstitial(placement, callbacks) {
    interstitialCount++;
    events.push('showInterstitial:' + placement);
    callbacks.beforeAd();
    mutedDuringInterstitial = platformMutes.at(-1) === true;
    await new Promise(resolve => setTimeout(resolve, 1));
    callbacks.afterAd();
  }
};
const mockBanners = {
  isSupported() { return true; },
  async showBanner(id, size) {
    events.push('showBanner:' + id + ':' + size);
  },
  hideBanner(id) { events.push('hideBanner:' + id); }
};
mockSdk.ads = mockAds;
mockSdk.banners = mockBanners;
const fakeWindow = {
  Yes2SDK: mockSdk,
  GameAudio: mockAudio,
  Module: { _web_set_flag(flag, value) { pauseFlags.push([flag, value]); } },
  addEventListener() {}
};
const fakeDocument = {
  addEventListener() {},
  fullscreenElement: null
};
const context = {
  window: fakeWindow,
  document: fakeDocument,
  screen: { orientation: { lock: async () => {} } },
  console,
  Promise,
  Date,
  Math,
  JSON,
  URLSearchParams,
  setTimeout,
  clearTimeout,
  setInterval() { return 0; },
  clearInterval() {},
  matchMedia: () => ({ matches: false }),
  Q: { has: () => false, get: () => null },
  game,
  Module: fakeWindow.Module,
  GameAudio: mockAudio,
  $: () => element,
  setPaused(value) { pauseFlags.push(['paused', !!value]); },
  startRace() { startRaceCount++; events.push('startRace'); }
};

vm.runInNewContext(helper, context, { filename: 'built-game-yes2sdk-helper.js' });

async function waitFor(fn, label) {
  const deadline = Date.now() + 5000;
  while (Date.now() < deadline) {
    if (fn()) return;
    await new Promise(resolve => setTimeout(resolve, 10));
  }
  throw new Error('Timed out waiting for ' + label + '. Events: ' + events.join(', '));
}

(async () => {
  context.yes2FinishLoading();
  await waitFor(() => events.includes('startGameAsync'), 'startGameAsync');
  await waitFor(() => events.includes('gameplayStart'), 'gameplayStart');
  assert.ok(events.indexOf('initializeAsync') >= 0, 'SDK must initialize');
  assert.ok(events.indexOf('progress:100') >= 0, 'loading progress must reach 100');
  assert.ok(events.indexOf('initializeAsync') < events.indexOf('startGameAsync'), 'initialize must precede startGameAsync');
  assert.ok(events.indexOf('startGameAsync') < events.indexOf('gameplayStart'), 'startGameAsync must precede gameplayStart');

  assert.equal(typeof sdkHandlers.pause, 'function', 'SDK pause event handler must be registered');
  assert.equal(typeof sdkHandlers.resume, 'function', 'SDK resume event handler must be registered');
  assert.equal(typeof sdkHandlers.audioEnabledChange, 'function', 'SDK audioEnabledChange handler must be registered');

  sdkHandlers.pause();
  assert.ok(pauseFlags.some(x => x[0] === 'paused' && x[1] === true), 'platform pause must pause the game');
  assert.ok(platformMutes.at(-1) === true, 'platform pause must mute audio');
  sdkHandlers.audioEnabledChange({ enabled: false });
  assert.ok(platformMutes.at(-1) === true, 'host mute setting must be honored');
  sdkHandlers.audioEnabledChange({ enabled: true });
  sdkHandlers.resume();
  assert.ok(platformMutes.at(-1) === false, 'resume with host audio enabled must unmute platform audio');

  // The initial 3-minute no-ad gate must not display an interstitial.
  await context.raceAgainWithAd();
  assert.equal(interstitialCount, 0, 'an interstitial must not show during the first three minutes');
  assert.ok(startRaceCount >= 1, 'replay must never be blocked when the ad is skipped');

  // After the cooldown, a requested interstitial must mute and restore audio around the ad.
  context.yes2SessionStartedAt = Date.now() - 240000;
  context.yes2LastInterstitial = Date.now() - 240000;
  await context.raceAgainWithAd();
  assert.equal(interstitialCount, 1, 'an interstitial should be requested after the cooldown');
  assert.equal(mutedDuringInterstitial, true, 'audio must be muted while the interstitial is active');
  assert.ok(startRaceCount >= 2, 'the next race must start after the interstitial');
  assert.ok(events.includes('gameplayStop'), 'gameplayStop must be sent at a break');
  assert.ok(events.filter(e => e === 'gameplayStart').length >= 2, 'gameplayStart must bracket active play');

  console.log(JSON.stringify({
    result: 'PASS',
    checks: [
      'SDK initialize → loading progress → startGameAsync → gameplayStart order',
      'pause/resume event handlers',
      'platform audio enabled/disabled events',
      'no interstitial in the first three minutes',
      'interstitial mute/restore and replay continuation',
      'gameplayStop/gameplayStart lifecycle'
    ],
    sdkEvents: events,
    interstitialCount,
    startRaceCount
  }, null, 2));
})().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
