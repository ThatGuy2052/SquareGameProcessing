// one fragment of the player's death explosion, a tumbling green square that flies
// outward and fades away
class DeathParticle {
  float x, y; // current world position of the fragment
  float vx, vy; // velocity applied each frame
  float size; // rendered square size
  float rot, rotSpeed; // current angle and angular velocity
  float life; // remaining normalized opacity lifetime

  // creates one fragment with an initial position, velocity, size, and rotation
  DeathParticle(float x, float y, float vx, float vy, float size) {
    this.x = x;
    this.y = y;
    this.vx = vx;
    this.vy = vy;
    this.size = size;
    this.rot = random(TWO_PI);
    this.rotSpeed = random(-3, 3);
    this.life = 1.0;
  }

  // advances the fragment using frame-rate-independent drag and lifetime decay
  void update(float deltaTime, float totalLifeSeconds) {
    float step = deltaTime * 60;
    x += vx * step;
    y += vy * step;
    vx *= pow(0.985, step); // light drag so the burst keeps drifting outward for the whole animation
    vy *= pow(0.985, step);
    rot += rotSpeed * step;
    life -= deltaTime / totalLifeSeconds; // frame-rate independent, spans the full death animation
  }

  // draws the fragment only while its lifetime is still positive
  void display() {
    if (life <= 0) return;
    pushMatrix();
    translate(x, y);
    rotate(rot);
    rectMode(CENTER);
    fill(0, 255, 0, 255 * constrain(life, 0, 1));
    rect(0, 0, size, size);
    popMatrix();
  }
}

class Player 
{
  float x, y; // world-space center position
  float w, h; // collision and rendering footprint
  float speed; // player movement speed
  PVector cameraPos; // smoothed camera target position
  float screenPositionX; // screen-space x position used by the lighting shader
  float screenPositionY; // screen-space y position used by the lighting shader
  int camMovementCutoff = 75; // distance from the camera before camera tracking kicks in
  boolean exitbounding = false; // keeps the camera following until it settles near the player

 // death animation state: player explodes into particles, camera shakes, and the
 // screen pulses red before the scene hands off to the Lose screen
 boolean dead = false; // true while the death animation is active
 float deathTimer = 0; // elapsed time in the death animation
 final float DEATH_DURATION = 1.3; // total death-animation duration in seconds
 ArrayList<DeathParticle> deathParticles = new ArrayList<DeathParticle>(); // fragments emitted on death


  // creates a player with its world position, footprint, and movement speed
  Player(float x, float y, float w, float h, float speed) 
  {
    
    this.x = x;
    this.y = y; 
    this.w = w;
    this.h = h; 
    this.speed = speed;
    cameraPos = new PVector(this.x, this.y);
  }

  void startDeath() {
    if (dead) return;
    dead = true;
    deathTimer = 0;
    deathParticles.clear();
    int count = 20;
    for (int i = 0; i < count; i++) {
      float angle = random(TWO_PI);
      float speedAmount = random(6, 16);
      deathParticles.add(new DeathParticle(x, y, cos(angle) * speedAmount, sin(angle) * speedAmount, random(10, 24)));
    }
  }

  void updateDeath(float deltaTime) {
    deathTimer += deltaTime;
    for (DeathParticle p : deathParticles) {
      p.update(deltaTime, DEATH_DURATION);
    }
  }

  boolean deathAnimationDone() {
    return deathTimer >= DEATH_DURATION;
  }

  // shake decays with an eased-out curve (fast at first, then settles) so it reads as
  // finite instead of a constant, endless jitter
  float deathShakeAmount() {
    float t = constrain(deathTimer / DEATH_DURATION, 0, 1);
    float remaining = 1 - t;
    return 14 * remaining * remaining;
  }

  // alpha for a full-screen red overlay: pulses faster/brighter than the ambient
  // danger glow and ramps up as the animation progresses
  float deathRedPulseAlpha() {
    float t = constrain(deathTimer / DEATH_DURATION, 0, 1);
    float pulse = 0.5 + 0.5 * sin(deathTimer * 30);
    return lerp(70, 210, t) * pulse;
  }

  void updateCamera(float deltaTime) 
  {
    camera();
    beginCamera();
    if ((abs(cameraPos.x - x) > camMovementCutoff || abs(cameraPos.y - y) > camMovementCutoff) || exitbounding) 
    {
      float smoothing = 1 - pow(1 - 0.05, deltaTime * 60);
      cameraPos.x = lerp(cameraPos.x, x, smoothing);
      cameraPos.y = lerp(cameraPos.y, y, smoothing);
      exitbounding = true;
     
    }
    if (abs(cameraPos.x - x) < 25 && abs(cameraPos.y - y) < 25 && exitbounding) 
    {
    // cameraPos.x = x;
    // cameraPos.y = y;
    exitbounding = false;
    }
    float shakeX = 0, shakeY = 0;
    if (dead) {
      float shake = deathShakeAmount();
      shakeX = random(-shake, shake);
      shakeY = random(-shake, shake);
    }
    translate(width / 2 - cameraPos.x + shakeX, height / 2 - cameraPos.y + shakeY);
    endCamera();
  }

  void update(BlocksManager blocksManager, float deltaTime) 
  {
    float dx = 0;
    float dy = 0;

    if (up) dy -= 1;
    if (down) dy += 1;
    if (left) dx -= 1;
    if (right) dx += 1;

    // normalize movement so diagonal isn't faster
    if (dx != 0 || dy != 0) {
      float len = sqrt(dx * dx + dy * dy);
      dx /= len;
      dy /= len;
    }

    float movement = speed * deltaTime * 60;
    dx *= movement;
    dy *= movement;

    // try moving on the x axis, clamping to the wall instead of rejecting the whole move
    float newX = x + dx;
    x = blocksManager.resolveX(x, y, w, h, newX, false);

    // try moving on the y axis, clamping to the wall instead of rejecting the whole move
    float newY = y + dy;
    y = blocksManager.resolveY(x, y, w, h, newY, false);
  }

  void display() 
  {
    screenPositionX = screenX(x, y);
    screenPositionY = screenY(x, y);
    if (dead) {
      for (DeathParticle p : deathParticles) {
        p.display();
      }
      return;
    }
    rectMode(CENTER);
    fill(0,255,0);
    rect(x, y, w, h);
  }


}

  boolean up, down, left, right, esc, r, shift; // current keyboard state used by movement and global shortcuts

    void keyPressed() 
    {
    if (key == 'w' || key == 'W') up = true;
    if (key == 's' || key == 'S') down = true;
    if (key == 'a' || key == 'A') left = true;
    if (key == 'd' || key == 'D') right = true;
    if (keyCode == ESC) esc = true;
    if (keyCode == SHIFT) shift = true;
    if (key == 'r' || key == 'R') r = true;
  }

  void keyReleased() 
  {
    if (key == 'w' || key == 'W') up = false;
    if (key == 's' || key == 'S') down = false;
    if (key == 'a' || key == 'A') left = false;
    if (key == 'd' || key == 'D') right = false;
    if (keyCode == ESC) esc = false;
    if (keyCode == SHIFT) shift = false;
    if (key == 'r' || key == 'R') r = false;
  }