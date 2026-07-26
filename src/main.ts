import Phaser from 'phaser';
import '@fontsource/press-start-2p';
import { BootScene } from './scenes/BootScene';
import { TitleScene } from './scenes/TitleScene';
import { WorldScene } from './scenes/WorldScene';
import { BattleScene } from './scenes/BattleScene';
import { DebugScene } from './scenes/DebugScene';

// GBA-native resolution, FireRed style. Scaled up to fit the window.
export const VP_W = 240;
export const VP_H = 160;

const game = new Phaser.Game({
  type: Phaser.AUTO,
  parent: 'game',
  width: VP_W,
  height: VP_H,
  backgroundColor: '#10141f',
  pixelArt: true,
  roundPixels: true,
  // Exact deltas — keeps the automated playtest harness deterministic.
  fps: { smoothStep: false },
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
  },
  scene: [BootScene, TitleScene, WorldScene, BattleScene, DebugScene],
});

// Audio needs a real user gesture: init on first key/pointer, M toggles mute.
import('./audio/sound').then(({ Sound }) => {
  (window as any).__sound = Sound;
  const init = () => Sound.init();
  window.addEventListener('keydown', init);
  window.addEventListener('pointerdown', init);
  window.addEventListener('keydown', (e) => {
    if (e.key === 'm' || e.key === 'M') Sound.toggleMute();
  });
});

// ── Automated playtest harness ────────────────────────────────────────────
// The AI dev pipeline drives the game headlessly: synthetic key events plus
// manual loop pumping (RAF stalls when the preview tab is hidden).
const W = window as any;
W.__game = game;
import('./core/state').then((m) => { W.__state = m.GameState; });
// Tweens/clocks in Phaser 4 advance on wall-clock time, so pumps run the loop
// for real milliseconds with time scaled up to make animations near-instant.
W.__pump = (ms = 100) => {
  const scenes = () => game.scene.getScenes(true);
  for (const s of scenes()) { s.tweens.timeScale = 40; s.time.timeScale = 40; }
  const start = performance.now();
  let i = 0;
  while (performance.now() - start < ms) game.loop.step(start + i++ * 16.7);
  for (const s of scenes()) { s.tweens.timeScale = 1; s.time.timeScale = 1; }
  return scenes().map((s) => s.scene.key);
};
const dispatch = (type: string, key: string, code: string, keyCode: number) =>
  window.dispatchEvent(new KeyboardEvent(type, { key, code, keyCode, which: keyCode } as any));
W.__keys = {
  z: ['z', 'KeyZ', 90],
  x: ['x', 'KeyX', 88],
  up: ['ArrowUp', 'ArrowUp', 38],
  down: ['ArrowDown', 'ArrowDown', 40],
  left: ['ArrowLeft', 'ArrowLeft', 37],
  right: ['ArrowRight', 'ArrowRight', 39],
};
// Game logic is async (dialog/battle await key events), so between pumps we
// must yield to the microtask queue for those continuations to run.
const drain = async (n = 25) => {
  for (let i = 0; i < n; i++) await null;
};
/** Step the loop an exact number of frames (no wall-clock coupling). */
W.__frames = (n: number) => {
  const start = performance.now();
  for (let i = 0; i < n; i++) game.loop.step(start + i * 16.7);
};
/** One tap = one key press = at most one grid step; async UI settles after. */
W.__tap = async (name: string) => {
  const [key, code, kc] = W.__keys[name];
  dispatch('keydown', key, code, kc);
  W.__frames(2); // key registers, at most one step begins
  dispatch('keyup', key, code, kc);
  for (let r = 0; r < 4; r++) {
    await drain();
    W.__pump(40);
  }
};
/** Run a sequence of taps, e.g. __seq('up','up','left','z','z'). */
W.__seq = async (...names: string[]) => {
  for (const n of names) await W.__tap(n);
  await drain();
  return game.scene.getScenes(true).map((s) => s.scene.key);
};
