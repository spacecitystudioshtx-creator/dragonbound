// Touch controls: GBA-style D-pad + A/B buttons that drive the game by
// dispatching the same synthetic keyboard events the engine already reads.
// Portrait: console-style bar under the screen. Landscape: overlay.
// Enabled on touch devices, or force with /?touch for desktop testing.

const KEYS: Record<string, [string, string, number]> = {
  up: ['ArrowUp', 'ArrowUp', 38],
  down: ['ArrowDown', 'ArrowDown', 40],
  left: ['ArrowLeft', 'ArrowLeft', 37],
  right: ['ArrowRight', 'ArrowRight', 39],
  a: ['z', 'KeyZ', 90],
  b: ['x', 'KeyX', 88],
};

function key(type: 'keydown' | 'keyup', name: string): void {
  const [k, code, keyCode] = KEYS[name];
  window.dispatchEvent(new KeyboardEvent(type, { key: k, code, keyCode, which: keyCode } as any));
}

export function initTouchControls(): void {
  const isTouch =
    'ontouchstart' in window ||
    navigator.maxTouchPoints > 0 ||
    new URLSearchParams(location.search).has('touch');
  if (!isTouch) return;

  document.body.classList.add('touch');
  const root = document.getElementById('controls')!;

  // ── D-pad: one pad, direction from thumb position, slide to change ──────
  const dpad = document.createElement('div');
  dpad.id = 'dpad';
  dpad.innerHTML = '<div class="dpad-arm h"></div><div class="dpad-arm v"></div><div class="nub"></div>';
  root.appendChild(dpad);

  let heldDir: string | null = null;

  const dirFromEvent = (e: PointerEvent): string | null => {
    const r = dpad.getBoundingClientRect();
    const dx = e.clientX - (r.left + r.width / 2);
    const dy = e.clientY - (r.top + r.height / 2);
    if (Math.abs(dx) < 8 && Math.abs(dy) < 8) return heldDir; // dead zone: keep current
    return Math.abs(dx) > Math.abs(dy) ? (dx > 0 ? 'right' : 'left') : (dy > 0 ? 'down' : 'up');
  };

  const setDir = (dir: string | null): void => {
    if (dir === heldDir) return;
    if (heldDir) key('keyup', heldDir);
    heldDir = dir;
    if (dir) key('keydown', dir);
    dpad.classList.toggle('active', dir !== null);
  };

  dpad.addEventListener('pointerdown', (e) => {
    try { dpad.setPointerCapture(e.pointerId); } catch { /* synthetic/stale pointer */ }
    setDir(dirFromEvent(e));
    e.preventDefault();
  });
  dpad.addEventListener('pointermove', (e) => {
    if (heldDir !== null) setDir(dirFromEvent(e));
  });
  const releasePad = () => setDir(null);
  dpad.addEventListener('pointerup', releasePad);
  dpad.addEventListener('pointercancel', releasePad);

  // ── A / B buttons ────────────────────────────────────────────────────────
  const makeButton = (id: string, label: string, keyName: string): void => {
    const el = document.createElement('div');
    el.id = id;
    el.className = 'ab';
    el.textContent = label;
    root.appendChild(el);
    el.addEventListener('pointerdown', (e) => {
      try { el.setPointerCapture(e.pointerId); } catch { /* synthetic/stale pointer */ }
      el.classList.add('pressed');
      key('keydown', keyName);
      e.preventDefault();
    });
    const up = () => {
      el.classList.remove('pressed');
      key('keyup', keyName);
    };
    el.addEventListener('pointerup', up);
    el.addEventListener('pointercancel', up);
  };
  makeButton('btnA', 'A', 'a');
  makeButton('btnB', 'B', 'b');

  // iOS: block double-tap zoom & long-press callouts inside the whole app
  document.getElementById('app')!.addEventListener('touchend', (e) => {
    if ((e.target as HTMLElement).closest('#controls')) e.preventDefault();
  }, { passive: false });
}
