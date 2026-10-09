class BlocksManager {
  ArrayList<Block> blocks; // collision and rendering blocks that make up the current level
  int blockSize; // width and height of one logical grid cell in world units
  int cols, rows; // number of logical grid cells across and down the level
  int screenW, screenH; // world dimensions used to build the grid
  PShape blocksShape; // cached batched geometry, rebuilt only when the block set changes

  BlocksManager(int screenW, int screenH, int blockSize) {
    // derive the logical grid once so every later collision and path query uses the same coords
    this.screenW = screenW;
    this.screenH = screenH;
    this.blockSize = blockSize;
    this.cols = screenW / blockSize;
    this.rows = screenH / blockSize;
    blocks = new ArrayList<Block>();
  }

  // carves a real maze using a recursive backtracker (randomized DFS) so every open
  // cell is guaranteed reachable from every other open cell (a perfect maze),
  // then braids in a handful of extra connections so there are some alternate routes   
  void generateMaze() {
    generateMaze(0.12);
  }

  // braidChance: odds (0-1) that a wall between two already-connected neighboring
  // cells gets knocked down too, adding loops/branches on top of the base spanning tree
  void generateMaze(float braidChance) {
    blocks.clear();

    // maze cells occupy every other grid coordinate, leaving the in-between coordinates for walls
    int mazeCols = max(1, (cols - 1) / 2);
    int mazeRows = max(1, (rows - 1) / 2);

    boolean[][] visited = new boolean[mazeCols][mazeRows]; // tracks cells already reached by the carving walk
    boolean[][] openGrid = new boolean[cols][rows]; // true for floor cells and carved passages

    int[] dx = {1, -1, 0, 0};
    int[] dy = {0, 0, 1, -1};

    ArrayList<int[]> stack = new ArrayList<int[]>(); // explicit DFS stack used instead of recursive calls
    visited[0][0] = true;
    openGrid[mazeToGrid(0)][mazeToGrid(0)] = true;
    stack.add(new int[]{0, 0});

    while (!stack.isEmpty()) {
      // the top stack entry is the current dead-end or frontier cell
      int[] current = stack.get(stack.size() - 1);
      int cx = current[0];
      int cy = current[1];

      ArrayList<Integer> dirs = new ArrayList<Integer>();
      for (int d = 0; d < 4; d++) dirs.add(d);
      java.util.Collections.shuffle(dirs);

      boolean carved = false;
      for (int d : dirs) {
        // shuffle directions so each generated maze gets a different corridor layout
        int nx = cx + dx[d];
        int ny = cy + dy[d];
        if (nx >= 0 && nx < mazeCols && ny >= 0 && ny < mazeRows && !visited[nx][ny]) {
          visited[nx][ny] = true;

          int gx1 = mazeToGrid(cx);
          int gy1 = mazeToGrid(cy);
          int gx2 = mazeToGrid(nx);
          int gy2 = mazeToGrid(ny);

          openGrid[gx1][gy1] = true;
          // opening the midpoint removes the wall between the two logical maze cells
          openGrid[(gx1 + gx2) / 2][(gy1 + gy2) / 2] = true;
          openGrid[gx2][gy2] = true;

          stack.add(new int[]{nx, ny});
          carved = true;
          break;
        }
      }

      // no unvisited neighbor means this branch is done, so backtrack one cell
      if (!carved) stack.remove(stack.size() - 1);
    }

    // braiding pass: randomly knock down a few more inter-cell walls to create loops,
    // so the maze has some branching alternate paths instead of being one single trail
    for (int mx = 0; mx < mazeCols; mx++) {
      for (int my = 0; my < mazeRows; my++) {
        if (mx + 1 < mazeCols) {
          int wallX = mazeToGrid(mx) + 1;
          int wallY = mazeToGrid(my);
          if (!openGrid[wallX][wallY] && random(1) < braidChance) {
            openGrid[wallX][wallY] = true;
          }
        }
        if (my + 1 < mazeRows) {
          int wallX = mazeToGrid(mx);
          int wallY = mazeToGrid(my) + 1;
          if (!openGrid[wallX][wallY] && random(1) < braidChance) {
            openGrid[wallX][wallY] = true;
          }
        }
      }
    }

    for (int gx = 0; gx < cols; gx++) {
      for (int gy = 0; gy < rows; gy++) {
        // every grid cell not marked open becomes a solid collision block
        if (!openGrid[gx][gy]) {
          blocks.add(new Block(gx * blockSize + blockSize / 2.0, gy * blockSize + blockSize / 2.0, blockSize, blockSize));
        }
      }
    }
  }

  // maps a logical maze-cell coordinate to its position on the full wall/floor grid
  int mazeToGrid(int mazeCoord) {
    // odd coordinates keep logical maze cells separated by one-cell-thick walls
    return mazeCoord * 2 + 1;
  }

  boolean isCellBlocked(int gx, int gy) {
    return isCellBlocked(gx, gy, false);
  }

  boolean isCellBlocked(int gx, int gy, boolean enemiesCanPass) {
    // treat outside-grid queries as walls so pathfinding can't leave the level
    if (gx < 0 || gx >= cols || gy < 0 || gy >= rows) return true;
    return checkCollision(gx * blockSize, gy * blockSize, blockSize, blockSize, enemiesCanPass);
  }

  // world-space centers of every non-blocked grid cell, usable as spawn candidates
  ArrayList<PVector> getOpenCellCenters() {
    ArrayList<PVector> cells = new ArrayList<PVector>();
    // convert every walkable grid coordinate back to its world-space center
    for (int gx = 0; gx < cols; gx++) {
      for (int gy = 0; gy < rows; gy++) {
        if (!isCellBlocked(gx, gy)) {
          cells.add(new PVector(gx * blockSize + blockSize / 2.0, gy * blockSize + blockSize / 2.0));
        }
      }
    }
    return cells;
  }

  // picks whichever candidate cell is farthest from the reference point (simple spread-out spawn heuristic)
  PVector pickFarCell(ArrayList<PVector> cells, PVector reference) {
    PVector best = cells.get(0);
    float bestDist = -1;
    for (PVector c : cells) {
      float d = PVector.dist(c, reference);
      if (d > bestDist) {
        bestDist = d;
        best = c;
      }
    }
    return best;
  }

  // BFS reachability check between two world positions, walking grid cell to grid cell
  // works regardless of how the blocks were created (generated maze or hand-authored level)
  boolean isConnected(PVector a, PVector b) {
    // convert world positions to grid coords before running the reachability search
    int ax = floor(a.x / blockSize);
    int ay = floor(a.y / blockSize);
    int bx = floor(b.x / blockSize);
    int by = floor(b.y / blockSize);

    if (isCellBlocked(ax, ay) || isCellBlocked(bx, by)) return false;
    if (ax == bx && ay == by) return true;

    boolean[][] visited = new boolean[cols][rows]; // stops us revisiting cells and guarantees finite work
    visited[ax][ay] = true;
    java.util.LinkedList<int[]> queue = new java.util.LinkedList<int[]>(); // FIFO frontier for breadth-first traversal
    queue.add(new int[]{ax, ay});

    int[] dx = {1, -1, 0, 0};
    int[] dy = {0, 0, 1, -1};

    while (!queue.isEmpty()) {
      // expand the oldest frontier cell so the first discovery of the target is the shortest
      int[] cur = queue.poll();
      for (int d = 0; d < 4; d++) {
        int nx = cur[0] + dx[d];
        int ny = cur[1] + dy[d];
        if (nx < 0 || nx >= cols || ny < 0 || ny >= rows) continue;
        if (visited[nx][ny] || isCellBlocked(nx, ny)) continue;
        if (nx == bx && ny == by) return true;
        visited[nx][ny] = true;
        queue.add(new int[]{nx, ny});
      }
    }
    return false;
  }

  // BFS shortest path over grid cells, returning cell-center waypoints from just after the
  // start cell to the goal cell (empty if unreachable). cost is O(cols*rows) regardless of
  // block count, unlike a visibility graph built from every block's corners
  ArrayList<PVector> findCellPath(float sx, float sy, float gx, float gy) {
    return findCellPath(sx, sy, gx, gy, false);
  }

  ArrayList<PVector> findCellPath(float sx, float sy, float gx, float gy, boolean enemiesCanPass) {
    ArrayList<PVector> result = new ArrayList<PVector>();

    // convert the start and goal from world positions to grid cells
    int ax = floor(sx / blockSize);
    int ay = floor(sy / blockSize);
    int bx = floor(gx / blockSize);
    int by = floor(gy / blockSize);

    if (isCellBlocked(ax, ay, enemiesCanPass) || isCellBlocked(bx, by, enemiesCanPass)) return result;
    if (ax == bx && ay == by) return result;

    int[][] prevX = new int[cols][rows]; // stores each cell's predecessor x coord
    int[][] prevY = new int[cols][rows]; // stores each cell's predecessor y coord
    boolean[][] visited = new boolean[cols][rows]; // marks cells already added to the BFS frontier
    visited[ax][ay] = true;

    java.util.LinkedList<int[]> queue = new java.util.LinkedList<int[]>(); // FIFO queue that produces a shortest path
    queue.add(new int[]{ax, ay});

    int[] dx = {1, -1, 0, 0};
    int[] dy = {0, 0, 1, -1};

    boolean found = false;
    while (!queue.isEmpty() && !found) {
      int[] cur = queue.poll();
      for (int d = 0; d < 4 && !found; d++) {
        int nx = cur[0] + dx[d];
        int ny = cur[1] + dy[d];
        if (nx < 0 || nx >= cols || ny < 0 || ny >= rows) continue;
        if (visited[nx][ny] || isCellBlocked(nx, ny, enemiesCanPass)) continue;
        visited[nx][ny] = true;
        prevX[nx][ny] = cur[0];
        prevY[nx][ny] = cur[1];
        if (nx == bx && ny == by) found = true;
        queue.add(new int[]{nx, ny});
      }
    }

    if (!visited[bx][by]) return result;

    // follow predecessor links backward from the goal, then reverse them into travel order
    ArrayList<int[]> cells = new ArrayList<int[]>();
    int cx = bx, cy = by;
    while (!(cx == ax && cy == ay)) {
      cells.add(new int[]{cx, cy});
      int px = prevX[cx][cy];
      int py = prevY[cx][cy];
      cx = px;
      cy = py;
    }
    java.util.Collections.reverse(cells);

    for (int[] c : cells) {
      result.add(new PVector(c[0] * blockSize + blockSize / 2.0, c[1] * blockSize + blockSize / 2.0));
    }
    return result;
  }

  void display() {
    // a rebuilt group shape avoids issuing one draw call per individual wall block
    if (blocksShape != null) {
      shape(blocksShape);
    }
  }

  // combines every block into one PShape so the whole level draws in a single call
  // instead of a beginShape/vertex/endShape sequence per block, per frame
  void rebuildShape() {
    blocksShape = createShape(GROUP);
    // cache each block's immutable geometry inside one drawable group
    for (Block b : blocks) {
      blocksShape.addChild(b.buildShape());
    }
  }

  void clear() {
    blocks.clear();
    blocksShape = null;
  }

  int count() {
    return blocks.size();
  }

  ArrayList<Block> getBlocks() {
    return blocks;
  }

  boolean checkCollision(float x, float y, float w, float h) {
    return checkCollision(x, y, w, h, false);
  }

  boolean checkCollision(float x, float y, float w, float h, boolean enemiesCanPass) {
    // pick the collision rule based on whether the moving object is the player or an enemy
    for (Block b : blocks) {
      if (enemiesCanPass && !b.blocksEnemies()) continue;
      if (!enemiesCanPass && !b.blocksPlayer()) continue;
      if (b.collidesWith(x, y, w, h)) {
        return true;
      }
    }
    return false;
  }

  // resolves horizontal movement, clamping to the touching edge of any blocking block
  float resolveX(float x, float y, float w, float h, float newX) {
    return resolveX(x, y, w, h, newX, false);
  }

  float resolveX(float x, float y, float w, float h, float newX, boolean enemiesCanPass) {
    // clamp against every intersected block so sliding along multiple walls stays stable
    for (Block b : blocks) {
      if (enemiesCanPass && !b.blocksEnemies()) continue;
      if (!enemiesCanPass && !b.blocksPlayer()) continue;
      if (b.collidesWith(newX - w/2, y - h/2, w, h)) {
        if (newX > x) {
          newX = min(newX, b.min.x - w/2);
        } else if (newX < x) {
          newX = max(newX, b.max.x + w/2);
        }
      }
    }
    return newX;
  }

  // resolves vertical movement, clamping to the touching edge of any blocking block
  float resolveY(float x, float y, float w, float h, float newY) {
    return resolveY(x, y, w, h, newY, false);
  }

  float resolveY(float x, float y, float w, float h, float newY, boolean enemiesCanPass) {
    // apply the same clamping strategy independently on the vertical axis
    for (Block b : blocks) {
      if (enemiesCanPass && !b.blocksEnemies()) continue;
      if (!enemiesCanPass && !b.blocksPlayer()) continue;
      if (b.collidesWith(x - w/2, newY - h/2, w, h)) {
        if (newY > y) {
          newY = min(newY, b.min.y - h/2);
        } else if (newY < y) {
          newY = max(newY, b.max.y + h/2);
        }
      }
    }
    return newY;
  }

  // merges grid-adjacent blocks into fewer, larger rectangle blocks
  void mergeConnectedBlocks() {
    if (blocks.isEmpty()) return;

    boolean[][] occupied = new boolean[cols][rows]; // grid cells covered by mergeable blocks
    ArrayList<Block> unmerged = new ArrayList<Block>(); // special blocks that have to keep their own shape
    for (Block b : blocks) {
      if (!b.canMerge()) {
        unmerged.add(b);
        continue;
      }
      int gx = round(b.min.x / blockSize);
      int gy = round(b.min.y / blockSize);
      int gw = round((b.max.x - b.min.x) / blockSize);
      int gh = round((b.max.y - b.min.y) / blockSize);
      for (int ix = gx; ix < gx + gw; ix++) {
        for (int iy = gy; iy < gy + gh; iy++) {
          if (ix >= 0 && ix < cols && iy >= 0 && iy < rows) {
            occupied[ix][iy] = true;
          }
        }
      }
    }

    boolean[][] used = new boolean[cols][rows]; // stops a cell from entering more than one merged rectangle
    ArrayList<Block> merged = new ArrayList<Block>(); // replacement rectangles built from contiguous occupancy

    for (int gx = 0; gx < cols; gx++) {
      for (int gy = 0; gy < rows; gy++) {
        if (!occupied[gx][gy] || used[gx][gy]) continue;

        // grow the rectangle right as far as possible before testing additional rows
        int w = 1;
        while (gx + w < cols && occupied[gx + w][gy] && !used[gx + w][gy]) {
          w++;
        }

        // grow downward only while every cell in the proposed row is still available
        int h = 1;
        while (gy + h < rows) {
          boolean rowFree = true;
          for (int ix = gx; ix < gx + w; ix++) {
            if (!occupied[ix][gy + h] || used[ix][gy + h]) {
              rowFree = false;
              break;
            }
          }
          if (!rowFree) break;
          h++;
        }

        for (int ix = gx; ix < gx + w; ix++) {
          for (int iy = gy; iy < gy + h; iy++) {
            used[ix][iy] = true;
          }
        }

        float x = (gx + w / 2.0) * blockSize;
        float y = (gy + h / 2.0) * blockSize;
        merged.add(new Block(x, y, w * blockSize, h * blockSize));
      }
    }

    merged.addAll(unmerged);
    blocks = merged;
    rebuildShape();
  }
}
