state("witness64_d3d11") {}
// TODO: Handle challenge start the same as theater input, and get rid of the sigscan
// Multipanel busted. https://www.twitch.tv/videos/419028576?t=01h08m40s
// TODO: Tutorial Patio EP vs Tutorial Flowers EP

startup {
  // Relative to Livesplit.exe
  vars.logFilePath = Directory.GetCurrentDirectory() + "\\autosplitter_witness.log";
  vars.log = (Action<string>)((string logLine) => {
    print(logLine);
    string time = System.DateTime.Now.ToString("dd/MM/yy hh:mm:ss.fff");
    // AppendAllText will create the file if it doesn't exist.
    System.IO.File.AppendAllText(vars.logFilePath, time + ": " + logLine + "\r\n");
  });

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
    0x00816, // Cinema input panel
    0x03554, 0x03553, 0x0354F, 0x0354A, 0x03550, 0x03546, // Cinema Panels
    0x0A3B6, // Tutorial Back Left
    0x0362A, // Tutorial Gate
    0x09F99, // Desert Laser Redirect
    0x34D97, // Boat map
    0x079E0, // Town Triple Panel
    0x09D9C, // Monastery Bonsai
    0x0A07A, // Bunker Elevator
    0x09F80, // Mountaintop Box
    0x17C35, // Mountaintop Crazyhorse
    0x09FCD, // Mountain Multi
    0x09EEC, // Mountain Elevator
  };
  vars.keepWalkOns = new List<int>{
    0x033EA, // Yellow
    0x01BE9, // Purple
    0x01CD3, // Green
    0x01D3F, // Blue
  };
  vars.multipanel = new List<int>{
    0x09FCC, 0x09FCE, 0x09FCF, 0x09FD0, 0x09FD1, 0x09FD2
  };

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

  // Other misc settings
  settings.Add("Start on challenge start", false);
  settings.Add("Reset on challenge stop", false);
  settings.Add("Split on eclipse environmental start", false);

  settings.Add("Split on easter egg ending", true);
  settings.Add("Override first text component with a Failed Panels count", false);
  settings.Add("feature_stop_tracking", false, "Feature: Don't stop tracking a panel if another is started");

  // Config files may live next to Livesplit.exe or next to the splits file.
  // Ideally, they should end with .witness_config, but they may end with .witness_conf (discord likes to truncate file extensions)
  var files = new List<string>();
  files.AddRange(System.IO.Directory.GetFiles(Directory.GetCurrentDirectory(), "*.witness_config"));
  files.AddRange(System.IO.Directory.GetFiles(Directory.GetCurrentDirectory(), "*.witness_conf"));
  files.AddRange(System.IO.Directory.GetFiles(System.IO.Path.GetDirectoryName(timer.Run.FilePath), "*.witness_config"));
  files.AddRange(System.IO.Directory.GetFiles(System.IO.Path.GetDirectoryName(timer.Run.FilePath), "*.witness_conf"));

  vars.configFiles = new Dictionary<string, string>();
  settings.Add("configs", (vars.configFiles.Count > 0), "Split based on configuration file:");
  foreach (var file in files) {
    string fileName = file.Split('\\').Last();
    if (vars.configFiles.ContainsKey(fileName)) {
      vars.log("Found two config files with the same name: " + file + " and " + vars.configFiles[fileName]);
      continue; // Discard the second one. Hopefully the user can figure this out.
    }
    vars.configFiles[fileName] = file;
    settings.Add(fileName, false, null, "configs");
  }
  vars.log("Autosplitter loaded");
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
  vars.log("witness64_d3d11.globals = "+basePointer.ToString("X"));

  Func<int, int, DeepPointer> createPointer = (int id, int offset) => {
    return new DeepPointer(basePointer, 0x18, id*8, offset);
  };
  // First panel in the game
  int panelType = createPointer(0x64, 0x8).Deref<int>(game);
  if (panelType == 0) {
    // Sleeping lags livesplit, but so does repeatedly throwing exceptions,
    // and this doesn't also lag the game.
    Thread.Sleep(1000);
    throw new Exception("Couldn't find panel type!");
  }
  vars.log("Panel type: 0x"+panelType.ToString("X"));

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
  vars.doorOffset = game.ReadValue<int>(ptr);

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

  // Entity_Door::update()
  ptr = scanner.Scan(new SigScanTarget(4,
    "F3 0F10 8B ????????", // movss xmm1, [rbx + target1]
    "F3 0F10 83 ????????", // movss xmm1, [rbx + target2]
    "48 89 BC 24 ????????" // mov [rsp+??], rdi
  ));
  if (ptr == IntPtr.Zero) {
    throw new Exception("Could not find door offsets!");
  }
  vars.doorCurrent = game.ReadValue<int>(ptr);
  vars.doorTarget = game.ReadValue<int>(ptr+8);

  // Entity_Obelisk_Report::light_up
  ptr = scanner.Scan(new SigScanTarget(3,
    "C3",                      // ret
    "C7 81 ???????? 01000000", // mov [rcx+offset], 1
    "48 83 C4 20"              // add rsp, 20
  ));
  vars.epOffset = game.ReadValue<int>(ptr);

  vars.log(
    "Solved offset: "+vars.solvedOffset.ToString("X")
    + " | Completed offset: "+vars.completedOffset.ToString("X")
    + " | Obelisk offset: "+obeliskOffset.ToString("X")
    + " | Door offset: "+vars.doorOffset.ToString("X")
    + " | Door current: "+vars.doorCurrent.ToString("X")
    + " | Door target: "+vars.doorTarget.ToString("X")
    + " | Record Power offset: "+recordPowerOffset.ToString("X")
    + " | EP offset: "+vars.epOffset.ToString("X")
  );

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

  vars.addPanel = (Action<int, int>)((int panel, int maxSolves) => {
    if (!vars.panels.ContainsKey(panel)) {
      int type = createPointer(panel-1, 0x8).Deref<int>(game);
      if (type == 0) {
        vars.log("Attempted to add panel 0x" + panel.ToString("X") + " but panel type was 0! This is likely due to an incorrect ID in your configuration file.");
      }
      if (type == panelType) {
        vars.panels[panel] = new Tuple<int, int, DeepPointer>(
          0,         // Number of times solved
          maxSolves, // Number of times to split
          createPointer(panel-1, vars.solvedOffset)
        );
      } else { // Not a panel, insert a placeholder to avoid 'starting' again.
        vars.panels[panel] = null;
      }
    }
  });

  vars.panels = new Dictionary<int, Tuple<int, int, DeepPointer>>();
  vars.obeliskWatchers = new MemoryWatcherList();
  vars.keepWatchers = new MemoryWatcherList();
  vars.multiWatchers = new MemoryWatcherList();
  vars.configWatchers = new MemoryWatcherList();

  if (settings["Split on environmental patterns"]) {
    foreach (int obelisk in vars.obelisks) {
      vars.obeliskWatchers.Add(new MemoryWatcher<int>(createPointer(obelisk-1, obeliskOffset)));
    }
  }

  vars.initPuzzles = (Action)(() => {
    vars.epCount = 0;
    foreach (var watcher in vars.obeliskWatchers) vars.epCount += watcher.Current;
    vars.log("Loaded with EP count: "+vars.epCount);
    vars.panels.Clear();
    vars.keepWatchers = new MemoryWatcherList();
    vars.multiWatchers = new MemoryWatcherList();
    vars.configWatchers = new MemoryWatcherList();
    if (settings["Split on all panels (solving and non-solving)"]) {
      foreach (var panel in vars.keepWalkOns) {
        vars.keepWatchers.Add(new MemoryWatcher<int>(createPointer(panel, vars.solvedOffset)));
      }
      vars.keepWatchers.UpdateAll(game);
      foreach (var panel in vars.multipanel) {
        vars.addPanel(panel, 0);
        vars.multiWatchers.Add(new MemoryWatcher<int>(createPointer(panel, vars.completedOffset)));
      }
      vars.multiWatchers.UpdateAll(game);
      // Multi-panels use the solved offset, since they need to be solved every time you exit them
      foreach (var panel in vars.multiPanels) vars.addPanel(panel, 9999);
      // Boat speed panel should never split, it's too inconsistent
      vars.addPanel(0x34C80, 0);
    } else if (settings["configs"]) {
      string[] lines = {""};
      foreach (var configFile in vars.configFiles.Keys) {
        if (settings[configFile]) {
          // Full path is saved in the dictionary.
          lines = System.IO.File.ReadAllLines(vars.configFiles[configFile]);
          vars.log("Selected config file: " + configFile);
          break;
        }
      }
      if (lines.Length == 0) {
        vars.log("Config file empty or no config file selected!");
      } else {
        string mode = "";
        int version = 0;
        for (int i=0; i<lines.Length; i++) {
          var line = lines[i].Split('#')[0]; // First, strip comments
          line = line.Trim();
          if (line == "") continue; // No reason to process empty lines

          if (line.Contains(':')) {
            var parts = line.Split(':');
            mode = parts[0];
            if (mode == "version") version = Int32.Parse(parts[1]);
            continue;
          }

          int id = Convert.ToInt32(line, 16);
          MemoryWatcher watcher = null;
          if (mode == "panels") {
            if (vars.keepWalkOns.Contains(id) || vars.multipanel.Contains(id)) {
              watcher = new MemoryWatcher<int>(createPointer(id, vars.completedOffset));
            } else {
              vars.addPanel(id + 1, 1);
              continue;
            }
          } else if (mode == "multipanels") {
            if (vars.keepWalkOns.Contains(id) || vars.multipanel.Contains(id)) {
              watcher = new MemoryWatcher<int>(createPointer(id, vars.solvedOffset));
            } else {
              vars.addPanel(id + 1, 9999);
              continue;
            }
          } else if (mode == "eps") {
            watcher = new MemoryWatcher<int>(createPointer(id, vars.epOffset));
          } else if (mode == "doors") {
            watcher = new MemoryWatcher<float>(createPointer(id, vars.doorOffset));
          } else {
            vars.log("Encountered unknown mode: " + mode);
            continue;
          }
          watcher.Name = mode.TrimEnd('s') + " 0x" + id.ToString("X");
          vars.configWatchers.Add(watcher);
          vars.log("Watching " + watcher.Name);
        }
        vars.log("Watching " + vars.panels.Count + " panels");
        vars.configWatchers.UpdateAll(game);
      }
    }

    vars.deathCount = 0;
    vars.updateText = false;
    if (settings["Override first text component with a Failed Panels count"]) {
      foreach (LiveSplit.UI.Components.IComponent component in timer.Layout.Components) {
        if (component.GetType().Name == "TextComponent") {
          vars.tc = component;
          vars.tcs = vars.tc.Settings;
          vars.updateText = true;
          vars.log("Found text component at " + component);
          break;
        }
      }
    }
  });
  vars.initPuzzles();
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
  vars.eyelidStart.Update(game);
  vars.keepWatchers.UpdateAll(game);
  vars.multiWatchers.UpdateAll(game);
  vars.obeliskWatchers.UpdateAll(game);
  vars.configWatchers.UpdateAll(game);

  if (vars.updateText) {
    vars.tcs.Text1 = "Failed Panels:";
    vars.tcs.Text2 = vars.deathCount.ToString();
  }
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
  if (vars.playerMoving.Old == 0 && vars.playerMoving.Current == 1) {
    if (vars.startTime == 0.0) {
      vars.startTime = vars.time.Current;
      vars.initPuzzles();
      return true;
    }
  }
  if (settings["Start on challenge start"]) {
    if (vars.challengeActive.Old == 0.0 && vars.challengeActive.Current == 1.0) {
      vars.startTime = vars.time.Current;
      vars.initPuzzles();
      return true;
    }
  }
}

split {
  var newPanel = false;
  if (settings["feature_stop_tracking"]) {
    if (vars.puzzle.Old == 0 && vars.puzzle.Current != 0 && vars.activePanel == 0) {
      newPanel = true;
    }
  } else {
    if (vars.puzzle.Old == 0 && vars.puzzle.Current != 0) {
      newPanel = true;
    }
  }
  if (newPanel) {
    int panel = vars.puzzle.Current;
    vars.activePanel = panel;
    vars.log("Started panel 0x"+(panel-1).ToString("X") + " " + vars.activePanel);
    if (!vars.panels.ContainsKey(panel)) {
      vars.log("Encountered new panel 0x"+(panel-1).ToString("X"));
      if (settings["Split on all panels (solving and non-solving)"]) {
        vars.addPanel(panel, 1);
      } else {
        vars.addPanel(panel, 0);
      }
      if (panel == 0x339B9 && settings["Split on eclipse environmental start"]) {
        vars.log("Splitting for eclipse start");
        return true;
      }
    }
  }
  if (vars.activePanel != 0) {
    int panel = vars.activePanel;
    if (!vars.panels.ContainsKey(panel) || vars.panels[panel] == null) {
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
    if (state == 1 || state == 4 ||
      // Cinema input panel exits in state 3 on the first solve
      (vars.activePanel == 0x00816 && state == 3 && puzzleData.Item1 == 0) ||
      // Challenge start exits in state 3 sometimes
      (vars.activePanel == 0x0A333 && state == 3)
    ) {
      vars.panels[panel] = new Tuple<int, int, DeepPointer>(
        puzzleData.Item1 + 1, // Current solve count
        puzzleData.Item2,     // Maximum solve count
        puzzleData.Item3      // State pointer
      );
      vars.log("Panel 0x" + panel.ToString("X") + " has been solved " + vars.panels[panel].Item1+ " of "+puzzleData.Item2 + " time(s)");
      vars.activePanel = 0;
      if (puzzleData.Item1 < puzzleData.Item2) { // Split fewer times than the max
        return true;
      }
    } else if (state == 2 || state == 3) {
      vars.log("Panel 0x" + panel.ToString("X") + " exited in state " + state);
      vars.activePanel = 0;
      vars.deathCount++;
    } else if (state != 0) { // This should not happen, there are no other known states.
      vars.log("Panel 0x" + panel.ToString("X") + " exited in state " + state);
      vars.activePanel = 0;
    }
  }

  foreach (var configWatch in vars.configWatchers) {
    // N.B. doors go from 0 to 0.blah so this isn't exactly 0 -> 1
    if (configWatch.Old == 0 && configWatch.Current > 0) {
      vars.log("Splitting for config setting: " + configWatch.Name);
      return true;
    }
  }

  if (settings["Split on all panels (solving and non-solving)"]) {
    // Keep panels don't trigger nicely since they never become the active panel
    for (int i=0; i<vars.keepWatchers.Count; i++) {
      var panel = vars.keepWatchers[i];
      if (panel.Old == 0 && panel.Current == 1) {
        string color = new List<string>{"Yellow", "Purple", "Green", "Blue"}[i];
        vars.log(color + " keep panel has been solved");
        return true;
      }
    }
    // Avoid duplication for multipanel
    for (int i=0; i<vars.multiWatchers.Count; i++) {
      var panel = vars.multiWatchers[i];
      if (panel.Old == 0 && panel.Current == 1) {
        vars.log("Completed multipanel " + i);
        return true;
      }
    }
  }
  if (settings["Split on environmental patterns"]) {
    int epCount = 0;
    foreach (var watcher in vars.obeliskWatchers) epCount += watcher.Current;
    if (epCount > vars.epCount) {
      vars.log("Solved EP #" + epCount);
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