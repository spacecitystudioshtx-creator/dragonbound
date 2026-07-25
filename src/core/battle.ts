import { MOVES, typeMultiplier } from './db';
import type { DrakeInstance } from './drake';
import type { MoveData } from './types';

export interface TurnResult {
  messages: string[];
  attackerFainted: boolean;
  defenderFainted: boolean;
}

/** Execute one move: attacker uses moveId on defender. Mutates both. */
export function executeMove(attacker: DrakeInstance, defender: DrakeInstance, moveId: string): TurnResult {
  const move = MOVES[moveId];
  const msgs: string[] = [`${attacker.name} used ${move.name}!`];

  if (attacker.skipTurn) {
    attacker.skipTurn = false;
    return { messages: [`${attacker.name} is recovering and can't move!`], attackerFainted: false, defenderFainted: false };
  }

  // Accuracy check (attacker's accuracy debuffs + defender's evasion buffs)
  const hitChance = (move.accuracy / 100) * attacker.accMod * (1 - defender.evasion);
  if (Math.random() > hitChance) {
    msgs.push(`But it missed!`);
    return { messages: msgs, attackerFainted: false, defenderFainted: false };
  }

  // Damage
  if (move.power > 0) {
    const typeMult = typeMultiplier(move.type, defender.species.type);
    // Soften type swings (2.0 -> ~1.6, 0.5 -> ~0.6) so counters are strong,
    // not absolute; levels carry more weight than the chart.
    const softMult = Math.pow(typeMult, 0.7);
    const stab = move.type === attacker.species.type ? 1.2 : 1.0;
    const effDef = move.effect === 'ignore_def_buffs' ? defender.def : defender.def * defender.defMod;
    const raw = (attacker.level + 2) * (move.power / 50) * (attacker.atk / effDef);
    const dmg = Math.max(1, Math.floor(raw * softMult * stab * (0.85 + Math.random() * 0.15) * 2.4));
    defender.hp = Math.max(0, defender.hp - dmg);

    if (typeMult > 1) msgs.push(`It's super effective!`);
    else if (typeMult < 1) msgs.push(`It's not very effective...`);

    // Recoil / reflect
    if (move.effect === 'self_damage' && move.effect_value) {
      const recoil = Math.max(1, Math.floor(dmg * move.effect_value));
      attacker.hp = Math.max(0, attacker.hp - recoil);
      msgs.push(`${attacker.name} was hurt by recoil!`);
    }
    if (defender.reflect && defender.hp > 0) {
      const ref = Math.max(1, Math.floor(dmg * 0.25));
      attacker.hp = Math.max(0, attacker.hp - ref);
      msgs.push(`${defender.name}'s armor reflected damage!`);
    }
  }

  // Status effects
  applyEffect(attacker, defender, move, msgs);

  return {
    messages: msgs,
    attackerFainted: attacker.fainted,
    defenderFainted: defender.fainted,
  };
}

function applyEffect(attacker: DrakeInstance, defender: DrakeInstance, move: MoveData, msgs: string[]): void {
  const v = move.effect_value ?? 0;
  switch (move.effect) {
    case 'lower_accuracy':
      defender.accMod = Math.max(0.4, defender.accMod - v);
      msgs.push(`${defender.name}'s accuracy fell!`);
      break;
    case 'raise_evasion':
      attacker.evasion = Math.min(0.5, attacker.evasion + v);
      msgs.push(`${attacker.name} became harder to hit!`);
      break;
    case 'raise_defense':
      attacker.defMod += v;
      msgs.push(`${attacker.name}'s defense rose!`);
      break;
    case 'reflect_damage':
      attacker.defMod += 0.2;
      attacker.reflect = true;
      msgs.push(`${attacker.name}'s hide hardened — contact will burn!`);
      break;
    case 'fortify':
      attacker.defMod += v;
      attacker.skipTurn = true;
      msgs.push(`${attacker.name} braced into a fortress!`);
      break;
    case 'heal_self': {
      const amt = Math.floor(attacker.maxHp * (v || 0.4));
      attacker.hp = Math.min(attacker.maxHp, attacker.hp + amt);
      msgs.push(`${attacker.name} recovered health!`);
      break;
    }
    default:
      break; // none, trap, block_bench, etc. — no-op for now
  }
}

/** Pick a move for the AI: prefers highest expected damage, some randomness. */
export function pickAiMove(attacker: DrakeInstance, defender: DrakeInstance): string {
  const scored = attacker.moves.map((id) => {
    const m = MOVES[id];
    let score = m.power * typeMultiplier(m.type, defender.species.type) * (m.accuracy / 100);
    if (m.power === 0) score = attacker.hp === attacker.maxHp ? 15 : 5; // status moves early
    return { id, score: score + Math.random() * 12 };
  });
  scored.sort((a, b) => b.score - a.score);
  return scored[0].id;
}

/** Runestone catch attempt. Returns [success, wobbles 0-3]. */
export function tryCapture(target: DrakeInstance): [boolean, number] {
  const hpFactor = 1 - 0.65 * (target.hp / target.maxHp);
  const chance = Math.min(0.95, (target.species.catch_rate / 255) * (0.35 + hpFactor));
  const roll = Math.random();
  if (roll < chance) return [true, 3];
  return [false, Math.min(2, Math.floor((chance / Math.max(roll, 0.01)) * 3))];
}

// Tuned for FireRed-like pacing: ~4-6 wild wins per level early on.
export function xpReward(enemy: DrakeInstance, isTrainer: boolean): number {
  const statTotal = Object.values(enemy.species.base_stats).reduce((a, b) => a + b, 0);
  return Math.floor((14 + enemy.level * 7) * (statTotal / 130) * (isTrainer ? 1.5 : 1));
}
