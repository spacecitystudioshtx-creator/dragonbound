import Phaser from 'phaser';
import { DRAKES } from '../core/db';
import { frameOf } from '../core/tiles';
import manifest from '../data/tileset.gen.json';

export class BootScene extends Phaser.Scene {
  constructor() {
    super('Boot');
  }

  preload(): void {
    this.load.spritesheet('ground', 'assets/tiles/ground.png', { frameWidth: 16, frameHeight: 16 });
    for (const p of Object.keys((manifest as any).props)) {
      this.load.image(`prop_${p}`, `assets/tiles/props/${p}.png`);
    }
    this.load.spritesheet('characters', 'assets/tiles/characters.png', { frameWidth: 16, frameHeight: 16 });
    this.load.spritesheet('player', 'assets/player_sheet.png', { frameWidth: 16, frameHeight: 16 });
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

    // Make sure the pixel font is ready before any scene renders text.
    document.fonts.load('8px "Press Start 2P"').then(() => {
      const params = new URLSearchParams(window.location.search);
      if (params.has('debug')) {
        this.scene.start('Debug', { sheet: params.get('debug') || 'ground' });
      } else {
        this.scene.start('Title');
      }
    });
  }
}
