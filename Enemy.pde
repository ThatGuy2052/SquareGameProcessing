class Enemy {
  float x, y; // world-space center position
  float w, h; // collision and rendering footprint
  float speed; // movement speed in world units per frame-scale step

  ArrayList<PVector> path; // current smoothed route toward the player
  int pathIndex; // waypoint currently being followed
  float repathTimer; // countdown until the route gets rebuilt
  float repathInterval = 0.1; // rebuild ten times a second so waypoints can actually be reached

  // near-miss tracking: edge-triggered with hysteresis so lingering just outside the
  // catch box doesn't spam a new "near miss" every frame
  final float nearMissRadius = 55; // distance that starts one near-miss event
  final float nearMissResetRadius = 100; // distance required before another near miss can count
  boolean nearPlayer = false; // hysteresis state that stops repeated counts while lingering nearby

  // creates an enemy and applies the smaller, faster nightmare-mode profile when enabled
  Enemy(float x, float y, float w, float h, float speed) {
    this.x = x;
    this.y = y;
    this.w = GameSettings.nightmareMode ? 30 : w;
    this.h = GameSettings.nightmareMode ? 30 : h;
    this.speed = GameSettings.nightmareMode ? 4.5 : speed;
    path = new ArrayList<PVector>();
    pathIndex = 0;
    repathTimer = 0;
  }

  void update(Player player, BlocksManager blocksManager, float deltaTime) {
    repathTimer -= deltaTime;

    // gate solely on the timer so finishing a path early can't force a rebuild before the
    // next scheduled 10fps tick - the enemy just holds at the last waypoint until then
    if (repathTimer <= 0) {
      buildPath(player, blocksManager);
      repathTimer = repathInterval;
    }

    if (!path.isEmpty() && pathIndex < path.size()) {
      PVector target = path.get(pathIndex);
      float d = dist(x, y, target.x, target.y);
      if (d < speed * deltaTime * 60) {
        pathIndex++;
      } else {
        moveToward(target.x, target.y, blocksManager, deltaTime);
      }
    }

    if(abs(x - player.x) < w && abs(y - player.y) < h) {
      onCaughtPlayer(player);
    }
  }

  // overridable so special contexts (e.g. the tutorial) can react without ending the game
  void onCaughtPlayer(Player player) {
    player.startDeath();
  }

  // returns true once when the enemy first comes within nearMissRadius of the player,
  // resetting only once it backs off past nearMissResetRadius (hysteresis)
  boolean checkNearMiss(Player player) {
    float d = dist(x, y, player.x, player.y);
    if (!nearPlayer && d < nearMissRadius) {
      nearPlayer = true;
      return true;
    }
    if (nearPlayer && d > nearMissResetRadius) {
      nearPlayer = false;
    }
    return false;
  }

  void moveToward(float tx, float ty, BlocksManager blocksManager, float deltaTime) {
    float dx = tx - x;
    float dy = ty - y;
    float len = sqrt(dx * dx + dy * dy);
    if (len == 0) return;
    float movement = speed * deltaTime * 60;
    dx = dx / len * movement;
    dy = dy / len * movement;

    // at a corner, resolving one axis first can make the other axis look blocked
    // try both slide orders and keep whichever makes the most progress toward the waypoint
    float xFirst = blocksManager.resolveX(x, y, w, h, x + dx, true);
    float xFirstY = blocksManager.resolveY(xFirst, y, w, h, y + dy, true);

    float yFirstY = blocksManager.resolveY(x, y, w, h, y + dy, true);
    float yFirstX = blocksManager.resolveX(x, yFirstY, w, h, x + dx, true);

    float xFirstDistance = dist(xFirst, xFirstY, tx, ty);
    float yFirstDistance = dist(yFirstX, yFirstY, tx, ty);
    if (xFirstDistance <= yFirstDistance) {
      x = xFirst;
      y = xFirstY;
    } else {
      x = yFirstX;
      y = yFirstY;
    }
  }

  // builds a path via a cheap grid BFS (cost independent of block count), then string-pulls
  // it into fewer, smoother waypoints using line-of-sight checks against nearby blocks only
  // (an earlier version built a visibility graph over every block corner and ran Dijkstra on
  // it, which cost roughly O(blocks^3) per repath -- fine for a few dozen blocks, but a maze's
  // hundreds of wall blocks made it repath into hundreds of millions of ops, 10x/sec/enemy)
  int smoothLookahead = 30; // cap how far ahead we scan for a shortcut, to bound worst-case cost

  void buildPath(Player player, BlocksManager blocksManager) {
    path.clear();
    pathIndex = 0;

    ArrayList<PVector> cellPath = blocksManager.findCellPath(x, y, player.x, player.y, true);
    if (cellPath.isEmpty()) return;

    float fromX = x, fromY = y;
    int i = 0;
    while (i < cellPath.size()) {
      int limit = min(cellPath.size() - 1, i + smoothLookahead);
      int farthest = i;
      for (int j = limit; j > i; j--) {
        if (hasLineOfSight(fromX, fromY, cellPath.get(j).x, cellPath.get(j).y, blocksManager)) {
          farthest = j;
          break;
        }
      }
      PVector wp = cellPath.get(farthest);
      path.add(wp);
      fromX = wp.x;
      fromY = wp.y;
      i = farthest + 1;
    }
  }

  // checks whether a straight line between two points is unobstructed by any block, treating
  // each block as inflated by the enemy's half-size so its own footprint (not just its center)
  // is guaranteed to clear the block. this also naturally blocks paths that thread through a
  // diagonal gap between two separate blocks too narrow for the enemy to actually fit through
  boolean hasLineOfSight(float x1, float y1, float x2, float y2, BlocksManager blocksManager) {
    for (Block b : blocksManager.getBlocks()) {
      if (!b.blocksEnemies()) continue;
      if (segmentIntersectsInflatedBlock(x1, y1, x2, y2, b)) {
        return false;
      }
    }
    return true;
  }

  boolean segmentIntersectsInflatedBlock(float x1, float y1, float x2, float y2, Block b) {
    // shrink slightly so resting flush against a block (a common, valid state after collision
    // resolution) isn't itself treated as blocked, which used to freeze the enemy with nowhere to go
    float shrink = 0.5;
    float minX = b.min.x - w / 2 + shrink;
    float minY = b.min.y - h / 2 + shrink;
    float maxX = b.max.x + w / 2 - shrink;
    float maxY = b.max.y + h / 2 - shrink;
    return segmentIntersectsRect(x1, y1, x2, y2, minX, minY, maxX, maxY);
  }

  // liang-barsky segment vs axis-aligned rectangle intersection test
  boolean segmentIntersectsRect(float x1, float y1, float x2, float y2,
                                 float minX, float minY, float maxX, float maxY) {
    float dx = x2 - x1;
    float dy = y2 - y1;
    float tMin = 0, tMax = 1;

    float[] p = {-dx, dx, -dy, dy};
    float[] q = {x1 - minX, maxX - x1, y1 - minY, maxY - y1};

    for (int i = 0; i < 4; i++) {
      if (p[i] == 0) {
        if (q[i] < 0) return false; // parallel to this boundary and outside it
      } else {
        float t = q[i] / p[i];
        if (p[i] < 0) {
          if (t > tMax) return false;
          if (t > tMin) tMin = t;
        } else {
          if (t < tMin) return false;
          if (t < tMax) tMax = t;
        }
      }
    }
    return true;
  }

  void display() {
    rectMode(CENTER);
    fill(200, 30, 30);
    rect(x, y, w, h);
  }
}
