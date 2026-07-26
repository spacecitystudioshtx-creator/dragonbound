import Phaser from 'phaser';
import { VP_W, VP_H } from '../main';
import { GameState } from '../core/state';
import { isA, isB } from '../ui/Textbox';
import { Sound } from '../audio/sound';

const FONT = { fontFamily: '"Press Start 2P"', fontSize: '8px', color: '#383030', resolution: 3 };

export class TitleScene extends Phaser.Scene {
  private menuObjs: Phaser.GameObjects.GameObject[] = [];
  private mode: 'menu' | 'confirm' = 'menu';
  private sel = 0;

  constructor() {
    super('Title');
  }

  create(): void {
    this.cameras.main.setBackgroundColor('#182838');
    Sound.playMusic('title'); // queued until the first key press unlocks audio
    this.menuObjs = [];
    this.mode = 'menu';
    this.sel = 0;

    // Ember glow horizon
    const g = this.add.graphics();
    g.fillStyle(0x883020, 1).fillRect(0, 118, VP_W, 3);
    g.fillStyle(0x502018, 1).fillRect(0, 121, VP_W, VP_H - 121);

    this.add.image(VP_W / 2, 66, 'drake_ashvane').setScale(1.1);

    this.add
      .text(VP_W / 2, 116, 'DRAGONBOUND', {
        fontFamily: '"Press Start 2P"', fontSize: '16px', color: '#f8d848',
        stroke: '#802818', strokeThickness: 4, resolution: 3,
      })
      .setOrigin(0.5);

    if (GameState.hasSave()) {
      this.showMenu(['CONTINUE', 'NEW GAME']);
    } else {
      const prompt = this.add
        .text(VP_W / 2, 140, 'PRESS Z TO BEGIN', {
          fontFamily: '"Press Start 2P"', fontSize: '7px', color: '#f8f8f8', resolution: 3,
        })
        .setOrigin(0.5);
      this.tweens.add({ targets: prompt, alpha: 0.25, duration: 700, yoyo: true, repeat: -1 });
    }

    this.input.keyboard!.on('keydown', this.onKey, this);
    this.events.once('shutdown', () => this.input.keyboard?.off('keydown', this.onKey, this));
  }

  /** FireRed-style white menu box over the lower banner. */
  private showMenu(options: string[]): void {
    this.clearMenu();
    const w = 108, h = options.length * 14 + 12;
    const x = (VP_W - w) / 2, y = 124;
    const g = this.add.graphics();
    g.fillStyle(0x303030, 1).fillRoundedRect(x - 2, y - 2, w + 4, h + 4, 4);
    g.fillStyle(0xf8f8f8, 1).fillRoundedRect(x, y, w, h, 3);
    this.menuObjs.push(g);
    options.forEach((o, i) => {
      this.menuObjs.push(this.add.text(x + 16, y + 7 + i * 14, o, FONT));
    });
    const cursor = this.add.text(x + 6, y + 7, '▶', { ...FONT, color: '#e04038' });
    this.menuObjs.push(cursor);
    (this as any)._cursor = cursor;
    (this as any)._menuY = y;
    this.sel = 0;
  }

  private clearMenu(): void {
    this.menuObjs.forEach((o) => o.destroy());
    this.menuObjs = [];
  }

  private onKey(e: KeyboardEvent): void {
    const hasSave = GameState.hasSave();
    if (!hasSave && this.mode === 'menu') {
      if (isA(e)) {
        GameState.newGame();
        this.startWorld();
      }
      return;
    }

    const cursor = (this as any)._cursor as Phaser.GameObjects.Text;
    const menuY = (this as any)._menuY as number;

    if (this.mode === 'menu') {
      if (e.key === 'ArrowUp' || e.key === 'ArrowDown' || e.key === 'w' || e.key === 's') {
        this.sel = 1 - this.sel;
        cursor.setY(menuY + 7 + this.sel * 14);
        Sound.sfx('tick');
      } else if (isA(e)) {
        Sound.sfx('blip');
        if (this.sel === 0) {
          GameState.load();
          this.startWorld();
        } else {
          // NEW GAME over an existing save: confirm the erase.
          this.mode = 'confirm';
          this.showMenu(['ERASE & BEGIN', 'BACK']);
        }
      }
    } else {
      if (e.key === 'ArrowUp' || e.key === 'ArrowDown' || e.key === 'w' || e.key === 's') {
        this.sel = 1 - this.sel;
        cursor.setY(menuY + 7 + this.sel * 14);
        Sound.sfx('tick');
      } else if (isA(e)) {
        if (this.sel === 0) {
          Sound.sfx('blip');
          GameState.clearSave();
          GameState.newGame();
          this.startWorld();
        } else {
          this.backToMenu();
        }
      } else if (isB(e)) {
        this.backToMenu();
      }
    }
  }

  private backToMenu(): void {
    this.mode = 'menu';
    this.showMenu(['CONTINUE', 'NEW GAME']);
  }

  private startWorld(): void {
    this.input.keyboard!.off('keydown', this.onKey, this);
    this.cameras.main.fadeOut(300, 0, 0, 0);
    this.cameras.main.once('camerafadeoutcomplete', () => {
      this.scene.start('World', { map: GameState.map, x: GameState.x, y: GameState.y });
    });
  }
}
