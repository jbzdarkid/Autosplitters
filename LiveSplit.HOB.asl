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
  var animationNames = new Dictionary<string, string> {
    // Unused (for splits):
    // ITEM_PLUG_WALLBATTERY
    // INT_CONTROLLER_ORB_ACTIVATE
    // INT_GLOVE_PRESS_FLAT
    // INT_HANDLE_TURN

    // CINE_SWORDFORGEDOOR_PRYOPEN
    // CINE_DOOR_PRY_AXEKNIGHT_PLAYER
    // CINE_WORLDPIECE_WATER_PICKUP
    // CINE_WORLDPIECE_FOREST_INSERT
    // CINE_WORLDPIECE_WATER_PICKUP
    // CINE_WORLDPIECE_FOREST_INSERT (reused for two of them at least)
    
    // TODO: I don't have a stable pointer for this yet. I should play around with some fixed/common animations (like the ORB) to find one.
    // ... or I can just do the 2x pointer option and be lazy. I like being lazy.



    { "BUTTON", "INT_GLOVE_PRESS_WALL" },
    { "SWITCH", "SWITCH_WALL_PULL" },
    { "POWERUP", "INT_GLOVE_UPGRADE" },
    { "HEALTH", "INT_HEALTHGET" },
    { "ENERGY", "INT_CONSTRUCT_LOOT_01" },
    { "SWORD", "INT_GETSWORDPIECE02" },
    { "CORRUPTION", "INT_SEED_KILL" },
    { "CORE", "INT_TITAN_CORE_REMOVE1" },
    { "BUTTERFLY", "INT_BUTTERFLY_COLLECT_01" },
  };
  
  vars.splits = new Dictionary<string, Func<bool>>();
  vars.completedSplits = new HashSet<string>();

  vars.CloseToPoint = (Func<double, double, double, bool>) ((double x, double y, double z) => {
    var distanceToPlayer = (x - vars.hobX.Current) * (x - vars.hobX.Current) +
                           (y - vars.hobY.Current) * (y - vars.hobY.Current) +
                           (z - vars.hobZ.Current) * (z - vars.hobZ.Current);
    return distanceToPlayer < 100.0; // 10 units
  });

  var addEnterLevelSetting = (Action<string, string, string, string>)((string toLevel, string id, string text, string tooltip) => {
    settings.Add(id, false, text);
    settings.SetToolTip(id, tooltip);
    toLevel = levelNames[toLevel];
    vars.splits[id] = (Func<bool>)(() => vars.level.Changed && vars.level.Current == toLevel);
  });
  var addExitLevelSetting = (Action<string, string, string, string>)((string fromLevel, string id, string text, string tooltip) => {
    settings.Add(id, false, text);
    settings.SetToolTip(id, tooltip);
    fromLevel = levelNames[fromLevel];
    vars.splits[id] = (Func<bool>)(() => vars.level.Changed && vars.level.Old == fromLevel);
  });
  var addAnimationSetting = (Action<double, double, double, string, string, string>)((double x, double y, double z, string id, string text, string tooltip) => {
    settings.Add(id, false, text);
    settings.SetToolTip(id, tooltip);
    // animation = animationNames[animation];
    vars.splits[id] = (Func<bool>)(() => vars.moveset.Changed && vars.moveset.Current == 16 && vars.CloseToPoint(x, y, z));
  });

  addEnterLevelSetting("WAKEUP",                    "enter_wakeup",     "Intro clip",           "Clipping into the intro building to start the credits");
  addExitLevelSetting("WAKEUP",                     "exit_wakeup",      "Wakeup",               "Exiting the intro building after getting the arm");
  addEnterLevelSetting("FORGE",                     "enter_forge",      "Enter Forge",          "Entering the forge before getting the sword");
  addExitLevelSetting("FORGE",                      "exit_forge",       "Exit Forge",           "Exiting the forge after getting the sword");
  addEnterLevelSetting("PUNCH",                     "enter_punch",      "Enter Punch",          "Entering the punch cave before getting the upgrade");
  addExitLevelSetting("PUNCH",                      "exit_punch",       "Exit Punch",           "Exiting the punch cave after getting the upgrade");
  addEnterLevelSetting("WARP",                      "enter_warp",       "Enter Warp",           "Entering the warp cave before getting the upgrade");
  addExitLevelSetting("WARP",                       "exit_warp",        "Exit Warp",            "Exiting the warp cave after getting the upgrade");
  addAnimationSetting(24.2, 4, -246.9,              "electric_lever",   "Activate Spider",      "Powering up the spider in the electrical area");
  addEnterLevelSetting("ELECTRIC",                  "enter_electric",   "Enter Electrical",     "Entering the underground electrical dungeon");
  addExitLevelSetting("ELECTRIC",                   "exit_electric",    "Exit Electrical",      "Exiting the underground electrical dungeon");
  addEnterLevelSetting("FACTORY",                   "enter_factory",    "Enter Factory",        "Entering the large dome in wetlands");
  addAnimationSetting(141.5, -118.4, 10.5,          "raise_factory",    "Factory Handprint",    "Pressing the wall handprint in factory to raise the land");
  addExitLevelSetting("FACTORY",                    "exit_factory",     "Exit Factory",         "Exiting the factory after grabbing the forest tablet");
  addAnimationSetting(181.0, 0.8, -361.6,           "place_forest",     "Activate Forest",      "Placing the forest tablet to raise the land");
  addAnimationSetting(257, 25.7, -254.5,            "forest_corrupt",   "Forest Corruption",    "Clearing the corruption in the forest");
  addAnimationSetting(-17.5, 8.2, -111,             "electric_corrupt", "Electric Corruption",  "Clearing the corruption in the electrical area");
  addAnimationSetting(-102.9, 0.8, -38.4,           "place_cemetery",   "Activate Cemetery",    "Placing the cemetery tablet to raise the land");
  addAnimationSetting(-11.6, 6, 69,                 "cemetery_corrupt", "Cemetery Corruption",  "Clearing the corruption in the cemetery");
  addEnterLevelSetting("GRAPPLE",                   "enter_grapple",    "Enter Grapple",        "Entering the grapple cave before getting the upgrade");
  addExitLevelSetting("GRAPPLE",                    "exit_grapple",     "Exit Grapple",         "Exiting the grapple cave after getting the upgrade");
  addAnimationSetting(-45.9, 14, 123.5,             "grab_water",       "Water Tablet",         "Pikcing up the water tablet");
  addAnimationSetting(-317.5, 10.8, 86.3,           "place_water",      "Activate Water",       "Placing the water tablet to raise the land");
  addEnterLevelSetting("UNDERWATER",                "enter_underwater", "Enter Underwater",     "Entering the underwater dungeon (only splits once)");
  addAnimationSetting(-126.3, 0, -36.8,             "water_corrupt",    "Water Corruption",     "Clearing the corruption underwater");
  addExitLevelSetting("UNDERWATER",                 "exit_underwater",  "Exit Underwater",      "Exiting the underwater dungeon (unsplits if you re-enter underwater)");
  addAnimationSetting(-338.1, 6, 18.9,              "pipes_corrupt",    "Pipes Corruption",     "Clearing the corruption in the pipes area");
  addAnimationSetting(-78.3, 1, -383.3,             "intro_corrupt",    "Intro Corruption",     "Clearing the corruption in the introduction area");
  addAnimationSetting(-338.4, -2, -282.1,           "wetlands_corrupt", "Wetlands Corruption",  "Clearing the corruption in the wetlands");
  addAnimationSetting(-372.4, -7.1, -304.2,         "wetlands_core",    "Wetlands Core",        "Picking up the core from the colossus in wetlands");
  addAnimationSetting(256.3, 25.7, -252.8,          "sprite_core",      "Sprite Mom Core",      "Picking up the core from Sprite Mom in forest");
  addAnimationSetting(299, 13, -145,                "forest_core",      "Forest Core",          "Picking up the core from the colossus in forest");
  addAnimationSetting(51, 1.6, 98.4,                "robot_wakeup",     "Activate Colossus",    "Pressing the handprint after inserting all 3 cores");

  settings.Add("butterflies", false, "Split on collecting a butterfly");

  settings.Add("deathcount", false, "Override first text component with a Death Counter");
  vars.deathCount = 0;
  vars.tcs = null;
  foreach (LiveSplit.UI.Components.IComponent component in timer.Layout.Components) {
    if (component.GetType().Name == "TextComponent") {
      vars.tc = component;
      vars.tcs = vars.tc.Settings;
      vars.tcs.Text1 = "Deaths:";
      vars.tcs.Text2 = "0";
      vars.log("Found text component at " + component);
      break;
    }
  }
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
  vars.animation = new StringWatcher(new DeepPointer(gameWorld, 0x50, 0xA8, 0xA8, 0x04, 0x34), 200);
  vars.animation2 = new StringWatcher(new DeepPointer(gameWorld, 0x50, 0xA8, 0xA8, 0x04, 0x34, 0), 200);

  vars.watchers = new MemoryWatcherList() { vars.inMenu, vars.hobX, vars.hobY, vars.hobZ, vars.level, vars.moveset, vars.animation, vars.animation2 };
  vars.log("Found all sigscans, ready for start of run");
}

update {
  vars.watchers.UpdateAll(game);

  if (vars.tcs != null && settings["deathcount"]) {
    if (vars.moveset.Changed && vars.moveset.Current == 18) { // dead
      vars.deathCount++;
      vars.tcs.Text1 = "Deaths:";
      vars.tcs.Text2 = vars.deathCount.ToString();
    }
  }
  
  if (vars.completedSplits.Contains("bad_ending") && vars.moveset.Changed && vars.moveset.Current == 16
    && vars.CloseToPoint(0.4, 126, 102.3)) {
    vars.log("Unsplitting from bad ending because we started a new animation at " + vars.hobX.Current + " " + vars.hobY.Current + " " + vars.hobZ.Current);
    vars.completedSplits.Remove("bad_ending");
    new TimerModel{CurrentState = timer}.UndoSplit();
  }
}

start {
  if (vars.inMenu.Changed && vars.CloseToPoint(3.2, 0.2, -529.4)) {
    vars.log("inMenu changed while near start point: " + vars.inMenu.Old + " " + vars.inMenu.Current);
  }
  if (vars.inMenu.Old == 0.5f && vars.inMenu.Current == 0.0f) {
    vars.log("Exited the menu, checking for start point " + vars.hobX.Current + " " + vars.hobY.Current + " " + vars.hobZ.Current);
    if (vars.CloseToPoint(3.2, 0.2, -529.4)) {
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
    if (vars.CloseToPoint(3.2, 0.2, -529.4)) {
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
  
  if (settings["butterflies"]) {
    if (vars.moveset.Changed && vars.moveset.Current == 16 && vars.animation2.Current == "INT_BUTTERFLY_COLLECT_01") {
      vars.log("Collected butterfly at " + vars.hobX.Current + " " + vars.hobY.Current + " " + vars.hobZ.Current);
      return true;
    }
  }

  // It is possible to move (roll, blink, etc) before accepting the queen's offer, so for this one "close to point" is a bit larger.
  // TODO: It seems like, in some cases there are multiple animations in the final cutscene. I added an 'unsplit' to the update block in case a second animation starts playing, but I should *probably* find the animation name/id to make this more robust.
  if (vars.moveset.Changed && vars.CloseToPoint(0.4, 126, 102.3) && vars.moveset.Old == 16) {
    vars.log("Completed the game (bad ending) at " + vars.hobX.Current + " " + vars.hobY.Current + " " + vars.hobZ.Current);
    vars.completedSplits.Add("bad_ending");
    return true;
  }

  if (!vars.completedSplits.Contains("bad_ending") && vars.completedSplits.Contains("robot_wakeup") && vars.CloseToPoint(83.5, 0, -92.3, 5.0)) {
    vars.log("Backup split for 'end of game' (e.g. good ending)");
    return true;
  }

  return false;
}
