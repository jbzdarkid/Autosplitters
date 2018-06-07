state("FEZ") {}
// Animation states:
// 00: None
// 01: Idle
// 02: LookingLeft
// 03: LookingRight
// 04: LookingUp
// 05: LookingDown
// 06: Walking
// 07: Running
// 08: Jumping
// 09: FrontClimbingLadder
// 0A: BackClimbingLadder
// 0B: SideClimbingLadder
// 0C: CarryIdle
// 0D: CarryWalk
// 0E: CarryJump
// 0F: CarrySlide
// 10: CarryEnter
// 11: CarryHeavyIdle
// 12: CarryHeavyWalk
// 13: CarryHeavyJump
// 14: CarryHeavySlide
// 15: CarryHeavyEnter
// 16: DropTrile
// 17: DropHeavyTrile
// 18: Throwing
// 19: ThrowingHeavy
// 1A: Lifting
// 1B: LiftingHeavy
// 1C: Dying
// 1D: Suffering
// 1E: Falling
// 1F: Bouncing
// 20: Flying
// 21: Dropping
// 22: Sliding
// 23: Landing
// 24: ReadingSign
// 25: FreeFalling
// 26: CollectingFez
// 27: Victory
// 28: EnteringDoor
// 29: Grabbing
// 2A: Pushing
// 2B: SuckedIn
// 2C: FrontClimbingVine
// 2D: FrontClimbingVineSideways
// 2E: SideClimbingVine
// 2F: BackClimbingVine
// 30: BackClimbingVineSideways
// 31: WakingUp
// 32: OpeningTreasure
// 33: OpeningDoor
// 34: WalkingTo
// 35: Treading
// 36: Swimming
// 37: Sinking
// 38: Teetering
// 39: HurtSwim
// 3A: EnteringTunnel
// 3B: PushingPivot
// 3C: EnterDoorSpin
// 3D: EnterDoorSpinCarry
// 3E: EnterDoorSpinCarryHeavy
// 3F: EnterTunnelCarry
// 40: EnterTunnelCarryHeavy
// 41: RunTurnAround
// 42: FindingTreasure
// 43: IdlePlay
// 44: IdleSleep
// 45: IdleLookAround
// 46: PullUpCornerLedge
// 47: LowerToCornerLedge
// 48: GrabCornerLedge
// 49: GrabLedgeFront
// 4A: GrabLedgeBack
// 4B: PullUpFront
// 4C: PullUpBack
// 4D: LowerToLedge
// 4E: ShimmyFront
// 4F: ShimmyBack
// 50: ToCornerFront
// 51: ToCornerBack
// 52: FromCornerBack
// 53: IdleToClimb
// 54: IdleToFrontClimb
// 55: IdleToSideClimb
// 56: JumpToClimb
// 57: JumpToSideClimb
// 58: ClimbOverLadder
// 59: GrabTombstone
// 5A: PivotTombstone
// 5B: LetGoOfTombstone
// 5C: EnteringPipe
// 5D: ExitDoor
// 5E: ExitDoorCarry
// 5F: ExitDoorCarryHeavy
// 60: LesserWarp
// 61: GateWarp
// 62: SleepWake
// 63: ReadTurnAround
// 64: EndReadTurnAround
// 65: TurnToBell
// 66: HitBell
// 67: TurnAwayFromBell
// 68: CrushHorizontal
// 69: CrushVertical
// 6A: DrumsIdle
// 6B: DrumsCrash
// 6C: DrumsTom
// 6D: DrumsTom2
// 6E: DrumsToss
// 6F: DrumsTwirl
// 70: DrumsHiHat
// 71: VictoryForever
// 72: Floating
// 73: Standing
// 74: StandWinking
// 75: IdleYawn

startup {
  vars.timerDebug = 0.0;
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

  vars.PageScan = (Func<Process, MemPageProtect, SigScanTarget, int>)((proc, protect, target) => 
  {
    foreach (var page in proc.MemoryPages())
    {
      if (page.State == MemPageState.MEM_COMMIT && page.Type == MemPageType.MEM_PRIVATE && page.Protect == protect)
      {
        var scanner = new SignatureScanner(proc, page.BaseAddress, (int)page.RegionSize);

        IntPtr ptr = scanner.Scan(target);
        if (ptr != IntPtr.Zero) {
          print(ptr.ToString("X"));
          // TODO: Why is this not the current page?
          return (int)ptr - (int)proc.Modules[0].BaseAddress;
        }
      }
    }
    return 0;
  });
  
  vars.levels = new List<string> {"ABANDONED_A", "ABANDONED_B", "ABANDONED_C", "ANCIENT_WALLS", "ARCH", "BELL_TOWER", "BIG_OWL", "BIG_TOWER", "BOILEROOM", "CABIN_INTERIOR_A", "CABIN_INTERIOR_B", "CLOCK", "CMY", "CMY_B", "CMY_FORK", "CODE_MACHINE", "CRYPT", "DRUM", "ELDERS", "EXTRACTOR_A", "FIVE_TOWERS", "FIVE_TOWERS_CAVE", "FOX", "FRACTAL", "GEEZER_HOUSE", "GEEZER_HOUSE_2D", "GLOBE", "GLOBE_INT", "GOMEZ_HOUSE", "GOMEZ_HOUSE_2D", "GOMEZ_HOUSE_END_32", "GOMEZ_HOUSE_END_64", "GRAVE_CABIN", "GRAVE_GHOST", "GRAVE_LESSER_GATE", "GRAVE_TREASURE_A", "GRAVEYARD_A", "GRAVEYARD_GATE", "HEX_REBUILD", "INDUST_ABANDONED_A", "INDUSTRIAL_CITY", "INDUSTRIAL_HUB", "INDUSTRIAL_SUPERSPIN", "KITCHEN", "KITCHEN_2D", "LAVA", "LAVA_FORK", "LAVA_SKULL", "LIBRARY_INTERIOR", "LIGHTHOUSE", "LIGHTHOUSE_HOUSE_A", "LIGHTHOUSE_SPIN", "MAUSOLEUM", "MEMORY_CORE", "MINE_A", "MINE_BOMB_PILLAR", "MINE_WRAP", "NATURE_HUB", "NUZU_ABANDONED_A", "NUZU_ABANDONED_B", "NUZU_BOILERROOM", "NUZU_DORM", "NUZU_SCHOOL", "OBSERVATORY", "OCTOHEAHEDRON", "OLDSCHOOL", "OLDSCHOOL_RUINS", "ORRERY", "ORRERY_B", "OWL", "PARLOR", "PARLOR_2D", "PIVOT_ONE", "PIVOT_THREE", "PIVOT_THREE_CAVE", "PIVOT_TWO", "PIVOT_WATERTOWER", "PURPLE_LODGE", "PURPLE_LODGE_RUIN", "PYRAMID", "QUANTUM", "RAILS", "RITUAL", "SCHOOL", "SCHOOL_2D", "SEWER_FORK", "SEWER_GEYSER", "SEWER_HUB", "SEWER_LESSER_GATE_B", "SEWER_PILLARS", "SEWER_PIVOT", "SEWER_QR", "SEWER_START", "SEWER_TO_LAVA", "SEWER_TREASURE_ONE", "SEWER_TREASURE_TWO", "SHOWERS", "SKULL", "SKULL_B", "SPINNING_PLATES", "STARGATE", "STARGATE_RUINS", "SUPERSPIN_CAVE", "TELESCOPE", "TEMPLE_OF_LOVE", "THRONE", "TREE", "TREE_CRUMBLE", "TREE_OF_DEATH", "TREE_ROOTS", "TREE_SKY", "TRIAL", "TRIPLE_PIVOT_CAVE", "TWO_WALLS", "VILLAGEVILLE_2D", "VILLAGEVILLE_3D", "VILLAGEVILLE_3D_END_32", "VILLAGEVILLE_3D_END_64", "VISITOR", "WALL_HOLE", "WALL_INTERIOR_A", "WALL_INTERIOR_B", "WALL_INTERIOR_HOLE", "WALL_KITCHEN", "WALL_SCHOOL", "WALL_VILLAGE", "WATER_PYRAMID", "WATER_TOWER", "WATER_WHEEL", "WATER_WHEEL_B", "WATERFALL", "WATERFALL_ALT", "WATERTOWER_SECRET", "WEIGHTSWITCH_TEMPLE", "WELL_2", "WINDMILL_CAVE", "WINDMILL_INT", "ZU_4_SIDE", "ZU_BRIDGE", "ZU_CITY", "ZU_CITY_RUINS", "ZU_CODE_LOOP", "ZU_FORK", "ZU_HEADS", "ZU_HOUSE_EMPTY", "ZU_HOUSE_EMPTY_B", "ZU_HOUSE_QR", "ZU_HOUSE_RUIN_GATE", "ZU_HOUSE_RUIN_VISITORS", "ZU_HOUSE_SCAFFOLDING", "ZU_LIBRARY", "ZU_SWITCH", "ZU_SWITCH_B", "ZU_TETRIS", "ZU_THRONE_RUINS", "ZU_UNFOLD", "ZU_ZUISH"};
}

init {
  // Clear this in init so that restarting the game will force a re-scan of memory.
  vars.deathCount = 0;
  vars.watchers = new MemoryWatcherList();
  
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
  if (vars.watchers.Count == 0) {
    print("[Autosplitter] Scanning for timer");

    int scanPtr1 = vars.PageScan(game, MemPageProtect.PAGE_EXECUTE_READWRITE, new SigScanTarget(0,
      "33 C0",                // xor eax,eax
      "F3 AB",                // repe stosd
      "80 3D ?? ?? ?? ?? 00", // cmp byte ptr [XXXX57EC],00
      "0F 84 ?? ?? 00 00",    // je FezGame.SpeedRun::Draw+339
      "8B 0D ?? ?? ?? ??",    // mov ecx,[XXXX3514]
      "38 01"                 // cmp [ecx],al
    ));
    if (scanPtr1 == 0) {
      print("Couldn't find scanPtr1");
      return false;
    }
    
    vars.speedrunIsLive = new MemoryWatcher<bool>(new DeepPointer(scanPtr1 + 0x6, 0x0));
    vars.timerElapsed = new MemoryWatcher<long>(new DeepPointer(scanPtr1 + 0x13, 0x0, 0x4));
    vars.timerStart = new MemoryWatcher<long>(new DeepPointer(scanPtr1 + 0x13, 0x0, 0xC));
    vars.timerEnabled = new MemoryWatcher<bool>(new DeepPointer(scanPtr1 + 0x13, 0x0, 0x14));
  }
  if (vars.watchers.Count == 0 || vars.playerManager.Changed) {
    print("Scanning for player manager");
    int scanPtr2 = vars.PageScan(game, MemPageProtect.PAGE_READWRITE, new SigScanTarget(0,
      "49 00 43 00 6F 00 6D 00 70 00 61 00 72 00 61 00 62 00 6C 00 65" // IComparable
    ));
    if (scanPtr2 == 0) {
      print("Couldn't find scanPtr2");
      return false;
    }
    // This one is stable...
    vars.levelManager = new MemoryWatcher<int>(new DeepPointer(scanPtr2 + 0x1F8));
    
    // This one isn't...
    vars.playerManager = new MemoryWatcher<int>(new DeepPointer(scanPtr2 + 0x19C));
    vars.gomezAction = new MemoryWatcher<int>(new DeepPointer(scanPtr2 + 0x20C));
    vars.levelWatcher = new StringWatcher(new DeepPointer(scanPtr2 + 0x1FC, 0x5C, 0x14, 0x8), 100);

    // SpeedRun::AddCube might be useful here?
    //  8B 3D ???????? 47 89 3D ????????
    
    vars.watchers = new MemoryWatcherList() {
      vars.speedrunIsLive,
      vars.timerElapsed,
      vars.timerStart,
      vars.timerEnabled,
      vars.playerManager,
      vars.gomezAction,
      vars.levelWatcher,
    };
  }
  vars.watchers.UpdateAll(game);
  
  if (vars.tcs != null && (vars.updateText || old.deathCount != current.deathCount)) {
    vars.tcs.Text1 = "Fall Count:";
    vars.tcs.Text2 = vars.deathCount.ToString();
  }
}

start {
  if (vars.speedrunIsLive.Current && vars.timerEnabled.Current) {
    vars.watchers = new MemoryWatcherList();
    vars.deathCount = 0;
    vars.level = "MAIN_MENU";
    return true;
  }
}

reset {
  if (!vars.speedrunIsLive.Current) {
    print("Reset run");
    return true;
  }
}

split {
  if (vars.levelWatcher.Changed) {
    string oldLevel = vars.level;
    string newLevel = vars.levelWatcher.Current;
    if (vars.levels.Contains(newLevel) && oldLevel != newLevel) {
      print("[Autosplitter] Door Transition: " + oldLevel + " -> " + newLevel);
      vars.level = newLevel;
      if (settings["all_levels"]) {
        return true;
      }
      if (vars.level == "MEMORY_CORE" && newLevel == "NATURE_HUB") {
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
      } else if (oldLevel == "FIVE_TOWERS" && newLevel == "NATURE_HUB") {
        return settings["arch"];
      } else if (oldLevel == "VISITOR" && newLevel == "ZU_CITY_RUINS") {
        return settings["zu"];
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
    var timestamp = Stopwatch.GetTimestamp();
    var start = vars.timerStart.Current;
    var elapsed = vars.timerElapsed.Current;

    var elapsedTicks = timestamp - start + elapsed;
    var newTimerDebug = elapsedTicks * 10000000 / Stopwatch.Frequency;
    if (Math.Abs(vars.timerDebug - newTimerDebug) > 10000000) {
      print(start + " " + timestamp + " " + elapsed + " " + vars.timerDebug + " " + newTimerDebug);
    }
    vars.timerDebug = newTimerDebug;
    return new TimeSpan(vars.timerDebug);
  }
}
