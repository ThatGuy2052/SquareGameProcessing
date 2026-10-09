// a map marker (pure magenta in level images) that periodically spawns a new enemy
// at its own position, on a randomized cooldown so spawns don't feel mechanical
class EnemySpawner {
  float x, y, w, h; // world-space marker bounds and spawn position
  float minInterval = 8; // shortest delay between enemy spawns in seconds
  float maxInterval = 16; // longest delay between enemy spawns in seconds
  float timer; // remaining time until the next enemy gets created

  // creates a spawner at a level marker's position
  EnemySpawner(float x, float y, float w, float h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    resetTimer();
  }

  // picks a new randomized cooldown after every spawn
  void resetTimer() {
    timer = random(minInterval, maxInterval);
  }

  // returns a freshly spawned Enemy once the cooldown runs out, otherwise null
  // counts down the cooldown and returns an enemy once the timer expires
  Enemy update(float deltaTime) {
    timer -= deltaTime;
    if (timer <= 0) {
      resetTimer();
      return spawnEnemy();
    }
    return null;
  }

  // overridable so special contexts (e.g. the tutorial) can spawn a different Enemy subclass
  // factory method that subclasses override for tutorial-specific enemies
  Enemy spawnEnemy() {
    return new Enemy(x, y, 40, 40, 3);
  }

  // draws the magenta marker that identifies the spawner in the level
  void display() {
    rectMode(CENTER);
    fill(128, 0, 128); // purple
    rect(x, y, w, h);
  }
}
