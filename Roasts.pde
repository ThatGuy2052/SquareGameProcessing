// loads roast lines shown on the Lose screen from roasts.json (a plain
// {"roasts": ["...", ...]} array) so new roasts can get added without touching code
static class Roasts {
  // JSON file containing the lose-screen roast messages
  static final String ROASTS_FILE = "roasts.json";
  static ArrayList<String> lines = new ArrayList<String>(); // messages loaded into memory for quick random picks
  static boolean loaded = false; // stops repeated reads of the roast file

  // loads all roast strings from disk and marks the cache as ready
  static void load(PApplet app) {
    lines.clear();
    File file = new File(app.sketchPath(ROASTS_FILE));
    if (file.exists()) {
      JSONObject data = app.loadJSONObject(file.getAbsolutePath());
      JSONArray list = data.getJSONArray("roasts");
      for (int i = 0; i < list.size(); i++) {
        lines.add(list.getString(i));
      }
    }
    loaded = true;
  }

  // returns a random roast, or an empty string if the file has no messages
  static String random(PApplet app) {
    if (!loaded) load(app);
    if (lines.isEmpty()) return "";
    return lines.get(int(app.random(lines.size())));
  }
}
