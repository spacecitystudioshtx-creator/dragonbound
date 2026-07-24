import Phaser from 'phaser';
import { VP_W, VP_H } from '../main';
import { GameState } from '../core/state';
import { isA } from '../ui/Textbox';

export class TitleScene extends Phaser.Scene {
  constructor() {
    super('Title');
  }

  create(): void {
    this.cameras.main.setBackgroundColor('#182838');

    // Ember glow horizon
    const g = this.add.graphics();
    g.fillStyle(0x883020, 1).fillRect(0, 118, VP_W, 3);
    g.fillStyle(0x502018, 1).fillRect(0, 121, VP_W, VP_H - 121);

    this.add.image(VP_W / 2, 66, 'drake_ashvane').setScale(0.9);

    this.add
      .text(VP_W / 2, 116, 'DRAGONBOUND', {
        fontFamily: '"Press Start 2P"', fontSize: '16px', color: '#f8d848',
        stroke: '#802818', strokeThickness: 4, resolution: 3,
      })
      .setOrigin(0.5);

    const hasSave = GameState.hasSave();
    const prompt = this.add
      .text(VP_W / 2, 140, hasSave ? 'PRESS Z — CONTINUE   X — NEW GAME' : 'PRESS Z TO BEGIN', {
        fontFamily: '"Press Start 2P"', fontSize: '7px', color: '#f8f8f8', resolution: 3,
      })
      .setOrigin(0.5);
    this.tweens.add({ targets: prompt, alpha: 0.25, duration: 700, yoyo: true, repeat: -1 });

    this.input.keyboard!.on('keydown', (e: KeyboardEvent) => {
      if (isA(e)) {
        if (hasSave) GameState.load();
        else GameState.newGame();
        this.startWorld();
      } else if ((e.key === 'x' || e.key === 'X') && hasSave) {
        GameState.newGame();
        this.startWorld();
      }
    });
  }

  private startWorld(): void {
    this.cameras.main.fadeOut(300, 0, 0, 0);
    this.cameras.main.once('camerafadeoutcomplete', () => {
      this.scene.start('World', { map: GameState.map, x: GameState.x, y: GameState.y });
    });
  }
}
