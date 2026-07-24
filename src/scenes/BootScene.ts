import Phaser from 'phaser';
import { DRAKES } from '../core/db';

export class BootScene extends Phaser.Scene {
  constructor() {
    super('Boot');
  }

  preload(): void {
    this.load.spritesheet('tiles', 'assets/tiles/basictiles.png', { frameWidth: 16, frameHeight: 16 });
    this.load.spritesheet('characters', 'assets/tiles/characters.png', { frameWidth: 16, frameHeight: 16 });
    this.load.spritesheet('things', 'assets/tiles/things.png', { frameWidth: 16, frameHeight: 16 });
    this.load.spritesheet('player', 'assets/player_sheet.png', { frameWidth: 16, frameHeight: 16 });
    for (const id of Object.keys(DRAKES)) {
      this.load.image(`drake_${id}`, `assets/drakes/${id}_front.png`);
    }
  }

  create(): void {
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
        this.scene.start('Debug', { sheet: params.get('debug') || 'tiles' });
      } else {
        this.scene.start('Title');
      }
    });
  }
}
