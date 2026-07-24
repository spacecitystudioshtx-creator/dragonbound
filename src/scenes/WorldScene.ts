import Phaser from 'phaser';
import { getMap, getDialog, TRAINERS, DRAKES } from '../core/db';
import { tileInfo, frameOf } from '../core/tiles';
import { GameState } from '../core/state';
import { DrakeInstance } from '../core/drake';
import { Textbox, isA } from '../ui/Textbox';
import type { MapDef, LegendEntry, DialogLine } from '../core/types';
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
  enter: string | null;
  doorImg: Phaser.GameObjects.Image | null;
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
  private suppressBump = false;
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
    this.suppressBump = false;
    this.npcSprites.clear();

    this.buildMap();

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
    // Center maps smaller than the viewport (interiors) instead of pinning top-left.
    const mw = this.mapW * TILE, mh = this.mapH * TILE;
    cam.setBounds(
      Math.min(0, -(VP_W - mw) / 2), Math.min(0, -(VP_H - mh) / 2),
      Math.max(mw, VP_W), Math.max(mh, VP_H)
    );
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

  private entryAt(x: number, y: number): LegendEntry {
    const ch = this.map.rows[y]?.[x] ?? '.';
    return this.map.legend[ch] ?? { tile: 'grass' };
  }

  private buildMap(): void {
    this.grid = [];
    this.mapH = this.map.rows.length;
    this.mapW = Math.max(...this.map.rows.map((r) => r.length));

    for (let y = 0; y < this.mapH; y++) {
      const row: Cell[] = [];
      for (let x = 0; x < this.mapW; x++) {
        const entry = this.entryAt(x, y);
        const info = tileInfo(entry.tile);
        const px = x * TILE, py = y * TILE;

        // 1) base ground under transparent tiles/props
        const baseName = entry.base ?? info.base;
        if (baseName) {
          this.add.image(px, py, 'ground', frameOf(tileInfo(baseName).frame!)).setOrigin(0, 0).setDepth(0);
        }

        // 2) the tile itself: animated sprite, static ground, or y-sorted prop
        let doorImg: Phaser.GameObjects.Image | null = null;
        if (info.prop) {
          const spr = this.add.image(px + 8, py + TILE, `prop_${info.prop}`).setOrigin(0.5, 1);
          spr.setDepth(entry.tile === 'tall_grass' ? py + TILE + 0.5 : py + TILE);
        } else if (info.anim) {
          const spr = this.add.sprite(px, py, 'ground', frameOf(info.frame!)).setOrigin(0, 0).setDepth(1);
          spr.play({ key: info.anim, startFrame: (x + y) % 2 });
        } else if (info.frame) {
          const img = this.add.image(px, py, 'ground', frameOf(info.frame)).setOrigin(0, 0).setDepth(1);
          if (entry.tile === 'door') doorImg = img;
        }

        row.push({
          solid: entry.solid ?? info.solid ?? false,
          encounter: entry.encounter ?? false,
          dialog: entry.dialog ?? null,
          enter: entry.enter ?? null,
          doorImg,
        });
      }
      this.grid.push(row);
    }

    // 3) auto-edge fringes: path/water cells get grass banks where neighbors differ
    for (let y = 0; y < this.mapH; y++) {
      for (let x = 0; x < this.mapW; x++) {
        const fam = tileInfo(this.entryAt(x, y).tile).edges;
        if (!fam) continue;
        const sides: [string, number, number][] = [['n', 0, -1], ['s', 0, 1], ['w', -1, 0], ['e', 1, 0]];
        for (const [side, dx, dy] of sides) {
          const nx = x + dx, ny = y + dy;
          if (nx < 0 || ny < 0 || nx >= this.mapW || ny >= this.mapH) continue;
          const nfam = tileInfo(this.entryAt(nx, ny).tile).edges;
          if (nfam !== fam) {
            this.add.image(x * TILE, y * TILE, 'ground', frameOf(`${fam}_${side}`)).setOrigin(0, 0).setDepth(2);
          }
        }
      }
    }
  }

  private spawnNpcs(): void {
    for (const npc of this.map.npcs ?? []) {
      if (npc.vanish_flag && GameState.hasFlag(npc.vanish_flag)) continue;
      const facing = npc.facing ?? 'down';
      const spr = this.add
        .sprite(npc.x * TILE + 8, npc.y * TILE + 8, 'characters', npcFrame(npc.sprite, facing))
        .setDepth(npc.y * TILE + TILE);
      this.npcSprites.set(npc.id, spr);
      this.grid[npc.y][npc.x].solid = true;
    }
  }

  private spawnPlayer(x: number, y: number, facing: string): void {
    this.playerSprite = this.add.sprite(x * TILE + 8, y * TILE + 8, 'player', 0);
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
    if (this.playerSprite) this.playerSprite.setDepth(this.playerSprite.y + 8);
    if (this.moving || this.uiLocked || this.textbox?.isOpen) return;
    const k = this.keys;
    let dir: string | null = null;
    if (k.UP.isDown || k.W.isDown) dir = 'up';
    else if (k.DOWN.isDown || k.S.isDown) dir = 'down';
    else if (k.LEFT.isDown || k.A.isDown) dir = 'left';
    else if (k.RIGHT.isDown || k.D.isDown) dir = 'right';
    if (dir) this.tryStep(dir);
    else this.suppressBump = false; // released keys → bump-to-talk re-arms
  }

  private tryStep(dir: string): void {
    GameState.facing = dir;
    const { dx, dy } = DIRS[dir];
    const nx = GameState.x + dx;
    const ny = GameState.y + dy;

    this.playerSprite.play(`walk_${dir}`, true);

    if (nx < 0 || ny < 0 || nx >= this.mapW || ny >= this.mapH || this.grid[ny][nx].solid) {
      this.setPlayerIdle(dir);
      this.onBump(nx, ny);
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
        this.suppressBump = false;
        this.onStep(nx, ny);
      },
    });
  }

  /** Walking into something interactable starts the interaction (FireRed+). */
  private onBump(nx: number, ny: number): void {
    if (this.suppressBump || this.uiLocked) return;
    if (nx < 0 || ny < 0 || nx >= this.mapW || ny >= this.mapH) return;
    const cell = this.grid[ny][nx];
    const npc = (this.map.npcs ?? []).find((n) => n.x === nx && n.y === ny && this.npcSprites.has(n.id));
    this.suppressBump = true;
    if (npc) {
      const facePlayer = { down: 'up', up: 'down', left: 'right', right: 'left' }[GameState.facing]!;
      this.npcSprites.get(npc.id)?.setFrame(npcFrame(npc.sprite, facePlayer));
      this.runDialog(npc.dialog);
    } else if (cell.enter) {
      this.enterDoor(nx, ny, cell);
    } else if (cell.dialog) {
      this.runDialog(cell.dialog);
    }
  }

  private onStep(x: number, y: number): void {
    const exit = (this.map.exits ?? []).find((e) => e.x === x && e.y === y);
    if (exit) {
      this.uiLocked = true;
      this.cameras.main.fadeOut(200, 0, 0, 0);
      this.cameras.main.once('camerafadeoutcomplete', () => {
        this.scene.restart({ map: exit.to, spawn: exit.spawn });
      });
      return;
    }
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

  /** Door-opening animation, then move inside. */
  private enterDoor(x: number, y: number, cell: Cell): void {
    this.uiLocked = true;
    const img = cell.doorImg;
    img?.setFrame(frameOf('door_half'));
    this.time.delayedCall(110, () => img?.setFrame(frameOf('door_open')));
    this.time.delayedCall(220, () => {
      this.cameras.main.fadeOut(200, 0, 0, 0);
      this.cameras.main.once('camerafadeoutcomplete', () => {
        this.scene.restart({ map: cell.enter!, spawn: 'default' });
      });
    });
  }

  // ── Interaction & dialog ──────────────────────────────────────────────────

  private interact(): void {
    const { dx, dy } = DIRS[GameState.facing];
    const tx = GameState.x + dx;
    const ty = GameState.y + dy;
    if (tx < 0 || ty < 0 || tx >= this.mapW || ty >= this.mapH) return;

    const npc = (this.map.npcs ?? []).find((n) => n.x === tx && n.y === ty && this.npcSprites.has(n.id));
    if (npc) {
      const facePlayer = { down: 'up', up: 'down', left: 'right', right: 'left' }[GameState.facing]!;
      this.npcSprites.get(npc.id)?.setFrame(npcFrame(npc.sprite, facePlayer));
      this.runDialog(npc.dialog);
      return;
    }
    const cell = this.grid[ty][tx];
    if (cell.enter) this.enterDoor(tx, ty, cell);
    else if (cell.dialog) this.runDialog(cell.dialog);
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

  // ── Starter selection (FireRed-style framed panel) ────────────────────────

  private async pickStarter(): Promise<void> {
    if (GameState.party.length > 0) return;
    const options = ['ember', 'ripple', 'sprig'];

    await this.textbox.show('Choose your partner, young one.');

    while (true) {
      const idx = await this.starterPanel(options);
      const chosen = options[idx];
      await this.textbox.show(`So — ${DRAKES[chosen].name.toUpperCase()}, the ${DRAKES[chosen].type} drake?`);
      const yes = await this.textbox.choices(['YES', 'NO'], false);
      if (yes === 0) {
        GameState.party.push(new DrakeInstance(chosen, 5));
        GameState.runestones += 5;
        GameState.setFlag('starter_given');
        await this.textbox.show(`You received ${DRAKES[chosen].name.toUpperCase()}!`);
        await this.textbox.show('You also received 5 RUNESTONES. Throw one in battle to bind a wild drake!');
        GameState.save();
        return;
      }
    }
  }

  private starterPanel(options: string[]): Promise<number> {
    return new Promise((resolve) => {
      const objs: Phaser.GameObjects.GameObject[] = [];
      const dim = this.add.rectangle(0, 0, VP_W, VP_H, 0x101018, 0.45).setOrigin(0).setScrollFactor(0).setDepth(994);
      objs.push(dim);

      // Textbox-style frame
      const g = this.add.graphics().setScrollFactor(0).setDepth(995);
      g.fillStyle(0x303030, 1).fillRoundedRect(14, 8, 212, 96, 5);
      g.fillStyle(0xd8a038, 1).fillRoundedRect(16, 10, 208, 92, 4);
      g.fillStyle(0xf8f8f8, 1).fillRoundedRect(19, 13, 202, 86, 3);
      objs.push(g);

      const slots: { spr: Phaser.GameObjects.Image; name: Phaser.GameObjects.Text; box: Phaser.GameObjects.Graphics }[] = [];
      options.forEach((id, i) => {
        const cx = 53 + i * 67;
        const box = this.add.graphics().setScrollFactor(0).setDepth(996);
        objs.push(box);
        const spr = this.add.image(cx, 48, `drake_${id}`).setScale(0.52).setScrollFactor(0).setDepth(997);
        objs.push(spr);
        const name = this.add.text(cx, 80, DRAKES[id].name.toUpperCase(), {
          fontFamily: '"Press Start 2P"', fontSize: '7px', color: '#383030', resolution: 3,
        }).setOrigin(0.5, 0).setScrollFactor(0).setDepth(997);
        objs.push(name);
        const type = this.add.text(cx, 90, DRAKES[id].type.toUpperCase(), {
          fontFamily: '"Press Start 2P"', fontSize: '6px', color: '#a06848', resolution: 3,
        }).setOrigin(0.5, 0).setScrollFactor(0).setDepth(997);
        objs.push(type);
        slots.push({ spr, name, box });
      });

      const cursor = this.add.text(0, 14, '▼', {
        fontFamily: '"Press Start 2P"', fontSize: '8px', color: '#e04038', resolution: 3,
      }).setOrigin(0.5, 0).setScrollFactor(0).setDepth(998);
      objs.push(cursor);

      let sel = 0;
      let bounce: Phaser.Tweens.Tween | null = null;
      const paint = () => {
        slots.forEach((s, i) => {
          const cx = 53 + i * 67;
          s.box.clear();
          s.box.fillStyle(i === sel ? 0xfff0c8 : 0xefe8dc, 1).fillRoundedRect(cx - 27, 20, 54, 54, 4);
          s.box.lineStyle(1, i === sel ? 0xd8a038 : 0xc8c0b0, 1).strokeRoundedRect(cx - 27, 20, 54, 54, 4);
          s.spr.setScale(i === sel ? 0.58 : 0.48).setAlpha(i === sel ? 1 : 0.82);
          s.name.setColor(i === sel ? '#c03028' : '#383030');
        });
        cursor.setX(53 + sel * 67);
        bounce?.remove();
        bounce = this.tweens.add({ targets: slots[sel].spr, y: 45, duration: 260, yoyo: true, repeat: -1 });
        slots.forEach((s, i) => { if (i !== sel) s.spr.setY(48); });
      };
      paint();

      const keyHandler = (e: KeyboardEvent) => {
        if (e.key === 'ArrowLeft' || e.key === 'a') { sel = (sel + 2) % 3; paint(); }
        else if (e.key === 'ArrowRight' || e.key === 'd') { sel = (sel + 1) % 3; paint(); }
        else if (isA(e)) {
          this.input.keyboard!.off('keydown', keyHandler);
          bounce?.remove();
          objs.forEach((o) => o.destroy());
          resolve(sel);
        }
      };
      this.input.keyboard!.on('keydown', keyHandler);
    });
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
    this.suppressBump = true;
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
