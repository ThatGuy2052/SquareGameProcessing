@class Button{
    float x, y, w, h; // screen-space rectangle used for hit testing and drawing
    String label; // text rendered inside the button

    // creates a rectangular button at the given screen position
    Button(float x, float y, float w, float h, String label){
        this.x = x;
        this.y = y;
        this.w = w;
        this.h = h;
        this.label = label;
    }

    // draws the default gray button style
    void display(){
        rectMode(CORNER);
        fill(200);
        rect(x, y, w, h, 10);
        fill(0);
        textAlign(CENTER, CENTER);
        textSize(12);
        text(label, x + w/2, y + h/2);
    }

    // draws the button with whatever fill color the caller wants
    void display(int buttonColor){
        rectMode(CORNER);
        fill(buttonColor);
        rect(x, y, w, h, 10);
        fill(0);
        textAlign(CENTER, CENTER);
        textSize(12);
        text(label, x + w/2, y + h/2);
    }

    // true if the mouse is currently sitting inside this button
    boolean isMouseOver(){
        return mouseX > x && mouseX < x + w && mouseY > y && mouseY < y + h;
    }

    // switches scenes when this button gets a left-click
    void loadSceneOnClick(Scene scene){
        if(isMouseOver() && mousePressed && mouseButton == LEFT){
            SceneManager.setScene(scene);
        }
    }

    // opens the level picker and adds the selected PNG to the level library
    void ImportLevelOnClick(){
        if(isMouseOver() && mousePressed && mouseButton == LEFT){
            PImage levelDesign = selectPNGImage();
            if (levelDesign != null) {
                String file = LevelLibrary.addLevel(app, levelDesign);
                SceneManager.setScene(new Level(levelDesign, file));
            }
        }
    }

    // quits the app when this button is clicked
    void quitGameOnClick(){
        if(isMouseOver() && mousePressed && mouseButton == LEFT){
            exiting = true;
            exit();
        }
    }
}

// a button that flips on/off instead of navigating, with click-edge detection so
// holding the mouse down doesn't toggle every single frame
class ToggleButton extends Button {
    boolean wasMouseDown; // previous frame's pressed state, so we can detect a click edge

    // creates a toggle and ignores a mouse press carried over from another scene
    ToggleButton(float x, float y, float w, float h, String label){
        super(x, y, w, h, label);
        // seed with the current mouse state so a press held over from the previous
        // scene (e.g. the click that navigated here) doesn't get misread as a fresh click
        wasMouseDown = mousePressed;
    }

    // returns true only on the first frame of a left-click over this toggle
    boolean clicked(){
        boolean down = isMouseOver() && mousePressed && mouseButton == LEFT;
        boolean edge = down && !wasMouseDown;
        wasMouseDown = down;
        return edge;
    }

    // draws the standard green-on / gray-off toggle
    void display(boolean on){
        rectMode(CORNER);
        fill(on ? color(0, 200, 0) : color(150));
        rect(x, y, w, h, 10);
        fill(0);
        textAlign(CENTER, CENTER);
        textSize(12);
        text(label + ": " + (on ? "ON" : "OFF"), x + w/2, y + h/2);
    }

    // draws the on-state using a custom active color
    void display(boolean on, int activeColor){
        rectMode(CORNER);
        fill(on ? activeColor : color(150));
        rect(x, y, w, h, 10);
        fill(0);
        textAlign(CENTER, CENTER);
        textSize(12);
        text(label + ": " + (on ? "ON" : "OFF"), x + w/2, y + h/2);
    }

    // draws either a normal toggle or a dark locked state with a locked label
    void display(boolean on, boolean locked){
        rectMode(CORNER);
        fill(locked ? color(70) : (on ? color(0, 200, 0) : color(150)));
        rect(x, y, w, h, 10);
        fill(locked ? 255 : 0);
        textAlign(CENTER, CENTER);
        textSize(12);
        text(locked ? label + ": Locked (ON)" : label + ": " + (on ? "ON" : "OFF"), x + w/2, y + h/2);
    }

}