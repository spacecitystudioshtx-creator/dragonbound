// Central read-only access to the JSON data layer.
import drakesJson from '../../data/drakes.json';
import movesJson from '../../data/moves.json';
import typesJson from '../../data/types.json';
import type { DrakeSpecies, MoveData, DialogNpc, MapDef, TrainerDef } from './types';

export const DRAKES: Record<string, DrakeSpecies> = (drakesJson as any).drakes;
export const MOVES: Record<string, MoveData> = (movesJson as any).moves;

const TYPE_CHART: Record<string, Record<string, number>> = (typesJson as any).chart;

export function typeMultiplier(attackType: string, defendType: string): number {
  return TYPE_CHART[attackType]?.[defendType] ?? 1.0;
}

// Dialog files: data/dialog/<zone>.json, referenced as "<zone>.<npc_id>".
const dialogModules = import.meta.glob('../../data/dialog/*.json', { eager: true }) as Record<string, any>;

export function getDialog(ref: string): DialogNpc | null {
  const dot = ref.indexOf('.');
  const file = ref.slice(0, dot);
  const npcId = ref.slice(dot + 1);
  for (const path in dialogModules) {
    if (path.endsWith(`/${file}.json`)) {
      return dialogModules[path].npcs?.[npcId] ?? null;
    }
  }
  return null;
}

// Maps: data/maps/<id>.json
const mapModules = import.meta.glob('../../data/maps/*.json', { eager: true }) as Record<string, any>;

export function getMap(id: string): MapDef {
  for (const path in mapModules) {
    if (path.endsWith(`/${id}.json`)) return mapModules[path] as MapDef;
  }
  throw new Error(`Unknown map: ${id}`);
}

// Trainers: data/trainers.json
import trainersJson from '../../data/trainers.json';
export const TRAINERS: Record<string, TrainerDef> = (trainersJson as any).trainers;
