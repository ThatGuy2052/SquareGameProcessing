// the yellow goal block that completes the current level when the player touches it
class WinBlock {
  float x, y, w, h; // world-space bounds of the goal block
  Player player; // player whose position we check against the goal
  Scene sourceScene; // gameplay scene that owns the run and its stats

  // stores the goal bounds, the player for collision checks, and the scene that owns the run
  WinBlock(float x, float y, float w, float h, Player player, Scene sourceScene) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.player = player;
    this.sourceScene = sourceScene;
  }

  // checks for an overlap and records the win before switching to the result screen
  void update() {
    boolean overlapsX = abs(x - player.x) < (w + player.w) / 2;
    boolean overlapsY = abs(y - player.y) < (h + player.h) / 2;
    if (overlapsX && overlapsY) {
      if (sourceScene != null) sourceScene.recordLevelResult(true);
      SceneManager.setScene(new Win(sourceScene));
    }
  }

  // draws the goal as a yellow rectangle in world coords
  void display() {
    fill(255, 255, 0);
    rectMode(CENTER);
    rect(x, y, w, h);
  }
}