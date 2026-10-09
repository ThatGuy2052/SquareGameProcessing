// a proximity-triggered hint shown as a HUD caption while the player is near it
class TutorialHint {
  float x, y, radius; // world-space center and trigger radius for the hint
  String message; // text shown while the player is inside the trigger radius

  // creates a proximity hint with its trigger geometry and displayed message
  TutorialHint(float x, float y, float radius, String message) {
    this.x = x;
    this.y = y;
    this.radius = radius;
    this.message = message;
  }
}

// behaves exactly like Enemy except getting caught just flags itself for removal
// instead of ending the game, so the tutorial can show a "you would have died" notice
class TutorialEnemy extends Enemy {
  boolean caughtPlayer = false; // lets the tutorial remove the enemy without ending the tutorial

  // creates a tutorial enemy using the normal enemy movement and collision setup
  TutorialEnemy(float x, float y, float w, float h, float speed) {
    super(x, y, w, h, speed);
  }

  // marks the enemy as caught so the tutorial can show its warning state
  void onCaughtPlayer(Player player) {
    caughtPlayer = true;
  }
}

// spawns TutorialEnemy instead of Enemy, so spawned enemies can't end the tutorial either
class TutorialSpawner extends EnemySpawner {
  // creates a spawner that inherits the tutorial's delayed activation behavior
  TutorialSpawner(float x, float y, float w, float h) {
    super(x, y, w, h);
  }

  // creates a harmless TutorialEnemy instead of a lethal normal enemy
  Enemy spawnEnemy() {
    return new TutorialEnemy(x, y, 40, 40, 3);
  }
}

// hand-built level, not a PNG, that introduces the tile colors and the one-tile-gap
// alignment mechanic before dropping the player into real levels/mazes
class Tutorial extends Scene {
  final int CELL = 50; // world size of one tutorial grid cell
  final int COLS = 9;  // number of tutorial columns, including permanent side walls
  final int ROWS = 46; // number of tutorial rows, including permanent top and bottom walls
  final int MID = 4;   // center column of the walkable corridor
  final float MIN_HINT_SECONDS = 3.5; // minimum time each hint stays readable

  BlocksManager blocksManager; // hand-authored tutorial geometry and collision map
  Player player; // player being guided through the tutorial
  ArrayList<Enemy> enemies = new ArrayList<Enemy>(); // tutorial enemies that can be safely demonstrated
  ArrayList<TutorialHint> hints = new ArrayList<TutorialHint>(); // proximity hints shown along the route
  EnemySpawner spawner; // delayed enemy source in the wide dodge room
  WinBlock winBlock; // goal at the end of the tutorial path
  Button backButton = new Button(30, 30, 100, 50, "Back"); // returns to the main menu
  String currentMessage = null; // currently displayed hint text, if any
  float messageHoldTimer = 0; // time the current hint has been visible
  final float DEATH_FLASH_SECONDS = 4.5; // duration of the harmless caught warning
  float deathFlashTimer = 0; // remaining tutorial warning time
  final int SPAWNER_ROOM_TOP = 24, SPAWNER_ROOM_BOTTOM = 30; // rows that activate the spawner room
  boolean spawnerActive = false; // stops the spawner from activating more than once

  // builds the fixed tutorial map, entities, hints, and goal
  Tutorial() {
    blocksManager = new BlocksManager(COLS * CELL, ROWS * CELL, CELL);

    char[][] grid = new char[COLS][ROWS];
    for (int c = 0; c < COLS; c++) {
      for (int r = 0; r < ROWS; r++) {
        grid[c][r] = '.';
      }
    }
    for (int r = 0; r < ROWS; r++) {
      grid[0][r] = '#';
      grid[COLS - 1][r] = '#';
    }
    for (int c = 0; c < COLS; c++) {
      grid[c][0] = '#';
      grid[c][ROWS - 1] = '#';
    }

    grid[MID][1] = 'P'; // player start, tucked behind the gate below

    // a gate right past spawn: it walls off the spawn room from anything in the
    // arena beyond, since it blocks enemies but never the player
    for (int c = 1; c < COLS - 1; c++) grid[c][2] = 'G';

    // open arena (rows 3-11, full inner width) to dodge the enemy in, instead of a
    // narrow corridor - and the enemy sits off to a side, not straight ahead of spawn
    grid[2][9] = 'E';

    // narrows back down to a 3-wide corridor for the rest of the tutorial, with long
    // stretches between features so there's time to read each hint before the next
    // rows 24-30 are left open (full inner width) instead, for a roomy spawner pocket
    for (int r = 12; r < 45; r++) {
      if (r >= 24 && r <= 30) continue;
      grid[1][r] = '#';
      grid[2][r] = '#';
      grid[6][r] = '#';
      grid[7][r] = '#';
    }

    // a gate spanning the corridor: an enemy chasing from the arena gets stopped
    // here, the player doesn't
    grid[MID - 1][19] = 'G';
    grid[MID][19] = 'G';
    grid[MID + 1][19] = 'G';

    grid[MID][27] = 'M'; // an enemy spawner, with a wide open room to dodge its spawns in

    // a staggered one-tile gap: the block at row 35 is the wall to hug so you're
    // already flush with the true gap (col MID) at row 36, then row 37 forces you
    // to keep hugging the opposite side. approaching square-on instead of cutting a
    // diagonal corner is what gets you through cleanly
    grid[MID + 1][35] = '#';
    grid[MID - 1][36] = '#';
    grid[MID + 1][36] = '#';
    grid[MID - 1][37] = '#';

    grid[MID][44] = 'Y'; // win tile

    for (int c = 0; c < COLS; c++) {
      for (int r = 0; r < ROWS; r++) {
        float wx = c * CELL + CELL / 2;
        float wy = r * CELL + CELL / 2;
        switch (grid[c][r]) {
          case '#':
            blocksManager.blocks.add(new Block(wx, wy, CELL, CELL));
            break;
          case 'G':
            blocksManager.blocks.add(new PlayerOnlyGate(wx, wy, CELL, CELL));
            break;
          case 'P':
            player = new Player(wx, wy, 50, 50, 5);
            break;
          case 'E':
            enemies.add(new TutorialEnemy(wx, wy, 40, 40, 3));
            break;
          case 'M':
            spawner = new TutorialSpawner(wx, wy, 50, 50);
            break;
          case 'Y':
            winBlock = new WinBlock(wx, wy, 50, 50, player, null);
            break;
        }
      }
    }
    blocksManager.mergeConnectedBlocks();

    hints.add(new TutorialHint(MID * CELL + CELL / 2, 1 * CELL + CELL / 2, 120,
      "WASD to move. White blocks are solid walls that stop everyone."));
    hints.add(new TutorialHint(MID * CELL + CELL / 2, 2 * CELL + CELL / 2, 130,
      "That wall of blue ahead is a gate - it blocks enemies but not you, so nothing in the arena beyond can reach your spawn."));
    hints.add(new TutorialHint(2 * CELL + CELL / 2, 9 * CELL + CELL / 2, 280,
      "Red enemies chase you once you get close - you've got the whole arena to juke around it."));
    hints.add(new TutorialHint(MID * CELL + CELL / 2, 16 * CELL + CELL / 2, 210,
      "Blue gates block enemies but not you - step through one to shake off a chaser."));
    hints.add(new TutorialHint(MID * CELL + CELL / 2, 27 * CELL + CELL / 2, 220,
      "Purple tiles are enemy spawners. They keep producing enemies - this room is wide so you've got space to dodge whatever they spawn."));
    hints.add(new TutorialHint(MID * CELL + CELL / 2, 33 * CELL + CELL / 2, 220,
      "One-tile gap ahead: hug the wall right next to it so you're flush against the adjacent block, then slide through. Cutting the corner diagonally will just wedge you against the wall."));
    hints.add(new TutorialHint(MID * CELL + CELL / 2, 42 * CELL + CELL / 2, 150,
      "Reach the yellow tile to finish the tutorial."));
  }

  void update() {
    background(0);
    player.update(blocksManager, deltaTime);
    player.updateCamera(deltaTime);

    // TutorialEnemy flags itself instead of ending the game on touch; remove it here
    // and show a "you would have died" notice instead
    ArrayList<Enemy> stillAlive = new ArrayList<Enemy>();
    for (Enemy e : enemies) {
      e.update(player, blocksManager, deltaTime);
      if (e instanceof TutorialEnemy && ((TutorialEnemy) e).caughtPlayer) {
        deathFlashTimer = DEATH_FLASH_SECONDS;
        continue;
      }
      stillAlive.add(e);
    }
    enemies = stillAlive;
    deathFlashTimer = max(0, deathFlashTimer - deltaTime);

    // the spawner stays dormant (its cooldown isn't ticked) until the player actually
    // steps into its room
    if (!spawnerActive && player.y >= SPAWNER_ROOM_TOP * CELL && player.y <= (SPAWNER_ROOM_BOTTOM + 1) * CELL) {
      spawnerActive = true;
    }
    if (spawner != null && spawnerActive) {
      Enemy spawned = spawner.update(deltaTime);
      if (spawned != null) enemies.add(spawned);
    }
    winBlock.update();

    TutorialHint nearest = null;
    float bestDist = Float.MAX_VALUE;
    for (TutorialHint h : hints) {
      float d = dist(player.x, player.y, h.x, h.y);
      if (d < h.radius && d < bestDist) {
        bestDist = d;
        nearest = h;
      }
    }
    String candidate = (nearest != null) ? nearest.message : null;
    messageHoldTimer += deltaTime;
    // only swap (or hide) the displayed message once it's been up long enough to read
    if (currentMessage == null || !currentMessage.equals(candidate)) {
      if (currentMessage == null || messageHoldTimer >= MIN_HINT_SECONDS) {
        currentMessage = candidate;
        messageHoldTimer = 0;
      }
    }

    backButton.loadSceneOnClick(new Menu());
    if (keyCode == BACKSPACE) SceneManager.setScene(new Menu());
  }

  void display() {
    blocksManager.display();
    winBlock.display();
    player.display();
    for (Enemy e : enemies) {
      e.display();
    }
    if (spawner != null) spawner.display();

    // HUD text needs to be drawn in screen space, not under the world camera translate
    resetMatrix();

    fill(255);
    textAlign(LEFT, TOP);
    textSize(16);
    text("Tutorial - Backspace to return to menu", 20, 90);

    if (currentMessage != null) {
      float boxW = min(width - 80, 700);
      float boxH = 80;
      float boxX = width / 2 - boxW / 2;
      float boxY = height - boxH - 40;
      rectMode(CORNER);
      fill(0, 200);
      rect(boxX, boxY, boxW, boxH, 10);
      fill(255);
      textAlign(CENTER, CENTER);
      textSize(18);
      text(currentMessage, boxX + 20, boxY, boxW - 40, boxH);
    }

    if (deathFlashTimer > 0) {
      float boxW = min(width - 80, 700);
      float boxH = 90;
      float boxX = width / 2 - boxW / 2;
      float boxY = 140;
      rectMode(CORNER);
      fill(120, 0, 0, 220);
      rect(boxX, boxY, boxW, boxH, 10);
      fill(255);
      textAlign(CENTER, CENTER);
      textSize(18);
      text("You would have died there! Touching an enemy normally ends your run - " +
        "that one's been removed so you can keep practicing.", boxX + 20, boxY, boxW - 40, boxH);
    }

    fill(200);
    backButton.display();
  }
}
