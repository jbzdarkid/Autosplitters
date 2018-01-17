state("witness64_d3d11") {}
// TODO: Split for floor 1 finish
// TODO: Future investigation into do_success_side_effects
// TODO: Entity_Machine_Panel::init_pattern_data_lotus
// TODO: Random_Generator::get
// TODO: Challenge start / cinema initial solve return 3?
// TODO: Load EP count on run start / init
// TODO: Don't start after a certain time

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

  // 11 lasers which unlock the mountain-top box
  settings.Add("Split on lasers", true);
  vars.lasers = new List<int>{
    0x032F6, // Town
    0x03609, // Desert
    0x0360E, // Symmetry
    0x0360F, // Keep
    0x03613, // Quarry
    0x03614, // Treehouse
    0x03616, // Swamp
    0x03617, // Jungle
    0x09DE1, // Bunker
    0x17CA5, // Monastery
    0x19651, // Shadows
  };
  
  // One-off panels (usually to accompany 11 lasers splits)
  settings.Add("Split on tutorial door", true);
  settings.Add("Split when starting the boat", false);
  settings.Add("Split on greenhouse elevator", false);
  settings.Add("Split on mountain elevator", false);
  settings.Add("Split on final elevator", true);
}

init {
  vars.panels = null; // Used to detect if init completes properly
  vars.startTime = 0.0;
  vars.activePanel = 0;
  var page = modules.First();
  var scanner = new SignatureScanner(game, page.BaseAddress, page.ModuleMemorySize);

  // judge_panel()
  var ptr = scanner.Scan(new SigScanTarget(0,
    "C7 83 ???????? 01000000", // mov [rbx+offset], 1
    "48 0F45 C8"               // cmovne rcx, rax
  ));
  if (ptr == IntPtr.Zero) {
    print("Could not find solved and completed offsets!");
    return false;
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
    print("Could not find obelisk count offset!");
    return false;
  }
  int obeliskOffset = game.ReadValue<int>(ptr);
  print("Solved offset: "+vars.solvedOffset.ToString("X")+" | Completed offset: "+vars.completedOffset.ToString("X")+" | Obelisk offset: "+obeliskOffset.ToString("X")/*+" | Panel name offset: "+vars.panelNameOffset.ToString("X")+" | EP name offset: "+vars.epNameOffset.ToString("X")*/);
  
  // get_active_panel()
  ptr = scanner.Scan(new SigScanTarget(3, // Targeting byte 3
    "48 8B 05 ????????", // mov rax, [witness64_d3d11.exe + offset]
    "33 C9",             // xor ecx, ecx
    "48 85 C0",          // test rax, rax
    "74 06"              // je 6
  ));
  if (ptr == IntPtr.Zero) {
    print("Could not find current puzzle!");
    return false;
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

  // player_is_inside_movement_hint_marker()
  ptr = scanner.Scan(new SigScanTarget(4, // Targeting byte 4
    "F2 0F10 15 ????????", // movsd xmm2, [Core::time_info+10]
    "0F57 C9",             // xorps xmm1, xmm1
    "66 0F5A D2"           // cvtpd2ps xmm2, xmm2
  ));
  if (ptr == IntPtr.Zero) {
    print("Could not find time!");
    return false;
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
    print("Could not find game frames!");
    return false;
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
    print("Could not find player movement!");
    return false;
  }
  relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 8;
  vars.playerMoving = new MemoryWatcher<int>(new DeepPointer(
    relativePosition + game.ReadValue<int>(ptr)
  ));
  
  // Entity_Audio_Recording::play_or_stop()
  // 83 BB ???????? 00 48 8B CB 74 0A
  
  // do_focus_mode_left_mouse_press()
  // 8B 05 ???????? 85 C0 74 5B
  
  
  Func<int, int, DeepPointer> createPointer = (int puzzle, int offset) => {
    return new DeepPointer(basePointer, 0x18, (puzzle-1)*8, offset);
  };
  vars.addPanel = (Action<int, int, int>)((int panel, int maxSolves, int offset) => {
    if (!vars.panels.ContainsKey(panel)) {
      vars.panels[panel] = new Tuple<int, int, DeepPointer>(
        0,         // Number of times solved
        maxSolves, // Number of times to split
        createPointer(panel, offset)
      );
    }
  });

  vars.panels = new Dictionary<int, Tuple<int, int, DeepPointer>>();
  vars.keepWatchers = new MemoryWatcherList();
  vars.obeliskWatchers = new MemoryWatcherList();

  if (settings["Split on environmental patterns"]) {
    foreach (int obelisk in vars.obelisks) {
      vars.obeliskWatchers.Add(new MemoryWatcher<int>(createPointer(obelisk, obeliskOffset)));
    }
  }

  vars.initPuzzles = (Action)(() => {
    vars.epCount = 0;
    vars.panels.Clear();
    if (settings["Split on all panels (solving and non-solving)"]) {
      // Multi-panels use the solved offset, since they need to be solved every time you exit them
      foreach (var panel in vars.multiPanels) vars.addPanel(panel, 9999, vars.solvedOffset);
      foreach (var panel in vars.keepWalkOns) {
        vars.keepWatchers.Add(new MemoryWatcher<int>(createPointer(panel, vars.solvedOffset)));
      }
      vars.keepWatchers.UpdateAll(game);
      // Boat speed panel should never split, it's too inconsistent
      vars.addPanel(0x34C80, 0, vars.completedOffset);
      // Challenge start and Cinema input are special cases, they un-solve after you exit them, so to work around this I use the completed offset.
      vars.addPanel(0x0A333, 9999, vars.solvedOffset); // Challenge Start
      vars.addPanel(0x00816, 9999, vars.solvedOffset); // Cinema input panel
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
  });
  vars.initPuzzles();
  vars.ints = new int[1000];
}
/* Entity_Machine_Panel::Entity_Machine_Panel()

// State values:
// 0 - Unsolved
// 1 - Solved correctly
// 2 - Solved incorrecty
// 3 - Exited
// 4 - Negation pending
// 5 - Incorrect meta floor

0x000 long* vfTable = [Entity_Machine_Panel`vftable']
  0x0C8 float
  0x0E8 float
  0x0F8 float
  0x108 float
  0x118 float
  0x128 float
  0x138 float
  0x148 float
  0x158 float
  0x168 float
  0x178 float
  0x188 float
  0x1A8 float
  0x1B8 float
  0x1C8 float
  0x1D8 float
  0x1E8 float
  0x1F8 float
  0x198 float
  0x208 int
  0x20C float
  0x21C int = 2
  0x220 long
  0x228 ???
  0x22C int
  0x230 long
  0x238 long
  0x240 long
  0x248 long
  0x250 long
  0x258 long
  0x260 long
  0x268 long
  0x270 long
  0x278 long
  0x280 int
  0x284 float
  0x28C long
  0x294 (float/double)
  0x29C long
  0x2A4 float
  0x2A8 float
  0x2AC float
  0x2B4 long
  0x2BC long
  0x2C4 long
  0x2CC long
  0x2D4 long
  0x2DC int
  0x2E4 long
  0x2EC long
  0x2F4 long
  0x2FC long
  0x304 long
  0x30C ???
  0x310 int
  0x314 float
  0x318 float
  0x320 long
  0x328 long
  0x330 long
  0x340 float
  0x344 float
  0x34C int
  0x350 double (???)
  0x354 int
  0x358 float
  0x35C int
  0x360 double (???)
  0x364 int
  0x368 int
  0x36C int
  0x370 int
  0x374 int
  0x378 int = 0xFFFFFFFF
  0x380 int
  0x384 int
  0x388 long
  0x390 int = 0x3DCCCCCD
  0x398 int
  0x39C int = 1
  0x3A0 int = 1
  0x3A4 float
  0x3A8 double
  0x3B0 long
  0x3B8 long
  0x3C0 float
  0x3C8 long
  0x3D0 long
  0x3D8 long
  0x3E0 long
  0x3E8 int
  0x3F0 long
  0x3F8 long
  0x400 int
  0x408 long
  0x410 long
  0x418 long
  0x420 long
  0x428 long
  0x430 long
  0x438 long
  0x440 long
  0x448 long
  0x450 long
  0x458 long
  0x460 long
  0x468 int
  0x470 long
  0x478 int
  0x480 long
  0x488 int = 0xFFFFFFFF
  0x490 long
  0x498 long
  0x4A0 int
  0x4A4 ???
  0x4A8 long
  0x4B0 long
  0x4B8 long
  0x4C0 long
  0x4C8 long
  0x4D0 long
  0x4D8 long
  0x4E0 long
  0x4E8 long
  0x4F0 long
  0x4F8 long
  0x500 byte = 1
  
  
  0x
0x288 int state;
  0x29C float
0x2A0 int isCompleted;
  0x2C0
  0x310
  0x318
  0x310
  0x320
0x384 int texturesLoaded;
  0x450 int flags; // of some kind

  
*/
update {
  if (vars.panels == null) return false; // Init not yet done
  //print(""+(new DeepPointer(0x5B28C0, 0x18, 0x1AA70, 0x384)).Deref<int>(game));
/*
  string message = "";
  for (int i=0; i<vars.ints.Length; i+=4) {
    var ignored = new List<int>{0x8,0x10,0x14,0x18,0x20,0x28,0x2C,0x30,0x38,0x3C,0x48,0x54,0x70,0xA4,0xA8,0xAC,0xB4,0xB8,0xBC,0xCC,0xD4,0xE4,0xEC,0xF0,0xF4,0xF8,0xFC,0x108,0x118,0x120,0x128,0x12C,0x15C,0x178,0x180,0x194,0x198,0x1A0,0x1B0,0x1B4,0x1D0,0x1D4,0x1E8,0x1F0,0x1F4,0x204,0x278,0x2EC,0x30C,0x314,0x318,0x340,0x344,0x360,0x384,0x390,0x39C,0x3A0,0x3A4,0x3BC,0x3C0,0x3D4, 0x21C, 0x100, 0x4, 0xD8, 0x2E8, 0x3B0, 0x20C, 0x3D8, 0x218, 0x3B8, 0x50, 0x150, 0x190, 0x3E0, 0x1A8, 0x1C8, 0xE8, 0x358, 0x294, 0x148, 0x1A4, 0xD0, 0x378, 0x184};
    if (ignored.Contains(i)) continue;
    int newInt = (new DeepPointer(0x5B28C0, 0x18, 0x1AA70, i)).Deref<int>(game);
    if (vars.ints[i] != newInt) {
      //print(i + ": " + vars.ints[i] + " -> " + newInt);
      message += i.ToString("X")+" ";
      vars.ints[i] = newInt;
    }
  }
  if (message != "") print(message);
  */
  
  // Don't run if the game is loading / paused
  vars.time.Update(game);
  if (vars.time.Current <= vars.time.Old) return false;
  vars.puzzle.Update(game);
  vars.gameFrames.Update(game);
  vars.playerMoving.Update(game);
  vars.keepWatchers.UpdateAll(game);
  vars.obeliskWatchers.UpdateAll(game);
}

isLoading {
  return true; // Disable gameTime approximation
}

gameTime {
  return TimeSpan.FromSeconds(vars.time.Current - vars.startTime);
}

reset {
  if (vars.gameFrames.Current == 0) {
    vars.startTime = 0.0;
    return true;
  }
}

start {
  // FIXME: Should start only once?
  if (vars.playerMoving.Old == 0 && vars.playerMoving.Current == 1) {
    vars.startTime = vars.time.Current;
    vars.initPuzzles();
    return true;
  }
}

split {
  if (vars.puzzle.Old == 0 && vars.puzzle.Current != 0) {
    int panel = vars.puzzle.Current;
    vars.activePanel = panel;
    print("Started panel 0x"+panel.ToString("X"));
    if (!vars.panels.ContainsKey(panel) && settings["Split on all panels (solving and non-solving)"]) {
      // print("Encountered new panel 0x"+puzzle.ToString("X"));
      vars.addPanel(panel, 1, vars.solvedOffset);
    }
  }
  if (vars.activePanel != 0) {
    int panel = vars.activePanel;
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
      if (puzzleData.Item1 < puzzleData.Item2) { // Split fewer times than the max
        return true;
      }
    } else if (state != 0) {
      // TODO: EPs pass through this train too. Figure out if the puzzle is an EP maybe
      print("Panel 0x" + panel.ToString("X") + " exited in state " + state);
      vars.activePanel = 0;
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
  if (settings["Split on all panels (solving and non-solving)"]) {
    for (int i=0; i<4; i++) {
      var panel = vars.keepWatchers[i];
      if (panel.Old == 0 && panel.Current == 1) {
        string color = new List<string>{"Yellow", "Purple", "Green", "Blue"}[i];
        print(color + " keep panel has been solved");
        return true;
      }
    }
  }
}