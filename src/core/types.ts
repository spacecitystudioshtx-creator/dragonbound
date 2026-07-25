// Shapes of the JSON data layer in data/. The JSON files are the source of
// truth — the AI content pipeline appends to them and this code just reads.

export interface DrakeSpecies {
  name: string;
  type: string;
  class: string;
  base_stats: { hp: number; atk: number; def: number; spd: number };
  catch_rate: number;
  evolution: { level: number; to: string } | null;
  base_moves: string[];
}

export interface MoveData {
  name: string;
  type: string;
  power: number;
  accuracy: number;
  effect: string;
  effect_value?: number;
  description?: string;
}

export interface EncounterEntry {
  drake: string;
  min: number;
  max: number;
  weight: number;
}

export interface NpcDef {
  id: string;
  x: number;
  y: number;
  sprite: string;
  facing?: string;
  dialog: string; // "<file>.<npc_id>", e.g. "kindra.elder_moss"
  /** If this flag is set, the NPC no longer spawns. */
  vanish_flag?: string;
}

export interface ExitDef {
  x: number;
  y: number;
  to: string;
  spawn: string;
}

export interface LegendEntry {
  tile: string;
  base?: string;
  solid?: boolean;
  encounter?: boolean;
  /** Interactable tile (sign, locked door): dialog ref shown on approach. */
  dialog?: string;
  /** Door tile: map id to enter (target map's 'default' spawn). */
  enter?: string;
  /** Entry is blocked (dialog shown instead) until this flag is set. */
  requires_flag?: string;
}

export interface MapDef {
  id: string;
  name: string;
  legend: Record<string, LegendEntry>;
  rows: string[];
  npcs: NpcDef[];
  exits: ExitDef[];
  spawns: Record<string, { x: number; y: number; facing?: string }>;
  encounters?: { rate: number; table: EncounterEntry[] };
}

export type DialogLine =
  | string
  | { set_flag: string }
  | { start_battle: string }
  | { give_starter: true }
  | { heal_party: true };

export interface DialogNpc {
  name?: string;
  text?: string;
  lines?: DialogLine[];
  select?: { if_flag?: string; unless_flag?: string; use: string }[];
  sections?: Record<string, DialogLine[]>;
}

export interface TrainerDef {
  name: string;
  team: { drake: string; level: number }[];
  win_flag: string;
  /** Set win or lose — for story gates that only require facing the trainer. */
  fought_flag?: string;
  reward_text?: string;
}
