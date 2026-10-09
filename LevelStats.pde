// persists per-level speedrun stats (best/worst times, wins/losses, near misses) in
// levelstats.json, keyed by a stable level id (the level's PNG file name, or
// "__maze__" for the randomly generated Maze mode)
static class LevelStats {
  // the JSON file holding one stats record per level
  static final String STATS_FILE = "levelstats.json";

  static class Entry {
    int wins = 0; // number of completed normal or nightmare runs
    int losses = 0; // number of runs that ended in a death
    float bestTime = -1; // fastest completed run in seconds, -1 means no win exists yet
    float worstTime = -1; // slowest completed run in seconds, -1 means no win exists yet
    boolean trueCompletion = false; // whether this level has been completed while nightmare mode was active
    float trueTime = -1; // fastest nightmare-mode completion in seconds, -1 means none exists
    int totalNearMisses = 0; // lifetime count of near misses on this level
  }

  static HashMap<String, Entry> entries = new HashMap<String, Entry>(); // in-memory records keyed by level filename
  static boolean loaded = false; // stops repeated file loads during one application session

  // reads all saved entries and fills in defaults for fields added later
  static void load(PApplet app) {
    entries.clear();
    File file = new File(app.sketchPath(STATS_FILE));
    if (file.exists()) {
      JSONObject data = app.loadJSONObject(file.getAbsolutePath());
      JSONArray list = data.getJSONArray("levels");
      for (int i = 0; i < list.size(); i++) {
        JSONObject o = list.getJSONObject(i);
        Entry e = new Entry();
        e.wins = o.getInt("wins", 0);
        e.losses = o.getInt("losses", 0);
        e.bestTime = o.getFloat("bestTime", -1);
        e.worstTime = o.getFloat("worstTime", -1);
        e.trueCompletion = o.getBoolean("trueCompletion", false);
        e.trueTime = o.getFloat("trueTime", -1);
        e.totalNearMisses = o.getInt("totalNearMisses", 0);
        entries.put(o.getString("key"), e);
      }
    }
    loaded = true;
  }

  // writes every in-memory entry back out to the stats JSON file
  static void save(PApplet app) {
    JSONObject data = new JSONObject();
    JSONArray list = new JSONArray();
    for (String key : entries.keySet()) {
      Entry e = entries.get(key);
      JSONObject o = new JSONObject();
      o.setString("key", key);
      o.setInt("wins", e.wins);
      o.setInt("losses", e.losses);
      o.setFloat("bestTime", e.bestTime);
      o.setFloat("worstTime", e.worstTime);
      o.setBoolean("trueCompletion", e.trueCompletion);
      o.setFloat("trueTime", e.trueTime);
      o.setInt("totalNearMisses", e.totalNearMisses);
      list.append(o);
    }
    data.setJSONArray("levels", list);
    app.saveJSONObject(data, app.sketchPath(STATS_FILE));
  }

  // returns an existing record or creates a blank one for a newly imported level
  static Entry getEntry(PApplet app, String key) {
    if (!loaded) load(app);
    Entry e = entries.get(key);
    if (e == null) {
      e = new Entry();
      entries.put(key, e);
    }
    return e;
  }

  // records the outcome of one run and persists it, returns true if a win just beat
  // the previous personal-best time (so the Win screen can flag "New Best!")
  // keeps the original normal-mode api by recording a run without nightmare mode
  static boolean recordRun(PApplet app, String key, boolean won, float time, int nearMisses) {
    return recordRun(app, key, won, time, nearMisses, false);
  }

  // updates normal stats and the separate true stats for one completed run
  static boolean recordRun(PApplet app, String key, boolean won, float time, int nearMisses, boolean nightmareMode) {
    Entry e = getEntry(app, key);
    boolean newBest = false;
    if (won) {
      e.wins++;
      if (nightmareMode) {
        e.trueCompletion = true;
        if (e.trueTime < 0 || time < e.trueTime) e.trueTime = time;
      }
      if (e.bestTime < 0 || time < e.bestTime) {
        e.bestTime = time;
        newBest = true;
      }
      if (e.worstTime < 0 || time > e.worstTime) {
        e.worstTime = time;
      }
    } else {
      e.losses++;
    }
    e.totalNearMisses += nearMisses;
    save(app);
    return newBest;
  }

  // formats seconds as a two-digit minute and hundredth-second display string
  static String formatTime(float seconds) {
    if (seconds < 0) return "--:--.--";
    int minutes = int(seconds / 60);
    float remainder = seconds - minutes * 60;
    return nf(minutes, 2) + ":" + nf(remainder, 2, 2);
  }
}
