state("witness64_d3d11") {}
// TODO: Challenge start does not have a good split story. Maybe go back to using the watcher?
//  There's no real concern about this telling you even when you didn't get it, though this is mostly about 20CC, not AL -- if you don't start the challenge in AL, you'll know. Checking the splits isn't that big of a deal.

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
    0x03678, 0x03679, 0x03675, 0x03676, // Mill control panels
    0x03852, 0x03858, 0x275FA, // Boathouse control panels
    0x00609, 0x17C0A, 0x17E07, 0x17E2B, 0x181F5, 0x18488, // Swamp Control Panels
    0x17CE3, 0x17DB7, 0x17DD1, 0x17E52, // Treehouse R1, R2, L, Green Rotators
    0x2896A, // Town Bridge Control
    0x334D8, // Town RGB light control

    0x09E39, 0x09ED8, 0x09E86, // Purple, Blue, Orange Mountain Walkways
    0x00815, // Cinema input panel
    0x03553, 0x03552, 0x0354E, 0x03549, 0x0354F, 0x03545, // Cinema Panels
    0x0A3B5, // Tutorial Back Left
    0x03629, // Tutorial Gate
    0x09F98, // Desert Laser Redirect
    0x34D96, // Boat map
    0x079DF, // Town Triple Panel
    0x09D9B, // Monastery Bonsai
    0x0A079, // Bunker Elevator
    0x09F7F, // Mountaintop Box
    0x17C34, // Mountaintop Crazyhorse
    0x09FCC, // Mountain Multi
    0x09EEB, // Mountain Elevator
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
  vars.allPanels = new List<int>{
    0x00001, 0x00002, 0x00004, 0x00005, 0x00006, 0x00007, 0x00008, 0x00009, 0x0000A, 0x0001B, 0x0001C, 0x0001D, 0x0001E, 0x0001F, 0x00020, 0x00021, 0x00022, 0x00023, 0x00024, 0x00025, 0x00026, 0x00027, 0x00028, 0x00029, 0x00037, 0x00038, 0x0003B, 0x00055, 0x00059, 0x0005C, 0x0005D, 0x0005E, 0x0005F, 0x00060, 0x00061, 0x00062, 0x00064, 0x00065, 0x0006A, 0x0006B, 0x0006C, 0x0006D, 0x0006F, 0x00070, 0x00071, 0x00072, 0x00073, 0x00075, 0x00076, 0x00077, 0x00079, 0x0007C, 0x0007E, 0x00081, 0x00082, 0x00083, 0x00084, 0x00086, 0x00087, 0x00089, 0x0008A, 0x0008B, 0x0008C, 0x0008D, 0x0008F, 0x000B0, 0x00139, 0x00143, 0x00182, 0x00190, 0x00262, 0x0026D, 0x0026E, 0x0026F, 0x00290, 0x00293, 0x00295, 0x002A6, 0x002C2, 0x002C4, 0x002C6, 0x002C7, 0x00390, 0x003B2, 0x003E8, 0x00422, 0x0042D, 0x00469, 0x00472, 0x00474, 0x0048F, 0x0051F, 0x00524, 0x00553, 0x00557, 0x00558, 0x00567, 0x0056E, 0x0056F, 0x00596, 0x005F1, 0x00609, 0x00620, 0x00698, 0x006E3, 0x006FE, 0x0070E, 0x0070F, 0x00767, 0x0078D, 0x00815, 0x0087D, 0x0088E, 0x008B8, 0x008BB, 0x00973, 0x0097B, 0x0097D, 0x0097E, 0x0097F, 0x00982, 0x00983, 0x00984, 0x00985, 0x00986, 0x00987, 0x0098F, 0x00990, 0x00994, 0x00995, 0x00996, 0x00998, 0x00999, 0x0099D, 0x009A0, 0x009A1, 0x009A4, 0x009A6, 0x009AB, 0x009AD, 0x009AE, 0x009AF, 0x009B8, 0x009F5, 0x00A15, 0x00A1E, 0x00A52, 0x00A57, 0x00A5B, 0x00A61, 0x00A64, 0x00A68, 0x00A72, 0x00AFB, 0x00B10, 0x00B53, 0x00B71, 0x00B8D, 0x00BAF, 0x00BF3, 0x00C09, 0x00C22, 0x00C2E, 0x00C3F, 0x00C41, 0x00C59, 0x00C68, 0x00C72, 0x00C80, 0x00C92, 0x00CA1, 0x00CB9, 0x00CD4, 0x00CDB, 0x00E0C, 0x00E3A, 0x00FF8, 0x010CA, 0x0117A, 0x01205, 0x0129D, 0x012C9, 0x012D7, 0x013E6, 0x0146C, 0x01489, 0x0148A, 0x014B2, 0x014D1, 0x014D2, 0x014D4, 0x014D9, 0x014E7, 0x014E8, 0x014E9, 0x018A0, 0x018AF, 0x01983, 0x01987, 0x019DC, 0x019E7, 0x01A0D, 0x01A0F, 0x01A31, 0x01A54, 0x01BE9, 0x01CD3, 0x01D3F, 0x01E59, 0x01E5A, 0x021AE, 0x021AF, 0x021B0, 0x021B3, 0x021B4, 0x021B5, 0x021B6, 0x021B7, 0x021BB, 0x021D5, 0x021D7, 0x02886, 0x0288C, 0x032F5, 0x032F7, 0x032FF, 0x03317, 0x0339E, 0x033D4, 0x033EA, 0x0343A, 0x03481, 0x034D4, 0x034E3, 0x034E4, 0x034EC, 0x034F4, 0x03505, 0x03535, 0x03542, 0x03545, 0x03549, 0x0354E, 0x0354F, 0x03552, 0x03553, 0x0356B, 0x03608, 0x0360D, 0x0360E, 0x03612, 0x03613, 0x03615, 0x03616, 0x0361B, 0x03629, 0x03675, 0x03676, 0x03677, 0x03678, 0x03679, 0x0367C, 0x03686, 0x03702, 0x03713, 0x037FF, 0x0383A, 0x0383D, 0x0383F, 0x03852, 0x03858, 0x03859, 0x039B4, 0x03C08, 0x03C0C, 0x04CA4, 0x04CB3, 0x04CB5, 0x04CB6, 0x04D18, 0x079DF, 0x09D9B, 0x09D9F, 0x09DA1, 0x09DA2, 0x09DA6, 0x09DAF, 0x09DB1, 0x09DB3, 0x09DB4, 0x09DB5, 0x09DB8, 0x09DD5, 0x09DE0, 0x09E39, 0x09E49, 0x09E56, 0x09E57, 0x09E5A, 0x09E69, 0x09E6B, 0x09E6C, 0x09E6F, 0x09E71, 0x09E72, 0x09E73, 0x09E75, 0x09E78, 0x09E79, 0x09E7A, 0x09E7B, 0x09E85, 0x09E86, 0x09EAD, 0x09EAF, 0x09ED8, 0x09EEB, 0x09EFF, 0x09F01, 0x09F6E, 0x09F7D, 0x09F7F, 0x09F82, 0x09F86, 0x09F8E, 0x09F92, 0x09F94, 0x09F98, 0x09FA0, 0x09FAA, 0x09FC1, 0x09FCC, 0x09FCE, 0x09FCF, 0x09FD0, 0x09FD1, 0x09FD2, 0x09FD3, 0x09FD4, 0x09FD6, 0x09FD7, 0x09FD8, 0x09FDA, 0x09FDC, 0x09FF7, 0x09FF8, 0x09FFF, 0x0A010, 0x0A015, 0x0A01B, 0x0A01F, 0x0A02D, 0x0A036, 0x0A049, 0x0A053, 0x0A054, 0x0A079, 0x0A099, 0x0A0C8, 0x0A15C, 0x0A15F, 0x0A168, 0x0A16B, 0x0A16E, 0x0A171, 0x0A182, 0x0A249, 0x0A2CE, 0x0A2D7, 0x0A2DD, 0x0A2EA, 0x0A332, 0x0A3A8, 0x0A3AD, 0x0A3B2, 0x0A3B5, 0x0A3B9, 0x0A3BB, 0x0A3CB, 0x0A3CC, 0x0A3D0, 0x0A8DC, 0x0A8E0, 0x0AC74, 0x0AC7A, 0x0C335, 0x0C339, 0x0C373, 0x0CC7B, 0x15ADD, 0x17BDF, 0x17C02, 0x17C05, 0x17C09, 0x17C0A, 0x17C0D, 0x17C0E, 0x17C2E, 0x17C31, 0x17C34, 0x17C42, 0x17C71, 0x17C95, 0x17CA4, 0x17CA6, 0x17CAA, 0x17CAB, 0x17CAC, 0x17CBC, 0x17CC4, 0x17CC8, 0x17CDF, 0x17CE3, 0x17CE4, 0x17CE7, 0x17CF0, 0x17CF2, 0x17CF7, 0x17CFB, 0x17D01, 0x17D02, 0x17D27, 0x17D28, 0x17D2D, 0x17D6C, 0x17D72, 0x17D74, 0x17D88, 0x17D8C, 0x17D8E, 0x17D8F, 0x17D91, 0x17D97, 0x17D99, 0x17D9B, 0x17D9C, 0x17D9E, 0x17DA2, 0x17DAA, 0x17DAC, 0x17DAE, 0x17DB0, 0x17DB1, 0x17DB2, 0x17DB3, 0x17DB4, 0x17DB5, 0x17DB6, 0x17DB7, 0x17DB8, 0x17DB9, 0x17DC0, 0x17DC2, 0x17DC4, 0x17DC6, 0x17DC7, 0x17DC8, 0x17DCA, 0x17DCC, 0x17DCD, 0x17DD1, 0x17DD7, 0x17DD9, 0x17DDB, 0x17DDC, 0x17DDE, 0x17DE3, 0x17DEC, 0x17E07, 0x17E2B, 0x17E3C, 0x17E4D, 0x17E4F, 0x17E52, 0x17E5B, 0x17E5F, 0x17E61, 0x17E63, 0x17E67, 0x17ECA, 0x17F5F, 0x17F89, 0x17F93, 0x17F9B, 0x17FA0, 0x17FA2, 0x17FA9, 0x17FB9, 0x18076, 0x181A9, 0x181AB, 0x181F5, 0x18313, 0x1831B, 0x1831C, 0x1831D, 0x1831E, 0x18488, 0x18590, 0x193A6, 0x193A7, 0x193AA, 0x193AB, 0x19650, 0x196E2, 0x196F8, 0x1972A, 0x1972F, 0x19771, 0x19797, 0x1979A, 0x197E0, 0x197E5, 0x197E8, 0x19806, 0x19809, 0x198B5, 0x198BD, 0x198BF, 0x1C260, 0x1C2B1, 0x1C2DF, 0x1C2F3, 0x1C319, 0x1C31A, 0x1C33F, 0x1C343, 0x1C344, 0x1C349, 0x2700B, 0x275ED, 0x275FA, 0x27732, 0x2773D, 0x288AA, 0x288EA, 0x288FC, 0x28938, 0x2896A, 0x28998, 0x2899C, 0x289E7, 0x28A0D, 0x28A33, 0x28A69, 0x28A79, 0x28ABF, 0x28AC0, 0x28AC1, 0x28AC7, 0x28AC8, 0x28ACA, 0x28ACB, 0x28ACC, 0x28AD9, 0x28AE3, 0x28B39, 0x2FAF6, 0x32962, 0x32966, 0x334D5, 0x334D8, 0x334DB, 0x334DC, 0x334E1, 0x335AB, 0x335AC, 0x33638, 0x3369D, 0x337FA, 0x33961, 0x339BB, 0x33AB2, 0x33AF5, 0x33AF7, 0x34BC5, 0x34BC6, 0x34C7F, 0x34D96, 0x38663, 0x386FA, 0x3C113, 0x3C114, 0x3C124, 0x3C125, 0x3C12B, 0x3C12D, 0x3D9A6, 0x3D9A7, 0x3D9A8, 0x3D9A9, 0x3D9AA
  };

  // Environmental puzzles/patterns, the +135
  settings.Add("Split on environmental patterns", false);
  // Tracked via obelisks, which report their counts
  vars.obelisks = new List<int> {
    0x00097, // Treehouse
    0x00263, // Monastery
    0x00359, // Desert
    0x00367, // Mountain
    0x0A16C, // Town
    0x22073, // Shadows
  };

  settings.Add("Split on audio logs", false);

  // Other misc settings
  settings.Add("Only start on challenge start", false);
  settings.Add("Reset on challenge stop", false);
  settings.Add("Split on eclipse environmental start", false);

  settings.Add("Split on easter egg ending", true);
  settings.Add("Override first text component with a Failed Panels count", false);
  settings.Add("Override first text component with a Completed Audio Logs count", false);
  settings.Add("(Amerald Debugging)", false);

  vars.panelToString = (Func<int, string>)((int id) => {
    return "0x" + id.ToString("X").PadLeft(5, '0');
  });

  vars.configFiles = null;
  vars.settings = settings;
  var findConfigFiles = (Action<string>)((string folder) => {
    vars.log("Searching for config files in " + folder);
    var files = new List<string>();
    if (folder != null) {
      files.AddRange(System.IO.Directory.GetFiles(folder, "*.witness_config"));
      files.AddRange(System.IO.Directory.GetFiles(folder, "*.witness_config.txt"));
      files.AddRange(System.IO.Directory.GetFiles(folder, "*.witness_conf"));
    }
    vars.log("Found " + files.Count + " config files");

    // Only add the parent setting the first time we call this function
    if (vars.configFiles == null) {
      vars.configFiles = new Dictionary<string, string>();
      vars.settings.Add("configs", (files.Count > 0), "Split based on configuration file:");
    }

    foreach (var file in files) {
      string fileName = file.Split('\\').Last();
      if (vars.configFiles.ContainsKey(fileName)) continue;
      vars.configFiles[fileName] = file;
      vars.settings.Add(fileName, false, null, "configs");
    }
  });
  // Search for config files relative to LiveSplit.exe
  findConfigFiles(Directory.GetCurrentDirectory());
  // Search for config files relative to the current layout
  findConfigFiles(System.IO.Path.GetDirectoryName(timer.Layout.FilePath));
  // Search for config files relative to the current splits
  findConfigFiles(System.IO.Path.GetDirectoryName(timer.Run.FilePath));
  // Search for config files relative to the last-opened splits file (missing type info)
  // also: System.IO.Path.GetDirectoryName()
  // findConfigFiles(((LiveSplit.View.TimerForm)timer.Form).RunFactory.FilePath);
  // We can't run this later, because settings are baked once we exit this function.
  vars.log("Autosplitter loaded");
  vars.log("If you don't see a state descriptor below, your executable is named wrong.");
}

init {
  vars.panels = null; // Used to detect if init completes properly
  vars.gameIsRunning = false;
  vars.activePanel = -1;
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
  int globals = relativePosition + game.ReadValue<int>(ptr+46);

  // judge_panel()
  ptr = scanner.Scan(new SigScanTarget(2,
    "C7 83 ???????? 01000000", // mov [rbx+offset], 1
    "48 0F45 C8"               // cmovne rcx, rax
  ));
  if (ptr == IntPtr.Zero) {
    throw new Exception("Could not find solved offset!");
  }
  vars.solvedOffset = game.ReadValue<int>(ptr);

  // count_score()
  ptr = scanner.Scan(new SigScanTarget(7,
    "44 89 74 24 20", // mov [rsp+20], r14d
    "39 9F ????????"  // cmp [rdi+offset], ebx
  ));
  if (ptr == IntPtr.Zero) {
    throw new Exception("Could not find completed offset!");
  }
  vars.completedOffset = game.ReadValue<int>(ptr);

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
    globals, 0x18, 0xBFF*8, recordPowerOffset
  ));

  // Entity_Obelisk_Report::light_up
  ptr = scanner.Scan(new SigScanTarget(3,
    "C3",                      // ret
    "C7 81 ???????? 01000000", // mov [rcx+offset], 1
    "48 83 C4 20"              // add rsp, 20
  ));
  vars.epOffset = game.ReadValue<int>(ptr);

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
  relativePosition -= 0x13;
  vars.interactMode = new MemoryWatcher<int>(new DeepPointer(
    relativePosition + game.ReadValue<int>(ptr - 0x10)
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

  // do_focus_mode_left_mouse_press()
  ptr = scanner.Scan(new SigScanTarget(12, // Targeting byte 12
    "48 83 C4 20",   // add rsp, 20
    "5B",            // pop rbx
    "E9 ????????",   // jmp exit_focus_mode
    "8B 05 ????????" // mov eax, [id_to_use]
  ));
  if (ptr == IntPtr.Zero) {
    throw new Exception("Could not find audio log!");
  }
  relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;
  vars.audioLog = new MemoryWatcher<int>(new DeepPointer(
    relativePosition + game.ReadValue<int>(ptr)
  ));

  // Entity_Audio_Recording::set_render_parameters()
  ptr = scanner.Scan(new SigScanTarget(7, // Targeting byte 7
    "E9 AF010000",   // jmp +0x1AF
    "8B 83 ????0000" // mov eax, [rbx + offset]
  ));
  if (ptr == IntPtr.Zero) {
    throw new Exception("Could not find audio log playing!");
  }
  vars.audioLogOffset = game.ReadValue<int>(ptr);
  vars.completedAudioLogs = new HashSet<int>();

  // simulate_guy()
  ptr = scanner.Scan(new SigScanTarget(8,
    "F2 0F10 00",          // movsd xmm0, [rax]
    "F2 0F11 05 ????????", // movsd [target], xmm0
    "8B 48 08",            // mov ecx, [rax+08]
    "89 0D ????????"       // mov [???], ecx
  ));
  if (ptr == IntPtr.Zero) {
    throw new Exception("Could not find player position");
  }

  relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;
  vars.playerPos = relativePosition + game.ReadValue<int>(ptr);
  vars.GetDistanceToPlayer = (Func<int, float>) ((int panel) => {
    var panelX = vars.createPointer(panel, 0x24).Deref<float>(game);
    var panelY = vars.createPointer(panel, 0x28).Deref<float>(game);
    var panelZ = vars.createPointer(panel, 0x2C).Deref<float>(game);
    var playerX = new DeepPointer(vars.playerPos + 0x00).Deref<float>(game);
    var playerY = new DeepPointer(vars.playerPos + 0x04).Deref<float>(game);
    var playerZ = new DeepPointer(vars.playerPos + 0x08).Deref<float>(game);

    return (float)Math.Sqrt(
      Math.Pow(panelX - playerX, 2) +
      Math.Pow(panelY - playerY, 2) +
      Math.Pow(panelZ - playerZ, 2));
  });

  vars.log("-------------------"
    + "\nGlobals: " + globals.ToString("X")
    + "\nSolved offset: " + vars.solvedOffset.ToString("X")
    + "\nCompleted offset: " + vars.completedOffset.ToString("X")
    + "\nObelisk offset: " + obeliskOffset.ToString("X")
    + "\nDoor offset: " + vars.doorOffset.ToString("X")
    + "\nRecord Power offset: " + recordPowerOffset.ToString("X")
    + "\nEP offset: " + vars.epOffset.ToString("X")
    + "\nAudio log playing offset: " + vars.audioLogOffset.ToString("X")
    + "\n==================="
  );

  vars.createPointer = (Func<int, int, DeepPointer>)((int id, int offset) => {
    return new DeepPointer(globals, 0x18, id*8, offset);
  });

  vars.addPanel = (Action<int, int>)((int panel, int maxSolves) => {
    if (!vars.allPanels.Contains(panel)) {
      vars.log("Attempted to add panel 0x" + panel.ToString("X") + " which is not in the panel list! This is likely due to an incorrect ID in your configuration file.");
    } else if (!vars.panels.ContainsKey(panel)) { // This check is a little bit paranoid.
      vars.panels[panel] = new Tuple<int, int, DeepPointer>(
        0,         // Number of times solved
        maxSolves, // Number of times to split
        vars.createPointer(panel, vars.solvedOffset)
      );
    }
  });

  vars.panels = new Dictionary<int, Tuple<int, int, DeepPointer>>();
  vars.obeliskWatchers = new MemoryWatcherList();
  vars.watchers = new MemoryWatcherList();
  vars.watchedAudiologs = new HashSet<int>();

  if (settings["Split on environmental patterns"]) {
    foreach (int obelisk in vars.obelisks) {
      vars.obeliskWatchers.Add(new MemoryWatcher<int>(vars.createPointer(obelisk, obeliskOffset)));
    }
  }

  vars.initPuzzles = (Action)(() => {
    vars.activeAudioLog = 0;
    vars.hoveringOverAudioLog = null;
    vars.activelyPlayingAudioLog = null;
    vars.completedAudioLogs.Clear();
    vars.watchedAudiologs.Clear();
    vars.epCount = 0;
    vars.obeliskWatchers.UpdateAll(game);
    foreach (var watcher in vars.obeliskWatchers) vars.epCount += watcher.Current;
    vars.log("Loaded with EP count: " + vars.epCount);

    vars.panels.Clear();
    vars.watchers.Clear();
    if (settings["Split on all panels (solving and non-solving)"]) {
      foreach (var panel in vars.keepWalkOns) {
        // A little bit of a hack -- keep purple is essentially a multipanel, so we need to use the solved offset.
        var watcher = new MemoryWatcher<int>(vars.createPointer(panel, vars.solvedOffset));
        watcher.Name = "Keep walk-on " + vars.panelToString(panel);
        vars.watchers.Add(watcher);
      }
      foreach (var panel in vars.multipanel) {
        vars.addPanel(panel, 0);
        var watcher = new MemoryWatcher<int>(vars.createPointer(panel, vars.completedOffset));
        watcher.Name = "Multipanel " + vars.panelToString(panel);
        vars.watchers.Add(watcher);
      }
      vars.watchers.UpdateAll(game);
      // Multi-panels use the solved offset, since they need to be solved every time you exit them
      foreach (var panel in vars.multiPanels) vars.addPanel(panel, 9999);
      // Boat speed panel should never split, it's too inconsistent
      vars.addPanel(0x34C7F, 0);
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
          var line = lines[i].Split('#')[0]; // Strip comments
          line = line.Trim(); // Strip whitespace
          if (line == "") continue; // No reason to process empty lines

          if (line.Contains(':')) {
            var parts = line.Split(':');
            mode = parts[0];
            if (mode == "version") version = Int32.Parse(parts[1]);
            continue;
          }
          // Don't try to process the file if it's an unknown version
          if (version > 1) continue;

          int id = Convert.ToInt32(line, 16);
          MemoryWatcher watcher = null;
          if (mode == "panels") {
            if (vars.keepWalkOns.Contains(id) || vars.multipanel.Contains(id)) {
              watcher = new MemoryWatcher<int>(vars.createPointer(id, vars.completedOffset));
            } else {
              vars.addPanel(id, 1);
              continue;
            }
          } else if (mode == "multipanels") {
            if (vars.keepWalkOns.Contains(id) || vars.multipanel.Contains(id)) {
              watcher = new MemoryWatcher<int>(vars.createPointer(id, vars.solvedOffset));
            } else {
              vars.addPanel(id, 9999);
              continue;
            }
          } else if (mode == "eps") {
            watcher = new MemoryWatcher<int>(vars.createPointer(id, vars.epOffset));
          } else if (mode == "doors") {
            watcher = new MemoryWatcher<float>(vars.createPointer(id, vars.doorOffset));
          } else if (mode == "audiologs") {
            vars.watchedAudiologs.Add(id);
            continue;
          } else {
            vars.log("Encountered unknown mode: " + mode);
            continue;
          }
          watcher.Name = mode.TrimEnd('s') + ' ' + vars.panelToString(id);
          vars.watchers.Add(watcher);
          vars.log("Watching " + watcher.Name);
        }
        vars.log("Watching " + vars.panels.Count + " panels");
        vars.watchers.UpdateAll(game);
      }
    }

    vars.deathCount = 0;
    vars.updateText = false;
    if (settings["Override first text component with a Failed Panels count"]
     || settings["Override first text component with a Completed Audio Logs count"]
     || settings["(Amerald Debugging)"]) {
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

  // Don't run if the game is loading. This is necessary to handle reloads
  vars.time.Update(game);
  if (vars.time.Current <= vars.time.Old) return false;

  vars.gameFrames.Update(game);
  vars.puzzle.Update(game);
  // This is handled in update rather than reset to account for manual resets
  if (vars.gameFrames.Current == 0) vars.gameIsRunning = false;
  vars.playerMoving.Update(game);
  vars.interactMode.Update(game);
  vars.challengeActive.Update(game);
  vars.eyelidStart.Update(game);
  vars.obeliskWatchers.UpdateAll(game);
  vars.watchers.UpdateAll(game);

  if (vars.updateText) {
    if (settings["Override first text component with a Failed Panels count"]) {
      vars.tcs.Text1 = "Failed Panels:";
      vars.tcs.Text2 = vars.deathCount.ToString();
    } else if (settings["Override first text component with a Completed Audio Logs count"]) {
      vars.tcs.Text1 = "Audio Logs:";
      vars.tcs.Text2 = vars.completedAudioLogs.Count.ToString();
    } else if (settings["(Amerald Debugging)"]) {
      vars.tcs.Text1 = vars.panelToString(vars.activePanel);
      if (vars.panels.ContainsKey(vars.activePanel)) {
        var puzzleData = vars.panels[vars.activePanel];
        vars.tcs.Text2 = "" + puzzleData.Item3.Deref<int>(game);
      }
    }
  }
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
  if (settings["Only start on challenge start"]) {
    if (vars.challengeActive.Old == 0.0 && vars.challengeActive.Current == 1.0) {
      vars.gameIsRunning = true;
      vars.initPuzzles();
      return true;
    }
  } else {
    // If "Only start on challenge start" is active, don't start for any other reason
    if (vars.playerMoving.Old == 0 && vars.playerMoving.Current == 1) {
      if (!vars.gameIsRunning) {
        vars.gameIsRunning = true;
        vars.initPuzzles();
        return true;
      }
    }
    // Mode 0 == solve, Mode 1 == panel, Mode 2 == walk, Mode 3 == flythrough
    if (vars.interactMode.Old == 2 && vars.interactMode.Current != 2) {
      if (!vars.gameIsRunning) {
        vars.gameIsRunning = true;
        vars.initPuzzles();
        return true;
      }
    }
  }
}

split {
  if (vars.puzzle.Old == 0 && vars.puzzle.Current != 0) {
    int panel = vars.puzzle.Current - 1;
    if (vars.allPanels.Contains(panel)) { // Only set activePanel if it's actually a panel.
      vars.activePanel = panel;
      vars.log("Started panel " + vars.panelToString(panel));
      if (!vars.panels.ContainsKey(panel)) {
        vars.log("Encountered new panel " + vars.panelToString(panel));
        if (settings["Split on all panels (solving and non-solving)"]) {
          vars.addPanel(panel, 1);
        } else {
          vars.addPanel(panel, 0);
        }
      }
    }
  }

  if (vars.activePanel != -1 && vars.panels.ContainsKey(vars.activePanel)) {
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
    if (state == 1 || state == 4 ||
      // Cinema input panel exits in state 3 on the first solve
      (vars.activePanel == 0x00815 && state == 3 && puzzleData.Item1 == 0) ||
      // Challenge start exits in state 3 sometimes
      (vars.activePanel == 0x0A332 && state == 3) ||
      // If a puzzle is solved beyond a certain distance, report any state as success.
      // Stairs snipe is ~10, Town redirect snipe is ~22, Desert surface 8 is solvable at ~25
      // Town snipe is ~30, Quarry laser is ~32, Swamp snipe is ~45, Boathouse is ~70
      (state != 0 && vars.GetDistanceToPlayer(panel) > 27.0f)
    ) {
      vars.panels[panel] = new Tuple<int, int, DeepPointer>(
        puzzleData.Item1 + 1, // Current solve count
        puzzleData.Item2,     // Maximum solve count
        puzzleData.Item3      // State pointer
      );
      vars.log("Panel " + vars.panelToString(panel) + " has been solved " + vars.panels[panel].Item1 + " of " + puzzleData.Item2 + " time(s)");
      vars.activePanel = -1;
      if (puzzleData.Item1 < puzzleData.Item2) { // Split fewer times than the max
        return true;
      }
    } else if (state != 0) {
      vars.log("Panel " + vars.panelToString(panel) + " exited in state " + state);
      vars.activePanel = -1;
      if (state == 2 || state == 3) vars.deathCount++;
    }
  }

  foreach (var watcher in vars.watchers) {
    // N.B. doors go from 0 to 0.blah so this isn't exactly 0 -> 1
    if (watcher.Old == 0 && watcher.Current > 0) {
      vars.log("Splitting for watcher: " + watcher.Name);
      return true;
    }
  }

  if (settings["Split on audio logs"] || vars.watchedAudiologs.Count > 0
   || settings["Override first text component with a Completed Audio Logs count"]) {
    vars.audioLog.Update(game);
    if (vars.audioLog.Old == 0 && vars.audioLog.Current != 0) {
      var audioLog = vars.audioLog.Current - 1;
      vars.log("Started hovering over audio log: " + vars.panelToString(audioLog));
      vars.hoveringOverAudioLog = new MemoryWatcher<int>(vars.createPointer(audioLog, vars.audioLogOffset));
    } else if (vars.audioLog.Old != 0 && vars.audioLog.Current == 0) {
      var audioLog = vars.audioLog.Old - 1;
      vars.log("Stopped hovering over audio log: " + vars.panelToString(audioLog));
      vars.hoveringOverAudioLog = null;
    }

    if (vars.hoveringOverAudioLog != null) {
      vars.hoveringOverAudioLog.Update(game);
      if (vars.hoveringOverAudioLog.Old == 0 && vars.hoveringOverAudioLog.Current == 1) {
        vars.activeAudioLog = vars.audioLog.Current - 1;
        vars.log("Started playing audio log: " + vars.panelToString(vars.activeAudioLog));
        vars.activelyPlayingAudioLog = vars.hoveringOverAudioLog;
        vars.hoveringOverAudioLog = null;
        if (settings["Split on audio logs"]) {
          return true;
        } else if (vars.watchedAudiologs.Contains(vars.activeAudioLog)) {
          vars.watchedAudiologs.Remove(vars.activeAudioLog);
          return true;
        }
      }
    }

    if (vars.activelyPlayingAudioLog != null) {
      vars.activelyPlayingAudioLog.Update(game);
      if (vars.activelyPlayingAudioLog.Old == 1 && vars.activelyPlayingAudioLog.Current == 0) {
        vars.log("Audio log " + vars.panelToString(vars.activeAudioLog) + " stopped playing");
        vars.activelyPlayingAudioLog = null;

        int played = vars.createPointer(vars.activeAudioLog, vars.audioLogOffset + 4).Deref<int>(game);
        vars.log("Audio log finished playing: " + played); // Note: This is true when solving EEE, for some reason.
        if (played == 1) vars.completedAudioLogs.Add(vars.activeAudioLog);
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

  if (settings["Split on eclipse environmental start"]) {
    if (vars.puzzle.Old == 0 && vars.puzzle.Current == 0x339B9) {
      vars.log("Splitting for eclipse start");
      return true;
    }
  }

  if (settings["Split on easter egg ending"]) {
    if (vars.eyelidStart.Old == -1 && vars.eyelidStart.Current > 0) {
      return true;
    }
  }
}
