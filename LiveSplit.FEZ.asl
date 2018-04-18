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

  vars.PageScan = (Func<Process, SigScanTarget, MemPageProtect, IntPtr>)((proc, target, protect) => 
  {
    var ptr = IntPtr.Zero;

    foreach (var page in proc.MemoryPages())
    {
      if (page.State == MemPageState.MEM_COMMIT && page.Type == MemPageType.MEM_PRIVATE && page.Protect == protect)
      {
        var scanner = new SignatureScanner(proc, page.BaseAddress, (int)page.RegionSize);

        if (ptr == IntPtr.Zero) {
          ptr = scanner.Scan(target);
        } else {
          break;
        }
      }
    }

    return ptr;
  });

  vars.ScanStable = (Action<Process>)((proc) => 
  {
    int offset = (int)proc.Modules[0].BaseAddress;

    IntPtr scanPtr1 = vars.PageScan(proc, vars.scanTarget1, MemPageProtect.PAGE_EXECUTE_READWRITE);
    vars.scanPtr1 = scanPtr1;
    int baseOffset = (int)scanPtr1 - offset;

    vars.speedrunIsLive = new MemoryWatcher<bool>(new DeepPointer(baseOffset + 0x6, 0x0));
    vars.timerElapsed = new MemoryWatcher<long>(new DeepPointer(baseOffset + 0x13, 0x0, 0x4));
    vars.timerStart = new MemoryWatcher<long>(new DeepPointer(baseOffset + 0x13, 0x0, 0xC));
    vars.timerEnabled = new MemoryWatcher<bool>(new DeepPointer(baseOffset + 0x13, 0x0, 0x14));
  });

  vars.ScanPlayerManager = (Action<Process>)((proc) => 
  {
    int offset = (int)proc.Modules[0].BaseAddress;
    
    IntPtr scanPtr2 = vars.PageScan(proc, vars.scanTarget2, MemPageProtect.PAGE_READWRITE);
    vars.scanPtr2 = scanPtr2;
    int baseOffset = (int)scanPtr2 - offset;

    vars.gomezAction = new MemoryWatcher<byte>(new DeepPointer(baseOffset + 0x20C));
    vars.doorEnter = new MemoryWatcher<byte>(new DeepPointer(baseOffset + 0x23F));

    vars.doorDest = new StringWatcher(new DeepPointer(baseOffset + 0x1D0, 0x8), 100);
    vars.level = new StringWatcher(new DeepPointer(baseOffset + 0x1FC, 0x5C, 0x14, 0x8), 100);

    /*


    vars.scanPtr2 = vars.PageScan(proc, vars.scanTarget2, MemPageProtect.PAGE_READWRITE);
    vars.playerManagerAddr = vars.scanPtr2 + 0x19C;
    vars.gameStateAddr = proc.ReadValue<int>((IntPtr)vars.playerManagerAddr + 0x60);
    vars.saveDataAddr = proc.ReadValue<int>((IntPtr)vars.gameStateAddr + 0x5C);

    vars.playerManager = new MemoryWatcher<int>((IntPtr)vars.playerManagerAddr);
    vars.gomezAction = new MemoryWatcher<byte>((IntPtr)vars.playerManagerAddr + 0x70);
    vars.doorEnter = new MemoryWatcher<byte>((IntPtr)vars.playerManagerAddr + 0xA3);
    vars.doorDestAddr = new MemoryWatcher<int>((IntPtr)vars.playerManagerAddr + 0x34);
    vars.currentLevelAddr = new MemoryWatcher<int>((IntPtr)vars.saveDataAddr + 0x14);

    vars.doorDestAddr.Update(proc);
    vars.doorDestSW = new StringWatcher((IntPtr)vars.doorDestAddr.Current + 0x8, 100);

    vars.currentLevelAddr.Update(proc);
    vars.currentLevel = new StringWatcher((IntPtr)vars.currentLevelAddr.Current + 0x8, 44);
    vars.level = new StringWatcher((IntPtr)vars.currentLevelAddr.Current + 0x8, 100);
    vars.level.Update(proc);
    */
  });
}

init {
  vars.scanPtr1 = IntPtr.Zero;
  vars.scanPtr2 = IntPtr.Zero;
  vars.speedrunIsLive = new MemoryWatcher<bool>(IntPtr.Zero);
  vars.timerElapsed = new MemoryWatcher<long>(IntPtr.Zero);
  vars.timerStart = new MemoryWatcher<long>(IntPtr.Zero);
  vars.timerEnabled = new MemoryWatcher<bool>(IntPtr.Zero);
  vars.gomezAction = new MemoryWatcher<int>(IntPtr.Zero);
  vars.doorEnter = new MemoryWatcher<byte>(IntPtr.Zero);

  vars.watchers = new MemoryWatcherList();
}

update {
  vars.watchers.UpdateAll(game);
  
  if (vars.scanPtr1 == IntPtr.Zero || vars.scanPtr2 == IntPtr.Zero) {
    print("[Autosplitter] Scanning memory");

    vars.ScanStable(game);
    vars.ScanPlayerManager(game);
  }

  vars.watchers = new MemoryWatcherList()
  {
    vars.speedrunIsLive,
    vars.timerElapsed,
    vars.timerStart,
    vars.timerEnabled,
    vars.gomezAction,
    vars.doorEnter,
    vars.level,
    vars.doorDest,
  };
}

start {
  return vars.speedrunIsLive.Current && vars.timerEnabled.Current;
}

reset {
  return !vars.speedrunIsLive.Current;
}

split {
  if (vars.doorEnter.Changed && vars.doorEnter.Current == 1) {
    print("[Autosplitter] Door Transition: " + vars.level.Current + " -> " + vars.doorDest.Current);
    // if (settings["Split on all doors"]) return true;
    if (vars.level.Current == "MEMORY_CORE" && vars.doorDest.Current == "NATURE_HUB") {
      return settings["village"];
    } else if (vars.level.Current == "TWO_WALLS" && vars.doorDest.Current == "NATURE_HUB") {
      return settings["bellTower"];
    } else if (vars.level.Current == "PIVOT_WATERTOWER" && vars.doorDest.Current == "MEMORY_CORE") {
      return settings["lighthouse"];
    } else if (vars.level.Current == "ZU_BRIDGE" && vars.doorDest.Current == "ZU_CITY_RUINS") {
      return settings["tree"];
    } else if (vars.level.Current == "GOMEZ_HOUSE_END_32" && vars.doorDest == "VILLAGEVILLE_3D_END_32") {
      print("<177>");
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
  if (settings["ending32"] && vars.doorEnter.Current == 1 && vars.level.Current == "GOMEZ_HOUSE_END_32" && vars.doorDest == "VILLAGEVILLE_3D_END_32" && !vars.timerEnabled.Current) {
    print("<193>");
    return true;
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
