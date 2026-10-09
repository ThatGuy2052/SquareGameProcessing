// persists on/off flags for screen shader effects in settings.json
static class GameSettings {
  // name of the JSON file used to persist the user's display and gameplay preferences
  static final String SETTINGS_FILE = "settings.json";

  // enables the CRT post-processing shader
  static boolean crtEnabled = true;
  // enables the bloom post-processing shader
  static boolean bloomEnabled = true;
  // controls the normal player-centered lighting shader
  static boolean lightingEnabled = true;
  // enables the harder mode that forces lighting and records true completions
  static boolean nightmareMode = false;
  // enables the red death flash during the player's death animation
  static boolean deathFlashEnabled = true;
  // enables the red danger glow near enemies
  static boolean dangerEdgesEnabled = true;
  // restarts a run automatically after the death animation
  static boolean autoRestartOnDeath = false;
  // shows the elapsed run timer during gameplay
  static boolean statsHudEnabled = true;
  // allows roast messages to appear on the lose screen
  static boolean roastsEnabled = true;

  // loads saved preferences and keeps defaults for fields missing from older files
  static void load(PApplet app) {
    File file = new File(app.sketchPath(SETTINGS_FILE));
    if (!file.exists()) return;
    JSONObject data = app.loadJSONObject(file.getAbsolutePath());
    crtEnabled = data.getBoolean("crtEnabled", true);
    bloomEnabled = data.getBoolean("bloomEnabled", true);
    lightingEnabled = data.getBoolean("lightingEnabled", true);
    nightmareMode = data.getBoolean("nightmareMode", false);
    deathFlashEnabled = data.getBoolean("deathFlashEnabled", true);
    dangerEdgesEnabled = data.getBoolean("dangerEdgesEnabled", true);
    autoRestartOnDeath = data.getBoolean("autoRestartOnDeath", false);
    statsHudEnabled = data.getBoolean("statsHudEnabled", true);
    roastsEnabled = data.getBoolean("roastsEnabled", true);
  }

  // serializes the current preferences so they survive the next launch
  static void save(PApplet app) {
    JSONObject data = new JSONObject();
    data.setBoolean("crtEnabled", crtEnabled);
    data.setBoolean("bloomEnabled", bloomEnabled);
    data.setBoolean("lightingEnabled", lightingEnabled);
    data.setBoolean("nightmareMode", nightmareMode);
    data.setBoolean("deathFlashEnabled", deathFlashEnabled);
    data.setBoolean("dangerEdgesEnabled", dangerEdgesEnabled);
    data.setBoolean("autoRestartOnDeath", autoRestartOnDeath);
    data.setBoolean("statsHudEnabled", statsHudEnabled);
    data.setBoolean("roastsEnabled", roastsEnabled);
    app.saveJSONObject(data, app.sketchPath(SETTINGS_FILE));
  }
}
