state("FEZ") {}

startup {
  print("startup");
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
    "33 C0",        //xor eax,eax
    "F3 AB",        //repe stosd
    "80 3D ?? ?? ?? ?? 00", //cmp byte ptr [XXXX57EC],00
    "0F 84 ?? ?? 00 00",  //je FezGame.SpeedRun::Draw+339
    "8B 0D ?? ?? ?? ??",  //mov ecx,[XXXX3514]
    "38 01"         //cmp [ecx],al
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
    vars.scanPtr1 = vars.PageScan(proc, vars.scanTarget1, MemPageProtect.PAGE_EXECUTE_READWRITE);
    vars.speedrunAddr = proc.ReadValue<int>((IntPtr)vars.scanPtr1 + 0x6);
    vars.timerPtr = proc.ReadValue<int>((IntPtr)vars.scanPtr1 + 0x13);

    vars.speedrunBegan = new MemoryWatcher<bool>((IntPtr)vars.speedrunAddr);
    vars.timerAddr = new MemoryWatcher<int>((IntPtr)vars.timerPtr);
    vars.timerAddr.Update(proc);

    vars.GetTimer();
  });

  vars.GetTimer = (Action)(() => 
  {
    vars.timerElapsed = new MemoryWatcher<long>((IntPtr)vars.timerAddr.Current + 0x4);
    vars.timerStart = new MemoryWatcher<long>((IntPtr)vars.timerAddr.Current + 0xC);
    vars.timerEnabled = new MemoryWatcher<bool>((IntPtr)vars.timerAddr.Current + 0x14);
  });

  vars.ScanPlayerManager = (Action<Process>)((proc) => 
  {
    vars.scanPtr2 = vars.PageScan(proc, vars.scanTarget2, MemPageProtect.PAGE_READWRITE);
    print("0x"+vars.scanPtr2.ToString("X"));
    vars.playerManagerAddr = vars.scanPtr2 + 0x19C;
    print("0x"+vars.playerManagerAddr.ToString("X"));
    vars.gameStateAddr = proc.ReadValue<int>((IntPtr)vars.playerManagerAddr + 0x60);
    print("0x"+vars.gameStateAddr.ToString("X"));
    vars.saveDataAddr = proc.ReadValue<int>((IntPtr)vars.gameStateAddr + 0x5C);
    print("0x"+vars.saveDataAddr.ToString("X"));

    vars.playerManager = new MemoryWatcher<int>((IntPtr)vars.playerManagerAddr);
    vars.gomezAction = new MemoryWatcher<byte>((IntPtr)vars.playerManagerAddr + 0x70);
    vars.doorEnter = new MemoryWatcher<byte>((IntPtr)vars.playerManagerAddr + 0xA3);
    vars.doorDestAddr = new MemoryWatcher<int>((IntPtr)vars.playerManagerAddr + 0x34);
    vars.currentLevelAddr = new MemoryWatcher<int>((IntPtr)vars.saveDataAddr + 0x14);

    vars.doorDestAddr.Update(proc);
    vars.GetDoorDest(proc);

    vars.currentLevelAddr.Update(proc);
    vars.GetCurrentLevel();
  });

  vars.GetDoorDest = (Action<Process>)((proc) =>
  {
    vars.doorDest = proc.ReadString((IntPtr)vars.doorDestAddr.Current + 0x8, 44);
  });

  vars.GetCurrentLevel = (Action)(() =>
  {
    vars.currentLevel = new StringWatcher((IntPtr)vars.currentLevelAddr.Current + 0x8, 44); //stringwatcher is used because the pointer changes before the string is loaded
  });
}

init {
  print("init");
  vars.scanPtr1 = IntPtr.Zero;
  vars.scanPtr2 = IntPtr.Zero;
  vars.speedrunBegan = new MemoryWatcher<bool>(IntPtr.Zero);
  vars.timerAddr = new MemoryWatcher<int>(IntPtr.Zero);
  vars.timerElapsed = new MemoryWatcher<long>(IntPtr.Zero);
  vars.timerStart = new MemoryWatcher<long>(IntPtr.Zero);
  vars.timerEnabled = new MemoryWatcher<bool>(IntPtr.Zero);
  vars.playerManager = new MemoryWatcher<int>(IntPtr.Zero);
  vars.gomezAction = new MemoryWatcher<int>(IntPtr.Zero);
  vars.doorEnter = new MemoryWatcher<byte>(IntPtr.Zero);
  vars.doorDestAddr = new MemoryWatcher<int>(IntPtr.Zero);
  vars.currentLevelAddr = new MemoryWatcher<int>(IntPtr.Zero);
  vars.currentLevel = new StringWatcher(IntPtr.Zero, 0);

  vars.watchers = new MemoryWatcherList();
}

update {
  vars.watchers.UpdateAll(game);
  
  if (vars.scanPtr1 == IntPtr.Zero || vars.scanPtr2 == IntPtr.Zero)
  {
    print("[Autosplitter] Scanning memory");

    vars.ScanStable(game);
    vars.ScanPlayerManager(game);
  }

  if (vars.timerAddr.Changed) {
    vars.GetTimer();
  }

  if (vars.playerManager.Changed) {
    vars.ScanPlayerManager(game);
  } else if (vars.doorDestAddr.Changed && vars.doorDestAddr.Current != 0) {
    vars.GetDoorDest(game);
  } else if (vars.currentLevelAddr.Changed) {
    vars.GetCurrentLevel();
  }

  vars.watchers = new MemoryWatcherList()
  {
    vars.speedrunBegan,
    vars.timerAddr,
    vars.timerElapsed,
    vars.timerStart,
    vars.timerEnabled,
    vars.playerManager,
    vars.gomezAction,
    vars.doorEnter,
    vars.doorDestAddr,
    vars.currentLevelAddr,
    vars.currentLevel
  };
}

start {
  return vars.speedrunBegan.Current && vars.timerEnabled.Current;
}

reset {
  return !vars.speedrunBegan.Current;
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
