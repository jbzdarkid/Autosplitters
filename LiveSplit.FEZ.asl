state("FEZ") {}

startup {
  settings.Add("cubes", false, "Split on Cubes");
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
  settings.Add("deathcount", false, "Override first text component with a Fall Counter");
}

init {
  print("[Autosplitter] Scanning for FezGame");
  
  int fezGame = 0;
  foreach (var page in game.MemoryPages()) {
    if (page.Protect != MemPageProtect.PAGE_READWRITE) continue;
    var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);

    IntPtr ptr = scanner.Scan(new SigScanTarget(0,
      "32 00 30 00 31 00 36 00 2D 00 31 00 32 00 2D 00 30 00 31" // 2016-12-01 19:39:28
    ));
    if (ptr != IntPtr.Zero) {
      fezGame = (int)ptr - (int)game.Modules[0].BaseAddress - 0xA0;
      break;
    }
  }
  if (fezGame == 0) {
    print("Couldn't find FezGame!");
  } else {
    print("Found FezGame at 0x" + fezGame.ToString("X"));
  }
  
  vars.timerElapsed = new MemoryWatcher<long>(new DeepPointer(fezGame + 0x38, 0x4));
  vars.timerStart = new MemoryWatcher<long>(new DeepPointer(fezGame + 0x38, 0xC));
  vars.timerEnabled = new MemoryWatcher<bool>(new DeepPointer(fezGame + 0x38, 0x14));
  vars.level = new StringWatcher(new DeepPointer(fezGame + 0x7C, 0x38, 0x4, 0x8), 100);
  vars.gameTime = 0.0;

  // TODO: These should work for auto start & death count
  vars.speedrunIsLive = new MemoryWatcher<bool>(new DeepPointer(0x0));
  vars.gomezAction = new MemoryWatcher<int>(new DeepPointer(fezGame + 0x7C, 0x88, 0x70));
  /*
    SigScanTarget(0,
      "33 C0",                // xor eax,eax
      "F3 AB",                // repe stosd
      "80 3D ?? ?? ?? ?? 00", // cmp byte ptr [XXXX57EC],00
      "0F 84 ?? ?? 00 00",    // je FezGame.SpeedRun::Draw+339
      "8B 0D ?? ?? ?? ??",    // mov ecx,[XXXX3514]
      "38 01"                 // cmp [ecx],al
    );
    vars.speedrunIsLive = new MemoryWatcher<bool>(new DeepPointer(scanPtr1 + 0x6, 0x0));
  */
  
  vars.watchers = new MemoryWatcherList() {
    vars.speedrunIsLive,
    vars.timerElapsed,
    vars.timerStart,
    vars.timerEnabled,
    vars.gomezAction,
    vars.level,
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
}

update {
  vars.watchers.UpdateAll(game);
  if (vars.tcs != null && (vars.updateText || old.deathCount != current.deathCount)) {
    vars.tcs.Text1 = "Fall Count:";
    vars.tcs.Text2 = vars.deathCount.ToString();
  }
}

start {
  if (vars.speedrunIsLive.Current && vars.timerEnabled.Current) {
    vars.deathCount = 0;
    return true;
  }
}

reset {
  // TODO: Re-enable once this variable is done
  /*if (!vars.speedrunIsLive.Current) {
    print("Reset run");
    return true;
  }*/
}

split {
  if (vars.level.Changed) {
    print("[Autosplitter] Door Transition: " + vars.level.Old + " -> " + vars.level.Current);
    if (settings["all_levels"]) {
      return true;
    }
    if (vars.level.Old == "MEMORY_CORE" && vars.level.Current == "NATURE_HUB") {
      return settings["village"];
    } else if (vars.level.Old == "TWO_WALLS" && vars.level.Current == "NATURE_HUB") {
      return settings["bellTower"];
    } else if (vars.level.Old == "PIVOT_WATERTOWER" && vars.level.Current == "MEMORY_CORE") {
      return settings["lighthouse"];
    } else if (vars.level.Old == "ZU_BRIDGE" && vars.level.Current == "ZU_CITY_RUINS") {
      return settings["tree"];
    } else if (vars.level.Old == "GOMEZ_HOUSE_END_32" && vars.level.Current == "VILLAGEVILLE_3D_END_32") {
      return settings["ending32"];
    } else if (vars.level.Old == "CMY_B" && vars.level.Current == "NATURE_HUB") {
      return settings["waterfall"];
    } else if (vars.level.Old == "FIVE_TOWERS" && vars.level.Current == "NATURE_HUB") {
      return settings["arch"];
    } else if (vars.level.Old == "VISITOR" && vars.level.Current == "ZU_CITY_RUINS") {
      return settings["zu"];
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
    var oldGameTime = vars.gameTime;
    var elapsedTicks = Stopwatch.GetTimestamp() - vars.timerStart.Current + vars.timerElapsed.Current;;
    // 10,000,000: Number of ticks in a second
    vars.gameTime = elapsedTicks * 10000000 / Stopwatch.Frequency;
    if (Math.Abs(vars.gameTime - oldGameTime) > 10000000) { // Time jump by > 1s
      print("Gametime jumped by >1s, waiting for a more stable value.");
      print("Old gametime: " + oldGameTime + " New gametime: " + vars.gameTime);
      return false; // TODO: Throws an error?
    }
    return new TimeSpan(vars.gameTime);
  }
}
