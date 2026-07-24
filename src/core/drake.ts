import { DRAKES, MOVES } from './db';
import type { DrakeSpecies } from './types';

// A drake the player (or an enemy) actually owns: species + level + state.
export class DrakeInstance {
  speciesId: string;
  level: number;
  xp = 0; // progress toward next level
  hp: number;
  nickname: string | null = null;
  moves: string[];

  // Volatile battle state (reset each battle)
  accMod = 1.0;
  evasion = 0.0;
  defMod = 1.0;
  reflect = false;
  skipTurn = false;

  constructor(speciesId: string, level: number) {
    this.speciesId = speciesId;
    this.level = level;
    this.moves = [...this.species.base_moves].slice(0, 4);
    this.hp = this.maxHp;
  }

  get species(): DrakeSpecies {
    return DRAKES[this.speciesId];
  }

  get name(): string {
    return this.nickname ?? this.species.name;
  }

  get maxHp(): number {
    return Math.floor(this.species.base_stats.hp * (1 + this.level * 0.08)) + 8;
  }
  get atk(): number {
    return Math.floor(this.species.base_stats.atk * (1 + this.level * 0.06));
  }
  get def(): number {
    return Math.floor(this.species.base_stats.def * (1 + this.level * 0.06));
  }
  get spd(): number {
    return Math.floor(this.species.base_stats.spd * (1 + this.level * 0.06));
  }

  get fainted(): boolean {
    return this.hp <= 0;
  }

  xpToNext(): number {
    return 8 * this.level * this.level;
  }

  /** Add xp; returns list of messages (level ups). Evolution handled by caller. */
  gainXp(amount: number): string[] {
    const msgs: string[] = [];
    this.xp += amount;
    while (this.xp >= this.xpToNext()) {
      this.xp -= this.xpToNext();
      const beforeHp = this.maxHp;
      this.level += 1;
      this.hp = Math.min(this.maxHp, this.hp + (this.maxHp - beforeHp));
      msgs.push(`${this.name} grew to level ${this.level}!`);
    }
    return msgs;
  }

  /** If eligible, evolve and return a message. */
  tryEvolve(): string | null {
    const evo = this.species.evolution;
    if (!evo || this.level < evo.level) return null;
    const oldName = this.name;
    const hpFrac = this.hp / this.maxHp;
    this.speciesId = evo.to;
    this.moves = [...this.species.base_moves].slice(0, 4);
    this.hp = Math.max(1, Math.floor(this.maxHp * hpFrac));
    return `What?! ${oldName} evolved into ${this.species.name}!`;
  }

  resetBattleState(): void {
    this.accMod = 1.0;
    this.evasion = 0.0;
    this.defMod = 1.0;
    this.reflect = false;
    this.skipTurn = false;
  }

  heal(): void {
    this.hp = this.maxHp;
  }

  serialize() {
    return {
      speciesId: this.speciesId,
      level: this.level,
      xp: this.xp,
      hp: this.hp,
      nickname: this.nickname,
      moves: this.moves,
    };
  }

  static deserialize(d: any): DrakeInstance {
    const inst = new DrakeInstance(d.speciesId, d.level);
    inst.xp = d.xp ?? 0;
    inst.hp = Math.min(d.hp ?? inst.maxHp, inst.maxHp);
    inst.nickname = d.nickname ?? null;
    if (Array.isArray(d.moves) && d.moves.every((m: string) => MOVES[m])) {
      inst.moves = d.moves;
    }
    return inst;
  }
}
