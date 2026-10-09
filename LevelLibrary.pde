@// stashes imported level images in a "levels" folder and keeps track of them in levels.json
static class LevelLibrary {
  // folder where imported level PNGs live
  static final String FOLDER = "levels";
  // index file mapping display names to the stable level filenames
  static final String INDEX_FILE = FOLDER + "/levels.json";

  // grabs the level index, or just returns an empty list if nothing's been imported yet
  static JSONArray loadIndex(PApplet app) {
    File indexFile = new File(app.sketchPath(INDEX_FILE));
    if (!indexFile.exists()) {
      return new JSONArray();
    }
    JSONObject data = app.loadJSONObject(indexFile.getAbsolutePath());
    return data.getJSONArray("levels");
  }

  // saves the current level index after an import or some other library change
  static void saveIndex(PApplet app, JSONArray levels) {
    JSONObject data = new JSONObject();
    data.setJSONArray("levels", levels);
    app.saveJSONObject(data, app.sketchPath(INDEX_FILE));
  }

  // saves the image as a new level file and registers it in levels.json, appending
  // the generated name to the index
  static String addLevel(PApplet app, PImage image) {
    File folder = new File(app.sketchPath(FOLDER));
    if (!folder.exists()) folder.mkdirs();

    JSONArray levels = loadIndex(app);
    int number = levels.size() + 1;
    String fileName = "level_" + number + ".png";
    image.save(app.sketchPath(FOLDER + "/" + fileName));

    JSONObject entry = new JSONObject();
    entry.setString("name", "Level " + number);
    entry.setString("file", fileName);
    levels.append(entry);
    saveIndex(app, levels);

    return fileName;
  }

  // loads a level image from the library folder using its stable filename
  static PImage loadLevelImage(PApplet app, String fileName) {
    return app.loadImage(app.sketchPath(FOLDER + "/" + fileName));
  }
}
