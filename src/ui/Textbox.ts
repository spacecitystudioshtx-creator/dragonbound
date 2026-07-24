import Phaser from 'phaser';
import { VP_W, VP_H } from '../main';

const BOX_H = 44;
const PAD = 7;
const FONT = { fontFamily: '"Press Start 2P"', fontSize: '8px', color: '#383030', resolution: 3 };
const CHARS_PER_LINE = 27;

/**
 * FireRed-style dialog textbox pinned to the bottom of the screen.
 * show() displays pages of text (A to advance); choices() shows a menu.
 */
export class Textbox {
  private scene: Phaser.Scene;
  private container: Phaser.GameObjects.Container;
  private text: Phaser.GameObjects.Text;
  private arrow: Phaser.GameObjects.Text;
  private choiceBox: Phaser.GameObjects.Container | null = null;
  isOpen = false;

  constructor(scene: Phaser.Scene) {
    this.scene = scene;
    const g = scene.add.graphics();
    // Outer border (dark), inner border (orange), white fill — GBA textbox look
    g.fillStyle(0x303030, 1).fillRoundedRect(2, VP_H - BOX_H - 2, VP_W - 4, BOX_H, 4);
    g.fillStyle(0xd8a038, 1).fillRoundedRect(4, VP_H - BOX_H, VP_W - 8, BOX_H - 4, 3);
    g.fillStyle(0xf8f8f8, 1).fillRoundedRect(6, VP_H - BOX_H + 2, VP_W - 12, BOX_H - 8, 2);

    this.text = scene.add.text(PAD + 4, VP_H - BOX_H + PAD, '', FONT).setLineSpacing(6);
    this.arrow = scene.add.text(VP_W - 16, VP_H - 14, '▼', { ...FONT, color: '#e04038' }).setVisible(false);

    this.container = scene.add.container(0, 0, [g, this.text, this.arrow]);
    this.container.setDepth(1000).setScrollFactor(0).setVisible(false);
  }

  private wrap(line: string): string[] {
    const words = line.split(' ');
    const rows: string[] = [];
    let cur = '';
    for (const w of words) {
      if ((cur + ' ' + w).trim().length > CHARS_PER_LINE) {
        rows.push(cur.trim());
        cur = w;
      } else {
        cur = (cur + ' ' + w).trim();
      }
    }
    if (cur) rows.push(cur);
    return rows;
  }

  /** Show one string (possibly multiple pages). Resolves when player dismisses. */
  async show(line: string): Promise<void> {
    this.isOpen = true;
    this.container.setVisible(true);
    const rows = this.wrap(line);
    for (let i = 0; i < rows.length; i += 2) {
      await this.typePage(rows.slice(i, i + 2).join('\n'));
      await this.waitForA();
    }
  }

  /** Show a sequence of pages, keeping the box open between them. */
  async showMany(lines: string[]): Promise<void> {
    for (const l of lines) await this.show(l);
    this.close();
  }

  /** Show text immediately with no typewriter and no wait (menu prompts). */
  prompt(line: string): void {
    this.isOpen = true;
    this.container.setVisible(true);
    this.arrow.setVisible(false);
    this.text.setText(this.wrap(line).slice(0, 2).join('\n'));
  }

  close(): void {
    this.isOpen = false;
    this.container.setVisible(false);
    this.arrow.setVisible(false);
    this.text.setText('');
  }

  private typePage(page: string): Promise<void> {
    return new Promise((resolve) => {
      this.arrow.setVisible(false);
      let i = 0;
      let done = false;
      const finish = () => {
        if (done) return;
        done = true;
        timer.remove();
        this.scene.input.keyboard!.off('keydown', skipHandler);
        this.text.setText(page);
        this.arrow.setVisible(true);
        resolve();
      };
      const timer = this.scene.time.addEvent({
        delay: 18,
        repeat: page.length - 1,
        callback: () => {
          i += 1;
          this.text.setText(page.slice(0, i));
          if (i >= page.length) finish();
        },
      });
      const skipHandler = (e: KeyboardEvent) => {
        if (isA(e)) finish();
      };
      this.scene.input.keyboard!.on('keydown', skipHandler);
    });
  }

  private waitForA(): Promise<void> {
    return new Promise((resolve) => {
      const h = (e: KeyboardEvent) => {
        if (isA(e)) {
          this.scene.input.keyboard!.off('keydown', h);
          resolve();
        }
      };
      // Attached in a microtask, so the keypress that finished typing has
      // already fully dispatched and can't also advance the page.
      this.scene.input.keyboard!.on('keydown', h);
    });
  }

  /** Show a vertical choice menu (top-right). Resolves selected index, -1 if cancelled. */
  choices(options: string[], allowCancel = true): Promise<number> {
    return new Promise((resolve) => {
      const w = Math.max(...options.map((o) => o.length)) * 8 + 26;
      const h = options.length * 14 + 12;
      const x = VP_W - w - 4;
      const y = VP_H - BOX_H - h - 4;

      const g = this.scene.add.graphics();
      g.fillStyle(0x303030, 1).fillRoundedRect(0, 0, w, h, 4);
      g.fillStyle(0xf8f8f8, 1).fillRoundedRect(2, 2, w - 4, h - 4, 3);
      const items = options.map((o, i) =>
        this.scene.add.text(16, 8 + i * 14, o, FONT)
      );
      const cursor = this.scene.add.text(6, 8, '▶', { ...FONT, color: '#e04038' });
      this.choiceBox = this.scene.add.container(x, y, [g, ...items, cursor]);
      this.choiceBox.setDepth(1001).setScrollFactor(0);

      let sel = 0;
      const keyHandler = (e: KeyboardEvent) => {
        if (e.key === 'ArrowUp' || e.key === 'w') sel = (sel + options.length - 1) % options.length;
        else if (e.key === 'ArrowDown' || e.key === 's') sel = (sel + 1) % options.length;
        else if (isA(e)) return finish(sel);
        else if (isB(e) && allowCancel) return finish(-1);
        cursor.setY(8 + sel * 14);
      };
      const finish = (result: number) => {
        this.scene.input.keyboard!.off('keydown', keyHandler);
        this.choiceBox?.destroy();
        this.choiceBox = null;
        resolve(result);
      };
      this.scene.input.keyboard!.on('keydown', keyHandler);
    });
  }
}

export function isA(e: KeyboardEvent): boolean {
  return e.key === 'z' || e.key === 'Z' || e.key === ' ' || e.key === 'Enter';
}
export function isB(e: KeyboardEvent): boolean {
  return e.key === 'x' || e.key === 'X' || e.key === 'Backspace' || e.key === 'Escape';
}
