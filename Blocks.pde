class Block {
  PVector[] points; // polygon vertices used for drawing and collision bounds
  PVector min, max; // axis-aligned bounding box, derived from points

  // creates a block from any polygon vertex list and computes its bounds
  // supports any number of vertices (triangle, pentagon, arbitrary polygon, etc)
  Block(PVector... points) {
    this.points = points;
    computeBounds();
  }

  // creates a square block centered at the given position
  Block(float x, float y, int size) {
    this(x, y, size, size);
  }

  // creates an axis-aligned rectangular block centered at the given position
  Block(float x, float y, float w, float h) {
    this(
      new PVector(x - (w/2), y - (h/2)),
      new PVector(x + (w/2), y - (h/2)),
      new PVector(x + (w/2), y + (h/2)),
      new PVector(x - (w/2), y + (h/2))
    );
  }

  // computes the axis-aligned bounds used by collision and merge checks
  void computeBounds() {
    float minX = Float.MAX_VALUE, minY = Float.MAX_VALUE;
    float maxX = -Float.MAX_VALUE, maxY = -Float.MAX_VALUE;
    for (PVector p : points) {
      minX = min(minX, p.x);
      minY = min(minY, p.y);
      maxX = max(maxX, p.x);
      maxY = max(maxY, p.y);
    }
    min = new PVector(minX, minY);
    max = new PVector(maxX, maxY);
  }

  // returns the number of polygon vertices
  int pointCount() {
    return points.length;
  }

  // returns a wrapped vertex so callers can close polygon edges naturally
  // wraps around so index == pointCount() returns the first point again (closes the shape)
  PVector getPoint(int i) {
    return points[i % points.length];
  }

  // draws the polygon directly in the current world transform
  void display() {
    fill(255);
    beginShape();
    for (PVector p : points) {
      vertex(p.x, p.y);
    }
    endShape(CLOSE);
  }

  // builds reusable GPU geometry for batched rendering
  // builds this block's static geometry once so many blocks can be drawn via a single
  // cached PShape instead of re-issuing beginShape/vertex/endShape for each one every frame
  PShape buildShape() {
    PShape s = createShape();
    s.beginShape();
    s.noStroke();
    s.fill(255);
    for (PVector p : points) {
      s.vertex(p.x, p.y);
    }
    s.endShape(CLOSE);
    return s;
  }

  // tests the block's bounds against an axis-aligned moving rectangle
  boolean collidesWith(float x, float y, float w, float h) {
    return x < max.x && x + w > min.x && y < max.y && y + h > min.y;
  }

  // reports whether this block participates in enemy collision checks
  boolean blocksEnemies() {
    return true;
  }

  // reports whether this block participates in player collision checks
  boolean blocksPlayer() {
    return true;
  }

  // reports whether the block may be merged with adjacent rectangles
  boolean canMerge() {
    return true;
  }
}