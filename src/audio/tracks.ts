// Chiptune tracks as note data — the audio equivalent of the map JSONs.
// Each track: channels of [startBeat, note, beats] events over a fixed loop.
// Waves mirror the GBA sound chip: square lead, triangle bass, noise drums.
// Percussion notes on 'noise' channels: 'kick' | 'snare' | 'hat' | 'rumble'.

export type NoteEvent = [number, string, number];

export interface Channel {
  wave: 'square' | 'triangle' | 'sawtooth' | 'noise';
  vol: number;
  notes: NoteEvent[];
}

export interface Track {
  bpm: number;
  beats: number; // loop length in beats
  channels: Channel[];
}

/** Root+fifth bass, half notes: one chord root per bar. */
function bassRootFifth(chords: string[]): NoteEvent[] {
  const out: NoteEvent[] = [];
  chords.forEach((root, bar) => {
    const fifth = transpose(root, 7);
    out.push([bar * 4, root, 2], [bar * 4 + 2, fifth, 2]);
  });
  return out;
}

/** Driving eighth-note bass, octave-bouncing, one chord root per bar. */
function bassPulse(chords: string[]): NoteEvent[] {
  const out: NoteEvent[] = [];
  chords.forEach((root, bar) => {
    const up = transpose(root, 12);
    for (let i = 0; i < 8; i++) {
      out.push([bar * 4 + i * 0.5, i % 2 ? up : root, 0.5]);
    }
  });
  return out;
}

/** kick on 1&3, hat on off-beats, snare on 2&4 — per bar, for n bars. */
function drums(bars: number, opts: { snare?: boolean; hats?: boolean } = {}): NoteEvent[] {
  const out: NoteEvent[] = [];
  for (let b = 0; b < bars; b++) {
    out.push([b * 4, 'kick', 0.1], [b * 4 + 2, 'kick', 0.1]);
    if (opts.snare) out.push([b * 4 + 1, 'snare', 0.1], [b * 4 + 3, 'snare', 0.1]);
    if (opts.hats) for (let i = 0; i < 4; i++) out.push([b * 4 + i + 0.5, 'hat', 0.05]);
  }
  return out;
}

const SEMI: Record<string, number> = { C: 0, D: 2, E: 4, F: 5, G: 7, A: 9, B: 11 };

export function noteToFreq(note: string): number {
  const m = note.match(/^([A-G])([#b]?)(\d)$/);
  if (!m) return 440;
  let n = SEMI[m[1]] + (m[2] === '#' ? 1 : m[2] === 'b' ? -1 : 0);
  const midi = (parseInt(m[3]) + 1) * 12 + n;
  return 440 * Math.pow(2, (midi - 69) / 12);
}

function transpose(note: string, semis: number): string {
  const m = note.match(/^([A-G])([#b]?)(\d)$/)!;
  let midi = (parseInt(m[3]) + 1) * 12 + SEMI[m[1]] + (m[2] === '#' ? 1 : m[2] === 'b' ? -1 : 0);
  midi += semis;
  const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  return `${names[midi % 12]}${Math.floor(midi / 12) - 1}`;
}

export const TRACKS: Record<string, Track> = {
  // ── Kindra town: warm, lilting, F major ─────────────────────────────────
  town: {
    bpm: 96,
    beats: 32,
    channels: [
      {
        wave: 'square', vol: 0.10,
        notes: [
          [0, 'A4', 1], [1, 'G4', 0.5], [1.5, 'F4', 0.5], [2, 'G4', 1], [3, 'A4', 1],
          [4, 'C5', 1.5], [5.5, 'A4', 0.5], [6, 'G4', 2],
          [8, 'A4', 1], [9, 'Bb4', 0.5], [9.5, 'C5', 0.5], [10, 'D5', 1], [11, 'C5', 1],
          [12, 'A4', 1], [13, 'G4', 0.5], [13.5, 'F4', 0.5], [14, 'F4', 2],
          [16, 'F4', 1], [17, 'G4', 0.5], [17.5, 'A4', 0.5], [18, 'C5', 1], [19, 'A4', 1],
          [20, 'D5', 1.5], [21.5, 'C5', 0.5], [22, 'A4', 2],
          [24, 'G4', 1], [25, 'A4', 0.5], [25.5, 'Bb4', 0.5], [26, 'A4', 1], [27, 'G4', 1],
          [28, 'F4', 3],
        ],
      },
      { wave: 'triangle', vol: 0.16, notes: bassRootFifth(['F2', 'Bb2', 'D3', 'C3', 'F2', 'Bb2', 'C3', 'F2']) },
    ],
  },

  // ── Dustway route: bright, adventurous, G major ─────────────────────────
  route: {
    bpm: 128,
    beats: 32,
    channels: [
      {
        wave: 'square', vol: 0.10,
        notes: [
          [0, 'D5', 0.5], [0.5, 'B4', 0.5], [1, 'G4', 1], [2, 'A4', 0.5], [2.5, 'B4', 0.5], [3, 'D5', 1],
          [4, 'E5', 1], [5, 'D5', 0.5], [5.5, 'B4', 0.5], [6, 'A4', 2],
          [8, 'B4', 0.5], [8.5, 'C5', 0.5], [9, 'D5', 1], [10, 'E5', 0.5], [10.5, 'F#5', 0.5], [11, 'G5', 1],
          [12, 'F#5', 1], [13, 'E5', 0.5], [13.5, 'D5', 0.5], [14, 'D5', 2],
          [16, 'G5', 1], [17, 'F#5', 0.5], [17.5, 'E5', 0.5], [18, 'D5', 1], [19, 'B4', 1],
          [20, 'C5', 1], [21, 'B4', 0.5], [21.5, 'A4', 0.5], [22, 'B4', 2],
          [24, 'A4', 0.5], [24.5, 'B4', 0.5], [25, 'C5', 1], [26, 'A4', 1], [27, 'F#4', 1],
          [28, 'G4', 3],
        ],
      },
      { wave: 'triangle', vol: 0.15, notes: bassPulse(['G2', 'C3', 'G2', 'D3', 'E3', 'C3', 'D3', 'G2']) },
      { wave: 'noise', vol: 0.05, notes: drums(8, { hats: true }) },
    ],
  },

  // ── The Scald: low, ominous, E phrygian ─────────────────────────────────
  scald: {
    bpm: 100,
    beats: 32,
    channels: [
      {
        wave: 'square', vol: 0.08,
        notes: [
          [0, 'E4', 3], [4, 'G4', 2], [6, 'F4', 2],
          [8, 'E4', 2], [12, 'B3', 4],
          [16, 'E4', 3], [20, 'C5', 2], [22, 'B4', 2],
          [24, 'G4', 1], [25, 'F4', 1], [26, 'E4', 5],
        ],
      },
      {
        wave: 'triangle', vol: 0.18,
        notes: (() => {
          const out: NoteEvent[] = [];
          const pat = ['E2', 'E2', 'E2', 'F2'];
          for (let bar = 0; bar < 8; bar++) {
            pat.forEach((n, i) => out.push([bar * 4 + i, bar % 4 === 3 ? transpose(n, -2) : n, 0.9]));
          }
          return out;
        })(),
      },
      {
        wave: 'noise', vol: 0.05,
        notes: Array.from({ length: 8 }, (_, b) => [b * 4, 'rumble', 1.5] as NoteEvent),
      },
    ],
  },

  // ── Battle: fast, driving, A minor ──────────────────────────────────────
  battle: {
    bpm: 150,
    beats: 32,
    channels: [
      {
        wave: 'square', vol: 0.11,
        notes: [
          [0, 'A4', 0.5], [0.5, 'A4', 0.5], [1, 'C5', 0.5], [1.5, 'A4', 0.5], [2, 'E5', 1], [3, 'D5', 0.5], [3.5, 'C5', 0.5],
          [4, 'B4', 0.5], [4.5, 'B4', 0.5], [5, 'D5', 0.5], [5.5, 'B4', 0.5], [6, 'F5', 1], [7, 'E5', 0.5], [7.5, 'D5', 0.5],
          [8, 'C5', 0.5], [8.5, 'C5', 0.5], [9, 'E5', 0.5], [9.5, 'C5', 0.5], [10, 'G5', 1], [11, 'F5', 0.5], [11.5, 'E5', 0.5],
          [12, 'E5', 0.5], [12.5, 'D5', 0.5], [13, 'C5', 0.5], [13.5, 'B4', 0.5], [14, 'A4', 2],
          [16, 'A5', 1], [17, 'G5', 0.5], [17.5, 'F5', 0.5], [18, 'E5', 1], [19, 'C5', 1],
          [20, 'D5', 0.5], [20.5, 'E5', 0.5], [21, 'F5', 1], [22, 'E5', 0.5], [22.5, 'D5', 0.5], [23, 'C5', 1],
          [24, 'B4', 0.5], [24.5, 'C5', 0.5], [25, 'D5', 1], [26, 'G#4', 1], [27, 'B4', 1],
          [28, 'A4', 2], [30, 'E5', 2],
        ],
      },
      { wave: 'triangle', vol: 0.16, notes: bassPulse(['A2', 'A2', 'G2', 'G2', 'F2', 'F2', 'E2', 'E2']) },
      { wave: 'noise', vol: 0.06, notes: drums(8, { snare: true, hats: true }) },
    ],
  },

  // ── Title: bold little fanfare, C major ─────────────────────────────────
  title: {
    bpm: 110,
    beats: 32,
    channels: [
      {
        wave: 'square', vol: 0.10,
        notes: [
          [0, 'C5', 1], [1, 'E5', 1], [2, 'G5', 2],
          [4, 'F5', 1], [5, 'E5', 1], [6, 'D5', 2],
          [8, 'E5', 1], [9, 'G5', 1], [10, 'A5', 2], [12, 'G5', 4],
          [16, 'F5', 1], [17, 'A5', 1], [18, 'G5', 2],
          [20, 'E5', 1], [21, 'C5', 1], [22, 'D5', 2],
          [24, 'E5', 1], [25, 'D5', 1], [26, 'C5', 5],
        ],
      },
      { wave: 'triangle', vol: 0.15, notes: bassRootFifth(['C3', 'A2', 'F2', 'G2', 'C3', 'A2', 'F2', 'C3']) },
    ],
  },
};
