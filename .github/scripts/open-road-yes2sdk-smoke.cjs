#!/usr/bin/env node
'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

const gameJsPath = process.argv[2];
if (!gameJsPath) throw new Error('Usage: node open-road-yes2sdk-smoke.cjs <built-game.js>');
const source = fs.readFileSync(gameJsPath, 'utf8');
assert.ok(source.includes("print: function (t) { if (Q.has('verbose')) console.log(t); }"), 'Emscripten stdout must not log in Inspector debug mode');
assert.ok(source.includes('window.__openRoadSdkInitPromise'), 'game code must reuse the early HTML SDK-init promise');
assert.ok(source.includes('window.__openRoadSdkInitCalled'), 'SDK initialization must be guarded as a one-shot action');
assert.ok(source.includes("else if (Q.has('verbose')) console.warn(t);"), 'non-fatal Emscripten stderr must be quiet unless verbose mode is explicit');
assert.ok(source.includes("toggleGamePause"), 'the in-game Pause/Resume action must be wired');
assert.ok(source.includes("showRewarded('race-bonus-points'"), 'the results-screen rewarded ad must use the official wrapper');
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
let rewardedCount = 0;
let progressCalls = 0;
let mutedDuringInterstitial = false;
let mutedDuringRewardedAd = false;
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
  attributes: {},
  setAttribute(name, value) { this.attributes[name] = String(value); },
  focus() {}
};
const game = { ready: true, menuOpen: false, userPaused: false, state: { phase: 1 }, loaded: true };
const mockAudio = {
  setActive(on) { activeAudioStates.push(!!on); },
  setPlatformMuted(on) { platformMutes.push(!!on); },
  isMuted() { return platformMutes.length ? platformMutes.at(-1) : false; },
  toggleMute() { return true; }
};
const mockSdk = {
  async initializeAsync() { events.push('initializeAsync'); },
  setLoadingProgress(n) { progressCalls++; events.push('progress:' + n); },
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
  isBannerSupported() { return true; },
  async showInterstitial(placement, callbacks) {
    interstitialCount++;
    events.push('showInterstitial:' + placement);
    callbacks.beforeAd();
    mutedDuringInterstitial = platformMutes.at(-1) === true;
    await new Promise(resolve => setTimeout(resolve, 1));
    callbacks.afterAd();
  },
  async showBanner(position) { events.push('showBanner:' + position); },
  hideBanner() { events.push('hideBanner'); },
  isRewardedSupported() { return true; },
  async showRewarded(placement, callbacks) {
    rewardedCount++;
    events.push('showRewarded:' + placement);
    callbacks.beforeAd();
    mutedDuringRewardedAd = platformMutes.at(-1) === true;
    await new Promise(resolve => setTimeout(resolve, 1));
    callbacks.adViewed();
    callbacks.afterAd();
    return 'viewed';
  }
};
const storedValues = new Map();
const fakeStorage = {
  getItem(key) { return storedValues.has(key) ? storedValues.get(key) : null; },
  setItem(key, value) { storedValues.set(key, String(value)); }
};
const fakeWindow = {
  Yes2SDK: mockSdk,
  Yes2Runtime: { ads: mockAds },
  GameAudio: mockAudio,
  Module: { _web_set_flag(flag, value) { pauseFlags.push([flag, value]); }, canvas: { focus() { events.push('canvasFocus'); } } },
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
  localStorage: fakeStorage,
  held: { touch: 1 },
  BIT: { left: 4, right: 8 },
  pushInput() { events.push('pushInput'); },
  setInterval() { return 0; },
  clearInterval() {},
  matchMedia: () => ({ matches: false }),
  Q: { has: () => false, get: () => null },
  game,
  Module: fakeWindow.Module,
  localStorage: fakeStorage,
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
  // Repeated callers share the same boot promise; neither init nor the platform-ready signal may repeat.
  await context.yes2SdkReady();
  context.yes2FinishLoading();
  context.yes2FinishLoading();
  await new Promise(resolve => setTimeout(resolve, 30));
  assert.equal(events.filter(e => e === 'initializeAsync').length, 1, 'SDK initialization must be called exactly once');
  assert.equal(events.filter(e => e === 'startGameAsync').length, 1, 'startGameAsync must be called exactly once');
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

  // The new HUD button must stop steering/gameplay and then resume without opening the menu.
  context.toggleGamePause();
  assert.equal(game.userPaused, true, 'pause button must set the manual paused state');
  assert.equal(element.textContent, '▶', 'pause button should turn into a resume icon');
  assert.ok(pauseFlags.some(x => x[0] === 'paused' && x[1] === true), 'pause button must pause the engine');
  assert.equal(activeAudioStates.at(-1), false, 'manual pause must silence game audio');
  context.toggleGamePause();
  assert.equal(game.userPaused, false, 'second press must resume the game');
  assert.equal(element.textContent, 'Ⅱ', 'resume should restore the pause icon');
  assert.ok(pauseFlags.some(x => x[0] === 'paused' && x[1] === false), 'resume must unpause the engine');
  assert.equal(activeAudioStates.at(-1), true, 'resume must restore game audio');

  // Repeated per-frame values must not flood the SDK/Inspector event log.
  const progressBefore = progressCalls;
  for (let i = 0; i < 100; i++) context.yes2Progress(47);
  await new Promise(resolve => setTimeout(resolve, 100));
  context.yes2Progress(48);
  await new Promise(resolve => setTimeout(resolve, 1600));
  const progressDelta = progressCalls - progressBefore;
  assert.ok(progressDelta <= 2, 'loading progress must be coalesced to no more than two updates in this 1.7-second window');

  // A player-selected natural break must be signalled immediately; the portal applies its own ad policy.
  await context.raceAgainWithAd();
  assert.equal(interstitialCount, 1, 'first natural replay break should request an interstitial without a game-side timer gate');
  assert.equal(mutedDuringInterstitial, true, 'audio must be muted while the interstitial is active');
  assert.ok(startRaceCount >= 1, 'replay must never be blocked when the ad is skipped');
  assert.ok(events.includes('gameplayStop'), 'gameplayStop must be sent at a break');
  assert.ok(events.filter(e => e === 'gameplayStart').length >= 2, 'gameplayStart must bracket active play');
  assert.ok(events.includes('gameplayStop'), 'gameplayStop must be sent at a break');
  assert.ok(events.filter(e => e === 'gameplayStart').length >= 2, 'gameplayStart must bracket active play');

  await context.yes2ShowResultBanner();
  assert.ok(events.includes('showBanner:bottom'), 'results banner must use the official runtime ads wrapper');
  context.yes2HideBanner();
  assert.ok(events.includes('hideBanner'), 'banner must be hidden when racing resumes');

  // Subsequent natural breaks are signalled too; no-fill must never strand the player.
  await context.raceAgainWithAd();
  assert.equal(interstitialCount, 2, 'each player-chosen natural break should be signalled to platform pacing');
  assert.ok(startRaceCount >= 2, 'replay must always continue after ad completion');

  // Reward is optional and is granted only if the official runtime reports that the video was viewed.
  context.yes2PrepareRewardOffer();
  await context.watchRewardedBonus();
  assert.equal(rewardedCount, 1, 'results screen must be able to request a rewarded ad');
  assert.equal(context.yes2GetSprintPoints(), 500, 'rewarded completion should award the advertised points exactly once');
  assert.equal(mutedDuringRewardedAd, true, 'audio must be muted during a rewarded video');
  assert.equal(context.yes2RewardedOnThisResult, true, 'a rewarded ad must mark this result screen as having shown an ad');

  // Do not chain a second ad immediately after the rewarded video on the same result screen.
  await context.raceAgainWithAd();
  assert.equal(interstitialCount, 2, 'interstitial must be skipped on the same result screen after a rewarded ad');
  context.yes2RewardedOnThisResult = false; // next race/result is a new ad opportunity
  await context.raceAgainWithAd();
  assert.equal(interstitialCount, 3, 'an interstitial can be requested again at a later natural break');

  console.log(JSON.stringify({
    result: 'PASS',
    checks: [
      'SDK initialize → loading progress → startGameAsync → gameplayStart order',
      'initializeAsync and startGameAsync each called exactly once even when lifecycle hooks repeat',
      'pause/resume event handlers',
      'dedicated manual pause/resume button and audio state',
      'platform audio enabled/disabled events',
      'loading progress is deduplicated and rate-limited',
      'interstitial mute/restore and replay continuation',
      'results banner uses official runtime and hides at next race',
      'rewarded ad awards 500 points only on viewed outcome',
      'rewarded ad pauses/mutes and avoids chaining an interstitial on same result',
      'Emscripten console logs gated behind explicit verbose flag',
      'all player-chosen natural breaks are signalled to platform pacing',
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
