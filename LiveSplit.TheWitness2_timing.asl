state("witness64_d3d11") {}

startup {
  vars.logFilePath = Directory.GetCurrentDirectory() + "\\autosplitter_witness.log";
  vars.log = (Action<string>)((string logLine) => {
    string time = System.DateTime.Now.ToString("dd/mm/yy hh:mm:ss:fff");
    // AppendAllText will create the file if it doesn't exist.
    System.IO.File.AppendAllText(vars.logFilePath, time + ": " + logLine + "\r\n");
  });
  vars.log("Autosplitter loaded");
}

init {
  vars.panels = null; // Used to detect if init completes properly
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
  vars.basePointer = relativePosition + game.ReadValue<int>(ptr+46);
  vars.log("witness64_d3d11.globals = " + vars.basePointer.ToString("X"));

  // judge_panel()
  ptr = scanner.Scan(new SigScanTarget(0,
    "C7 83 ???????? 01000000", // mov [rbx+offset], 1
    "48 0F45 C8"               // cmovne rcx, rax
  ));
  if (ptr == IntPtr.Zero) {
    throw new Exception("Could not find solved and completed offsets!");
  }
  vars.solvedOffset = game.ReadValue<int>(ptr+2);

  // get_panel_color_cycle_factors()
  ptr = scanner.Scan(new SigScanTarget(9, // Targeting byte 9
    "83 FA 02",           // cmp edx, 02
    "7F 3B",              // jg get_panel_color_cycle_factors + A9
    "F2 0F10 05 ????????" // movsd xmm0, [Core::time_info+10]
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

  vars.panels = new Dictionary<int, Tuple<int, DeepPointer>>();
}

update {
  if (vars.panels == null) return false; // Init not yet done

  // Don't run if the game is loading / paused
  vars.time.Update(game);
  if (vars.time.Current <= vars.time.Old) return false;
  vars.puzzle.Update(game);
  vars.gameFrames.Update(game);
  // Separated out to handle manual resets
  vars.playerMoving.Update(game);
}

reset {
  if (vars.gameFrames.Old != 0 && vars.gameFrames.Current == 0) {
    vars.log("Started a new game");
    return true;
  } else if (vars.gameFrames.Old != 0 && vars.gameFrames.Current < vars.gameFrames.Old - 10) {
    vars.log("Loaded a save");
    return true;
  }
}

start {
  if (vars.playerMoving.Old == 0 && vars.playerMoving.Current == 1) {
    vars.panels.Clear();
    return true;
  }
}

split {
  if (vars.puzzle.Old == 0 && vars.puzzle.Current != 0) {
    int panel = vars.puzzle.Current;
    vars.activePanel = panel;
    if (!vars.panels.ContainsKey(panel)) {
      vars.log("Encountered new panel 0x" + panel.ToString("X"));
      vars.panels[panel] = new Tuple<int, DeepPointer>(0, new DeepPointer(vars.basePointer, 0x18, (panel-1)*8, vars.solvedOffset));
      return true;
    } else {
      vars.log("Started existing panel 0x" + panel.ToString("X"));
    }
  }
  if (vars.activePanel != 0) {
    int panel = vars.activePanel;
    if (!vars.panels.ContainsKey(panel)) {
      vars.activePanel = 0;
      return false;
    }
    var puzzleData = vars.panels[panel];
    int state = puzzleData.Item2.Deref<int>(game);
    if (state == 1 || state == 4
      // Cinema input panel exits in state 3 on the first solve
      || (vars.activePanel == 0x00816 && state == 3 && puzzleData.Item1 == 0)
      // Challenge start exits in state 3 sometimes
      || (vars.activePanel == 0xA3333 && state == 3)
    ) {
      vars.panels[panel] = new Tuple<int, DeepPointer>(
        puzzleData.Item1 + 1, // Solve count
        puzzleData.Item2      // State pointer
      );
      vars.log("Solved panel 0x" + panel.ToString("X"));
      vars.activePanel = 0;
      return true;
    }
  }
}
