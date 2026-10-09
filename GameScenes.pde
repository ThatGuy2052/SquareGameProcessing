// main menu that opens the tutorial, level list, maze, settings, or application exit
class Menu extends Scene {
    Button tutorialButton = new Button(width/2 - 50, height/2 - 100, 100, 50, "Tutorial"); // opens the guided tutorial
    Button levelMenuButton = new Button(width/2 - 50, height/2 - 25, 100, 50, "Level Menu"); // opens imported levels
    Button mazeLevelButton = new Button(width/2 - 50, height/2 + 50, 100, 50, "Maze Level"); // starts a generated maze
    Button settingsButton = new Button(width/2 - 50, height/2 + 125, 100, 50, "Settings"); // opens display and gameplay settings
    Button quitButton = new Button(width/2 - 50, height/2 + 200, 100, 50, "Quit"); // requests application exit
  // routes button input to the right destination scene
  void update() {
    tutorialButton.loadSceneOnClick(new Tutorial());
    levelMenuButton.loadSceneOnClick(new LevelMenu());
    mazeLevelButton.loadSceneOnClick(new Maze());
    settingsButton.loadSceneOnClick(new SettingsMenu());
    quitButton.quitGameOnClick();
  }

  // draws the title and all main-menu controls
  void display() {
    background(0);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(100);
    text("Square", width/2, height/3);
    tutorialButton.display();
    levelMenuButton.display();
    mazeLevelButton.display();
    settingsButton.display();
    quitButton.display();
  }
}

// settings screen that edits and persists the global GameSettings flags
class SettingsMenu extends Scene {
  Button backButton = new Button(30, 30, 100, 50, "Back"); // returns to the main menu
  ToggleButton crtToggle = new ToggleButton(width/2 - 100, height/2 - 160, 200, 50, "CRT Shader"); // toggles CRT processing
  ToggleButton bloomToggle = new ToggleButton(width/2 - 100, height/2 - 90, 200, 50, "Bloom"); // toggles bloom processing
  ToggleButton lightingToggle = new ToggleButton(width/2 - 100, height/2 - 20, 200, 50, "Lighting"); // toggles normal lighting unless locked
  ToggleButton nightmareToggle = new ToggleButton(width/2 - 100, height/2 + 50, 200, 50, "Nightmare Mode"); // enables the harder lighting and stats mode
  ToggleButton deathFlashToggle = new ToggleButton(width/2 - 100, height/2 + 120, 200, 50, "Death Flash"); // toggles the death overlay
  ToggleButton dangerEdgesToggle = new ToggleButton(width/2 - 100, height/2 + 190, 200, 50, "Danger Edges"); // toggles enemy danger glow
  ToggleButton autoRestartToggle = new ToggleButton(width/2 - 100, height/2 + 260, 200, 50, "Auto-Restart on Death"); // toggles automatic retries
  ToggleButton statsHudToggle = new ToggleButton(width/2 - 100, height/2 + 330, 200, 50, "Speedrun Timer"); // toggles the gameplay timer
  ToggleButton roastsToggle = new ToggleButton(width/2 - 100, height/2 + 400, 200, 50, "Death Roasts"); // toggles lose-screen roast text

  // handles setting toggles and persists each change immediately
  void update() {
    backButton.loadSceneOnClick(new Menu());
    if (crtToggle.clicked()) {
      GameSettings.crtEnabled = !GameSettings.crtEnabled;
      GameSettings.save(app);
    }
    if (bloomToggle.clicked()) {
      GameSettings.bloomEnabled = !GameSettings.bloomEnabled;
      GameSettings.save(app);
    }
    if (lightingToggle.clicked()) {
      if (!GameSettings.nightmareMode) {
        GameSettings.lightingEnabled = !GameSettings.lightingEnabled;
        GameSettings.save(app);
      }
    }
    if (nightmareToggle.clicked()) {
      GameSettings.nightmareMode = !GameSettings.nightmareMode;
      if (GameSettings.nightmareMode) GameSettings.lightingEnabled = true;
      GameSettings.save(app);
    }
    if (deathFlashToggle.clicked()) {
      GameSettings.deathFlashEnabled = !GameSettings.deathFlashEnabled;
      GameSettings.save(app);
    }
    if (dangerEdgesToggle.clicked()) {
      GameSettings.dangerEdgesEnabled = !GameSettings.dangerEdgesEnabled;
      GameSettings.save(app);
    }
    if (autoRestartToggle.clicked()) {
      GameSettings.autoRestartOnDeath = !GameSettings.autoRestartOnDeath;
      GameSettings.save(app);
    }
    if (statsHudToggle.clicked()) {
      GameSettings.statsHudEnabled = !GameSettings.statsHudEnabled;
      GameSettings.save(app);
    }
    if (roastsToggle.clicked()) {
      GameSettings.roastsEnabled = !GameSettings.roastsEnabled;
      GameSettings.save(app);
    }
  }

  // draws the settings controls, including the locked lighting state
  void display() {
    background(0);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(48);
    text("Settings", width/2, height/4);
    crtToggle.display(GameSettings.crtEnabled);
    bloomToggle.display(GameSettings.bloomEnabled);
    lightingToggle.display(GameSettings.lightingEnabled || GameSettings.nightmareMode, GameSettings.nightmareMode);
    nightmareToggle.display(GameSettings.nightmareMode, color(200, 0, 0));
    deathFlashToggle.display(GameSettings.deathFlashEnabled);
    dangerEdgesToggle.display(GameSettings.dangerEdgesEnabled);
    autoRestartToggle.display(GameSettings.autoRestartOnDeath);
    statsHudToggle.display(GameSettings.statsHudEnabled);
    roastsToggle.display(GameSettings.roastsEnabled);
    backButton.display();
  }
}

// generated maze gameplay scene with a player, enemies, and one goal block
class Maze extends Scene {
  BlocksManager blocksManager; // generated maze geometry and collision queries
   Player player; // player controlled by keyboard input
   ArrayList<Enemy> enemies = new ArrayList<Enemy>(); // enemies pursuing the player
   WinBlock winBlock; // goal that ends the run successfully
        Maze(){
         levelKey = "__maze__";
         levelDisplayName = "Random Maze";
         blocksManager = new BlocksManager(width, height, 50);
         blocksManager.generateMaze();
         blocksManager.mergeConnectedBlocks();


         ArrayList<PVector> openCells = blocksManager.getOpenCellCenters();
         PVector playerPos = openCells.get(int(random(openCells.size())));
         player = new Player(playerPos.x, playerPos.y, 40, 40, 5);

         int enemyCount = int(random(1, 6));
         for (int i = 0; i < enemyCount && !openCells.isEmpty(); i++) {
           PVector enemyPos = blocksManager.pickFarCell(openCells, playerPos);
           enemies.add(new Enemy(enemyPos.x, enemyPos.y, 40, 40, 3));
           openCells.remove(enemyPos);
         }

         PVector winPos = blocksManager.pickFarCell(openCells, playerPos);
         winBlock = new WinBlock(winPos.x, winPos.y, 50, 50, player, this);
        }

  // advances death state, movement, enemy pursuit, and goal collision
  void update() {
      background(0);
  if (player.dead) {
    player.updateDeath(deltaTime);
    player.updateCamera(deltaTime);
    if (player.deathAnimationDone()) {
      recordLevelResult(false);
      if (GameSettings.autoRestartOnDeath) {
        SceneManager.retryLastPlayScene();
      } else {
        SceneManager.setScene(new Lose(this));
      }
    }
    return;
  }
  elapsedTime += deltaTime;
  player.update(blocksManager, deltaTime);
  player.updateCamera(deltaTime);
  for (Enemy e : enemies) {
    e.update(player, blocksManager, deltaTime);
    if (!player.dead && e.checkNearMiss(player)) nearMissCount++;
  }
  winBlock.update();
  }

  // draws maze geometry, entities, death effects, and the run timer
  void display() {
    blocksManager.display();
    winBlock.display();
    player.display();
    for (Enemy e : enemies) {
      e.display();
    }
    if (player.dead) displayDeathOverlay(player);
    displayRunTimer(elapsedTime);
  }

  // returns a newly generated maze for a fresh retry
  Scene retry() {
    return new Maze();
  }
}

// result scene shown after a player reaches the goal
class Win extends Scene {
  Button mainMenuButton = new Button(width/2 - 245, height/5 * 3, 100, 50, "Main Menu"); // returns to the main menu
  Button mazeButton = new Button(width/2 - 125, height/5 * 3, 100, 50, "Maze"); // starts another generated maze
  Button levelMenuButton = new Button(width/2 - 5, height/5 * 3, 100, 50, "Level Menu"); // returns to imported levels
  Button retryButton = new Button(width/2 + 115, height/5 * 3, 100, 50, "Retry"); // replays the previous run

  String levelKey; // identifier of the completed level
  float runTime; // duration of the displayed run
  int nearMisses; // near misses recorded in the displayed run
  boolean newBest; // whether this run set a new normal best time
  boolean newWorst; // whether this run set a new normal worst time
  boolean nightmareMode; // mode captured by the source gameplay scene
  LevelStats.Entry statsEntry; // persistent record displayed below the result message

  // copies run data from the source scene for result rendering
  Win(Scene source) {
    if (source != null && source.levelKey != null) {
      levelKey = source.levelKey;
      runTime = source.elapsedTime;
      nearMisses = source.nearMissCount;
      nightmareMode = source.nightmareMode;
      newBest = source.statsRecorded && LevelStats.getEntry(app, levelKey).bestTime == runTime;
      newWorst = source.statsRecorded && LevelStats.getEntry(app, levelKey).worstTime == runTime;

      if(newBest && newWorst)
      {
        newWorst = false;
        newBest = true;
      }
      statsEntry = LevelStats.getEntry(app, levelKey);
    }
  }

  // handles result-screen navigation and retry input
  void update() {
    mainMenuButton.loadSceneOnClick(new Menu());
    mazeButton.loadSceneOnClick(new Maze());
    levelMenuButton.loadSceneOnClick(new LevelMenu());
    if (retryButton.isMouseOver() && mousePressed && mouseButton == LEFT) {
      SceneManager.retryLastPlayScene();
    }
  }

  // draws the win headline, stats, and green navigation buttons
  void display() {
    background(0);
    fill(0,255,0);
    textAlign(CENTER, CENTER);
    textSize(32);
    boolean showStats = statsEntry != null;
    text("You Win!", width/2, height/2 - (showStats ? 60 : 0));
    if (showStats) displayResultStats(runTime, nearMisses, newBest, newWorst, statsEntry);
    mainMenuButton.display(color(0, 200, 0));
    mazeButton.display(color(0, 200, 0));
    levelMenuButton.display(color(0, 200, 0));
    retryButton.display(color(0, 200, 0));
  }
}

// result scene shown after the player dies
class Lose extends Scene {
  Button mainMenuButton = new Button(width/2 - 245, height/5 * 3, 100, 50, "Main Menu"); // returns to the main menu
  Button mazeButton = new Button(width/2 - 125, height/5 * 3, 100, 50, "Maze"); // starts another generated maze
  Button levelMenuButton = new Button(width/2 - 5, height/5 * 3, 100, 50, "Level Menu"); // returns to imported levels
  Button retryButton = new Button(width/2 + 115, height/5 * 3, 100, 50, "Retry"); // replays the previous run

  String levelKey; // identifier of the failed level
  float runTime; // duration of the displayed run
  int nearMisses; // near misses recorded in the displayed run
  LevelStats.Entry statsEntry; // persistent record displayed below the result message
  boolean nightmareMode; // mode captured by the source gameplay scene
  String roast = GameSettings.roastsEnabled ? Roasts.random(app) : ""; // optional lose-screen message

  // copies run data from the source scene for result rendering
  Lose(Scene source) {
    if (source != null && source.levelKey != null) {
      levelKey = source.levelKey;
      runTime = source.elapsedTime;
      nearMisses = source.nearMissCount;
      nightmareMode = source.nightmareMode;
      statsEntry = LevelStats.getEntry(app, levelKey);
    }
  }

  // handles result-screen navigation and retry input
  void update() {
    mainMenuButton.loadSceneOnClick(new Menu());
    mazeButton.loadSceneOnClick(new Maze());
    levelMenuButton.loadSceneOnClick(new LevelMenu());
    if (retryButton.isMouseOver() && mousePressed && mouseButton == LEFT) {
      SceneManager.retryLastPlayScene();
    }
  }

  // draws the lose headline, optional roast, stats, and red navigation buttons
  void display() {
    background(0);
    fill(255,0,0);
    textAlign(CENTER, CENTER);
    textSize(32);
    boolean showStats = statsEntry != null;
    text("You Lose!", width/2, height/2 - (showStats ? 95 : 0));
    if (GameSettings.roastsEnabled) {
      textSize(20);
      fill(255, 180, 180);
      text(roast, width/2, height/2 - (showStats ? 60 : -35));
      fill(255, 0, 0);
      textSize(32);
    }
    if (showStats) displayResultStats(runTime, nearMisses, false, false, statsEntry);
    mainMenuButton.display(color(200, 0, 0));
    mazeButton.display(color(200, 0, 0));
    levelMenuButton.display(color(200, 0, 0));
    retryButton.display(color(200, 0, 0));
  }
}

// shared run-summary block drawn on the Win/Lose screens under the headline text:
// this run's time/near-misses plus the level's lifetime best/worst/win-loss record
// styled to match the tutorial's HUD captions: a rounded black box with white text
void displayResultStats(float runTime, int nearMisses, boolean newBest, boolean newWorst, LevelStats.Entry stats) {
  float boxW = min(width - 80, 640);
  float boxH = 145;
  float boxX = width/2 - boxW/2;
  float boxY = height/2 - 40;
  rectMode(CORNER);
  fill(0, 200);
  rect(boxX, boxY, boxW, boxH, 10);

  textAlign(CENTER, CENTER);
  fill(255);
  textSize(20);
  text("Time: " + LevelStats.formatTime(runTime) + (newBest ? "  (New Best!)" : "") + (newWorst ? "  (New Worst?)" : ""), width/2, boxY + 25);
  text("Near Misses This Run: " + nearMisses, width/2, boxY + 55);
  textSize(16);
  text("Best: " + LevelStats.formatTime(stats.bestTime) +
       "   Worst: " + LevelStats.formatTime(stats.worstTime), width/2, boxY + 87);
    text("True Time: " + LevelStats.formatTime(stats.trueTime) +
      "   True Completion: " + stats.trueCompletion, width/2, boxY + 107);
  text("Wins: " + stats.wins + "   Losses: " + stats.losses +
      "   Total Near Misses: " + stats.totalNearMisses, width/2, boxY + 127);
}


class Level extends Scene {
  BlocksManager blocksManager; // collision map built from the imported image
  Player player; // player spawn read from the green image marker
  ArrayList<Enemy> enemies = new ArrayList<Enemy>(); // hand-placed and spawned enemies
  ArrayList<EnemySpawner> spawners = new ArrayList<EnemySpawner>(); // magenta image markers that create enemies
  WinBlock winBlock; // goal created from the yellow image marker
  PImage levelDesign; // original image used to construct this level
        // creates an imported level without a persistent key
        Level(PImage levelDesign){
            this(levelDesign, null);
        }

        // creates an imported level and decodes its colored entity markers
        Level(PImage levelDesign, String levelKey){
            this.levelDesign = levelDesign;
            this.levelKey = levelKey;
            this.levelDisplayName = levelKey;
            blocksManager = new BlocksManager(levelDesign.width * 50, levelDesign.height * 50, 50);

                for (int x = 0; x < levelDesign.width; x++) {
                for (int y = 0; y < levelDesign.height; y++) {
                    color c = levelDesign.get(x, y);
                        if (c == color(0, 255, 0)) {
                        // green pixel = player start position
                        player = new Player(x * 50 + 25, y * 50 + 25, 50, 50, 5);
                    } 
                }
            }

            for (int x = 0; x < levelDesign.width; x++) {
                for (int y = 0; y < levelDesign.height; y++) {
                    color c = levelDesign.get(x, y);
                    if (c == color(255)) {
                        // white pixel = a solid block
                        blocksManager.blocks.add(new Block(x * 50, y * 50, 50, 50));
                    } else if (c == color(0, 0, 255)) {
                      // blue pixel = a wall that only blocks enemies
                      blocksManager.blocks.add(new PlayerOnlyGate(x * 50 + 25, y * 50 + 25, 50, 50));
                    } else if (c == color(255, 0, 0)) {
                        // red pixel = an enemy
                        enemies.add(new Enemy(x * 50 + 25, y * 50 + 25, 40, 40, 3));
                    } else if (c == color(255, 255, 0)) {
                        // yellow pixel = the win block
                        winBlock = new WinBlock(x * 50 + 25, y * 50 + 25, 50, 50, player, this);
                    } else if (c == color(255, 0, 255)) {
                        // magenta pixel = an enemy spawner
                        spawners.add(new EnemySpawner(x * 50 + 25, y * 50 + 25, 50, 50));
                    }
                }
            }
            blocksManager.mergeConnectedBlocks();

            // hand-authored levels aren't generated with a maze algorithm, so verify
            // the player can actually reach every enemy and the win block
            for (Enemy e : enemies) {
              if (!blocksManager.isConnected(new PVector(player.x, player.y), new PVector(e.x, e.y))) {
                println("Warning: an enemy spawn is unreachable from the player start position.");
              }
            }
            if (winBlock != null && !blocksManager.isConnected(new PVector(player.x, player.y), new PVector(winBlock.x, winBlock.y))) {
              println("Warning: the win block is unreachable from the player start position.");
            }
        }

  // advances level gameplay, enemy spawners, death handling, and goal checks
  void update() {
      background(0);
  if (player.dead) {
    player.updateDeath(deltaTime);
    player.updateCamera(deltaTime);
    if (player.deathAnimationDone()) {
      recordLevelResult(false);
      if (GameSettings.autoRestartOnDeath) {
        SceneManager.retryLastPlayScene();
      } else {
        SceneManager.setScene(new Lose(this));
      }
    }
    return;
  }
  elapsedTime += deltaTime;
  player.update(blocksManager, deltaTime);
  player.updateCamera(deltaTime);
  for (Enemy e : enemies) {
    e.update(player, blocksManager, deltaTime);
    if (!player.dead && e.checkNearMiss(player)) nearMissCount++;
  }
  for (EnemySpawner s : spawners) {
    Enemy spawned = s.update(deltaTime);
    if (spawned != null) {
      enemies.add(spawned);
    }
  }
  winBlock.update();
  }

  // draws level geometry, entities, spawners, death effects, and the run timer
  void display() {
    blocksManager.display();
    winBlock.display();
    player.display();
    for (Enemy e : enemies) {
      e.display();
    }
    for (EnemySpawner s : spawners) {
      s.display();
    }
    if (player.dead) displayDeathOverlay(player);
    displayRunTimer(elapsedTime);
  }

  // rebuilds the same imported level for a fresh attempt
  Scene retry() {
    return new Level(levelDesign, levelKey);
  }
}

// full-screen red flash drawn while the death animation (screenshake + explosion) plays
// out; additive blending keeps the green explosion particles visible through the tint
void displayDeathOverlay(Player player) {
  if (!GameSettings.deathFlashEnabled) return;
  resetMatrix();
  noStroke();
  rectMode(CORNER);
  blendMode(ADD);
  fill(180, 0, 0, player.deathRedPulseAlpha());
  rect(0, 0, width, height);
  blendMode(BLEND);
}

// speedrun clock shown top-middle of the screen during Level/Maze gameplay, styled to
// match the tutorial's HUD captions: a rounded black box with white text
void displayRunTimer(float elapsedTime) {
  if (!GameSettings.statsHudEnabled) return;
  resetMatrix();
  String label = LevelStats.formatTime(elapsedTime);
  textSize(28);
  float boxW = textWidth(label) + 40;
  float boxH = 44;
  float boxX = width/2 - boxW/2;
  float boxY = 14;
  rectMode(CORNER);
  fill(0, 200);
  rect(boxX, boxY, boxW, boxH, 10);

  fill(255);
  textAlign(CENTER, CENTER);
  text(label, width/2, boxY + boxH/2);
}


class LevelCard {
  String name; // display name shown below the card image
  PImage image; // original pixel-art level image
  String file; // stable key into LevelLibrary and LevelStats
  PGraphics nightmarePreview; // cached masked preview used while nightmare mode is enabled
  int nightmarePreviewWidth = -1; // width of the cached preview in pixels
  int nightmarePreviewHeight = -1; // height of the cached preview in pixels

  // creates a menu card from a level name, image, and stable file key
  LevelCard(String name, PImage image, String file) {
    this.name = name;
    this.image = image;
    this.file = file;
  }

  // draws the original image normally, or a spotlight-masked nightmare preview
  void displayImage(float x, float y, float drawW, float drawH) {
    if (!GameSettings.nightmareMode) {
      image(image, x, y, drawW, drawH);
      return;
    }

    int previewWidth = max(1, round(drawW));
    int previewHeight = max(1, round(drawH));
    if (nightmarePreview == null || nightmarePreviewWidth != previewWidth || nightmarePreviewHeight != previewHeight) {
      nightmarePreviewWidth = previewWidth;
      nightmarePreviewHeight = previewHeight;
      nightmarePreview = createGraphics(previewWidth, previewHeight, P2D);
      nightmarePreview.noSmooth();
      ((PGraphicsOpenGL) nightmarePreview).textureSampling(2);
      nightmarePreview.beginDraw();
      nightmarePreview.background(0);
      nightmarePreview.image(image, 0, 0, previewWidth, previewHeight);

      PVector playerPosition = findPlayerPosition();
      float playerX = playerPosition.x * previewWidth / image.width;
      float playerY = playerPosition.y * previewHeight / image.height;
      float lightRadius = min(previewWidth, previewHeight) * 0.28;
      lightingShader.set("resolution", (float) previewWidth, (float) previewHeight);
      lightingShader.set("lightCenter", playerX, playerY);
      lightingShader.set("lightRadius", lightRadius);
      lightingShader.set("lightSoftness", lightRadius * 0.45);
      lightingShader.set("dangerAmount", 0.0);
      lightingShader.set("nightmareMode", 1.0);
      nightmarePreview.filter(lightingShader);
      nightmarePreview.endDraw();
    }
    image(nightmarePreview, x, y);
  }

  // finds the average location of green player pixels in the source level image
  PVector findPlayerPosition() {
    image.loadPixels();
    float playerX = 0;
    float playerY = 0;
    int playerPixels = 0;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        color pixel = image.pixels[y * image.width + x];
        if (red(pixel) == 0 && green(pixel) == 255 && blue(pixel) == 0) {
          playerX += x;
          playerY += y;
          playerPixels++;
        }
      }
    }
    if (playerPixels == 0) return new PVector(image.width / 2, image.height / 2);
    return new PVector(playerX / playerPixels, playerY / playerPixels);
  }
}

class LevelMenu extends Scene {
  ArrayList<LevelCard> cards = new ArrayList<LevelCard>(); // imported levels shown in the scrolling grid

  final float cardWidth = 220; // fixed card width used by the responsive grid
  final float cardSpacing = 40; // horizontal and vertical gap between cards
  final float imageHeight = 160; // reserved image area inside each card
  final float playButtonHeight = 50; // height of the card's play control
  final float textHeight = 35; // space reserved for the level name
  final float statsHeight = 76; // space reserved for normal and true stats
  final float cardHeight = imageHeight + 10 + playButtonHeight + textHeight + statsHeight; // total card height
  final float topMargin = 120; // header area kept clear above the card grid

  float scrollY = 0; // current vertical scroll offset
  Button backButton = new Button(30, 30, 100, 50, "Back"); // returns to the main menu
  Button importButton = new Button(width - 220, 30, 190, 50, "Import Level"); // opens the PNG importer

  // loads all registered level cards from the persistent level index
  LevelMenu() {
    JSONArray levels = LevelLibrary.loadIndex(app);
    for (int i = 0; i < levels.size(); i++) {
      JSONObject entry = levels.getJSONObject(i);
      String name = entry.getString("name");
      String file = entry.getString("file");
      PImage img = LevelLibrary.loadLevelImage(app, file);
      cards.add(new LevelCard(name, img, file));
    }
  }

  // number of cards that fit per row given the current screen width
  // calculates how many fixed-width cards fit across the current window
  int columns() {
    return max(1, floor((width + cardSpacing) / (cardWidth + cardSpacing)));
  }

  // calculates the number of rows needed by the card list
  int rows() {
    return ceil(cards.size() / float(columns()));
  }

  // centers the complete card grid horizontally
  float gridStartX() {
    int cols = columns();
    float gridWidth = cols * cardWidth + (cols - 1) * cardSpacing;
    return (width - gridWidth) / 2;
  }

  // returns the x-coordinate for a card index
  float cardX(int index) {
    int col = index % columns();
    return gridStartX() + col * (cardWidth + cardSpacing);
  }

  // returns the y-coordinate for a card index after scrolling
  float cardY(int index) {
    int row = index / columns();
    return topMargin + cardSpacing + row * (cardHeight + cardSpacing) - scrollY;
  }

  // computes the largest scroll offset that keeps the grid reachable
  float maxScroll() {
    float visibleHeight = height - topMargin;
    return max(0, cardSpacing + rows() * (cardHeight + cardSpacing) - visibleHeight);
  }

  // handles dragging, card selection, importing, and the backspace shortcut
  void update() {
    // drag to scroll vertically while the mouse is held down
    if (mousePressed && mouseButton == LEFT) {
      scrollY -= (mouseY - pmouseY);
      scrollY = constrain(scrollY, 0, maxScroll());

      for (int i = 0; i < cards.size(); i++) {
        float x = cardX(i);
        float y = cardY(i);
        float playY = y + imageHeight + 10;
        if (mouseX > x && mouseX < x + cardWidth && mouseY > playY && mouseY < playY + playButtonHeight) {
          SceneManager.setScene(new Level(cards.get(i).image, cards.get(i).file));
        }
      }
    }

    backButton.loadSceneOnClick(new Menu());
    if (importButton.isMouseOver() && mousePressed && mouseButton == LEFT) {
      PImage levelDesign = selectPNGImage();
      if (levelDesign != null) {
        String name = "Level " + (cards.size() + 1);
        String file = LevelLibrary.addLevel(app, levelDesign);
        cards.add(new LevelCard(name, levelDesign, file));
      }
    }

    if (keyCode == BACKSPACE) SceneManager.setScene(new Menu());
  }

  // draws the level grid, card previews, stats, and navigation controls
  void display() {
    background(0);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(32);
    text("Level Menu", width/2, 60);

    for (int i = 0; i < cards.size(); i++) {
      LevelCard card = cards.get(i);
      float x = cardX(i);
      float y = cardY(i);
      if (y + cardHeight < topMargin || y > height) continue; // offscreen, skip drawing

      fill(0);
      rect(x, y, cardWidth, imageHeight);

      float scale = min(cardWidth / card.image.width, imageHeight / card.image.height);
      float drawW = card.image.width * scale;
      float drawH = card.image.height * scale;
      card.displayImage(x + (cardWidth - drawW)/2, y + (imageHeight - drawH)/2, drawW, drawH);

      float playY = y + imageHeight + 10;
      boolean hover = mouseX > x && mouseX < x + cardWidth && mouseY > playY && mouseY < playY + playButtonHeight;
      fill(hover ? color(0, 200, 0) : color(0, 150, 0));
      rect(x, playY, cardWidth, playButtonHeight, 10);
      fill(255);
      textSize(20);
      text("Play", x + cardWidth/2, playY + playButtonHeight/2);

      textSize(16);
      text(card.name, x + cardWidth/2, playY + playButtonHeight + 25);

      // inspectable per-level stats: personal best time, win/loss record, near misses
      LevelStats.Entry stats = LevelStats.getEntry(app, card.file);
      fill(180);
      textSize(13);
      text("Best: " + LevelStats.formatTime(stats.bestTime) + " Worst: " + LevelStats.formatTime(stats.worstTime),
           x + cardWidth/2, playY + playButtonHeight + textHeight + 12);
      text("W: " + stats.wins + " L: " + stats.losses + "Near Misses: " + stats.totalNearMisses, x + cardWidth/2, playY + playButtonHeight + textHeight + 30);
       text("True Time: " + LevelStats.formatTime(stats.trueTime), x + cardWidth/2, playY + playButtonHeight + textHeight + 48);
       text("True Completion: " + stats.trueCompletion, x + cardWidth/2, playY + playButtonHeight + textHeight + 64);
    }

    fill(200);
    backButton.display();
    fill(200);
    importButton.display();
  }

  // applies mouse-wheel scrolling while keeping the offset inside its valid range
  void mouseWheel(float delta) {
    scrollY += delta * 40;
    scrollY = constrain(scrollY, 0, maxScroll());
  }
}
