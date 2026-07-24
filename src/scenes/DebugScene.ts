import Phaser from 'phaser';

/**
 * Dev-only tile/frame index viewer: open /?debug=tiles (or characters,
 * things, player) to see every frame with its index overlaid.
 */
export class DebugScene extends Phaser.Scene {
  constructor() {
    super('Debug');
  }

  create(data: { sheet: string }): void {
    const key = data.sheet;
    this.cameras.main.setBackgroundColor('#2a2a3a');
    const tex = this.textures.get(key);
    const frames = tex.frameTotal - 1; // exclude __BASE
    const perRow = 8;
    const cell = 26;
    for (let i = 0; i < frames; i++) {
      const x = 8 + (i % perRow) * cell;
      const y = 8 + Math.floor(i / perRow) * cell;
      this.add.image(x, y, key, i).setOrigin(0, 0).setScale(1);
      this.add.text(x, y + 16, String(i), {
        fontFamily: '"Press Start 2P"', fontSize: '5px', color: '#ffff88', resolution: 4,
      });
    }
    this.cameras.main.setZoom(1);
    // Scroll with arrows
    this.input.keyboard!.on('keydown-DOWN', () => (this.cameras.main.scrollY += 26));
    this.input.keyboard!.on('keydown-UP', () => (this.cameras.main.scrollY -= 26));
  }
}
