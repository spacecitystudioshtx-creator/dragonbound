// GBA-flavored Web Audio chiptune engine: three oscillator voices + noise,
// no samples, no assets. Music tracks come from tracks.ts as note data.
// Everything no-ops gracefully until the browser grants an AudioContext
// (first real key press), so game logic never depends on audio state.
import { TRACKS, noteToFreq, type Track } from './tracks';

class SoundEngineImpl {
  private ctx: AudioContext | null = null;
  private musicGain!: GainNode;
  private sfxGain!: GainNode;
  private masterGain!: GainNode;
  private noiseBuf!: AudioBuffer;
  muted = false;

  private currentTrack: string | null = null;
  private loopTimer: number | null = null;
  private nextLoopAt = 0;
  private liveNodes: AudioScheduledSourceNode[] = [];

  /** Call from a real user gesture. Safe to call repeatedly. */
  init(): void {
    if (this.ctx) {
      void this.ctx.resume().then(() => this.replayQueued());
      return;
    }
    try {
      this.ctx = new AudioContext();
    } catch {
      return;
    }
    this.masterGain = this.ctx.createGain();
    this.masterGain.gain.value = 0.9;
    this.masterGain.connect(this.ctx.destination);
    this.musicGain = this.ctx.createGain();
    this.musicGain.gain.value = 1;
    this.musicGain.connect(this.masterGain);
    this.sfxGain = this.ctx.createGain();
    this.sfxGain.gain.value = 1;
    this.sfxGain.connect(this.masterGain);

    // 1s of white noise, reused by all percussion/noise effects
    this.noiseBuf = this.ctx.createBuffer(1, this.ctx.sampleRate, this.ctx.sampleRate);
    const data = this.noiseBuf.getChannelData(0);
    for (let i = 0; i < data.length; i++) data[i] = Math.random() * 2 - 1;

    // If a track was requested before init (e.g. title screen), start it now.
    void this.ctx.resume().then(() => this.replayQueued());
  }

  /** Start a track that was requested before the context was unlocked. */
  private replayQueued(): void {
    if (this.currentTrack && this.loopTimer === null) {
      const t = this.currentTrack;
      this.currentTrack = null;
      this.playMusic(t);
    }
  }

  private get ready(): boolean {
    return !!this.ctx && this.ctx.state === 'running';
  }

  toggleMute(): boolean {
    this.muted = !this.muted;
    if (this.ctx) this.masterGain.gain.value = this.muted ? 0 : 0.9;
    return this.muted;
  }

  // ── Voices ────────────────────────────────────────────────────────────────

  private tone(
    dest: GainNode, wave: OscillatorType, freq: number, at: number, dur: number, vol: number,
    slideTo?: number,
  ): void {
    if (!this.ready) return;
    const ctx = this.ctx!;
    const osc = ctx.createOscillator();
    osc.type = wave;
    osc.frequency.setValueAtTime(freq, at);
    if (slideTo !== undefined) osc.frequency.exponentialRampToValueAtTime(Math.max(20, slideTo), at + dur);
    const g = ctx.createGain();
    g.gain.setValueAtTime(0, at);
    g.gain.linearRampToValueAtTime(vol, at + 0.008);
    g.gain.setValueAtTime(vol, at + Math.max(0.01, dur - 0.04));
    g.gain.linearRampToValueAtTime(0.0001, at + dur);
    osc.connect(g).connect(dest);
    osc.start(at);
    osc.stop(at + dur + 0.05);
    if (dest === this.musicGain) this.trackNode(osc);
  }

  private noise(dest: GainNode, at: number, dur: number, vol: number, filterHz?: number): void {
    if (!this.ready) return;
    const ctx = this.ctx!;
    const src = ctx.createBufferSource();
    src.buffer = this.noiseBuf;
    src.loop = true;
    const g = ctx.createGain();
    g.gain.setValueAtTime(vol, at);
    g.gain.exponentialRampToValueAtTime(0.0001, at + dur);
    let node: AudioNode = src;
    if (filterHz) {
      const f = ctx.createBiquadFilter();
      f.type = 'lowpass';
      f.frequency.value = filterHz;
      src.connect(f);
      node = f;
    }
    node.connect(g).connect(dest);
    src.start(at);
    src.stop(at + dur + 0.05);
    if (dest === this.musicGain) this.trackNode(src);
  }

  private trackNode(n: AudioScheduledSourceNode): void {
    this.liveNodes.push(n);
    if (this.liveNodes.length > 400) this.liveNodes.splice(0, 100);
  }

  // ── Music ────────────────────────────────────────────────────────────────

  playMusic(name: string): void {
    if (this.currentTrack === name && this.loopTimer !== null) return;
    this.stopMusic();
    this.currentTrack = name;
    if (!this.ready || !TRACKS[name]) return;
    const track = TRACKS[name];
    this.nextLoopAt = this.ctx!.currentTime + 0.08;
    this.scheduleLoop(track, this.nextLoopAt);
    this.nextLoopAt += this.loopDur(track);
    this.loopTimer = window.setInterval(() => {
      if (!this.ready || !this.currentTrack) return;
      if (this.ctx!.currentTime > this.nextLoopAt - 0.35) {
        this.scheduleLoop(track, this.nextLoopAt);
        this.nextLoopAt += this.loopDur(track);
      }
    }, 150);
  }

  stopMusic(): void {
    if (this.loopTimer !== null) {
      clearInterval(this.loopTimer);
      this.loopTimer = null;
    }
    this.currentTrack = null;
    for (const n of this.liveNodes) {
      try { n.stop(); } catch { /* already stopped */ }
    }
    this.liveNodes = [];
  }

  get playing(): string | null {
    return this.currentTrack;
  }

  private loopDur(t: Track): number {
    return (t.beats * 60) / t.bpm;
  }

  private scheduleLoop(track: Track, t0: number): void {
    const spb = 60 / track.bpm;
    for (const ch of track.channels) {
      for (const [beat, note, beats] of ch.notes) {
        const at = t0 + beat * spb;
        const dur = Math.max(0.05, beats * spb * 0.92);
        if (ch.wave === 'noise') {
          if (note === 'kick') this.noise(this.musicGain, at, 0.09, ch.vol * 2.2, 220);
          else if (note === 'snare') this.noise(this.musicGain, at, 0.09, ch.vol * 1.6, 1800);
          else if (note === 'hat') this.noise(this.musicGain, at, 0.04, ch.vol);
          else if (note === 'rumble') this.noise(this.musicGain, at, dur, ch.vol * 1.6, 140);
        } else {
          this.tone(this.musicGain, ch.wave, noteToFreq(note), at, dur, ch.vol);
        }
      }
    }
  }

  // ── SFX ──────────────────────────────────────────────────────────────────

  sfx(name: string): void {
    if (!this.ready) return;
    const t = this.ctx!.currentTime + 0.01;
    const s = this.sfxGain;
    switch (name) {
      case 'blip': // A-button / text advance
        this.tone(s, 'square', 920, t, 0.055, 0.06);
        break;
      case 'tick': // menu cursor
        this.tone(s, 'square', 620, t, 0.04, 0.05);
        break;
      case 'bump':
        this.tone(s, 'triangle', 130, t, 0.09, 0.14, 90);
        break;
      case 'door':
        this.tone(s, 'square', 392, t, 0.07, 0.08);
        this.tone(s, 'square', 523, t + 0.08, 0.09, 0.08);
        break;
      case 'encounter': // battle sting: two falling zaps
        this.tone(s, 'square', 1100, t, 0.16, 0.10, 220);
        this.tone(s, 'square', 1100, t + 0.18, 0.16, 0.10, 220);
        this.noise(s, t, 0.3, 0.05, 900);
        break;
      case 'hit':
        this.noise(s, t, 0.1, 0.12, 1200);
        this.tone(s, 'square', 300, t, 0.08, 0.09, 150);
        break;
      case 'faint':
        this.tone(s, 'square', 500, t, 0.4, 0.10, 80);
        break;
      case 'levelup':
        [523, 659, 784, 1047].forEach((f, i) => this.tone(s, 'square', f, t + i * 0.07, 0.09, 0.08));
        break;
      case 'evolve':
        [392, 494, 587, 784, 988].forEach((f, i) => this.tone(s, 'square', f, t + i * 0.09, 0.12, 0.08));
        break;
      case 'catch':
        [659, 784, 1047].forEach((f, i) => this.tone(s, 'square', f, t + i * 0.09, 0.1, 0.09));
        this.tone(s, 'square', 1319, t + 0.28, 0.3, 0.09);
        break;
      case 'heal':
        [784, 988, 1175, 1568].forEach((f, i) => this.tone(s, 'square', f, t + i * 0.06, 0.08, 0.07));
        break;
      case 'victory': // short win fanfare
        this.tone(s, 'square', 523, t, 0.12, 0.09);
        this.tone(s, 'square', 659, t + 0.13, 0.12, 0.09);
        this.tone(s, 'square', 784, t + 0.26, 0.12, 0.09);
        this.tone(s, 'square', 1047, t + 0.4, 0.45, 0.10);
        this.tone(s, 'triangle', 262, t, 0.85, 0.12);
        break;
      case 'run':
        this.tone(s, 'square', 700, t, 0.2, 0.07, 1400);
        break;
    }
  }
}

export const Sound = new SoundEngineImpl();
