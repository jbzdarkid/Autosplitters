state("FEZ") {}

state("MONOMODDED_FEZ") {}

startup {
  vars.logFilePath = Directory.GetCurrentDirectory() + "\\autosplitter_fez.log";
  vars.log = (Action<string>)((string logLine) => {
    print(logLine);
    string time = System.DateTime.Now.ToString("dd/MM/yy hh:mm:ss:fff");
    System.IO.File.AppendAllText(vars.logFilePath, time + ": " + logLine + "\r\n");
  });
  try {
    vars.log("Autosplitter loaded");
  } catch (System.IO.FileNotFoundException e) {
    System.IO.File.Create(vars.logFilePath);
    vars.log("Autosplitter loaded, log file created");
  }

  vars.levels = new HashSet<string> {"ABANDONED_A", "ABANDONED_B", "ABANDONED_C", "ANCIENT_WALLS", "ARCH", "BELL_TOWER", "BIG_OWL", "BIG_TOWER", "BOILEROOM", "CABIN_INTERIOR_A", "CABIN_INTERIOR_B", "CLOCK", "CMY", "CMY_B", "CMY_FORK", "CODE_MACHINE", "CRYPT", "DRUM", "ELDERS", "EXTRACTOR_A", "FIVE_TOWERS", "FIVE_TOWERS_CAVE", "FOX", "FRACTAL", "GEEZER_HOUSE", "GEEZER_HOUSE_2D", "GLOBE", "GLOBE_INT", "GOMEZ_HOUSE", "GOMEZ_HOUSE_2D", "GOMEZ_HOUSE_END_32", "GOMEZ_HOUSE_END_64", "GRAVE_CABIN", "GRAVE_GHOST", "GRAVE_LESSER_GATE", "GRAVE_TREASURE_A", "GRAVEYARD_A", "GRAVEYARD_GATE", "HEX_REBUILD", "INDUST_ABANDONED_A", "INDUSTRIAL_CITY", "INDUSTRIAL_HUB", "INDUSTRIAL_SUPERSPIN", "KITCHEN", "KITCHEN_2D", "LAVA", "LAVA_FORK", "LAVA_SKULL", "LIBRARY_INTERIOR", "LIGHTHOUSE", "LIGHTHOUSE_HOUSE_A", "LIGHTHOUSE_SPIN", "MAUSOLEUM", "MEMORY_CORE", "MINE_A", "MINE_BOMB_PILLAR", "MINE_WRAP", "NATURE_HUB", "NUZU_ABANDONED_A", "NUZU_ABANDONED_B", "NUZU_BOILERROOM", "NUZU_DORM", "NUZU_SCHOOL", "OBSERVATORY", "OCTOHEAHEDRON", "OLDSCHOOL", "OLDSCHOOL_RUINS", "ORRERY", "ORRERY_B", "OWL", "PARLOR", "PARLOR_2D", "PIVOT_ONE", "PIVOT_THREE", "PIVOT_THREE_CAVE", "PIVOT_TWO", "PIVOT_WATERTOWER", "PURPLE_LODGE", "PURPLE_LODGE_RUIN", "PYRAMID", "QUANTUM", "RAILS", "RITUAL", "SCHOOL", "SCHOOL_2D", "SEWER_FORK", "SEWER_GEYSER", "SEWER_HUB", "SEWER_LESSER_GATE_B", "SEWER_PILLARS", "SEWER_PIVOT", "SEWER_QR", "SEWER_START", "SEWER_TO_LAVA", "SEWER_TREASURE_ONE", "SEWER_TREASURE_TWO", "SHOWERS", "SKULL", "SKULL_B", "SPINNING_PLATES", "STARGATE", "STARGATE_RUINS", "SUPERSPIN_CAVE", "TELESCOPE", "TEMPLE_OF_LOVE", "THRONE", "TREE", "TREE_CRUMBLE", "TREE_OF_DEATH", "TREE_ROOTS", "TREE_SKY", "TRIAL", "TRIPLE_PIVOT_CAVE", "TWO_WALLS", "VILLAGEVILLE_2D", "VILLAGEVILLE_3D", "VILLAGEVILLE_3D_END_32", "VILLAGEVILLE_3D_END_64", "VISITOR", "WALL_HOLE", "WALL_INTERIOR_A", "WALL_INTERIOR_B", "WALL_INTERIOR_HOLE", "WALL_KITCHEN", "WALL_SCHOOL", "WALL_VILLAGE", "WATER_PYRAMID", "WATER_TOWER", "WATER_WHEEL", "WATER_WHEEL_B", "WATERFALL", "WATERFALL_ALT", "WATERTOWER_SECRET", "WEIGHTSWITCH_TEMPLE", "WELL_2", "WINDMILL_CAVE", "WINDMILL_INT", "ZU_4_SIDE", "ZU_BRIDGE", "ZU_CITY", "ZU_CITY_RUINS", "ZU_CODE_LOOP", "ZU_FORK", "ZU_HEADS", "ZU_HOUSE_EMPTY", "ZU_HOUSE_EMPTY_B", "ZU_HOUSE_QR", "ZU_HOUSE_RUIN_GATE", "ZU_HOUSE_RUIN_VISITORS", "ZU_HOUSE_SCAFFOLDING", "ZU_LIBRARY", "ZU_SWITCH", "ZU_SWITCH_B", "ZU_TETRIS", "ZU_THRONE_RUINS", "ZU_UNFOLD", "ZU_ZUISH"};

  vars.splits = new Dictionary<string, List<string>>();
  var addSetting = (Action<string, string, string, string, string>)((string settingId, string name, string fromLevel, string toLevel, string tooltip) => {
    settings.Add(settingId, false, name);
    settings.SetToolTip(settingId, tooltip);
    if (!vars.levels.Contains(fromLevel)) throw new Exception(fromLevel + " is not a valid level name");
    if (!vars.levels.Contains(toLevel)) throw new Exception(toLevel + " is not a valid level name");

    string splitsKey = fromLevel + "." + toLevel;
    List<string> splitsValue;
    if (!vars.splits.TryGetValue(splitsKey, out splitsValue)) {
      splitsValue = new List<string>();
      vars.splits[splitsKey] = splitsValue;
    }
    splitsValue.Add(settingId);
  });

  settings.Add("all_levels", false, "Split when changing levels");
  settings.Add("anySplits", true, "Any% Splits");
  settings.CurrentDefaultParent = "anySplits";

  addSetting("village",    "Village",                "MEMORY_CORE",        "NATURE_HUB",             "Entering Nature Hub from Memory Core");
  addSetting("bellTower",  "Bell Tower",             "TWO_WALLS",          "NATURE_HUB",             "Entering Nature Hub from Two Walls shortcut door");
  addSetting("waterfall",  "Waterfall",              "CMY_B",              "NATURE_HUB",             "Warping to Nature Hub from CMY B");
  addSetting("waterfall2", "Waterfall (8bac route)", "ZU_CODE_LOOP",       "NATURE_HUB",             "Warping to Nature Hub from Infinite Fall");
  addSetting("arch",       "Arch",                   "FIVE_TOWERS",        "NATURE_HUB",             "Warping to Nature Hub from Five Towers");
  addSetting("tree",       "Tree",                   "ZU_BRIDGE",          "ZU_CITY_RUINS",          "Entering Zu City Ruins from Zu Bridge");
  addSetting("zu",         "Zu",                     "VISITOR",            "ZU_CITY_RUINS",          "Warping to Zu City Ruins from Visitor");
  addSetting("lighthouse", "Lighthouse",             "PIVOT_WATERTOWER",   "MEMORY_CORE",            "Entering Memory Core from Pivot Watertower shortcut door");
  addSetting("ending32",   "Ending (32)",            "GOMEZ_HOUSE_END_32", "VILLAGEVILLE_3D_END_32", "Exiting Gomez's house after 32-cube ending");

  settings.CurrentDefaultParent = null;
  settings.Add("fullCompletionSplits", false, "Full Completion Splits (Juikuen's route)");
  settings.CurrentDefaultParent = "fullCompletionSplits";

  addSetting("full_village",     "Village",            "MEMORY_CORE",        "NATURE_HUB",             "Entering Nature Hub from Memory Core");
  addSetting("full_waterfall",   "Waterfall",          "CMY_B",              "NATURE_HUB",             "Warping to Nature Hub from CMY B");
  addSetting("full_bellTower",   "Bell Tower",         "TWO_WALLS",          "NATURE_HUB",             "Entering Nature Hub from Two Walls shortcut door");
  addSetting("full_mine",        "Mine",               "MINE_WRAP",          "NATURE_HUB",             "Warping to Nature Hub from Mine Wrap");
  addSetting("full_tree",        "Tree",               "ZU_BRIDGE",          "ZU_CITY_RUINS",          "Entering Zu City Ruins from Zu Bridge");
  addSetting("full_zu",          "Zu",                 "ZU_CITY_RUINS",      "NATURE_HUB",             "Warping to Nature Hub from Zu City Ruins");
  addSetting("full_arch",        "Arch",               "QUANTUM",            "NATURE_HUB",             "Warping to Nature Hub from Quantum");
  addSetting("full_lighthouse",  "Lighthouse",         "PIVOT_WATERTOWER",   "MEMORY_CORE",            "Entering Memory Core from Pivot Watertower shortcut door");
  addSetting("full_cubeDoors",   "Cube Doors",         "PIVOT_WATERTOWER",   "INDUSTRIAL_HUB",         "Entering Industrial Hub from Pivot Watertower");
  addSetting("full_industrial",  "Industrial",         "WELL_2",             "SEWER_START",            "Entering Sewer Start from Well 2");
  addSetting("full_sewers",      "Sewers",             "SEWER_TO_LAVA",      "NUZU_ABANDONED_B",       "Entering Nuzu Abandoned B from Sewer To Lava");
  addSetting("full_industrial2", "Industrial Wrap-up", "INDUSTRIAL_HUB",     "NATURE_HUB",             "Warping to Nature Hub from Industrial Hub");
  addSetting("full_graveyard",   "Graveyard",          "GRAVEYARD_GATE",     "NATURE_HUB",             "Warping to Nature Hub from Graveyard Gate");
  addSetting("full_ending64",    "Ending (64)",        "GOMEZ_HOUSE_END_64", "VILLAGEVILLE_3D_END_64", "Exiting Gomez's house after 64-cube ending");

  settings.CurrentDefaultParent = null;
  settings.Add("artifactSplits", false, "Artifact% Splits");
  settings.CurrentDefaultParent = "artifactSplits";

  addSetting("artifact_village",    "Village",                "MEMORY_CORE",        "NATURE_HUB",             "Entering Nature Hub from Memory Core");
  addSetting("artifact_bellTower",  "Bell Tower",             "TWO_WALLS",          "NATURE_HUB",             "Entering Nature Hub from Two Walls shortcut door");
  addSetting("artifact_waterfall",  "Waterfall",              "CMY_B",              "NATURE_HUB",             "Warping to Nature Hub from CMY B");
  addSetting("artifact_arch",       "Arch",                   "FIVE_TOWERS",        "NATURE_HUB",             "Warping to Nature Hub from Five Towers");
  addSetting("artifact_tree",       "Tree",                   "ZU_BRIDGE",          "ZU_CITY_RUINS",          "Entering Zu City Ruins from Zu Bridge");
  addSetting("artifact_zu",         "Zu",                     "ZU_LIBRARY",         "ZU_CITY_RUINS",          "Entering Zu City Ruins from Zu Library");
  addSetting("artifact_graveyard",  "Graveyard",              "GRAVE_TREASURE_A",   "GRAVEYARD_GATE",         "Entering Graveyard Gate from Graveyard Treasure");
  addSetting("artifact_lighthouse", "Lighthouse",             "NATURE_HUB",         "MEMORY_CORE",            "Entering Memory Core from Nature Hub");
  addSetting("artifact_ending32",   "Ending (32)",            "GOMEZ_HOUSE_END_32", "VILLAGEVILLE_3D_END_32", "Exiting Gomez's house after 32-cube ending");

  settings.CurrentDefaultParent = null;
  settings.Add("deathcount", false, "Override first text component with a Fall Counter");
}

init {
  vars.log("Running signature scans...");
  int fezGame = 0;
  int speedrunIsLive = 0;
  int timerBase = 0;
  IntPtr ptr;
  foreach (var page in game.MemoryPages()) {
    var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);

    // FezGame.Program::MainInternal
    ptr = scanner.Scan(new SigScanTarget(36,
      "38 00", // cmp byte ptr [eax], al
      "8B C8", // mov ecx, eax
      "BA 03 00 00 00" // mov edx, 3 ; ThreadPriority.AboveNormal
    ));
    if (ptr != IntPtr.Zero) fezGame = game.ReadValue<int>(ptr) - (int)modules.First().BaseAddress;

    // FezGame.Speedrun::Draw
    ptr = scanner.Scan(new SigScanTarget(6,
      "33 C0",               // xor eax,eax
      "F3 AB",               // repe stosd
      "80 3D ?? ?? ?? ?? 00" // cmp byte ptr [target],00
    ));
    if (ptr != IntPtr.Zero) {
      speedrunIsLive = game.ReadValue<int>(ptr) - (int)modules.First().BaseAddress;
      timerBase = game.ReadValue<int>(ptr + 13) - (int)modules.First().BaseAddress;
    }

    if (fezGame != 0 && speedrunIsLive != 0 && timerBase != 0) break;
  }
  if (fezGame == 0) {
    vars.log("Couldn't find FezGame.fez!");
    throw new Exception("Couldn't find FezGame.fez!");
  } else if (speedrunIsLive == 0 || timerBase == 0) {
    vars.log("Couldn't find speedrunIsLive / timerBase!");
    throw new Exception("Couldn't find speedrunIsLive / timerBase!");
  }

  vars.log("Found FezGame at 0x" + fezGame.ToString("X") +
           "\nFound speedrunIsLive at 0x" + speedrunIsLive.ToString("X") +
           "\nFound timerBase at 0x" + timerBase.ToString("X") +
           "\nFound all sigscans, ready for start of run");

  switch (modules.First().ModuleMemorySize) {
  case 4333568:
    vars.log("Loaded version 1.12 (steam) w/ HAT 1.2.0");
    goto case 1155072;
  case 1155072:
    vars.log("Loaded version 1.12 (steam)");
    // FezGame.SpeedRun.Began
    vars.speedrunIsLive = new MemoryWatcher<bool>(new DeepPointer(speedrunIsLive));
    // FezGame.SpeedRun.Timer.elapsed
    vars.timerElapsed = new MemoryWatcher<long>(new DeepPointer(timerBase, 0x4));
    // FezGame.Speedrun.Timer.startTimeStamp
    vars.timerStart = new MemoryWatcher<long>(new DeepPointer(timerBase, 0xC));
    // FezGame.SpeedRun.Timer.isRunning
    vars.timerEnabled = new MemoryWatcher<bool>(new DeepPointer(timerBase, 0x14));
    // FezGame.Program.fez.GameState.PlayerManager.action
    vars.gomezAction = new MemoryWatcher<int>(new DeepPointer(fezGame, 0x78, 0x6C, 0x70));
    // FezGame.Program.fez.GameState.SaveData.Level
    vars.levelWatcher = new StringWatcher(new DeepPointer(fezGame, 0x78, 0x60, 0x14, 0x8), 100);
    vars.watchers = new MemoryWatcherList { vars.speedrunIsLive, vars.timerElapsed, vars.timerStart, vars.timerEnabled, vars.gomezAction, vars.levelWatcher };
    break;
  case 1114112:
    vars.log("Loaded version 1.07 (steam)");
    // These 4 don't exist in this version, so we can't support automatic start/stop or IGT. Oh well.
    vars.speedrunIsLive = null;
    vars.timerElapsed = null;
    vars.timerStart = null;
    vars.timerEnabled = null;
    // FezGame.Program.fez.GameState.PlayerManager.action              vvvv
    vars.gomezAction = new MemoryWatcher<int>(new DeepPointer(fezGame, 0x70, 0x6C, 0x70));
    // FezGame.Program.fez.GameState.SaveData.Level                vvvv
    vars.levelWatcher = new StringWatcher(new DeepPointer(fezGame, 0x70, 0x60, 0x14, 0x8), 100);
    vars.watchers = new MemoryWatcherList { vars.gomezAction, vars.levelWatcher };
    break;
  default:
    throw new Exception("Unknown version: " + modules.First().ModuleMemorySize);
  }

  vars.gameTime = 0;
  vars.runStarting = false;
  vars.level = null;
  vars.deathCount = 0;
  vars.updateText = false;
  vars.tcs = null;
  if (settings["deathcount"]) {
    foreach (LiveSplit.UI.Components.IComponent component in timer.Layout.Components) {
      if (component.GetType().Name == "TextComponent") {
        vars.tc = component;
        vars.tcs = vars.tc.Settings;
        vars.updateText = true;
        vars.log("Found text component at " + component);
        break;
      }
    }
  }
}

update {
  vars.watchers.UpdateAll(game);
  if (vars.tcs != null && (vars.updateText || old.deathCount != current.deathCount)) {
    vars.tcs.Text1 = "Fall Count:";
    vars.tcs.Text2 = vars.deathCount.ToString();
  }
}

start {
  if (vars.speedrunIsLive == null) return false; // 1.07 does not have speedrun mode
  if (!vars.speedrunIsLive.Old && vars.speedrunIsLive.Current) {
    vars.log("Speedrun starting");
    vars.runStarting = true;
  }
  if (vars.runStarting && vars.timerEnabled.Current) {
    vars.log("Starting run");
    vars.deathCount = 0;
    vars.gameTime = 0;
    vars.level = "GOMEZ_HOUSE_2D";
    vars.runStarting = false;
    return true;
  }
}

reset {
  if (vars.speedrunIsLive == null) return false; // 1.07 does not have speedrun mode
  if (vars.speedrunIsLive.Old && !vars.speedrunIsLive.Current) {
    vars.log("Reset run");
    return true;
  }
}

split {
  if (vars.levelWatcher.Changed) {
    string oldLevel = vars.level;
    string newLevel = vars.levelWatcher.Current;
    vars.log("Changed level from " + oldLevel + " to " + newLevel);
    if (vars.levels.Contains(newLevel) && oldLevel != newLevel) {
      vars.log("New level is an actual level name: " + newLevel);
      vars.level = newLevel;

      if (settings["all_levels"]) return true;
      List<string> settingIds;
      if (vars.splits.TryGetValue(oldLevel + "." + newLevel, out settingIds)) {
        vars.log("Transition from " + oldLevel + " to " + newLevel + " found in splits dictionary");
        foreach (string settingId in settingIds) {
          vars.log("Setting " + settingId + " is " + settings[settingId]);
          if (settings[settingId]) return true;
        }
      }
    }
  }
  if (vars.gomezAction.Changed) {
    // ActionType.FreeFalling
    if (vars.gomezAction.Current == 0x25) {
      vars.deathCount++;
    }
  }
}

isLoading {
  return true; // Disable automatic interpolation when the timer is paused
}

gameTime {
  if (vars.timerEnabled != null && vars.timerEnabled.Current) {
    // C# stopwatches have an 'elapsed' value and a start timestamp.
    // The elapsed value counts the cumulative time it's been live in the past,
    // and the timestamp is the most recent time it was started.
    return TimeSpan.FromTicks(vars.timerElapsed.Current + Stopwatch.GetTimestamp() - vars.timerStart.Current);
  }
}