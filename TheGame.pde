import processing.opengl.PGraphicsOpenGL;

PApplet app; // shared Processing application reference used by persistence helpers
PShader crtShader; // shader that adds the CRT display effect
PShader bloomShader; // shader that adds glow around bright pixels
PShader lightingShader; // shader that masks the world around the player
float deltaTime = 1.0 / 60.0; // time since the previous frame, capped for stability
int previousFrameMillis; // timestamp used to calculate deltaTime
final float escHoldToMenuSeconds = 1.0; // hold duration required to return to the menu
long escHoldStartMillis = -1; // start timestamp for the escape hold gesture
final float shiftEscHoldToExitSeconds = 2.5; // hold duration required to exit with Shift+Esc
long shiftEscHoldStartMillis = -1; // start timestamp for the Shift+Esc hold gesture
final float rHoldToRestartSeconds = 1.0; // hold duration required to restart a run
long rHoldStartMillis = -1; // start timestamp for the restart hold gesture
boolean exiting = false; // keeps us from firing duplicate exit requests


// loads the opengl renderer, settings, shaders, and the menu scene
void setup() {
//   size(800, 600);
fullScreen(P2D); // shaders need a GL renderer; this must be the first line so Processing can size the surface before setup() runs
  app = this;

  // JOGL's window isn't DPI-aware like Java2D was, so force it to the true display pixel size/position
  surface.setLocation(0, 0);
  surface.setSize(displayWidth, displayHeight);
  previousFrameMillis = millis();

  noStroke();
  noSmooth(); // nearest-neighbor scaling so pixel art stays crisp
  // noSmooth() only disables shape/line antialiasing in P2D - images still need point sampling set explicitly
  ((PGraphicsOpenGL) g).textureSampling(2);

  GameSettings.load(app);
  LevelStats.load(app);
  crtShader = loadShader(sketchPath("shaders/crt.glsl"));
  bloomShader = loadShader(sketchPath("shaders/bloom.glsl"));
  lightingShader = loadShader(sketchPath("shaders/lighting.glsl"));

  SceneManager.setScene(new Menu());
}

// updates the hotkey overlays (hold to: main menu, restart, exit game), scene state, camera rendering, post-processing, and overlays every frame
void draw() {
  int currentMillis = millis();
  deltaTime = min((currentMillis - previousFrameMillis) / 1000.0, 0.1);
  previousFrameMillis = currentMillis;

  boolean showEscOverlay = false;
  float escHeldSeconds = 0;
  boolean showShiftEscOverlay = false;
  float shiftEscHeldSeconds = 0;
  if (esc && shift) {
    if (shiftEscHoldStartMillis < 0) shiftEscHoldStartMillis = millis();
    shiftEscHeldSeconds = (millis() - shiftEscHoldStartMillis) / 1000.0;
    if (shiftEscHeldSeconds >= shiftEscHoldToExitSeconds) {
      exiting = true;
      exit();
      return;
    }
    escHoldStartMillis = -1;
    showShiftEscOverlay = true;
  } else {
    shiftEscHoldStartMillis = -1;
  }

  if (esc && !shift && !(SceneManager.currentScene instanceof Menu)) {
    if (escHoldStartMillis < 0) escHoldStartMillis = millis();
    escHeldSeconds = (millis() - escHoldStartMillis) / 1000.0;
    if (escHeldSeconds >= escHoldToMenuSeconds) {
      SceneManager.setScene(new Menu());
      escHoldStartMillis = -1;
    } else {
      showEscOverlay = true;
    }
  } else {
    escHoldStartMillis = -1;
  }

  boolean showRestartOverlay = false;
  float rHeldSeconds = 0;
  boolean inPlayScene = SceneManager.currentScene instanceof Maze || SceneManager.currentScene instanceof Level;
  if (r && inPlayScene) {
    if (rHoldStartMillis < 0) rHoldStartMillis = millis();
    rHeldSeconds = (millis() - rHoldStartMillis) / 1000.0;
    if (rHeldSeconds >= rHoldToRestartSeconds) {
      SceneManager.retryLastPlayScene();
      rHoldStartMillis = -1;
    } else {
      showRestartOverlay = true;
    }
  } else {
    rHoldStartMillis = -1;
  }

  SceneManager.update();//this is cool [:
  SceneManager.display();

  Player activePlayer = null;
  ArrayList<Enemy> activeEnemies = null;
  if (SceneManager.currentScene instanceof Maze) {
    Maze maze = (Maze) SceneManager.currentScene;
    activePlayer = maze.player;
    activeEnemies = maze.enemies;
  } else if (SceneManager.currentScene instanceof Level) {
    Level level = (Level) SceneManager.currentScene;
    activePlayer = level.player;
    activeEnemies = level.enemies;
  }

  if ((GameSettings.lightingEnabled || GameSettings.nightmareMode) && activePlayer != null) {
    // use the position captured while the player was rendered with the active camera
    float playerScreenX = activePlayer.screenPositionX;
    float playerScreenY = activePlayer.screenPositionY;
    float nearestEnemyDistance = 1000000;
    if (activeEnemies != null) {
      for (Enemy enemy : activeEnemies) {
        nearestEnemyDistance = min(nearestEnemyDistance, dist(activePlayer.x, activePlayer.y, enemy.x, enemy.y));
      }
    }
    float dangerAmount = 0;
    if (GameSettings.dangerEdgesEnabled) {
      dangerAmount = 1.0 - constrain(nearestEnemyDistance / 300.0, 0, 1);
      dangerAmount = dangerAmount * dangerAmount;
    }

    lightingShader.set("resolution", (float) width, (float) height);
    lightingShader.set("lightCenter", playerScreenX, playerScreenY);
    lightingShader.set("lightRadius", 185.0);
    lightingShader.set("lightSoftness", 145.0);
    lightingShader.set("dangerAmount", dangerAmount);
    lightingShader.set("nightmareMode", GameSettings.nightmareMode ? 1.0 : 0.0);
    filter(lightingShader);
  }

  if (GameSettings.bloomEnabled) {
    bloomShader.set("resolution", (float) width, (float) height);
    bloomShader.set("bloomStrength", 0.6);
    filter(bloomShader);
  }

  if (GameSettings.crtEnabled) {
    crtShader.set("resolution", (float) width, (float) height);
    filter(crtShader);
  }

  if (GameSettings.nightmareMode) {
    resetMatrix();
    fill(255, 0, 0, 190);
    textAlign(RIGHT, TOP);
    textSize(18);
    text("NIGHTMARE MODE", width - 20, 20);
  }

  if (showEscOverlay) {
    resetMatrix(); // camera()'s reset doesn't reliably undo player.updateCamera()'s beginCamera/translate/endCamera in P2D - resetMatrix() clears it outright
    fill(255);
    textAlign(LEFT, TOP);
    textSize(20);
    text("Returning to menu in " +  nf(max(escHoldToMenuSeconds - escHeldSeconds, 0), 1, 1) + "...", 20, 20);
  }

  if (showRestartOverlay) {
    resetMatrix();
    fill(255);
    textAlign(LEFT, TOP);
    textSize(20);
    text("Restarting in " + nf(max(rHoldToRestartSeconds - rHeldSeconds, 0), 1, 1) + "...", 20, 50);
  }

  if (showShiftEscOverlay) {
    resetMatrix();
    fill(255);
    textAlign(LEFT, TOP);
    textSize(20);
    text("Exiting in " + nf(max(shiftEscHoldToExitSeconds - shiftEscHeldSeconds, 0), 1, 1) + "...", 20, 80);
  }

}

void mouseWheel(MouseEvent event) {
  SceneManager.mouseWheel(event.getCount());
}

void exit() {
  if (!exiting) return;
  super.exit();
}