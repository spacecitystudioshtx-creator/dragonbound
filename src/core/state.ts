import { DrakeInstance } from './drake';

// Global game state: party, flags, inventory, position. Saved to localStorage.
const SAVE_KEY = 'dragonbound_save_v1';

class GameStateImpl {
  party: DrakeInstance[] = [];
  flags = new Set<string>();
  runestones = 0;
  map = 'kindra_town';
  x = 10;
  y = 8;
  facing = 'down';

  get activeDrake(): DrakeInstance | null {
    return this.party.find((d) => !d.fainted) ?? this.party[0] ?? null;
  }

  hasFlag(f: string): boolean {
    return this.flags.has(f);
  }
  setFlag(f: string): void {
    this.flags.add(f);
  }

  healParty(): void {
    for (const d of this.party) d.heal();
  }

  get partyWiped(): boolean {
    return this.party.length > 0 && this.party.every((d) => d.fainted);
  }

  save(): void {
    const data = {
      version: 1,
      party: this.party.map((d) => d.serialize()),
      flags: [...this.flags],
      runestones: this.runestones,
      map: this.map,
      x: this.x,
      y: this.y,
      facing: this.facing,
    };
    localStorage.setItem(SAVE_KEY, JSON.stringify(data));
  }

  hasSave(): boolean {
    return localStorage.getItem(SAVE_KEY) !== null;
  }

  load(): boolean {
    const raw = localStorage.getItem(SAVE_KEY);
    if (!raw) return false;
    try {
      const data = JSON.parse(raw);
      this.party = (data.party ?? []).map((d: any) => DrakeInstance.deserialize(d));
      this.flags = new Set(data.flags ?? []);
      this.runestones = data.runestones ?? 0;
      this.map = data.map ?? 'kindra_town';
      this.x = data.x ?? 10;
      this.y = data.y ?? 8;
      this.facing = data.facing ?? 'down';
      return true;
    } catch {
      return false;
    }
  }

  newGame(): void {
    this.party = [];
    this.flags = new Set();
    this.runestones = 0;
    this.map = 'kindra_town';
    this.x = 10;
    this.y = 8;
    this.facing = 'down';
  }
}

export const GameState = new GameStateImpl();
