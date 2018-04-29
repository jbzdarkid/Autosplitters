state("witness64_d3d11") {}
// TODO: "Split on lasers" should actually split on lasers, not laser panels

startup {
  // Environmental puzzles/patterns, the +135
  settings.Add("Split on environmental patterns", false);
  // Tracked via obelisks, which report their counts
  vars.obelisks = new List<int> {
    0x00098, // Treehouse
    0x00264, // Monastery
    0x0035A, // Desert
    0x00368, // Mountain
    0x0A16D, // Town
    0x22074, // Shadows
  };

  settings.Add("Split on all panels (solving and non-solving)", false);
  // Panels which are solved multiple times in a normal run
  vars.multiPanels = new List<int>{
    0x03679, 0x0367A, 0x03676, 0x03677, // Mill control panels
    0x03853, 0x03859, 0x275FB, // Boathouse control panels
    0x0060A, 0x17C0B, 0x17E08, 0x17E2C, 0x181F6, 0x18489, // Swamp Control Panels
    0x17CE4, 0x17DB8, 0x17DD2, 0x17E53, // Treehouse R1, R2, L, Green Rotators
    0x2896B, // Town Bridge Control
    0x334D9, // Town RGB light control

    0x09E3A, 0x09ED9, 0x09E87, // Purple, Blue, Orange Mountain Walkways
    0x03554, 0x03553, 0x0354F, 0x0354A, 0x03550, 0x03546, // Cinema Panels
    0x0A3B6, // Tutorial Back Left
    0x0362A, // Tutorial Gate
    0x09F99, // Desert Laser Redirect
    0x34D97, // Boat map
    0x079E0, // Town Triple Panel
    0x09D9C, // Monastery Bonzai
    0x0A07A, // Bunker Elevator
    0x09F80, // Mountaintop Box
    0x17C35, // Mountaintop Crazyhorse
    0x09FCD, // Mountain Multi
    0x09EEC, // Mountain Elevator
  };
  
  vars.keepWalkOns = new List<int>{
    0x033EB, // Yellow
    0x01BEA, // Purple
    0x01CD4, // Green
    0x01D40, // Blue
  };

  vars.multipanel = new List<int>{
    0x09FCD, 0x09FCF, 0x09FD0, 0x09FD1, 0x09FD2, 0x09FD3
  };

  // 11 lasers which unlock the mountain-top box
  settings.Add("Split on lasers", true);
  vars.lasers = new List<int>{
    0x032F6, // Town
    0x03609, // Desert
    0x0360E, // Symmetry
    0x0360F, // Keep Front
    0x03318, // Keep Rear
    0x03613, // Quarry
    0x03614, // Treehouse
    0x03616, // Swamp
    0x03617, // Jungle
    0x09DE1, // Bunker
    0x17CA5, // Monastery
    0x19651, // Shadows
  };
  
  // One-off splits (usually to accompany 11 lasers splits)
  settings.Add("Split on tutorial door", true);
  settings.Add("Split when starting the boat", false);
  settings.Add("Split on greenhouse elevator", false);
  settings.Add("Split when completing the first mountain floor", false);
  settings.Add("Split on mountain elevator", false);
  settings.Add("Split on final elevator", true);
  settings.Add("Start/split on challenge start", false);
  settings.Add("Reset on challenge stop", false);
  settings.Add("Split on challenge end", false);
  settings.Add("Split on easter egg ending", true);
  settings.Add("Enable random doors practice", false);
  vars.randomDoorsHack = false;
}

init {
  vars.panels = null; // Used to detect if init completes properly
  vars.startTime = 0.0;
  vars.activePanel = 0;
  var page = modules.First();
  var scanner = new SignatureScanner(game, page.BaseAddress, page.ModuleMemorySize);

  // get_active_panel()
  IntPtr ptr = scanner.Scan(new SigScanTarget(3, // Targeting byte 3
    "48 8B 05 ????????", // mov rax, [witness64_d3d11.exe + offset]
    "33 C9",             // xor ecx, ecx
    "48 85 C0",          // test rax, rax
    "74 06"              // je 6
  ));
  if (ptr == IntPtr.Zero) {
    throw new Exception("Could not find current puzzle!");
  }
  int relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;
  vars.puzzle = new MemoryWatcher<int>(new DeepPointer(
    relativePosition + game.ReadValue<int>(ptr),
    game.ReadValue<byte>(ptr+14),
    game.ReadValue<int>(ptr+22)
  ));
  relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 50;
  int basePointer = relativePosition + game.ReadValue<int>(ptr+46);
  print("witness64_d3d11.globals = "+basePointer.ToString("X"));

  // judge_panel()
  ptr = scanner.Scan(new SigScanTarget(0,
    "C7 83 ???????? 01000000", // mov [rbx+offset], 1
    "48 0F45 C8"               // cmovne rcx, rax
  ));
  if (ptr == IntPtr.Zero) {
    throw new Exception("Could not find solved and completed offsets!");
  }
  vars.solvedOffset = game.ReadValue<int>(ptr+2);
  vars.completedOffset = game.ReadValue<int>(ptr+38);

  // found_a_pattern()
  ptr = scanner.Scan(new SigScanTarget(12,
    "48 8B 7C 24 60", // mov rdi, [rsp+60]
    "48 8B 74 24 58", // mov rsi, [rsp+58]
    "FF 83 ????????"  // inc [rbx + offset]
  ));
  if (ptr == IntPtr.Zero) {
    throw new Exception("Could not find obelisk count offset!");
  }
  int obeliskOffset = game.ReadValue<int>(ptr);

  // Entity_Door::update_position_and_orientation()
  ptr = scanner.Scan(new SigScanTarget(4,
    "F3 0F11 89 ????????", // mov [rcx + offset], xmm1
    "F3 0F59 89 ????????"  // mulss xmm1, [rcx + ??]
  ));
  if (ptr == IntPtr.Zero) {
    throw new Exception("Could not find door offset!");
  }
  int doorOffset = game.ReadValue<int>(ptr);
  vars.mountainDoor = new MemoryWatcher<float>(new DeepPointer(
    basePointer, 0x18, 0x9E54*8, doorOffset
  ));

  // Entity_Record_Player::power_on()
  ptr = scanner.Scan(new SigScanTarget(12, // Targeting byte 12
    "C7 83 ???????? 00000000", // mov [rbx+??], 0
    "C7 83 ???????? 0000803F", // mov [rbx+offset], 1.0
    "48 83 C4 60"              // add rsp, 60
  ));
  if (ptr == IntPtr.Zero) {
    throw new Exception("Could not find challenge start!");
  }
  int recordPowerOffset = game.ReadValue<int>(ptr);
  vars.challengeActive = new MemoryWatcher<float>(new DeepPointer(
    basePointer, 0x18, 0xBFF*8, recordPowerOffset
  ));

  // get_active_video_player_panel
  ptr = scanner.Scan(new SigScanTarget(4, // Targeting byte 4
    "5B",             // pop rbx
    "C3",             // ret
    "8B 81 ????????", // mov eax, [rcx+offset]
    "85 C0",          // test eax, eax
    "74 2A"           // je ??
  ));
  if (ptr == IntPtr.Zero) {
    throw new Exception("Could not find active movie!");
  }
  int activeMovieOffset = game.ReadValue<int>(ptr);
  vars.movie = new MemoryWatcher<int>(new DeepPointer(
    basePointer, 0x18, 0x3B6*8, activeMovieOffset
  ));
  
  print(
    "Solved offset: "+vars.solvedOffset.ToString("X")
    + " | Completed offset: "+vars.completedOffset.ToString("X")
    + " | Obelisk offset: "+obeliskOffset.ToString("X")
    + " | Door offset: "+doorOffset.ToString("X")
    + " | Record Power offset: "+recordPowerOffset.ToString("X")
    + " | Active Movie offset: "+activeMovieOffset.ToString("X")
    // + " | Panel name offset: "+vars.panelNameOffset.ToString("X")
    // + " | EP name offset: "+vars.epNameOffset.ToString("X")
  );

  // player_is_inside_movement_hint_marker()
  ptr = scanner.Scan(new SigScanTarget(4, // Targeting byte 4
    "F2 0F10 15 ????????", // movsd xmm2, [Core::time_info+10]
    "0F57 C9",             // xorps xmm1, xmm1
    "66 0F5A D2"           // cvtpd2ps xmm2, xmm2
  ));
  if (ptr == IntPtr.Zero) {
    throw new Exception("Could not find time!");
  }
  relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;
  vars.time = new MemoryWatcher<double>(new DeepPointer(
    relativePosition + game.ReadValue<int>(ptr)
  ));
  
  // update_scripted_stuff()
  ptr = scanner.Scan(new SigScanTarget(2, // Targeting byte 2
    "FF 05 ????????", // inc [num_script_frames]
    "0F28 74 24 ??",  // movaps xmm6, [rsp+??]
    "0F28 7C 24 ??"   // movaps xmm7, [rsp+??]
  ));
  if (ptr == IntPtr.Zero) {
    throw new Exception("Could not find game frames!");
  }
  relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;
  vars.gameFrames = new MemoryWatcher<int>(new DeepPointer(
    relativePosition + game.ReadValue<int>(ptr)
  ));

  // update_player_control()
  ptr = scanner.Scan(new SigScanTarget(9, // Targeting byte 9
    "83 3D ???????? 01",       // cmp dword ptr [globals+??], 01
    "C7 05 ???????? 01000000", // mov [player_control_got_moving_input], 01
    "75 ??"                    // jne ??
  ));
  if (ptr == IntPtr.Zero) {
    throw new Exception("Could not find player movement!");
  }
  relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 8;
  vars.playerMoving = new MemoryWatcher<int>(new DeepPointer(
    relativePosition + game.ReadValue<int>(ptr)
  ));
  
  // end2_eyelid_trigger()
  ptr = scanner.Scan(new SigScanTarget(8, // Targeting byte 8
    "48 83 EC ??",         // sub rsp, 28
    "F2 0F10 05 ????????", // mov xmm0, [end2_eyelid_start_time]
    "0F57 C9",             // xorps xmm1, xmm1
    "89 0D ????????"       // mov [end2_eyelid_box_id], ecx
  ));
  if (ptr == IntPtr.Zero) {
    throw new Exception("Could not find eyelid_start_time!");
  }
  relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;
  vars.eyelidStart = new MemoryWatcher<double>(new DeepPointer(
    relativePosition + game.ReadValue<int>(ptr)
  ));
  
  // Entity_Audio_Recording::play_or_stop()
  // 83 BB ???????? 00 48 8B CB 74 0A
  
  // do_focus_mode_left_mouse_press()
  // 8B 05 ???????? 85 C0 74 5B
  
  Func<int, int, DeepPointer> createPointer = (int puzzle, int offset) => {
    return new DeepPointer(basePointer, 0x18, (puzzle-1)*8, offset);
  };
  // First panel in the game
  int panelType = createPointer(0x65, 0x8).Deref<int>(game);
  if (panelType == 0) {
    throw new Exception("Couldn't find panel type!");
  }
  print("Panel type: 0x"+panelType.ToString("X"));
  vars.addPanel = (Action<int, int, int>)((int panel, int maxSolves, int offset) => {
    if (!vars.panels.ContainsKey(panel)) {
      int type = createPointer(panel, 0x8).Deref<int>(game);
      if (type == panelType) {
        vars.panels[panel] = new Tuple<int, int, DeepPointer>(
          0,         // Number of times solved
          maxSolves, // Number of times to split
          createPointer(panel, offset)
        );
      }
    }
  });

  vars.panels = new Dictionary<int, Tuple<int, int, DeepPointer>>();
  vars.keepWatchers = new MemoryWatcherList();
  vars.multiWatchers = new MemoryWatcherList();
  vars.obeliskWatchers = new MemoryWatcherList();

  if (settings["Split on environmental patterns"]) {
    foreach (int obelisk in vars.obelisks) {
      vars.obeliskWatchers.Add(new MemoryWatcher<int>(createPointer(obelisk, obeliskOffset)));
    }
  }

  vars.initPuzzles = (Action)(() => {
    vars.epCount = 0;
    foreach (var watcher in vars.obeliskWatchers) vars.epCount += watcher.Current;
    print("Loaded with EP count: "+vars.epCount);
    vars.panels.Clear();
    if (settings["Split on all panels (solving and non-solving)"]) {
      // Multi-panels use the solved offset, since they need to be solved every time you exit them
      foreach (var panel in vars.multiPanels) vars.addPanel(panel, 9999, vars.solvedOffset);
      foreach (var panel in vars.keepWalkOns) {
        vars.keepWatchers.Add(new MemoryWatcher<int>(createPointer(panel, vars.solvedOffset)));
      }
      vars.keepWatchers.UpdateAll(game);
      foreach (var panel in vars.multipanel) {
        vars.addPanel(panel, 0, vars.solvedOffset);
        vars.multiWatchers.Add(new MemoryWatcher<int>(createPointer(panel, vars.completedOffset)));
      }
      // Boat speed panel should never split, it's too inconsistent
      vars.addPanel(0x34C80, 0, vars.completedOffset);
      // Multi panel is handled separately, so it should never split
      vars.addPanel(0x9FCD, 0, vars.completedOffset);
      // Cinema input panel unsolves itself the first time
      vars.addPanel(0x00816, 0, vars.solvedOffset);
    } else {
      // Individual panels use the completed offset, since they just need to be completed the first time you exit them
      if (settings["Split on lasers"]) {
        foreach (var laser in vars.lasers) {
          vars.addPanel(laser, 1, vars.completedOffset);
        }
      }
      if (settings["Split on tutorial door"]) {
        vars.addPanel(0x0362A, 1, vars.completedOffset);
      }
      if (settings["Split when starting the boat"]) {
        vars.addPanel(0x34D97, 1, vars.completedOffset);
      }
      if (settings["Split on greenhouse elevator"]) {
        vars.addPanel(0x0A07A, 1, vars.completedOffset);
      }
      if (settings["Split on mountain elevator"]) {
        vars.addPanel(0x09EEC, 1, vars.completedOffset);
      }
      if (settings["Split on final elevator"]) {
        vars.addPanel(0x3D9AA, 1, vars.completedOffset);
      }
    }
    if (settings["Split on challenge end"]) {
      vars.addPanel(0x1C31A, 0, vars.solvedOffset); // Right pillar
      vars.addPanel(0x1C31B, 0, vars.solvedOffset); // Left pillar
    }
  });
  vars.initPuzzles();
  
  vars.randomDoorsPractice = (Func<bool>)(() => {
    bool enable = settings["Enable random doors practice"];
    // Entity_Door::close
    ptr = scanner.Scan(new SigScanTarget(11, // Targeting byte 11
      "84 C0",               // test al, al
      "74 11",               // je 11
      "0F 2F BF ?? ?? 00 00" // comiss xmm7, [rdi + offset]
      // "76 08" -> "77 08"  // jbe 08 -> ja 08
    ));
    if (ptr == IntPtr.Zero) {
      return false;
    }
    // This replaces the logic of
    if (!enable) {
      // If a puzzle is NOT solved, turn it off
      game.WriteBytes(ptr, new byte[] {0x76});
    } else { // with
      // If a puzzle IS solved, turn it off
      game.WriteBytes(ptr, new byte[] {0x77});
    }

    // Entity_Door::open
    ptr = scanner.Scan(new SigScanTarget(11, // Targeting byte 11
      "84 C0",               // test al, al
      "74 19",               // je 19
      "0F 2F B7 ?? ?? 00 00" // comiss xmm6, [rdi + offset]
      // "76 10" -> "EB 08"  // jbe 10 -> jmp 08
    ));
    if (ptr == IntPtr.Zero) {
      return false;
    }
    // This replaces the logic of
    if (!enable) {
      // If a puzzle is NOT solved, clear it. Always turn the puzzle on.
      // Note: This differs slightly from the original logic but is equivalent and slightly safer.
      game.WriteBytes(ptr, new byte[] {0x76, 0x08});
    } else { // with
      // Always turn the puzzle on
      game.WriteBytes(ptr, new byte[] {0xEB, 0x08});
    }
    
    IntPtr leftDoor = (new DeepPointer(basePointer, 0x18, 0x1983*8)).Deref<IntPtr>(game);
    IntPtr rightDoor = (new DeepPointer(basePointer, 0x18, 0x1987*8)).Deref<IntPtr>(game);

    // Adjust from "solved_t_target" to "id_to_power" is 0x20
    int idToPower = game.ReadValue<int>(ptr-4) + 0x20;
    // This replaces the logic of
    if (!enable) {
      // Power the double doors
      game.WriteBytes(leftDoor + idToPower, new byte[] {0x68, 0x7C, 0x01, 0x00});
      game.WriteBytes(rightDoor + idToPower, new byte[] {0x68, 0x7C, 0x01, 0x00});
    } else { // with
      // Power nothing
      game.WriteBytes(leftDoor + idToPower, new byte[] {0x00, 0x00, 0x00, 0x00});
      game.WriteBytes(rightDoor + idToPower, new byte[] {0x00, 0x00, 0x00, 0x00});
    }
    return true;
  });
}

update {
  if (vars.panels == null) return false; // Init not yet done
  
  // Don't run if the game is loading / paused
  vars.time.Update(game);
  if (vars.time.Current <= vars.time.Old) return false;
  vars.puzzle.Update(game);
  vars.gameFrames.Update(game);
  // Separated out to handle manual resets
  if (vars.gameFrames.Current == 0) vars.startTime = 0.0;
  vars.playerMoving.Update(game);
  vars.challengeActive.Update(game);
  vars.mountainDoor.Update(game);
  vars.movie.Update(game);
  vars.eyelidStart.Update(game);
  vars.keepWatchers.UpdateAll(game);
  vars.obeliskWatchers.UpdateAll(game);
  
  if (settings["Enable random doors practice"] != vars.randomDoorsHack) {
    print(vars.randomDoorsHack + " " + settings["Enable random doors practice"]);
    bool success = vars.randomDoorsPractice();
    if (!success) {
      // Only update the variable if the injection succeeded. We'll try again next frame.
      return false; 
    }
  }
  vars.randomDoorsHack = settings["Enable random doors practice"];
}

isLoading {
  return true; // Disable gameTime approximation
}

gameTime {
  return TimeSpan.FromSeconds(vars.time.Current - vars.startTime);
}

reset {
  if (vars.gameFrames.Old != 0 && vars.gameFrames.Current == 0) {
    return true;
  }
  if (settings["Reset on challenge stop"]) {
    if (vars.challengeActive.Old == 1.0 && vars.challengeActive.Current == 0.0) {
      return true;
    }
  }
}

start {
  if (vars.startTime == 0.0) {
    if (vars.playerMoving.Old == 0 && vars.playerMoving.Current == 1) {
      vars.startTime = vars.time.Current;
      vars.initPuzzles();
      vars.randomDoorsHack = false;
      return true;
    }
  }
  if (settings["Start/split on challenge start"]) {
    if (vars.challengeActive.Old == 0.0 && vars.challengeActive.Current == 1.0) {
      vars.startTime = vars.time.Current;
      vars.initPuzzles();
      vars.randomDoorsHack = false;
      return true;
    }
  }
}

split {
  if (vars.puzzle.Old == 0 && vars.puzzle.Current != 0) {
    int panel = vars.puzzle.Current;
    vars.activePanel = panel;
    print("Started panel 0x"+panel.ToString("X"));
    if (!vars.panels.ContainsKey(panel) && settings["Split on all panels (solving and non-solving)"]) {
      print("Encountered new panel 0x"+panel.ToString("X"));
      vars.addPanel(panel, 1, vars.solvedOffset);
      print(""+vars.panels[panel]);
    }
  }
  if (vars.activePanel != 0) {
    int panel = vars.activePanel;
    if (!vars.panels.ContainsKey(panel)) {
      vars.activePanel = 0;
      return false;
    }
    var puzzleData = vars.panels[panel];
    int state = puzzleData.Item3.Deref<int>(game);
    // Valid states:
    // 0: Unsolved
    // 1: Solved correctly
    // 2: Solved incorrectly
    // 3: Exited
    // 4: Pending negation
    // 5: Floor Meta Subpanel error
    if (state == 1 || state == 4) {
      vars.panels[panel] = new Tuple<int, int, DeepPointer>(
        puzzleData.Item1 + 1, // Solve count
        puzzleData.Item2,     // Maximum split count
        puzzleData.Item3      // State pointer
      );
      print("Panel 0x" + panel.ToString("X") + " has been solved " + vars.panels[panel].Item1+ " of "+puzzleData.Item2 + " time(s)");
      vars.activePanel = 0;
      if (settings["Split on challenge end"]) {
        if (vars.panels[0x1C31A].Item1 == 1 && vars.panels[0x1C31B].Item1 == 1) {
          return true;
        }
      }
      if (puzzleData.Item1 < puzzleData.Item2) { // Split fewer times than the max
        return true;
      }
    } else if (state != 0) {
      print("Panel 0x" + panel.ToString("X") + " exited in state " + state);
      vars.activePanel = 0;
    }
  }
  if (settings["Split on all panels (solving and non-solving)"]) {
    // Challenge starting panel unsolves itself
    if (vars.challengeActive.Old == 0.0 && vars.challengeActive.Current == 1.0) {
      print("Started the challenge");
      return true;
    }
    if (vars.movie.Old != vars.movie.Current) {
      print(vars.movie.Old+" "+vars.movie.Current);
    }
    // Cinema starting panel unsolves itself
    if (vars.movie.Old != vars.movie.Current) {
      if (vars.movie.Old == 2070 || vars.movie.Current == 2070) {
        return false; // Initialization
      }
      if (vars.movie.Current == 0) {
        return false; // Movie ending
      }
      print("Started movie 0x"+vars.movie.Current.ToString("X"));
      return true;
    }
    // Keep panels don't trigger nicely
    for (int i=0; i<vars.keepWatchers.Count; i++) {
      var panel = vars.keepWatchers[i];
      if (panel.Old == 0 && panel.Current == 1) {
        string color = new List<string>{"Yellow", "Purple", "Green", "Blue"}[i];
        print(color + " keep panel has been solved");
        return true;
      }
    }
    // Avoid duplication for multipanel
    for (int i=0; i<vars.multiWatchers.Count; i++) {
      var panel = vars.multiWatchers[i];
      if (panel.Old == 0 && panel.Current == 1) {
        print("Completed multipanel "+i);
        return true;
      }
    }
  }
  if (settings["Split when completing the first mountain floor"]) {
    // Increases gradually from 0 to 1
    if (vars.mountainDoor.Old == 0.0 && vars.mountainDoor.Current > 0.0) {
      print("Mountain floor 1 door started opening");
      return true;
    }
  }
  if (vars.challengeActive.Old == 0.0 && vars.challengeActive.Current == 1.0) {
    if (settings["Split on challenge end"]) {
      vars.panels[0x1C31A] = new Tuple<int, int, DeepPointer>(
        0,
        vars.panels[0x1C31A].Item2,
        vars.panels[0x1C31A].Item3
      );
      vars.panels[0x1C31B] = new Tuple<int, int, DeepPointer>(
        0,
        vars.panels[0x1C31B].Item2,
        vars.panels[0x1C31B].Item3
      );
    }
    if (settings["Start/split on challenge start"]) {
      print("Started the challenge");
      return true;
    }
  }
  if (settings["Split on environmental patterns"]) {
    int epCount = 0;
    foreach (var watcher in vars.obeliskWatchers) epCount += watcher.Current;
    if (epCount > vars.epCount) {
      print("Solved EP #" + epCount);
      vars.epCount = epCount;
      return true;
    }
  }
  if (settings["Split on easter egg ending"]) {
    if (vars.eyelidStart.Old == -1 && vars.eyelidStart.Current > 0) {
      return true;
    }
  }
}