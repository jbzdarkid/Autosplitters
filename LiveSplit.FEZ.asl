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
  settings.Add("cubes", false, "Split on Cubes");
  settings.Add("levels", false, "Split when changing levels");
  
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
    
    vars.playerManager = new MemoryWatcher<int>(new DeepPointer(scanPtr2 + 0x19C));
    vars.gomezAction = new MemoryWatcher<byte>(new DeepPointer(scanPtr2 + 0x20C));
    vars.level = new StringWatcher(new DeepPointer(scanPtr2 + 0x1FC, 0x5C, 0x14, 0x8), 100);
    vars.level.Update(game);

    // SpeedRun::AddCube might be useful here?
    //  8B 3D ???????? 47 89 3D ????????
    
    vars.watchers = new MemoryWatcherList() {
      vars.speedrunIsLive,
      vars.timerElapsed,
      vars.timerStart,
      vars.timerEnabled,
      vars.playerManager,
      vars.gomezAction,
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
  if (vars.gomezAction.Changed) {
    if (vars.gomezAction.Current == 0x3C || vars.gomezAction.Current == 0x3D || vars.gomezAction.Current == 0x3E || vars.gomezAction.Current == 0x62) {
      vars.level.Update(game);
      print("[Autosplitter] Door Transition: " + vars.level.Old + " -> " + vars.level.Current);
      if (settings["levels"]) {
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
      }
    } else if (vars.gomezAction.Current == 0x60) {
      // if (settings["Split on all warps"]) return true;
      print("[Autosplitter] Warp Activated: @" + vars.level.Current);
      if (vars.level.Current == "CMY_B") {
        return settings["waterfall"];
      } else if (vars.level.Current == "FIVE_TOWERS") {
        return settings["arch"];
      } else if (vars.level.Current == "VISITOR") {
        return settings["zu"];
      }
    } else if (vars.gomezAction.Current == 0x25) {
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
    var elapsedTicks = vars.timerElapsed.Current + Stopwatch.GetTimestamp() - vars.timerStart.Current;
    return new TimeSpan(elapsedTicks * 10000000 / Stopwatch.Frequency);
  }
}
