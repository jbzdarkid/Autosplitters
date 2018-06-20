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
  vars.gameTime = 0.0;
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

  // TODO: These should work for auto start & death count
  vars.speedrunIsLive = new MemoryWatcher<bool>(new DeepPointer(0x0));
  vars.gomezAction = new MemoryWatcher<bool>(new DeepPointer(0x0));
  
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

    new SigScanTarget(0,
      "49 00 43 00 6F 00 6D 00 70 00 61 00 72 00 61 00 62 00 6C 00 65" // IComparable
    ));
    vars.gomezAction = new MemoryWatcher<int>(new DeepPointer(scanPtr2 + 0x20C));
  */
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
