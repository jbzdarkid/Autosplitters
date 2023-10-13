state("FEZ") {}

startup {
  settings.Add("all_levels", false, "Split when changing levels");

  settings.Add("anySplits", true, "Any% Splits");
  settings.CurrentDefaultParent = "anySplits";

  settings.Add("village", false, "Village");
  settings.SetToolTip("village", "Entering Nature Hub from Memory Core");
  settings.Add("bellTower", false, "Bell Tower");
  settings.SetToolTip("bellTower", "Entering Nature Hub from Two Walls shortcut door");
  settings.Add("waterfall", false, "Waterfall");
  settings.SetToolTip("waterfall", "Warping to Nature Hub from CMY B");
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
  settings.Add("fullCompletionSplits", false, "Full Completion Splits (Juikuen's route)");
  settings.CurrentDefaultParent = "fullCompletionSplits";

  settings.Add("full_village", false, "Village");
  settings.SetToolTip("full_village", "Entering Nature Hub from Memory Core");
  settings.Add("full_waterfall", false, "Waterfall");
  settings.SetToolTip("full_waterfall", "Warping to Nature Hub from CMY B");
  settings.Add("full_bellTower", false, "Bell Tower");
  settings.SetToolTip("full_bellTower", "Entering Nature Hub from Two Walls shortcut door");
  settings.Add("full_mine", false, "Mine");
  settings.SetToolTip("full_mine", "Warping to Nature Hub from Mine Wrap");
  settings.Add("full_tree", false, "Tree");
  settings.SetToolTip("full_tree", "Entering Zu City Ruins from Zu Bridge");
  settings.Add("full_zu", false, "Zu");
  settings.SetToolTip("full_zu", "Warping to Nature Hub from Zu City Ruins");
  settings.Add("full_arch", false, "Arch");
  settings.SetToolTip("full_arch", "Warping to Nature Hub from Quantum");
  settings.Add("full_lighthouse", false, "Lighthouse");
  settings.SetToolTip("full_lighthouse", "Entering Memory Core from Pivot Watertower shortcut door");
  settings.Add("full_cubeDoors", false, "Cube Doors");
  settings.SetToolTip("full_cubeDoors", "Entering Industrial Hub from Pivot Watertower");
  settings.Add("full_industrial", false, "Industrial");
  settings.SetToolTip("full_industrial", "Entering Sewer Start from Well 2");
  settings.Add("full_sewers", false, "Sewers");
  settings.SetToolTip("full_sewers", "Entering Nuzu Abandoned B from Sewer To Lava");
  settings.Add("full_industrialWrapUp", false, "Industrial Wrap-up");
  settings.SetToolTip("full_industrialWrapUp", "Warping to Nature Hub from Industrial Hub");
  settings.Add("full_graveyard", false, "Graveyard");
  settings.SetToolTip("full_graveyard", "Warping to Nature Hub from Graveyard Gate");
  settings.Add("full_ending64", false, "Ending (64)");
  settings.SetToolTip("full_ending64", "Exiting Gomez's house after 64-cube ending");

  settings.CurrentDefaultParent = null;
  settings.Add("deathcount", false, "Override first text component with a Fall Counter");
}

init {
  print("Running signature scans...");
  int fezGame = 0;
  int speedrunIsLive = 0;
  int timerBase = 0;
  IntPtr ptr;
  foreach (var page in game.MemoryPages()) {
    var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);

    ptr = scanner.Scan(new SigScanTarget(0,
      "01 01 00 00 00 40 0D 03"
    ));
    if (ptr != IntPtr.Zero) {
      fezGame = (int)ptr - (int)modules.First().BaseAddress - 0x53;
    }

    // FezGame.Speedrun::Draw
    ptr = scanner.Scan(new SigScanTarget(6,
      "33 C0",               // xor eax,eax
      "F3 AB",               // repe stosd
      "80 3D ?? ?? ?? ?? 00" // cmp byte ptr [target],00
    ));
    if (ptr != IntPtr.Zero) {
      speedrunIsLive = game.ReadValue<int>(ptr) - (int)modules.First().BaseAddress;
      timerBase = game.ReadValue<int>(ptr + 0xD) - (int)modules.First().BaseAddress;
    }
  }
  if (fezGame == 0) {
    throw new Exception("Couldn't find FezGame!");
  } else {
    print("Found FezGame at 0x" + fezGame.ToString("X"));
  }
  if (speedrunIsLive == 0 || timerBase == 0) {
    throw new Exception("Couldn't find speedrunIsLive / timerBase!");
  } else {
    print("Found speedrunIsLive at 0x" + speedrunIsLive.ToString("X"));
    print("Found timerBase at 0x" + timerBase.ToString("X"));
  }

  vars.speedrunIsLive = new MemoryWatcher<bool>(new DeepPointer(speedrunIsLive));
  vars.timerElapsed = new MemoryWatcher<long>(new DeepPointer(timerBase, 0x4));
  vars.timerStart = new MemoryWatcher<long>(new DeepPointer(timerBase, 0xC));
  vars.timerEnabled = new MemoryWatcher<bool>(new DeepPointer(timerBase, 0x14));

  vars.gomezAction = new MemoryWatcher<int>(new DeepPointer(fezGame + 0x7C, 0x88, 0x70));
  vars.levelWatcher = new StringWatcher(new DeepPointer(fezGame + 0x7C, 0x38, 0x4, 0x8), 100);
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
        print("Found text component at " + component);
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
    vars.runStarting = true;
  }
  if (vars.runStarting && vars.timerEnabled.Current) {
    print("Starting run");
    vars.deathCount = 0;
    vars.gameTime = 0;
    vars.level = "GOMEZ_HOUSE_2D";
    vars.runStarting = false;
    return true;
  }
}

reset {
  if (vars.speedrunIsLive.Old && !vars.speedrunIsLive.Current) {
    print("Reset run");
    return true;
  }
}

split {
  if (vars.levelWatcher.Changed) {
    string oldLevel = vars.level;
    string newLevel = vars.levelWatcher.Current;
    if (vars.levels.Contains(newLevel) && oldLevel != newLevel) {
      print("Changed level from " + oldLevel + " to " + newLevel);
      vars.level = newLevel;
      if (settings["all_levels"]) {
        return true;
      }
      if (oldLevel == "MEMORY_CORE" && newLevel == "NATURE_HUB") {
        return settings["village"] || settings["full_village"];
      } else if (oldLevel == "TWO_WALLS" && newLevel == "NATURE_HUB") {
        return settings["bellTower"] || settings["full_bellTower"];
      } else if (oldLevel == "PIVOT_WATERTOWER" && newLevel == "MEMORY_CORE") {
        return settings["lighthouse"] || settings["full_lighthouse"];
      } else if (oldLevel == "ZU_BRIDGE" && newLevel == "ZU_CITY_RUINS") {
        return settings["tree"] || settings["full_tree"];
      } else if (oldLevel == "GOMEZ_HOUSE_END_32" && newLevel == "VILLAGEVILLE_3D_END_32") {
        return settings["ending32"];
      } else if (oldLevel == "GOMEZ_HOUSE_END_64" && newLevel == "VILLAGEVILLE_3D_END_64") {
        return settings["full_ending64"];
      } else if (oldLevel == "CMY_B" && newLevel == "NATURE_HUB") {
        return settings["waterfall"] || settings["full_waterfall"];
      } else if (oldLevel == "FIVE_TOWERS" && newLevel == "NATURE_HUB") {
        return settings["arch"];
      } else if (oldLevel == "QUANTUM" && newLevel == "NATURE_HUB") {
        return settings["full_arch"];
      } else if (oldLevel == "VISITOR" && newLevel == "ZU_CITY_RUINS") {
        return settings["zu"];
      } else if (oldLevel == "ZU_CITY_RUINS" && newLevel == "NATURE_HUB") {
        return settings["full_zu"];
      } else if (oldLevel == "MINE_WRAP" && newLevel == "NATURE_HUB") {
        return settings["full_mine"];
      } else if (oldLevel == "PIVOT_WATERTOWER" && newLevel == "INDUSTRIAL_HUB") {
        return settings["full_cubeDoors"];
      } else if (oldLevel == "WELL_2" && newLevel == "SEWER_START") {
        return settings["full_industrial"];
      } else if (oldLevel == "SEWER_TO_LAVA" && newLevel == "NUZU_ABANDONED_B") {
        return settings["full_sewers"];
      } else if (oldLevel == "INDUSTRIAL_HUB" && newLevel == "NATURE_HUB") {
        return settings["full_industrialWrapUp"];
      } else if (oldLevel == "GRAVEYARD_GATE" && newLevel == "NATURE_HUB") {
        return settings["full_graveyard"];
      }
    }
  }
  if (vars.gomezAction.Changed) {
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
      print("Gametime jumped by >1s, waiting for a more stable value.");
      print("Old gametime: " + vars.gameTime + " New gametime: " + newGameTime);
    } else {
      vars.gameTime = newGameTime;
    }
    return new TimeSpan(vars.gameTime);
  }
}
