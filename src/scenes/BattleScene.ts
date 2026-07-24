import Phaser from 'phaser';
import { VP_W, VP_H } from '../main';
import { GameState } from '../core/state';
import { DrakeInstance } from '../core/drake';
import { MOVES, DRAKES, TRAINERS } from '../core/db';
import { executeMove, pickAiMove, tryCapture, xpReward } from '../core/battle';
import { Textbox } from '../ui/Textbox';

const FONT = { fontFamily: '"Press Start 2P"', fontSize: '7px', color: '#383030', resolution: 3 };

// Which starter counters the player's — Sable always picks the advantage.
const RIVAL_COUNTER: Record<string, string> = { ember: 'ripple', ripple: 'sprig', sprig: 'ember' };

interface BattlePayload {
  kind: 'wild' | 'trainer';
  enemy?: { speciesId: string; level: number };
  trainerId?: string;
}

export class BattleScene extends Phaser.Scene {
  private player!: DrakeInstance;
  private enemy!: DrakeInstance;
  private enemyTeam: DrakeInstance[] = [];
  private payload!: BattlePayload;
  private textbox!: Textbox;
  private playerImg!: Phaser.GameObjects.Image;
  private enemyImg!: Phaser.GameObjects.Image;
  private hud!: Phaser.GameObjects.Graphics;
  private hudTexts: Phaser.GameObjects.Text[] = [];
  // Displayed HP values lag real HP and tween toward it (FireRed bar drain).
  private dispPlayerHp = 0;
  private dispEnemyHp = 0;

  constructor() {
    super('Battle');
  }

  create(payload: BattlePayload): void {
    this.payload = payload;
    this.player = GameState.activeDrake!;
    this.player.resetBattleState();

    if (payload.kind === 'wild') {
      this.enemyTeam = [new DrakeInstance(payload.enemy!.speciesId, payload.enemy!.level)];
    } else {
      const t = TRAINERS[payload.trainerId!];
      this.enemyTeam = t.team.map((m) => {
        let id = m.drake;
        if (id === '$rival_starter') {
          const starter = GameState.party[0]?.speciesId ?? 'ember';
          id = RIVAL_COUNTER[starter] ?? 'ripple';
        }
        return new DrakeInstance(id, m.level);
      });
    }
    this.enemy = this.enemyTeam[0];
    this.enemy.resetBattleState();

    this.drawField();
    this.textbox = new Textbox(this);
    this.runBattle();
  }

  // ── Visuals ───────────────────────────────────────────────────────────────

  private drawField(): void {
    const g = this.add.graphics();
    // Dusty route backdrop: warm sky bands + sandy ground
    const sky = [0x88b8d0, 0x98c4d8, 0xb0d0d8, 0xd0e0d8];
    sky.forEach((c, i) => g.fillStyle(c, 1).fillRect(0, i * 18, VP_W, 18));
    g.fillStyle(0xc8a868, 1).fillRect(0, 72, VP_W, VP_H - 72);
    // Platforms
    g.fillStyle(0xb08850, 1).fillEllipse(178, 74, 100, 26);
    g.fillStyle(0xb08850, 1).fillEllipse(62, 116, 104, 28);

    // Combatants slide onto their platforms during the intro (FireRed entry).
    this.enemyImg = this.add.image(VP_W + 60, 46, `drake_${this.enemy.speciesId}`).setScale(0.72);
    this.playerImg = this.add.image(-60, 88, `drake_${this.player.speciesId}`).setScale(0.8).setFlipX(true);

    this.dispPlayerHp = this.player.hp;
    this.dispEnemyHp = this.enemy.hp;
    this.hud = this.add.graphics().setDepth(50);
    this.redrawHud();
  }

  private slideIn(): Promise<void> {
    return new Promise((resolve) => {
      this.tweens.add({ targets: this.enemyImg, x: 178, duration: 450, ease: 'Cubic.easeOut' });
      this.tweens.add({
        targets: this.playerImg, x: 62, duration: 450, ease: 'Cubic.easeOut',
        onComplete: () => resolve(),
      });
    });
  }

  /** Animate HP bars draining/refilling toward real values. */
  private tweenHud(): Promise<void> {
    return new Promise((resolve) => {
      const proxy = { p: this.dispPlayerHp, e: this.dispEnemyHp };
      this.tweens.add({
        targets: proxy,
        p: this.player.hp,
        e: this.enemy.hp,
        duration: 420,
        ease: 'Linear',
        onUpdate: () => {
          this.dispPlayerHp = Math.round(proxy.p);
          this.dispEnemyHp = Math.round(proxy.e);
          this.redrawHud();
        },
        onComplete: () => {
          this.dispPlayerHp = this.player.hp;
          this.dispEnemyHp = this.enemy.hp;
          this.redrawHud();
          resolve();
        },
      });
    });
  }

  private lunge(img: Phaser.GameObjects.Image, dx: number): Promise<void> {
    return new Promise((resolve) => {
      this.tweens.add({
        targets: img, x: img.x + dx, duration: 90, yoyo: true, ease: 'Quad.easeOut',
        onComplete: () => resolve(),
      });
    });
  }

  private faintDrop(img: Phaser.GameObjects.Image): Promise<void> {
    return new Promise((resolve) => {
      this.tweens.add({
        targets: img, y: img.y + 26, alpha: 0, duration: 340, ease: 'Quad.easeIn',
        onComplete: () => resolve(),
      });
    });
  }

  private reviveSprite(img: Phaser.GameObjects.Image, x: number, y: number): void {
    img.setPosition(x, y).setAlpha(1);
  }

  private redrawHud(): void {
    this.hud.clear();
    this.hudTexts.forEach((t) => t.destroy());
    this.hudTexts = [];

    const box = (x: number, y: number, w: number, h: number) => {
      this.hud.fillStyle(0x303030, 1).fillRoundedRect(x - 2, y - 2, w + 4, h + 4, 3);
      this.hud.fillStyle(0xf0f0d8, 1).fillRoundedRect(x, y, w, h, 2);
    };
    const hpBar = (x: number, y: number, w: number, frac: number) => {
      this.hud.fillStyle(0x585858, 1).fillRect(x, y, w, 4);
      const color = frac > 0.5 ? 0x40c848 : frac > 0.2 ? 0xe8c030 : 0xe04038;
      this.hud.fillStyle(color, 1).fillRect(x, y, Math.max(0, Math.floor(w * frac)), 4);
    };
    const label = (x: number, y: number, s: string) => {
      this.hudTexts.push(this.add.text(x, y, s, FONT).setDepth(51));
    };

    // Enemy box (top-left)
    box(8, 8, 96, 26);
    label(12, 12, `${this.enemy.name.toUpperCase()} L${this.enemy.level}`);
    hpBar(12, 26, 84, this.dispEnemyHp / this.enemy.maxHp);

    // Player box (right, above panel)
    box(136, 74, 98, 38);
    label(140, 78, `${this.player.name.toUpperCase()} L${this.player.level}`);
    hpBar(140, 90, 86, this.dispPlayerHp / this.player.maxHp);
    label(140, 97, `${this.dispPlayerHp}/${this.player.maxHp}`);
    // XP bar
    this.hud.fillStyle(0x585858, 1).fillRect(140, 107, 86, 2);
    this.hud.fillStyle(0x4890f0, 1).fillRect(140, 107, Math.floor(86 * Math.min(1, this.player.xp / this.player.xpToNext())), 2);
  }

  private async flashSprite(img: Phaser.GameObjects.Image): Promise<void> {
    return new Promise((resolve) => {
      this.tweens.add({ targets: img, alpha: 0.15, duration: 70, yoyo: true, repeat: 2, onComplete: () => resolve() });
    });
  }

  // ── Battle loop ───────────────────────────────────────────────────────────

  private async runBattle(): Promise<void> {
    await this.slideIn();
    if (this.payload.kind === 'wild') {
      await this.textbox.show(`A wild ${this.enemy.name.toUpperCase()} appeared!`);
    } else {
      const t = TRAINERS[this.payload.trainerId!];
      await this.textbox.show(`${t.name.toUpperCase()} wants to battle!`);
      await this.textbox.show(`${t.name.toUpperCase()} sent out ${this.enemy.name.toUpperCase()}!`);
    }

    while (true) {
      const action = await this.mainMenu();
      if (action === 'run') {
        if (this.payload.kind === 'trainer') {
          await this.textbox.show(`You can't run from a trainer battle!`);
          continue;
        }
        await this.textbox.show('Got away safely!');
        return this.end('ran');
      }
      if (action === 'stone') {
        const done = await this.throwStone();
        if (done) return;
        // Enemy gets a free hit after a failed catch
        if (await this.enemyTurn()) return;
        continue;
      }
      if (action === 'swap') {
        const swapped = await this.swapMenu();
        if (swapped && (await this.enemyTurn())) return;
        continue;
      }
      if (typeof action === 'object') {
        if (await this.resolveRound(action.moveId)) return;
      }
    }
  }

  private async mainMenu(): Promise<'run' | 'stone' | 'swap' | { moveId: string }> {
    while (true) {
      this.textbox.prompt(`What will ${this.player.name.toUpperCase()} do?`);
      const idx = await this.textbox.choices(['FIGHT', 'STONE', 'SWAP', 'RUN'], false);
      if (idx === 0) {
        const names = this.player.moves.map((m) => MOVES[m].name.toUpperCase());
        const mi = await this.textbox.choices(names, true);
        if (mi >= 0) return { moveId: this.player.moves[mi] };
      } else if (idx === 1) return 'stone';
      else if (idx === 2) return 'swap';
      else if (idx === 3) return 'run';
    }
  }

  /** Full round (player move + enemy move, speed order). Returns true if battle ended. */
  private async resolveRound(moveId: string): Promise<boolean> {
    const playerFirst = this.player.spd >= this.enemy.spd;
    const order: ['player' | 'enemy', 'player' | 'enemy'] = playerFirst ? ['player', 'enemy'] : ['enemy', 'player'];
    for (const who of order) {
      if (who === 'player') {
        if (this.player.fainted) continue;
        const res = executeMove(this.player, this.enemy, moveId);
        await this.textbox.show(res.messages[0]);
        await this.lunge(this.playerImg, 14);
        await this.flashSprite(this.enemyImg);
        await this.tweenHud();
        for (const m of res.messages.slice(1)) await this.textbox.show(m);
        if (this.enemy.fainted && (await this.onEnemyFaint())) return true;
        if (this.player.fainted && (await this.onPlayerFaint())) return true;
      } else {
        if (this.enemy.fainted) continue;
        if (await this.enemyStrike()) return true;
      }
    }
    return false;
  }

  private async enemyTurn(): Promise<boolean> {
    if (this.enemy.fainted) return false;
    return this.enemyStrike();
  }

  private async enemyStrike(): Promise<boolean> {
    const res = executeMove(this.enemy, this.player, pickAiMove(this.enemy, this.player));
    await this.textbox.show(res.messages[0]);
    await this.lunge(this.enemyImg, -14);
    await this.flashSprite(this.playerImg);
    await this.tweenHud();
    for (const m of res.messages.slice(1)) await this.textbox.show(m);
    if (this.player.fainted && (await this.onPlayerFaint())) return true;
    if (this.enemy.fainted && (await this.onEnemyFaint())) return true;
    return false;
  }

  private async onEnemyFaint(): Promise<boolean> {
    await this.faintDrop(this.enemyImg);
    await this.textbox.show(`${this.enemy.name.toUpperCase()} fainted!`);
    const xp = xpReward(this.enemy, this.payload.kind === 'trainer');
    await this.textbox.show(`${this.player.name} gained ${xp} XP!`);
    for (const msg of this.player.gainXp(xp)) {
      this.redrawHud();
      await this.textbox.show(msg);
    }
    const evo = this.player.tryEvolve();
    if (evo) {
      await this.textbox.show(evo);
      this.playerImg.setTexture(`drake_${this.player.speciesId}`);
      this.redrawHud();
    }
    // Trainer: next drake?
    const next = this.enemyTeam.find((d) => !d.fainted);
    if (this.payload.kind === 'trainer' && next) {
      this.enemy = next;
      this.enemy.resetBattleState();
      this.enemyImg.setTexture(`drake_${this.enemy.speciesId}`);
      this.reviveSprite(this.enemyImg, 178, 46);
      this.dispEnemyHp = this.enemy.hp;
      this.redrawHud();
      await this.textbox.show(`${TRAINERS[this.payload.trainerId!].name.toUpperCase()} sent out ${this.enemy.name.toUpperCase()}!`);
      return false;
    }
    if (this.payload.kind === 'trainer') {
      await this.textbox.show(`You defeated ${TRAINERS[this.payload.trainerId!].name.toUpperCase()}!`);
      this.end('trainer_win');
    } else {
      this.end('win');
    }
    return true;
  }

  private async onPlayerFaint(): Promise<boolean> {
    await this.faintDrop(this.playerImg);
    await this.textbox.show(`${this.player.name.toUpperCase()} fainted!`);
    const next = GameState.party.find((d) => !d.fainted);
    if (next) {
      this.player = next;
      this.player.resetBattleState();
      this.playerImg.setTexture(`drake_${this.player.speciesId}`);
      this.reviveSprite(this.playerImg, 62, 88);
      this.dispPlayerHp = this.player.hp;
      this.redrawHud();
      await this.textbox.show(`Go, ${this.player.name.toUpperCase()}!`);
      return false;
    }
    this.end(this.payload.kind === 'trainer' ? 'trainer_lose' : 'lose');
    return true;
  }

  private async throwStone(): Promise<boolean> {
    if (this.payload.kind === 'trainer') {
      await this.textbox.show(`You can't bind another warden's drake!`);
      return false;
    }
    if (GameState.runestones <= 0) {
      await this.textbox.show(`You're out of runestones!`);
      return false;
    }
    if (GameState.party.length >= 6) {
      await this.textbox.show('Your party is full!');
      return false;
    }
    GameState.runestones -= 1;
    await this.textbox.show(`You hurled a RUNESTONE! (${GameState.runestones} left)`);
    const [success, wobbles] = tryCapture(this.enemy);
    for (let i = 0; i < wobbles; i++) {
      await this.textbox.show('. . .');
    }
    if (success) {
      await this.textbox.show(`Gotcha! ${this.enemy.name.toUpperCase()} was bound!`);
      GameState.party.push(this.enemy);
      this.end('caught');
      return true;
    }
    await this.textbox.show(`Oh no! The ${this.enemy.name.toUpperCase()} broke free!`);
    return false;
  }

  private async swapMenu(): Promise<boolean> {
    const options = GameState.party.map(
      (d) => `${d.name.toUpperCase()} L${d.level} ${d.fainted ? '(FNT)' : `${d.hp}/${d.maxHp}`}`
    );
    const idx = await this.textbox.choices(options, true);
    if (idx < 0) return false;
    const pick = GameState.party[idx];
    if (pick === this.player) return false;
    if (pick.fainted) {
      await this.textbox.show(`${pick.name.toUpperCase()} is in no shape to fight!`);
      return false;
    }
    this.player = pick;
    this.player.resetBattleState();
    this.playerImg.setTexture(`drake_${this.player.speciesId}`);
    this.reviveSprite(this.playerImg, 62, 88);
    this.dispPlayerHp = this.player.hp;
    this.redrawHud();
    await this.textbox.show(`Go, ${this.player.name.toUpperCase()}!`);
    return true;
  }

  private end(outcome: string): void {
    GameState.save();
    this.scene.stop();
    this.scene.wake('World', { outcome, trainerId: this.payload.trainerId });
  }
}
