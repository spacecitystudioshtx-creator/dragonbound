import Phaser from 'phaser';
import { getMap, getDialog, TRAINERS, DRAKES } from '../core/db';
import { tileInfo } from '../core/tiles';
import { GameState } from '../core/state';
import { DrakeInstance } from '../core/drake';
import { Textbox, isA } from '../ui/Textbox';
import type { MapDef, LegendEntry, NpcDef, DialogLine } from '../core/types';
import { VP_W, VP_H } from '../main';

const TILE = 16;
const STEP_MS = 170;

const DIRS: Record<string, { dx: number; dy: number }> = {
  down: { dx: 0, dy: 1 },
  left: { dx: -1, dy: 0 },
  right: { dx: 1, dy: 0 },
  up: { dx: 0, dy: -1 },
};

// Row order of directions in the character sheets (RPG-Maker-style).
const DIR_ROW: Record<string, number> = { down: 0, left: 1, right: 2, up: 3 };

// NPC sprite registry → characters.png (12 cols: 4 chars × 3 walk frames,
// 8 rows: 2 bands × 4 directions).
const NPC_SPRITES: Record<string, { char: number; band: number }> = {
  villager_a: { char: 0, band: 0 },
  villager_b: { char: 1, band: 0 },
  villager_c: { char: 2, band: 0 },
  villager_d: { char: 3, band: 0 },
  slime: { char: 0, band: 1 },
  ghost: { char: 1, band: 1 },
  bird: { char: 2, band: 1 },
  spider: { char: 3, band: 1 },
};

function npcFrame(sprite: string, facing: string): number {
  const s = NPC_SPRITES[sprite] ?? NPC_SPRITES.villager_a;
  return (s.band * 4 + (DIR_ROW[facing] ?? 0)) * 12 + s.char * 3 + 1;
}

interface Cell {
  solid: boolean;
  encounter: boolean;
  dialog: string | null;
}

export class WorldScene extends Phaser.Scene {
  private map!: MapDef;
  private grid: Cell[][] = [];
  private mapW = 0;
  private mapH = 0;
  private playerSprite!: Phaser.GameObjects.Sprite;
  private npcSprites = new Map<string, Phaser.GameObjects.Sprite>();
  private textbox!: Textbox;
  private moving = false;
  private uiLocked = false;
  private keys!: Record<string, Phaser.Input.Keyboard.Key>;
  private mapNameText?: Phaser.GameObjects.Container;

  constructor() {
    super('World');
  }

  create(data: { map: string; x?: number; y?: number; spawn?: string }): void {
    this.map = getMap(data.map);
    GameState.map = data.map;
    this.moving = false;
    this.uiLocked = false;
    this.npcSprites.clear();

    this.buildMap();

    // Spawn position: explicit coords > named spawn > default spawn
    let sx = data.x, sy = data.y, facing = GameState.facing;
    if (sx === undefined || sy === undefined) {
      const sp = this.map.spawns[data.spawn ?? 'default'] ?? this.map.spawns.default;
      sx = sp.x; sy = sp.y;
      if (sp.facing) facing = sp.facing;
    }
    GameState.x = sx!; GameState.y = sy!; GameState.facing = facing;

    this.spawnNpcs();
    this.spawnPlayer(sx!, sy!, facing);

    const cam = this.cameras.main;
    cam.setBounds(0, 0, Math.max(this.mapW * TILE, VP_W), Math.max(this.mapH * TILE, VP_H));
    cam.startFollow(this.playerSprite, true);
    cam.fadeIn(250, 0, 0, 0);

    this.textbox = new Textbox(this);
    this.keys = this.input.keyboard!.addKeys('UP,DOWN,LEFT,RIGHT,W,A,S,D') as any;
    this.input.keyboard!.on('keydown', (e: KeyboardEvent) => {
      if (isA(e) && !this.moving && !this.uiLocked) this.interact();
    });

    this.events.on('wake', (_sys: any, wakeData: any) => this.onBattleReturn(wakeData));
    this.showMapName();
    GameState.save();
  }

  // ── Map construction ──────────────────────────────────────────────────────

  private buildMap(): void {
    this.grid = [];
    this.mapH = this.map.rows.length;
    this.mapW = Math.max(...this.map.rows.map((r) => r.length));

    for (let y = 0; y < this.mapH; y++) {
      const row: Cell[] = [];
      const chars = this.map.rows[y];
      for (let x = 0; x < this.mapW; x++) {
        const ch = chars[x] ?? '.';
        const entry: LegendEntry = this.map.legend[ch] ?? { tile: 'grass' };
        const info = tileInfo(entry.tile);
        const baseName = entry.base ?? info.base;
        if (baseName) {
          this.add.image(x * TILE, y * TILE, 'tiles', tileInfo(baseName).index).setOrigin(0, 0);
        }
        this.add.image(x * TILE, y * TILE, 'tiles', info.index).setOrigin(0, 0);
        row.push({
          solid: entry.solid ?? info.solid ?? false,
          encounter: entry.encounter ?? false,
          dialog: entry.dialog ?? null,
        });
      }
      this.grid.push(row);
    }
  }

  private spawnNpcs(): void {
    for (const npc of this.map.npcs ?? []) {
      if (npc.vanish_flag && GameState.hasFlag(npc.vanish_flag)) continue;
      const facing = npc.facing ?? 'down';
      const spr = this.add
        .sprite(npc.x * TILE + 8, npc.y * TILE + 8, 'characters', npcFrame(npc.sprite, facing))
        .setDepth(5);
      this.npcSprites.set(npc.id, spr);
      this.grid[npc.y][npc.x].solid = true;
    }
  }

  private spawnPlayer(x: number, y: number, facing: string): void {
    this.playerSprite = this.add.sprite(x * TILE + 8, y * TILE + 8, 'player', 0).setDepth(10);
    for (const dir of Object.keys(DIR_ROW)) {
      const row = DIR_ROW[dir];
      if (!this.anims.exists(`walk_${dir}`)) {
        this.anims.create({
          key: `walk_${dir}`,
          frames: this.anims.generateFrameNumbers('player', { start: row * 4, end: row * 4 + 3 }),
          frameRate: 10,
          repeat: -1,
        });
      }
    }
    this.setPlayerIdle(facing);
  }

  private setPlayerIdle(facing: string): void {
    this.playerSprite.stop();
    this.playerSprite.setFrame(DIR_ROW[facing] * 4);
  }

  // ── Movement ──────────────────────────────────────────────────────────────

  update(): void {
    if (this.moving || this.uiLocked || this.textbox?.isOpen) return;
    const k = this.keys;
    let dir: string | null = null;
    if (k.UP.isDown || k.W.isDown) dir = 'up';
    else if (k.DOWN.isDown || k.S.isDown) dir = 'down';
    else if (k.LEFT.isDown || k.A.isDown) dir = 'left';
    else if (k.RIGHT.isDown || k.D.isDown) dir = 'right';
    if (dir) this.tryStep(dir);
  }

  private tryStep(dir: string): void {
    GameState.facing = dir;
    const { dx, dy } = DIRS[dir];
    const nx = GameState.x + dx;
    const ny = GameState.y + dy;

    this.playerSprite.play(`walk_${dir}`, true);

    if (nx < 0 || ny < 0 || nx >= this.mapW || ny >= this.mapH || this.grid[ny][nx].solid) {
      this.setPlayerIdle(dir);
      return;
    }

    this.moving = true;
    this.tweens.add({
      targets: this.playerSprite,
      x: nx * TILE + 8,
      y: ny * TILE + 8,
      duration: STEP_MS,
      onComplete: () => {
        GameState.x = nx;
        GameState.y = ny;
        this.moving = false;
        this.onStep(nx, ny);
      },
    });
  }

  private onStep(x: number, y: number): void {
    // Exit?
    const exit = (this.map.exits ?? []).find((e) => e.x === x && e.y === y);
    if (exit) {
      this.uiLocked = true;
      this.cameras.main.fadeOut(200, 0, 0, 0);
      this.cameras.main.once('camerafadeoutcomplete', () => {
        this.scene.restart({ map: exit.to, spawn: exit.spawn });
      });
      return;
    }
    // Wild encounter?
    const enc = this.map.encounters;
    if (enc && this.grid[y][x].encounter && GameState.party.length > 0 && Math.random() < enc.rate) {
      const total = enc.table.reduce((a, e) => a + e.weight, 0);
      let roll = Math.random() * total;
      let pick = enc.table[0];
      for (const e of enc.table) {
        roll -= e.weight;
        if (roll <= 0) { pick = e; break; }
      }
      const level = pick.min + Math.floor(Math.random() * (pick.max - pick.min + 1));
      this.startBattle({ kind: 'wild', enemy: { speciesId: pick.drake, level } });
    } else {
      this.setPlayerIdle(GameState.facing);
    }
  }

  // ── Interaction & dialog ──────────────────────────────────────────────────

  private interact(): void {
    const { dx, dy } = DIRS[GameState.facing];
    const tx = GameState.x + dx;
    const ty = GameState.y + dy;
    if (tx < 0 || ty < 0 || tx >= this.mapW || ty >= this.mapH) return;

    const npc = (this.map.npcs ?? []).find((n) => n.x === tx && n.y === ty && this.npcSprites.has(n.id));
    if (npc) {
      // NPC turns to face the player
      const facePlayer = { down: 'up', up: 'down', left: 'right', right: 'left' }[GameState.facing]!;
      this.npcSprites.get(npc.id)?.setFrame(npcFrame(npc.sprite, facePlayer));
      this.runDialog(npc.dialog);
      return;
    }
    const cellDialog = this.grid[ty][tx].dialog;
    if (cellDialog) this.runDialog(cellDialog);
  }

  private async runDialog(ref: string): Promise<void> {
    const npc = getDialog(ref);
    if (!npc) return;
    this.uiLocked = true;

    let lines: DialogLine[] = [];
    if (npc.text) lines = [npc.text];
    else if (npc.lines) lines = npc.lines;
    else if (npc.select && npc.sections) {
      for (const rule of npc.select) {
        if (rule.if_flag && !GameState.hasFlag(rule.if_flag)) continue;
        if (rule.unless_flag && GameState.hasFlag(rule.unless_flag)) continue;
        lines = npc.sections[rule.use] ?? [];
        break;
      }
    }

    for (const line of lines) {
      if (typeof line === 'string') {
        await this.textbox.show(line);
      } else if ('set_flag' in line) {
        GameState.setFlag(line.set_flag);
      } else if ('heal_party' in line) {
        GameState.healParty();
        await this.textbox.show('Your drakes were fully healed!');
      } else if ('give_starter' in line) {
        await this.pickStarter();
      } else if ('start_battle' in line) {
        this.textbox.close();
        this.uiLocked = false;
        this.startTrainerBattle(line.start_battle);
        return;
      }
    }
    this.textbox.close();
    this.uiLocked = false;
    GameState.save();
  }

  private async pickStarter(): Promise<void> {
    if (GameState.party.length > 0) return;
    const options = ['ember', 'ripple', 'sprig'];
    const names = options.map((id) => `${DRAKES[id].name} (${DRAKES[id].type})`);

    // Show the three starters above the textbox while choosing
    const sprites = options.map((id, i) =>
      this.add.image(48 + i * 72, 56, `drake_${id}`).setScale(0.6).setScrollFactor(0).setDepth(999)
    );
    await this.textbox.show('Choose your partner, young one.');
    const idx = await this.textbox.choices(names, false);
    sprites.forEach((s) => s.destroy());

    const chosen = options[idx];
    GameState.party.push(new DrakeInstance(chosen, 5));
    GameState.runestones += 5;
    GameState.setFlag('starter_given');
    await this.textbox.show(`You received ${DRAKES[chosen].name}!`);
    await this.textbox.show('You also received 5 RUNESTONES. Throw one in battle to bind a wild drake!');
    GameState.save();
  }

  // ── Battles ───────────────────────────────────────────────────────────────

  private startBattle(payload: any): void {
    this.uiLocked = true;
    this.cameras.main.flash(150, 255, 255, 255);
    this.time.delayedCall(250, () => {
      this.scene.run('Battle', payload);
      this.scene.sleep();
    });
  }

  private startTrainerBattle(trainerId: string): void {
    const t = TRAINERS[trainerId];
    if (!t) return;
    this.startBattle({ kind: 'trainer', trainerId });
  }

  private async onBattleReturn(data: any): Promise<void> {
    this.uiLocked = false;
    this.setPlayerIdle(GameState.facing);
    this.cameras.main.fadeIn(250, 0, 0, 0);
    GameState.save();

    if (data?.outcome === 'trainer_win' && data.trainerId) {
      const t = TRAINERS[data.trainerId];
      GameState.setFlag(t.win_flag);
      if (t.reward_text) {
        this.uiLocked = true;
        await this.textbox.show(t.reward_text);
        this.textbox.close();
        this.uiLocked = false;
      }
      GameState.save();
    }

    if (data?.outcome === 'lose' || data?.outcome === 'trainer_lose') {
      this.uiLocked = true;
      await this.textbox.show('You blacked out and rushed back to Kindra...');
      this.textbox.close();
      GameState.healParty();
      GameState.facing = 'down';
      this.scene.restart({ map: 'kindra_town', spawn: 'default' });
    }
  }

  // ── HUD ───────────────────────────────────────────────────────────────────

  private showMapName(): void {
    const g = this.add.graphics();
    g.fillStyle(0x303030, 0.85).fillRoundedRect(0, 0, this.map.name.length * 8 + 16, 18, 3);
    const t = this.add.text(8, 5, this.map.name, {
      fontFamily: '"Press Start 2P"', fontSize: '8px', color: '#f8f8f8', resolution: 3,
    });
    this.mapNameText = this.add.container(4, 4, [g, t]).setDepth(900).setScrollFactor(0);
    this.tweens.add({
      targets: this.mapNameText, alpha: 0, delay: 1800, duration: 400,
      onComplete: () => this.mapNameText?.destroy(),
    });
  }
}
