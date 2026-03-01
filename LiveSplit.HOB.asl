state("HOB") {}

startup {
  // Relative to Livesplit.exe
  vars.logFilePath = Directory.GetCurrentDirectory() + "\\autosplitter_hob.log";
  vars.log = (Action<string>)((string logLine) => {
    print(logLine);
    string time = System.DateTime.Now.ToString("dd/MM/yy hh:mm:ss.fff");
    // AppendAllText will create the file if it doesn't exist.
    System.IO.File.AppendAllText(vars.logFilePath, time + ": " + logLine + "\r\n");
  });

  var levelNames = new Dictionary<string, string> {
    { "OVERWORLD",  "MEDIA/LEVELS/OUTSIDE_CONFIG.DAT" },
    { "WAKEUP",     "MEDIA/LEVELS/DUNGEONS/GETGLOVEDUNGEON/GLOVE_WAKEUPDUNGEON.LAYOUT" },
    { "FORGE",      "MEDIA/LEVELS/DUNGEONS/SWORD FORGE/MASTER_SWORD_FORGE.LAYOUT" },
    { "PUNCH",      "MEDIA/LEVELS/DUNGEONS/TUTORIAL/GETPUNCH_WORKSHOP.LAYOUT" },
    { "WARP",       "MEDIA/LEVELS/DUNGEONS/TUTORIAL/GETWARP_WORKSHOP.LAYOUT" },
    { "ELECTRIC",   "MEDIA/LEVELS/DUNGEONS/ELECTRICAL DUNGEONS/ELECTRIC_CENTRAL_DUNGEON.LAYOUT" },
    { "FACTORY",    "MEDIA/LEVELS/DUNGEONS/PRISON/WORLDMACHINE_DUNGEON.LAYOUT" },
    { "SPIN ROOM",  "MEDIA/LEVELS/DUNGEONS/FOREST DUNGEONS/DUNGEON_MOTHERHOB.LAYOUT" },
    { "ELEC CAVE",  "MEDIA/LEVELS/DUNGEONS/OVERWORLD/10_10_FORESTTOTOWER.LAYOUT" },
    { "GRAPPLE",    "MEDIA/LEVELS/DUNGEONS/TUTORIAL/PAX_DUNGEON.LAYOUT" },
    { "UNDERWATER", "MEDIA/LEVELS/DUNGEONS/WATER/ABYSS.LAYOUT" },
  };
  vars.splits = new Dictionary<string, Func<bool>>();
  vars.completedSplits = new HashSet<string>();

  vars.CloseToPoint = (Func<double, double, double, double, bool>) ((double x, double y, double z, double distance) => {
    var distanceToPlayer = (x - vars.hobX.Current) * (x - vars.hobX.Current) +
                           (y - vars.hobY.Current) * (y - vars.hobY.Current) +
                           (z - vars.hobZ.Current) * (z - vars.hobZ.Current);
    return distanceToPlayer < (distance * distance);
  });

  var addAnimationSetting = (Action<double, double, double, string, string, string>)((double x, double y, double z, string id, string text, string tooltip) => {
    settings.Add(id, false, text);
    settings.SetToolTip(id, tooltip);
    // For most animations, I consider "close to a point" to be within 5 units
    vars.splits[id] = (Func<bool>)(() => vars.moveset.Old != 16 && vars.moveset.Current == 16 && vars.CloseToPoint(x, y, z, 5.0));
  });
  var addLevelChangeSetting = (Action<string, string, string, string, string>)((string fromLevel, string toLevel, string id, string text, string tooltip) => {
    settings.Add(id, false, text);
    settings.SetToolTip(id, tooltip);
    fromLevel = levelNames[fromLevel];
    toLevel = levelNames[toLevel];
    vars.splits[id] = (Func<bool>)(() => vars.level.Old == fromLevel && vars.level.Current == toLevel);
  });

  addLevelChangeSetting("OVERWORLD",  "WAKEUP",     "enter_wakeup",     "Intro clip",           "Clipping into the intro building to start the credits");
  addLevelChangeSetting("WAKEUP",     "OVERWORLD",  "exit_wakeup",      "Wakeup",               "Exiting the intro building after getting the arm");
  addLevelChangeSetting("OVERWORLD",  "FORGE",      "enter_forge",      "Enter Forge",          "Entering the forge before getting the sword");
  addLevelChangeSetting("FORGE",      "OVERWORLD",  "exit_forge",       "Exit Forge",           "Exiting the forge after getting the sword");
  addLevelChangeSetting("OVERWORLD",  "PUNCH",      "enter_punch",      "Enter Punch",          "Entering the punch cave before getting the upgrade");
  addLevelChangeSetting("PUNCH",      "OVERWORLD",  "exit_punch",       "Exit Punch",           "Exiting the punch cave after getting the upgrade");
  addLevelChangeSetting("OVERWORLD",  "WARP",       "enter_warp",       "Enter Warp",           "Entering the warp cave before getting the upgrade");
  addLevelChangeSetting("WARP",       "OVERWORLD",  "exit_warp",        "Exit Warp",            "Exiting the warp cave after getting the upgrade");
  addAnimationSetting(24.2, 4, -246.9,              "electric_lever",   "Activate Spider",      "Powering up the spider in the electrical area");
  addLevelChangeSetting("OVERWORLD",  "ELECTRIC",   "enter_electric",   "Enter Electrical",     "Entering the underground electrical dungeon");
  addLevelChangeSetting("ELECTRIC",   "OVERWORLD",  "exit_electric",    "Exit Electrical",      "Exiting the underground electrical dungeon");
  addLevelChangeSetting("OVERWORLD",  "FACTORY",    "enter_factory",    "Enter Factory",        "Entering the large dome in wetlands");
  addAnimationSetting(141.5, -118.4, 10.5,          "raise_factory",    "Factory Handprint",    "Pressing the wall handprint in factory to raise the land");
  addLevelChangeSetting("FACTORY",    "OVERWORLD",  "exit_factory",     "Exit Factory",         "Exiting the factory after grabbing the forest tablet");
  addAnimationSetting(181.0, 0.8, -361.6,           "place_forest",     "Activate Forest",      "Placing the forest tablet to raise the land");
  addAnimationSetting(257, 25.7, -254.5,            "forest_corrupt",   "Forest Corruption",    "Clearing the corruption in the forest");
  addAnimationSetting(-17.5, 8.2, -111,             "electric_corrupt", "Electric Corruption",  "Clearing the corruption in the electrical area");
  addAnimationSetting(-102.9, 0.8, -38.4,           "place_cemetery",   "Activate Cemetery",    "Placing the cemetery tablet to raise the land");
  addAnimationSetting(-11.6, 6, 69,                 "cemetery_corrupt", "Cemetery Corruption",  "Clearing the corruption in the cemetery");
  addLevelChangeSetting("OVERWORLD",  "GRAPPLE",    "enter_grapple",    "Enter Grapple",        "Entering the grapple cave before getting the upgrade");
  addLevelChangeSetting("GRAPPLE",    "OVERWORLD",  "exit_grapple",     "Exit Grapple",         "Exiting the grapple cave after getting the upgrade");
  addAnimationSetting(-45.9, 14, 123.5,             "grab_water",       "Water Tablet",         "Pikcing up the water tablet");
  addAnimationSetting(-317.5, 10.8, 86.3,           "place_water",      "Activate Water",       "Placing the water tablet to raise the land");
  addLevelChangeSetting("OVERWORLD",  "UNDERWATER", "enter_underwater", "Enter Underwater",     "Entering the underwater dungeon (only splits once)");
  addAnimationSetting(-126.3, 0, -36.8,             "water_corrupt",    "Water Corruption",     "Clearing the corruption underwater");
  addLevelChangeSetting("UNDERWATER", "OVERWORLD",  "exit_underwater",  "Exit Underwater",      "Exiting the underwater dungeon (unsplits if you re-enter underwater)");
  addAnimationSetting(-338.1, 6, 18.9,              "pipes_corrupt",    "Pipes Corruption",     "Clearing the corruption in the pipes area");
  addAnimationSetting(-78.3, 1, -383.3,             "intro_corrupt",    "Intro Corruption",     "Clearing the corruption in the introduction area");
  addAnimationSetting(-338.4, -2, -282.1,           "wetlands_corrupt", "Wetlands Corruption",  "Clearing the corruption in the wetlands");
  addAnimationSetting(-372.4, -7.1, -304.2,         "wetlands_core",    "Wetlands Core",        "Picking up the core from the colossus in wetlands");
  addAnimationSetting(256.3, 25.7, -252.8,          "sprite_core",      "Sprite Mom Core",      "Picking up the core from Sprite Mom in forest");
  addAnimationSetting(299, 13, -145,                "forest_core",      "Forest Core",          "Picking up the core from the colossus in forest");
  addAnimationSetting(51, 1.6, 98.4,                "robot_wakeup",     "Activate Colossus",    "Pressing the handprint after inserting all 3 cores");

  settings.Add("deathcount", false, "Override first text component with a Death Counter");
}

init {
  vars.log("Running signature scans...");

  var page = modules.First();
  var scanner = new SignatureScanner(game, page.BaseAddress, page.ModuleMemorySize);

  IntPtr ptr = scanner.Scan(new SigScanTarget(11, "80 BD 00 01 00 00 00"));
  if (ptr == IntPtr.Zero) {
    vars.log("Couldn't find GameWorld!");
    throw new Exception("Couldn't find GameWorld");
  }
  IntPtr gameWorldFunction = ptr + game.ReadValue<int>(ptr) + 5;
  int gameWorld = game.ReadValue<int>(gameWorldFunction) - (int)page.BaseAddress;
  vars.log("Found gameWorld: " + gameWorld.ToString("X"));

  ptr = scanner.Scan(new SigScanTarget(14, "8B 6C 24 14 51"));
  if (ptr == IntPtr.Zero) {
    vars.log("Couldn't find InMenu!");
    throw new Exception("Couldn't find InMenu");
  }
  IntPtr menuFunction = ptr + game.ReadValue<int>(ptr) + 5;
  int menu = game.ReadValue<int>(menuFunction) - (int)page.BaseAddress;
  vars.log("Found menu: " + menu.ToString("X"));

  vars.inMenu = new MemoryWatcher<float>(new DeepPointer(menu, 0x40));
  vars.hobX = new MemoryWatcher<float>(new DeepPointer(gameWorld, 0x50, 0x78, 0x74));
  vars.hobY = new MemoryWatcher<float>(new DeepPointer(gameWorld, 0x50, 0x78, 0x78));
  vars.hobZ = new MemoryWatcher<float>(new DeepPointer(gameWorld, 0x50, 0x78, 0x7C));
  vars.level = new StringWatcher(new DeepPointer(gameWorld, 0x4C, 0xD4, 0x0), 200);
  vars.moveset = new MemoryWatcher<int>(new DeepPointer(gameWorld, 0x50, 0xA8, 0x120, 0x2C));

  vars.watchers = new MemoryWatcherList() { vars.inMenu, vars.hobX, vars.hobY, vars.hobZ, vars.level, vars.moveset };
  vars.log("Found all sigscans, ready for start of run");

  vars.deathCount = 0;
  vars.updateText = false;
  vars.tcs = null;
  if (settings["deathcount"]) {
    foreach (LiveSplit.UI.Components.IComponent component in timer.Layout.Components) {
      if (component.GetType().Name == "TextComponent") {
        vars.tc = component;
        vars.tcs = vars.tc.Settings;
        vars.tcs.Text1 = "Deaths:";
        vars.tcs.Text2 = "0";
        vars.updateText = true;
        vars.log("Found text component at " + component);
        break;
      }
    }
  }
}

update {
  vars.watchers.UpdateAll(game);

  if (vars.tcs != null && vars.updateText) {
    if (vars.moveset.Changed && vars.moveset.Current == 18) { // dead
      vars.deathCount++;
      vars.tcs.Text1 = "Deaths:";
      vars.tcs.Text2 = vars.deathCount.ToString();
    }
  }
}

start {
  if (vars.inMenu.Changed && vars.CloseToPoint(3.2, 0.2, -529.4, 5.0)) {
    vars.log("inMenu changed while near start point: " + vars.inMenu.Old + " " + vars.inMenu.Current);
  }
  if (vars.inMenu.Old == 0.5f && vars.inMenu.Current == 0.0f) {
    vars.log("Exited the menu, checking for start point " + vars.hobX.Current + " " + vars.hobY.Current + " " + vars.hobZ.Current);
    if (vars.CloseToPoint(3.2, 0.2, -529.4, 5.0)) {
      vars.log("Starting run");
      vars.completedSplits.Clear();
      vars.deathCount = 0;
      return true;
    }
  }
}

reset {
  if (vars.inMenu.Old < 0.5f && vars.inMenu.Current == 0.5f) {
    vars.log("Entered the menu, checking for new game " + vars.hobX.Current + " " + vars.hobY.Current + " " + vars.hobZ.Current);
    if (vars.CloseToPoint(3.2, 0.2, -529.4, 5.0)) {
      vars.log("Resetting run");
      return true;
    }
  }
}

split {
  if (vars.moveset.Changed && vars.moveset.Current == 16) {
    vars.log("Started an animation at " + vars.hobX.Current + " " + vars.hobY.Current + " " + vars.hobZ.Current);
  }
  if (vars.level.Changed) {
    vars.log("Changed level from '" + vars.level.Old + "' to '" + vars.level.Current + "'");
  }

  foreach (var kvp in vars.splits) {
    string splitId = kvp.Key;
    var checkSplit = kvp.Value;

    // Special casing for the Sprite Mom core, since it's in the same location as the forest corruption
    if (splitId == "sprite_core" && !vars.completedSplits.Contains("intro_corrupt")) continue;

    // Special casing for the Activate Colossus split, since it triggers when you skip the water table cutscene
    if (splitId == "robot_wakeup" && !vars.completedSplits.Contains("forest_core")) continue;

    if (vars.completedSplits.Contains(splitId)) continue; // Do not evaluate splits if they were already completed
    if (checkSplit()) {
      vars.completedSplits.Add(splitId);

      // Special casing for the water dungeon, since you might re-enter this dungeon if you run out of time on grapple storage
      if (splitId == "exit_underwater") {
        vars.log("Player has exited underwater, removing enter_underwater in case we re-enter");
        vars.completedSplits.Remove("enter_underwater");
      } else if (splitId == "enter_underwater") {
        if (vars.completedSplits.Contains("exit_underwater") && settings["exit_underwater"]) {
          vars.log("Re-entered underwater after previously exiting; unsplitting.");
          vars.completedSplits.Remove("exit_underwater");
          new TimerModel{CurrentState = timer}.UndoSplit();
          return false;
        }
      }

      vars.log("Completed " + splitId + " splitting based on setting value: " + settings[splitId]);
      return settings[kvp.Key];
    }
  }

  // It is possible to move (roll, blink, etc) before accepting the queen's offer, so for this one "close to point" is a bit larger.
  // TODO: It seems like, in some cases there are multiple animations in the final cutscene. I added an 'unsplit' in case a second animation starts playing.
  if (vars.moveset.Changed && vars.CloseToPoint(0.4, 126, 102.3, 10.0)) {
    if (vars.moveset.Old == 16) {
      vars.log("Completed the game (bad ending) at " + vars.hobX.Current + " " + vars.hobY.Current + " " + vars.hobZ.Current);
      vars.completedSplits.Add("bad_ending");
      return true;
    } else if (vars.moveset.Current == 16 && vars.completedSplits.Contains("bad_ending")) {
      vars.log("Unsplitting from bad ending because we started a new animation at " + vars.hobX.Current + " " + vars.hobY.Current + " " + vars.hobZ.Current);
      vars.completedSplits.Remove("bad_ending");
      new TimerModel{CurrentState = timer}.UndoSplit();
      return false;
    }
  }

  if (!vars.completedSplits.Contains("bad_ending") && vars.completedSplits.Contains("robot_wakeup") && vars.CloseToPoint(83.5, 0, -92.3, 5.0)) {
    vars.log("Backup split for 'end of game' (e.g. good ending)");
    return true;
  }

  return false;
}
