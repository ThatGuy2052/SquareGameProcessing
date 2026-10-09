// a blue wall that blocks enemies but lets the player pass right through
class PlayerOnlyGate extends Block {
	// inherits the same polygon geometry while keeping its own special collision rules
	// creates a gate using the same polygon geometry as a normal block
	PlayerOnlyGate(float x, float y, float w, float h) {
		super(x, y, w, h);
	}

	// keeps enemies from crossing this block during pathfinding and collision resolution
	boolean blocksEnemies() {
		return true;
	}

	// lets the player cross the gate
	boolean blocksPlayer() {
		return false;
	}

	// prevents the gate from getting merged into neighboring normal blocks
	boolean canMerge() {
		return false;
	}

	// draws the gate in blue so its special collision behavior is visible in the level
	void display() {
		fill(0, 100, 255);
		beginShape();
		for (PVector p : points) {
			vertex(p.x, p.y);
		}
		endShape(CLOSE);
	}

	// builds the cached blue shape used by the batched block renderer
	PShape buildShape() {
		PShape s = createShape();
		s.beginShape();
		s.noStroke();
		s.fill(0, 100, 255);
		for (PVector p : points) {
			s.vertex(p.x, p.y);
		}
		s.endShape(CLOSE);
		return s;
	}
}