

static class SceneManager {
  // the scene whose update and display methods run during the current frame
  static Scene currentScene;
  // remembers the most recent Maze/Level scene so Win/Lose retry buttons and the
  // hold-R-to-restart shortcut know what to reload
  static Scene lastPlayScene;


  // makes a scene active and remembers it if it's retryable gameplay
  static void setScene(Scene scene) {
    currentScene = scene;
    if (scene instanceof Maze || scene instanceof Level) {
      lastPlayScene = scene;
    }
  }

  // recreates the most recent level or maze for the retry controls and shortcut
  static void retryLastPlayScene() {
    if (lastPlayScene != null) {
      Scene retryScene = lastPlayScene.retry();
      if (retryScene != null) setScene(retryScene);
    }
  }

  // sends the frame update to the active scene
  static void update() {
    if (currentScene != null) {
      currentScene.update();
    }
  }

  // sends the frame draw call to the active scene
  static void display() {
    if (currentScene != null) {
      currentScene.display();
    }
  }

  // forwards scrollwheel input to whatever scene is currently active
  static void mouseWheel(float delta) {
    if (currentScene != null) {
      currentScene.mouseWheel(delta);
    }
  }
}

class Scene {

  // speedrun/stats tracking, opted into by Level and Maze via levelKey - left null
  // (and therefore ignored by recordLevelResult) for menus/Tutorial/Win/Lose
  String levelKey = null; // stable identifier used to store this scene's level stats
  String levelDisplayName = null; // human-readable name used by scenes that display a level title
  float elapsedTime = 0; // seconds elapsed since this scene's run began
  int nearMissCount = 0; // number of enemy near misses recorded during this run
  boolean statsRecorded = false; // stops retries or auto-restarts from recording the same result twice
  boolean nightmareMode = GameSettings.nightmareMode; // captures the mode at run start so later setting changes can't alter the record

  // base constructor for menus and gameplay scenes
  Scene(){ }

  // update hook used by the scene manager
  void update() {
    // subclasses override this to run their own update logic
  }

  // returns a new scene for retryable gameplay, menus just return null by default
  Scene retry() {
    return null;
  }

  // display hook used by the scene manager
  void display() {
    // subclasses override this to draw their own content
  }

  // scroll-wheel hook used by scenes that support scrolling
  void mouseWheel(float delta) {
    // subclasses override this to handle scroll input
  }

  // saves this run's outcome to LevelStats exactly once, guarded so the auto-restart
  // path (which never shows the Lose screen) still records a loss
  void recordLevelResult(boolean won) {
    if (levelKey == null || statsRecorded) return;
    statsRecorded = true;
    LevelStats.recordRun(app, levelKey, won, elapsedTime, nearMissCount, nightmareMode);
  }
}