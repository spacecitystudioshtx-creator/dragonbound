import Phaser from 'phaser';
import { DRAKES } from '../core/db';
import { frameOf } from '../core/tiles';
import manifest from '../data/tileset.gen.json';
import charManifest from '../data/characters.gen.json';

export class BootScene extends Phaser.Scene {
  constructor() {
    super('Boot');
  }

  preload(): void {
    this.load.spritesheet('ground', 'assets/tiles/ground.png', { frameWidth: 16, frameHeight: 16 });
    for (const p of Object.keys((manifest as any).props)) {
      this.load.image(`prop_${p}`, `assets/tiles/props/${p}.png`);
    }
    // Generated character sheets: 3 cols (stepA, idle, stepB) x 4 rows (down/left/right/up)
    for (const name of (charManifest as any).chars as string[]) {
      this.load.spritesheet(`char_${name}`, `assets/chars/${name}.png`, {
        frameWidth: (charManifest as any).frameW,
        frameHeight: (charManifest as any).frameH,
      });
    }
    for (const id of Object.keys(DRAKES)) {
      this.load.image(`drake_${id}`, `assets/drakes/${id}_front.png`);
    }
  }

  create(): void {
    // Tile animations shared by every WorldScene instance.
    this.anims.create({
      key: 'tile_water',
      frames: [frameOf('water_0'), frameOf('water_1')].map((f) => ({ key: 'ground', frame: f })),
      frameRate: 1.6,
      repeat: -1,
    });
    this.anims.create({
      key: 'tile_flowers',
      frames: [frameOf('flowers_0'), frameOf('flowers_1')].map((f) => ({ key: 'ground', frame: f })),
      frameRate: 2,
      repeat: -1,
    });
    this.anims.create({
      key: 'tile_lava',
      frames: [frameOf('lava_0'), frameOf('lava_1')].map((f) => ({ key: 'ground', frame: f })),
      frameRate: 1.4,
      repeat: -1,
    });
    // Player walk cycles: step-idle-step-idle per direction row
    const dirs = ['down', 'left', 'right', 'up'];
    dirs.forEach((dir, r) => {
      this.anims.create({
        key: `walk_${dir}`,
        frames: [r * 3, r * 3 + 1, r * 3 + 2, r * 3 + 1].map((f) => ({ key: 'char_player', frame: f })),
        frameRate: 7,
        repeat: -1,
      });
    });

    // Placeholder for drakes whose sprite hasn't been generated yet, so new
    // data-only drakes are playable immediately.
    const typeColors: Record<string, number> = { fire: 0xd05038, water: 0x4878c8, nature: 0x58a848 };
    for (const [id, spec] of Object.entries(DRAKES)) {
      if (!this.textures.exists(`drake_${id}`)) {
        const g = this.add.graphics();
        g.fillStyle(typeColors[spec.type] ?? 0x888888, 1).fillCircle(40, 44, 30);
        g.fillStyle(0xffffff, 0.85).fillCircle(30, 36, 5).fillCircle(50, 36, 5);
        g.generateTexture(`drake_${id}`, 80, 80);
        g.destroy();
      }
    }

    // Make sure the pixel font is ready before any scene renders text —
    // but never hang on it (slow networks / backgrounded tabs).
    Promise.race([
      document.fonts.load('8px "Press Start 2P"').catch(() => undefined),
      new Promise((res) => setTimeout(res, 1500)),
    ]).then(() => {
      const params = new URLSearchParams(window.location.search);
      if (params.has('new')) {
        // QC shortcut: /?new wipes the save for a guaranteed fresh start.
        import('../core/state').then(({ GameState }) => {
          GameState.clearSave();
          this.scene.start('Title');
        });
        return;
      }
      if (params.has('debug')) {
        this.scene.start('Debug', { sheet: params.get('debug') || 'ground' });
      } else {
        this.scene.start('Title');
      }
    });
  }
}
