state("FEZ") {}

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

  settings.Add("all_levels", false, "Split when changing levels");
  settings.Add("anySplits", true, "Any% Splits");
  settings.CurrentDefaultParent = "anySplits";

  settings.Add("village", false, "Village");
  settings.SetToolTip("village", "Entering Nature Hub from Memory Core");
  settings.Add("bellTower", false, "Bell Tower");
  settings.SetToolTip("bellTower", "Entering Nature Hub from Two Walls shortcut door");
  settings.Add("waterfall", false, "Waterfall");
  settings.SetToolTip("waterfall", "Warping to Nature Hub from CMY B");
  settings.Add("waterfall2", false, "Waterfall (8bac route)");
  settings.SetToolTip("waterfall2", "Warping to Nature Hub from Infinite Fall");
  settings.Add("arch", false, "Arch");
  settings.SetToolTip("arch", "Warping to Nature Hub from Five Towers");
  settings.Add("tree", false, "Tree");
  settings.SetToolTip("tree", "Entering Zu City Ruins from Zu Bridge");
  settings.Add("zu", false, "Zu");
  settings.SetToolTip("zu", "Warping to Zu City Ruins from Visitor");
  settings.Add("lighthouse", false, "Lighthouse");
  settings.SetToolTip("lighthouse", "Entering Memory Core from Pivot Watertower shortcut door");
  settings.Add("ending32", false, "Ending (32)");
  settings.SetToolTip("ending32", "Exiting Gomez's house after 32-cube ending");

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

  vars.log("Found FezGame at 0x" + fezGame.ToString("X"));
  vars.log("Found speedrunIsLive at 0x" + speedrunIsLive.ToString("X"));
  vars.log("Found timerBase at 0x" + timerBase.ToString("X"));
  vars.log("Found all sigscans, ready for start of run");

  // FezGame.SpeedRun.Began
  vars.speedrunIsLive = new MemoryWatcher<bool>(new DeepPointer(speedrunIsLive));
  // FezGame.Speedrun.Timer.elapsed
  vars.timerElapsed = new MemoryWatcher<long>(new DeepPointer(timerBase, 0x4));
  // FezGame.Speedrun.Timer.startTimeStamp
  vars.timerStart = new MemoryWatcher<long>(new DeepPointer(timerBase, 0xC));
  // FezGame.Speedrun.Timer.isRunning
  vars.timerEnabled = new MemoryWatcher<bool>(new DeepPointer(timerBase, 0x14));
  // FezGame.Program.fez.GameState.PlayerManager.action
  vars.gomezAction = new MemoryWatcher<int>(new DeepPointer(fezGame, 0x78, 0x88, 0x70));
  // FezGame.Program.fez.GameState.SaveData.Level
  vars.levelWatcher = new StringWatcher(new DeepPointer(fezGame, 0x78, 0x60, 0x14, 0x8), 100);
  
  vars.gameTime = 0;
  vars.runStarting = false;
  vars.watchers = new MemoryWatcherList() {
    vars.speedrunIsLive,
    vars.timerElapsed,
    vars.timerStart,
    vars.timerEnabled,
    vars.gomezAction,
    vars.levelWatcher,
  };
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
  vars.levels = new List<string> {"ABANDONED_A", "ABANDONED_B", "ABANDONED_C", "ANCIENT_WALLS", "ARCH", "BELL_TOWER", "BIG_OWL", "BIG_TOWER", "BOILEROOM", "CABIN_INTERIOR_A", "CABIN_INTERIOR_B", "CLOCK", "CMY", "CMY_B", "CMY_FORK", "CODE_MACHINE", "CRYPT", "DRUM", "ELDERS", "EXTRACTOR_A", "FIVE_TOWERS", "FIVE_TOWERS_CAVE", "FOX", "FRACTAL", "GEEZER_HOUSE", "GEEZER_HOUSE_2D", "GLOBE", "GLOBE_INT", "GOMEZ_HOUSE", "GOMEZ_HOUSE_2D", "GOMEZ_HOUSE_END_32", "GOMEZ_HOUSE_END_64", "GRAVE_CABIN", "GRAVE_GHOST", "GRAVE_LESSER_GATE", "GRAVE_TREASURE_A", "GRAVEYARD_A", "GRAVEYARD_GATE", "HEX_REBUILD", "INDUST_ABANDONED_A", "INDUSTRIAL_CITY", "INDUSTRIAL_HUB", "INDUSTRIAL_SUPERSPIN", "KITCHEN", "KITCHEN_2D", "LAVA", "LAVA_FORK", "LAVA_SKULL", "LIBRARY_INTERIOR", "LIGHTHOUSE", "LIGHTHOUSE_HOUSE_A", "LIGHTHOUSE_SPIN", "MAUSOLEUM", "MEMORY_CORE", "MINE_A", "MINE_BOMB_PILLAR", "MINE_WRAP", "NATURE_HUB", "NUZU_ABANDONED_A", "NUZU_ABANDONED_B", "NUZU_BOILERROOM", "NUZU_DORM", "NUZU_SCHOOL", "OBSERVATORY", "OCTOHEAHEDRON", "OLDSCHOOL", "OLDSCHOOL_RUINS", "ORRERY", "ORRERY_B", "OWL", "PARLOR", "PARLOR_2D", "PIVOT_ONE", "PIVOT_THREE", "PIVOT_THREE_CAVE", "PIVOT_TWO", "PIVOT_WATERTOWER", "PURPLE_LODGE", "PURPLE_LODGE_RUIN", "PYRAMID", "QUANTUM", "RAILS", "RITUAL", "SCHOOL", "SCHOOL_2D", "SEWER_FORK", "SEWER_GEYSER", "SEWER_HUB", "SEWER_LESSER_GATE_B", "SEWER_PILLARS", "SEWER_PIVOT", "SEWER_QR", "SEWER_START", "SEWER_TO_LAVA", "SEWER_TREASURE_ONE", "SEWER_TREASURE_TWO", "SHOWERS", "SKULL", "SKULL_B", "SPINNING_PLATES", "STARGATE", "STARGATE_RUINS", "SUPERSPIN_CAVE", "TELESCOPE", "TEMPLE_OF_LOVE", "THRONE", "TREE", "TREE_CRUMBLE", "TREE_OF_DEATH", "TREE_ROOTS", "TREE_SKY", "TRIAL", "TRIPLE_PIVOT_CAVE", "TWO_WALLS", "VILLAGEVILLE_2D", "VILLAGEVILLE_3D", "VILLAGEVILLE_3D_END_32", "VILLAGEVILLE_3D_END_64", "VISITOR", "WALL_HOLE", "WALL_INTERIOR_A", "WALL_INTERIOR_B", "WALL_INTERIOR_HOLE", "WALL_KITCHEN", "WALL_SCHOOL", "WALL_VILLAGE", "WATER_PYRAMID", "WATER_TOWER", "WATER_WHEEL", "WATER_WHEEL_B", "WATERFALL", "WATERFALL_ALT", "WATERTOWER_SECRET", "WEIGHTSWITCH_TEMPLE", "WELL_2", "WINDMILL_CAVE", "WINDMILL_INT", "ZU_4_SIDE", "ZU_BRIDGE", "ZU_CITY", "ZU_CITY_RUINS", "ZU_CODE_LOOP", "ZU_FORK", "ZU_HEADS", "ZU_HOUSE_EMPTY", "ZU_HOUSE_EMPTY_B", "ZU_HOUSE_QR", "ZU_HOUSE_RUIN_GATE", "ZU_HOUSE_RUIN_VISITORS", "ZU_HOUSE_SCAFFOLDING", "ZU_LIBRARY", "ZU_SWITCH", "ZU_SWITCH_B", "ZU_TETRIS", "ZU_THRONE_RUINS", "ZU_UNFOLD", "ZU_ZUISH"};
}

update {
  vars.watchers.UpdateAll(game);
  if (vars.tcs != null && (vars.updateText || old.deathCount != current.deathCount)) {
    vars.tcs.Text1 = "Fall Count:";
    vars.tcs.Text2 = vars.deathCount.ToString();
  }
}

start {
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
      if (settings["all_levels"]) {
        return true;
      }
      if (oldLevel == "MEMORY_CORE" && newLevel == "NATURE_HUB") {
        return settings["village"];
      } else if (oldLevel == "TWO_WALLS" && newLevel == "NATURE_HUB") {
        return settings["bellTower"];
      } else if (oldLevel == "PIVOT_WATERTOWER" && newLevel == "MEMORY_CORE") {
        return settings["lighthouse"];
      } else if (oldLevel == "ZU_BRIDGE" && newLevel == "ZU_CITY_RUINS") {
        return settings["tree"];
      } else if (oldLevel == "GOMEZ_HOUSE_END_32" && newLevel == "VILLAGEVILLE_3D_END_32") {
        return settings["ending32"];
      } else if (oldLevel == "CMY_B" && newLevel == "NATURE_HUB") {
        return settings["waterfall"];
      } else if (oldLevel == "ZU_CODE_LOOP" && newLevel == "NATURE_HUB") {
        return settings["waterfall2"];
      } else if (oldLevel == "FIVE_TOWERS" && newLevel == "NATURE_HUB") {
        return settings["arch"];
      } else if (oldLevel == "VISITOR" && newLevel == "ZU_CITY_RUINS") {
        return settings["zu"];
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
  return true;
}

gameTime {
  if (vars.timerEnabled.Current)
  {
    var elapsedTicks = Stopwatch.GetTimestamp() - vars.timerStart.Current + vars.timerElapsed.Current;
    // 10,000,000: Number of ticks in a second
    var newGameTime = elapsedTicks * 10000000 / Stopwatch.Frequency;
    if (Math.Abs(newGameTime - vars.gameTime) > 10000000) { // Time jump by > 1s
      vars.log("Gametime jumped by >1s, waiting for a more stable value.");
      vars.log("Old gametime: " + vars.gameTime + " New gametime: " + newGameTime);
    } else {
      vars.gameTime = newGameTime;
    }
    return new TimeSpan(vars.gameTime);
  }
}
