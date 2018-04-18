state("FEZ") {}

startup {
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

  vars.scanTarget1 = new SigScanTarget(0,
    "33 C0",                //xor eax,eax
    "F3 AB",                //repe stosd
    "80 3D ?? ?? ?? ?? 00", //cmp byte ptr [XXXX57EC],00
    "0F 84 ?? ?? 00 00",    //je FezGame.SpeedRun::Draw+339
    "8B 0D ?? ?? ?? ??",    //mov ecx,[XXXX3514]
    "38 01"                 //cmp [ecx],al
  );
  vars.scanTarget2 = new SigScanTarget(0, "49 00 43 00 6F 00 6D 00 70 00 61 00 72 00 61 00 62 00 6C 00 65"); //IComparable

  vars.PageScan = (Func<Process, SigScanTarget, MemPageProtect, int>)((proc, target, protect) => 
  {
    foreach (var page in proc.MemoryPages())
    {
      if (page.State == MemPageState.MEM_COMMIT && page.Type == MemPageType.MEM_PRIVATE && page.Protect == protect)
      {
        var scanner = new SignatureScanner(proc, page.BaseAddress, (int)page.RegionSize);

        IntPtr ptr = scanner.Scan(target);
        if (ptr != IntPtr.Zero) {
          // TODO: Why is this not the current page?
          return (int)ptr - (int)proc.Modules[0].BaseAddress;
        }
      }
    }
    return 0;
  });
}

init {
  // Clear this in init so that restarting the game will force a re-scan of memory.
  vars.watchers = new MemoryWatcherList();
}

update {
  if (vars.watchers.Count == 0) {
    print("[Autosplitter] Scanning memory");

    int scanPtr1 = vars.PageScan(game, vars.scanTarget1, MemPageProtect.PAGE_EXECUTE_READWRITE);
    if (scanPtr1 == 0) return false;

    // TODO: Clean these up?
    vars.speedrunIsLive = new MemoryWatcher<bool>(new DeepPointer(scanPtr1 + 0x6, 0x0));
    vars.timerElapsed = new MemoryWatcher<long>(new DeepPointer(scanPtr1 + 0x13, 0x0, 0x4));
    vars.timerStart = new MemoryWatcher<long>(new DeepPointer(scanPtr1 + 0x13, 0x0, 0xC));
    vars.timerEnabled = new MemoryWatcher<bool>(new DeepPointer(scanPtr1 + 0x13, 0x0, 0x14));

    int scanPtr2 = vars.PageScan(game, vars.scanTarget2, MemPageProtect.PAGE_READWRITE);
    if (scanPtr2 == 0) return false;

    vars.gomezAction = new MemoryWatcher<byte>(new DeepPointer(scanPtr2 + 0x20C));
    vars.changingLevel = new MemoryWatcher<byte>(new DeepPointer(scanPtr2 + 0x23F));
    // Level isn't completely stable (too deep of a pointer, probably), so it hiccups some times.
    vars.level = new StringWatcher(new DeepPointer(scanPtr2 + 0x1FC, 0x5C, 0x14, 0x8), 100);
    vars.nextLevel = new StringWatcher(new DeepPointer(scanPtr2 + 0x1D0, 0x8), 100);

    vars.watchers = new MemoryWatcherList() {
      vars.speedrunIsLive,
      vars.timerElapsed,
      vars.timerStart,
      vars.timerEnabled,
      vars.gomezAction,
      vars.changingLevel,
      vars.level,
      vars.nextLevel,
    };
  }
  vars.watchers.UpdateAll(game);
}

start {
  return vars.speedrunIsLive.Current && vars.timerEnabled.Current;
}

reset {
  return !vars.speedrunIsLive.Current;
}

split {
  if (vars.changingLevel.Old == 0 && vars.changingLevel.Current == 1) {
    print("[Autosplitter] Door Transition: " + vars.level.Current + " -> " + vars.nextLevel.Current);
    // if (settings["Split on all doors"]) return true;
    if (vars.level.Current == "MEMORY_CORE" && vars.nextLevel.Current == "NATURE_HUB") {
      return settings["village"];
    } else if (vars.level.Current == "TWO_WALLS" && vars.nextLevel.Current == "NATURE_HUB") {
      return settings["bellTower"];
    } else if (vars.level.Current == "PIVOT_WATERTOWER" && vars.nextLevel.Current == "MEMORY_CORE") {
      return settings["lighthouse"];
    } else if (vars.level.Current == "ZU_BRIDGE" && vars.nextLevel.Current == "ZU_CITY_RUINS") {
      return settings["tree"];
    } else if (vars.level.Current == "GOMEZ_HOUSE_END_32" && vars.nextLevel.Current == "VILLAGEVILLE_3D_END_32") {
      return settings["ending32"];
    }
  }
  if (vars.gomezAction.Changed && vars.gomezAction.Current == 0x60) {
    // if (settings["Split on all warps"]) return true;
    print("[Autosplitter] Warp Activated: @" + vars.level.Current);
    if (vars.level.Current == "CMY_B") {
      return settings["waterfall"];
    } else if (vars.level.Current == "FIVE_TOWERS") {
      return settings["arch"];
    } else if (vars.level.Current == "VISITOR") {
      return settings["zu"];
    }
  }
}

isLoading {
  return true;
}

gameTime {
  if (vars.timerEnabled.Current)
  {
    var elapsedTicks = vars.timerElapsed.Current + Stopwatch.GetTimestamp() - vars.timerStart.Current;
    return new TimeSpan(elapsedTicks * 10000000 / Stopwatch.Frequency);
  }
}
