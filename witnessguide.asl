state("witness64_d3d11") {}
// Broken (and won't fix?)
// Town RGB blue is masked by red
// Bunker floor 2 is masked by 5
// Windmill deactivate -> Find door
// Use actual picture numbers rather than internal count?

startup {
  settings.Add("Loaded", true);
  vars.keepWalkOns = new List<int>{
    0x033EB, // Yellow
    0x01BEA, // Purple
    0x01CD4, // Green
    0x01D40, // Blue
  };
  vars.INPUT_FOLDER = "C:/Users/localhost/Dropbox/The Witness Tutorial Panels";
  vars.OUTPUT_FOLDER = "C:/Users/localhost/WitnessGuide";
}

init {
  vars.initDone = false;
  vars.activePanel = 0;
  vars.nextId = 0;
  vars.multiCount = 0;
  vars.swampIslandCount = 0;
  vars.activePanelPointer = null;
  vars.lightColor = "_b";
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
  ptr = scanner.Scan(new SigScanTarget(2,
    "C7 83 ???????? 01000000", // mov [rbx+offset], 1
    "48 0F45 C8"               // cmovne rcx, rax
  ));
  if (ptr == IntPtr.Zero) {
    throw new Exception("Could not find solved offset!");
  }
  int solvedOffset = game.ReadValue<int>(ptr);

  // clear_traced_edges()
  ptr = scanner.Scan(new SigScanTarget(2,
    "C7 83 ????0000 00000000", // mov [rbx + offset], 0
    "74 08"                    // je 08
  ));
  if (ptr == IntPtr.Zero) {
    throw new Exception("Could not find segment count offset!");
  }
  int segmentOffset = game.ReadValue<int>(ptr);

  // Entity_Bridge::update()
  ptr = scanner.Scan(new SigScanTarget(3,
    "0F2F 83 ????????", // comiss xmm0, [rbx + target]
    "73 28",            // jae
    "4C 8B 05 ????????" // mov r8, [SND_PIVOT_PANEL_CW]
  ));
  if (ptr == IntPtr.Zero) {
    throw new Exception("Could not find bridge offsets!");
  }
  int bridgeTargetA = game.ReadValue<int>(ptr);
  int bridgeTargetB = game.ReadValue<int>(ptr+34);

  // Entity_Door::update()
  ptr = scanner.Scan(new SigScanTarget(4,
    "F3 0F10 8B ????????", // movss xmm1, [rbx + target1]
    "F3 0F10 83 ????????", // movss xmm1, [rbx + target2]
    "48 89 BC 24 ????????" // mov [rsp+??], rdi
  ));
  if (ptr == IntPtr.Zero) {
    throw new Exception("Could not find door offsets!");
  }
  int doorCurrent = game.ReadValue<int>(ptr);
  int doorTarget = game.ReadValue<int>(ptr+8);

  // update_position_panel()
  ptr = scanner.Scan(new SigScanTarget(3,
    "45 3B B7 ????????", // cmp r14d, [r15+offset]
    "0F85 ????????"      // jne ??
  ));
  if (ptr == IntPtr.Zero) {
    throw new Exception("Could not find door offsets!");
  }
  int boatLength = game.ReadValue<int>(ptr);

  // update_position_panel()
  ptr = scanner.Scan(new SigScanTarget(5,
    "73 0E",             // jae ??
    "49 8B 87 ????????", // mov rax, [r15+offset]
    "0F28 F8"            // movaps xmm7, xmm0
  ));
  int waypointOffset = game.ReadValue<int>(ptr);

  // Entity_Obelisk_Report::light_up
  ptr = scanner.Scan(new SigScanTarget(3,
    "C3",                      // ret
    "C7 81 ???????? 01000000", // mov [rcx+offset], 1
    "48 83 C4 20"              // add rsp, 20
  ));
  int epOffset = game.ReadValue<int>(ptr);

  // Entity_Light::power_on
  ptr = scanner.Scan(new SigScanTarget(21,
    "40 53",        // push rbx
    "48 83 EC 20",  // sub rsp, 20
    "48 8B D9",     // mov rbx, rcx
    "E8 ????????",  // call Entity::wake
    "B2 01"         // mov dl, 01
  ));
  int lightOnOffset = game.ReadValue<int>(ptr);

  print(
    "Solved offset: "+solvedOffset.ToString("X")
    + "\n Segment offset: "+segmentOffset.ToString("X")
    + "\n Bridge TargetA offset: "+bridgeTargetA.ToString("X")
    + "\n Bridge TargetB offset: "+bridgeTargetB.ToString("X")
    + "\n Door Current offset: "+doorCurrent.ToString("X")
    + "\n Door Target offset: "+doorTarget.ToString("X")
    + "\n Boat Path Length offset: "+boatLength.ToString("X")
    + "\n Boat Waypoint offset: "+waypointOffset.ToString("X")
    + "\n EP offset: "+epOffset.ToString("X")
    + "\n Light On offset: "+lightOnOffset.ToString("X")
  );

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
  vars.playerX = new MemoryWatcher<float>(new DeepPointer(
    relativePosition + game.ReadValue<int>(ptr)
  ));
  vars.playerY = new MemoryWatcher<float>(new DeepPointer(
    relativePosition + game.ReadValue<int>(ptr) + 4
  ));
  vars.playerZ = new MemoryWatcher<float>(new DeepPointer(
    relativePosition + game.ReadValue<int>(ptr) + 8
  ));

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
  vars.audioLogs = new HashSet<int>();

  Func<int, int, DeepPointer> createPointer = (int puzzle, int offset) => {
    return new DeepPointer(basePointer, 0x18, (puzzle-1)*8, offset);
  };
  // First panel in the game
  int panelType = createPointer(0x65, 0x8).Deref<int>(game);
  if (panelType == 0) {
    throw new Exception("Couldn't find panel type!");
  }
  print("Panel type: 0x"+panelType.ToString("X"));
  vars.setActivePanel = (Action<int>)((int panel) => {
    int type = createPointer(panel, 0x8).Deref<int>(game);
    if (type == panelType) {
      vars.activePanel = panel;
      vars.activePanelPointer = createPointer(panel, solvedOffset);
    }
  });

  vars.keepWatchers = new MemoryWatcherList();
  foreach (var panel in vars.keepWalkOns) {
    vars.keepWatchers.Add(new MemoryWatcher<int>(createPointer(panel, solvedOffset)));
  }
  vars.keepWatchers.UpdateAll(game);

  Dictionary<int, string> epNames = new Dictionary<int, string>{
    {0x000D4, "Green Room"},
    {0x000F8, "Windmill Third Blade"},
    {0x001A4, "River"},
    {0x0053D, "Facade Right"},
    {0x0053E, "Rock Shadow"},
    {0x0053F, "Ground Shadow"},
    {0x005F7, "Boathouse Front Ramp"},
    {0x00615, "Lift Light"},
    {0x0069E, "Ramp Light"},
    {0x006E6, "Left Facade Near"},
    {0x006E7, "Right Facade Far"},
    {0x006E8, "Left Facade Far"},
    {0x0076A, "Burned House Shadow"},
    {0x00772, "Facade Left"},
    {0x0085A, "Boathouse Back Ramp"},
    {0x0105E, "Left Sliding Bridge"},
    {0x016B3, "CCW Bridge Shadow"},
    {0x01849, "Hallway"},
    {0x018B7, "Blue Left Pressure Plate"},
    {0x0332C, "Black Line Reflection"},
    {0x03336, "SE Tower Underside"},
    {0x03368, "Black Line"},
    {0x033BF, "Yellow Pressure Plate"},
    {0x033C0, "Purple Pressure Plate"},
    {0x033DE, "Green Pressure Plate"},
    {0x033E6, "Blue Right Pressure Plate"},
    {0x03413, "NE Tower Underside"},
    {0x034A8, "Left Shutter"},
    {0x034AE, "Middle Shutter"},
    {0x034B0, "Right Shutter"},
    {0x035C8, "Tractor"},
    {0x035CA, "Orange Crate"},
    {0x035CC, "CCW Bamboo Sky"},
    {0x035D0, "CW Bamboo Sky"},
    {0x035DF, "Inward Purple Sand"},
    {0x035F6, "Doorway"},
    {0x03602, "Outward Purple Sand"},
    {0x03604, "Around Purple Sand"},
    {0x036CF, "CW Bridge Shadow"},
    {0x03732, "Floodgate"},
    {0x037B3, "Windmill Second Blade"},
    {0x037B7, "Windmill First Blade"},
    {0x037BC, "Elevator"},
    {0x038A7, "NW Tower Underside"},
    {0x038AB, "SW Tower Underside"},
    {0x03A7A, "Stern"},
    {0x03A94, "Underwater Yellow Line"},
    {0x03A9F, "Underwater Orange Line"},
    {0x03AA7, "Underwater Bridge"},
    {0x03ABD, "Long Arch Moss"},
    {0x03ABF, "Straight Left Moss"},
    {0x03AC1, "Pop-up Wall Moss"},
    {0x03AC5, "Short Arch Moss"},
    {0x03AC6, "Green Leaf Moss"},
    {0x03B23, "Aft Circle"},
    {0x03B24, "Starboard Circle"},
    {0x03B25, "Port Circle"},
    {0x03B26, "Shipwreck CCW Underside"},
    {0x03BCF, "Tower Black Line"},
    {0x03BD0, "Redirect Black Line"},
    {0x03BD2, "Bell Tower Black Line"},
    {0x03BE3, "Left Courtyard"},
    {0x03BE4, "Right Courtyard"},
    {0x03C08, "Cove"},
    {0x03C1A, "Moss"},
    {0x03D07, "Garden"},
    {0x03D0E, "Bunker"},
    {0x03DAC, "Right Facade Near"},
    {0x03DAD, "Right Facade Stairs"},
    {0x03DAE, "Left Facade Stairs"},
    {0x03E02, "Grass Stairs"},
    {0x03E40, "Red Light"},
    {0x03E41, "Green Light"},
    {0x03E78, "Red Flowers"},
    {0x03E7D, "Purple Flowers"},
    {0x09D5E, "Yellow Pathway"},
    {0x09D5F, "Blue Pathway"},
    {0x09D64, "Pink Pathway"},
    {0x0A14D, "Pond Near Reflection"},
    {0x0A14E, "Pond Far Reflection"},
    {0x0A305, "Right Sliding Bridge"},
    {0x0A40A, "Stone Wall"},
    {0x17CBA, "Railroad"},
    {0x220A8, "Short Bridge"},
    {0x220BE, "Long Bridge"},
    {0x220E5, "Broken Wall Straight"},
    {0x220E6, "Broken Wall Bend"},
    {0x22107, "Desert"},
    {0x289D0, "Rock Line"},
    {0x289D2, "Rock Line Reflection"},
    {0x289F5, "Entrance"},
    {0x289F6, "Tree Halo"},
    {0x28A30, "Short Sewer"},
    {0x28A38, "Long Sewer"},
    {0x28A4B, "Shore"},
    {0x28A4D, "Sand Pile"},
    {0x28A7C, "Rooftop Vent"},
    {0x28ABE, "Inner Rope"},
    {0x28ABF, "Outer Rope"},
    {0x28AEA, "Dirt Path"},
    {0x28B2A, "Shipwreck Green"},
    {0x28B2B, "Shipwreck CW Underside"},
    {0x28B31, "Challenge"},
    {0x28B8B, "Yellow Vase"},
    {0x28B8F, "Bridge Underside"},
    {0x28B92, "Thundercloud"},
    {0x33490, "Hedge Mazes"},
    {0x334A4, "Path"},
    {0x334B7, "Entrance Pipe"},
    {0x334BA, "Shore"},
    {0x334BD, "Island"},
    {0x33506, "Bush"},
    {0x3351E, "Sand Snake"},
    {0x33530, "Gate"},
    {0x33531, "Cloud"},
    {0x335AF, "Cloud Cycle"},
    {0x335C9, "Stairs Left"},
    {0x335CA, "Stairs Right"},
    {0x33601, "Flowers"},
    {0x33660, "Stern of Boat"},
    {0x33693, "Brown Bridge"},
    {0x3369B, "Left White Arch"},
    {0x336C9, "Right White Arch"},
    {0x3370F, "Black Arch"},
    {0x33722, "Buoy"},
    {0x337F9, "Flood Room"},
    {0x33858, "Tutorial"},
    {0x3387A, "Tutorial Reflection"},
    {0x33890, "Couch"},
    {0x3397D, "Skylight"},
    {0x339B7, "Eclipse"},
    {0x33A21, "Catwalk"},
    {0x33A2A, "Window"},
    {0x33A2B, "Doorway"},
    {0x33B07, "Church"},
  };
  Dictionary<int, string> audioLogNames = new Dictionary<int, string>{
    {0x0050A, "Tutorial Gate"},
    {0x0074F, "Keep Front Wall"},
    {0x00761, "Swamp Shortcut"},
    {0x00763, "Mountain 1 Blue Panels"},
    {0x00A0F, "Mountaintop "},
    {0x011F9, "Mountain 1 Junk Column"},
    {0x012C7, "Keep Throne"},
    {0x015B7, "Town Obelisk"},
    {0x015C0, "Stones Tutorial"},
    {0x015C1, "Treehouse Green Bridge"},
    {0x329FE, "Shipwreck Bridge"},
    {0x329FF, "Mill Stairs"},
    {0x32A00, "Bunker Green Room"},
    {0x32A07, "Swamp Purple Underwater"},
    {0x32A08, "Mountain 2 Blue Path Panel"},
    {0x32A0A, "Town Lattice Panel Left"},
    {0x32A0E, "Shadows Orange Crate"},
    {0x336E5, "Easter Egg Ending Apple"},
    {0x338A3, "Easter Egg Ending Countertop"},
    {0x338A4, "Easter Egg Ending Sunbathing"},
    {0x338A5, "Easter Egg Ending Wine Table"},
    {0x338A6, "Easter Egg Ending Purple Flowers"},
    {0x338A7, "Easter Egg Ending Record"},
    {0x338AD, "Easter Egg Ending Briefcase (iOS)"},
    {0x338AE, "Easter Egg Ending Briefcase"},
    {0x338AF, "Easter Egg Ending Briefcase (?)"},
    {0x338B0, "Easter Egg Ending Briefcase (?)"},
    {0x338B7, "Easter Egg Ending Briefcase (?)"},
    {0x338BD, "UTM Town Shortcut"},
    {0x338C1, "UTM Challenge Record"},
    {0x338C9, "UTM Mountainside Shortcut"},
    {0x338CA, "UTM Invisible Dots"},
    {0x338D7, "UTM Stairwell"},
    {0x338EF, "Easter Egg Ending Pillow"},
    {0x339A8, "Tutorial Patio Roof"},
    {0x339A9, "Discard"},
    {0x33AFF, "Mountain 1 Purple Path Panel"},
    {0x33B36, "Peninsula "},
    {0x33B37, "Symmetry Fading Lines"},
    {0x3C0F3, "Town Bell Tower"},
    {0x3C0F4, "Jungle Entrance Left"},
    {0x3C0F7, "Boat Treehouse Rock"},
    {0x3C0FD, "Boat Broken Boat"},
    {0x3C0FE, "Desert Broken Wall"},
    {0x3C0FF, "Mountain 3 Peekaboo"},
    {0x3C100, "Jungle Entrance Right"},
    {0x3C101, "Mountain 3 Giant Floor"},
    {0x3C102, "Jungle Laser"},
    {0x3C103, "Cloud Cycle"},
    {0x3C104, "Treehouse Docks"},
    {0x3C105, "Tunnels Box"},
    {0x3C106, "Monastery Left Shutters"},
    {0x3C107, "Town Laser Redirect"},
    {0x3C108, "Easter Egg Ending Pool"},
    {0x3C109, "Symmetry Behind Laser"},
    {0x3C10A, "Town Lattice Panel Right"},
    {0x3C10B, "Keep Guitar Amp"},
    {0x3C10C, "Shadows Laser"},
    {0x3C10D, "Jungle Beach"},
    {0x3C10E, "Keep Corridor"},
    {0x3C12A, "Treehouse Shipwreck Shore"},
    {0x3C135, "UTM Cave In"},
  };

  Dictionary<int, string> panelNames = new Dictionary<int, string>{
    {0x00001, "Red Underwater 1"},
    {0x00002, "Teal Underwater 1"},
    {0x00004, "Teal Underwater 2"},
    {0x00005, "Teal Underwater 3"},
    {0x00006, "Blue Underwater 5"},
    {0x00007, "Rotation Tutorial 1"},
    {0x00008, "Rotation Tutorial 2"},
    {0x00009, "Rotation Tutorial 3"},
    {0x0000A, "Rotation Tutorial 4"},
    {0x0001B, "Stones Tutorial 2"},
    {0x0001C, "Stones Tutorial 4"},
    {0x0001D, "Stones Tutorial 5"},
    {0x0001E, "Stones Tutorial 6"},
    {0x0001F, "Stones Tutorial 7"},
    {0x00020, "Stones Tutorial 8"},
    {0x00021, "Stones Tutorial 9"},
    {0x00022, "Black Dots 1"},
    {0x00023, "Black Dots 2"},
    {0x00024, "Black Dots 3"},
    {0x00025, "Black Dots 4"},
    {0x00026, "Black Dots 5"},
    {0x00027, "Invisible Dots Symmetry 1"},
    {0x00028, "Invisible Dots Symmetry 2"},
    {0x00029, "Invisible Dots Symmetry 3"},
    {0x00037, "Exterior 3"},
    {0x00038, "Exterior 2"},
    {0x0003B, "Apple Tree 2"},
    {0x00055, "Apple Tree 3"},
    {0x00059, "Vertical Symmetry 3"},
    {0x0005C, "Vertical Symmetry 5"},
    {0x0005D, "Dots Tutorial 1"},
    {0x0005E, "Dots Tutorial 2"},
    {0x0005F, "Dots Tutorial 3"},
    {0x00060, "Dots Tutorial 4"},
    {0x00061, "Dots Tutorial 5"},
    {0x00062, "Vertical Symmetry 4"},
    {0x00064, "Straight"},
    {0x00065, "Fading Lines 1"},
    {0x0006A, "Invisible Dots 7"},
    {0x0006B, "Invisible Dots 2"},
    {0x0006C, "Invisible Dots 8"},
    {0x0006D, "Fading Lines 2"},
    {0x0006F, "Fading Lines 4"},
    {0x00070, "Fading Lines 5"},
    {0x00071, "Fading Lines 6"},
    {0x00072, "Fading Lines 3"},
    {0x00073, "Colored Dots 4"},
    {0x00075, "Colored Dots 3"},
    {0x00076, "Fading Lines 7"},
    {0x00077, "Colored Dots 5"},
    {0x00079, "Colored Dots 6"},
    {0x0007C, "Colored Dots 1"},
    {0x0007E, "Colored Dots 2"},
    {0x00081, "Rotational Symmetry 2"},
    {0x00082, "Melting 2"},
    {0x00083, "Rotational Symmetry 3"},
    {0x00084, "Melting 1"},
    {0x00086, "Vertical Symmetry 1"},
    {0x00087, "Vertical Symmetry 2"},
    {0x00089, "Invisible Dots 6"},
    {0x0008A, "Invisible Dots 5"},
    {0x0008B, "Invisible Dots 3"},
    {0x0008C, "Invisible Dots 4"},
    {0x0008D, "Rotational Symmetry 1"},
    {0x0008F, "Invisible Dots 1"},
    {0x000B0, "Door 1"},
    {0x00139, "Hedges 1"},
    {0x00143, "Apple Tree 1"},
    {0x00182, "Bend"},
    {0x00190, "Blue Right Near 1"},
    {0x00262, "Tutorial 3"},
    {0x0026D, "Dots 1"},
    {0x0026E, "Dots 2"},
    {0x0026F, "Dots 3"},
    {0x00290, "Exterior 1"},
    {0x00293, "Front Center"},
    {0x00295, "Center Left"},
    {0x002A6, "Vault"},
    {0x002C2, "Front Left"},
    {0x002C4, "Waves 1"},
    {0x002C6, "Waves 3"},
    {0x002C7, "Waves 7"},
    {0x00390, "Tutorial 7"},
    {0x003B2, "Rotation Advanced 1"},
    {0x003E8, "Transparent 2"},
    {0x00422, "Light 1"},
    {0x0042D, "River"},
    {0x00469, "Tutorial 1"},
    {0x00472, "Tutorial 2"},
    {0x00474, "Tutorial 4"},
    {0x0048F, "Surface 2"},
    {0x0051F, "Column"},
    {0x00524, "Column"},
    {0x00553, "Tutorial 5"},
    {0x00557, "Upper Row 1"},
    {0x00558, "Blue Right Near 2"},
    {0x00567, "Blue Right Near 3"},
    {0x0056E, "Entry"},
    {0x0056F, "Tutorial 6"},
    {0x00596, "Teal Underwater 5"},
    {0x005F1, "Upper Row 2"},
    {0x00609, "Surface Sliding Bridge Control"},
    {0x00620, "Upper Row 3"},
    {0x00698, "Surface 1"},
    {0x006E3, "Light 2"},
    {0x006FE, "Blue Right Near 4"},
    {0x0070E, "Waves 4"},
    {0x0070F, "Waves 5"},
    {0x00767, "Waves 2"},
    {0x0078D, "Pond 4"},
    {0x00815, "Video Input"},
    {0x0087D, "Waves 6"},
    {0x0088E, "Easy Maze"},
    {0x008B8, "Blue Left 1"},
    {0x008BB, "Pond 3"},
    {0x00973, "Blue Left 2"},
    {0x0097B, "Blue Left 3"},
    {0x0097D, "Blue Left 4"},
    {0x0097E, "Blue Left 5"},
    {0x0097F, "Red 2"},
    {0x00982, "Red 1"},
    {0x00983, "Tutorial 9"},
    {0x00984, "Tutorial 10"},
    {0x00985, "Tutorial 12"},
    {0x00986, "Tutorial 11"},
    {0x00987, "Tutorial 13"},
    {0x0098F, "Red 3"},
    {0x00990, "Red 4"},
    {0x00994, "Blue Right Far 1"},
    {0x00995, "Blue Right Far 3"},
    {0x00996, "Blue Right Far 4"},
    {0x00998, "Blue Right Far 5"},
    {0x00999, "Discontinuous 1"},
    {0x0099D, "Discontinuous 2"},
    {0x009A0, "Discontinuous 3"},
    {0x009A1, "Discontinuous 4"},
    {0x009A4, "Blue Discontinuous"},
    {0x009A6, "Purple Tetris"},
    {0x009AB, "Blue Underwater 1"},
    {0x009AD, "Blue Underwater 2"},
    {0x009AE, "Blue Underwater 3"},
    {0x009AF, "Blue Underwater 4"},
    {0x009B8, "Transparent 1"},
    {0x009F5, "Upper Row 4"},
    {0x00A15, "Transparent 3"},
    {0x00A1E, "Rotation Advanced 2"},
    {0x00A52, "Laser Yellow 1"},
    {0x00A57, "Laser Yellow 2"},
    {0x00A5B, "Laser Yellow 3"},
    {0x00A61, "Laser Blue 1"},
    {0x00A64, "Laser Blue 2"},
    {0x00A68, "Laser Blue 3"},
    {0x00A72, "Blue Cave In"},
    {0x00AFB, "Vault"},
    {0x00B10, "Left Door"},
    {0x00B53, "Transparent 4"},
    {0x00B71, "Quarry"},
    {0x00B8D, "Transparent 5"},
    {0x00BAF, "Hard Maze"},
    {0x00BF3, "Stones Maze"},
    {0x00C09, "Pedestal"},
    {0x00C22, "Triple 2"},
    {0x00C2E, "Rotation Advanced 3"},
    {0x00C3F, "Dots 4"},
    {0x00C41, "Dots 5"},
    {0x00C59, "Triple 2"},
    {0x00C68, "Triple 2"},
    {0x00C72, "Pond 1"},
    {0x00C80, "Triple 1"},
    {0x00C92, "Right Door"},
    {0x00CA1, "Triple 1"},
    {0x00CB9, "Triple 1"},
    {0x00CD4, "Column"},
    {0x00CDB, "Column"},
    {0x00E0C, "Lower Row 1"},
    {0x00E3A, "Rotation Advanced 4"},
    {0x00FF8, "Entrance Door"},
    {0x010CA, "Tutorial 8"},
    {0x0117A, "Flood 4"},
    {0x01205, "Flood 2"},
    {0x0129D, "Pond 2"},
    {0x012C9, "Stones Tutorial 3"},
    {0x012D7, "Final Far"},
    {0x013E6, "Teal Underwater 4"},
    {0x0146C, "Upper Row 5"},
    {0x01489, "Lower Row 2"},
    {0x0148A, "Lower Row 3"},
    {0x014B2, "Dots 6"},
    {0x014D1, "Red Underwater 4"},
    {0x014D2, "Red Underwater 2"},
    {0x014D4, "Red Underwater 3"},
    {0x014D9, "Lower Row 4"},
    {0x014E7, "Lower Row 5"},
    {0x014E8, "Lower Row 6"},
    {0x014E9, "Upper Row 8"},
    {0x018A0, "Blue Easy Symmetry"},
    {0x018AF, "Stones Tutorial 1"},
    {0x01983, "Left Peekaboo"},
    {0x01987, "Right Peekaboo"},
    {0x019DC, "Hedges 2"},
    {0x019E7, "Hedges 3"},
    {0x01A0D, "Blue Hard Symmetry"},
    {0x01A0F, "Hedges 4"},
    {0x01A31, "Rainbow"},
    {0x01A54, "Entry"},
    {0x01BE9, "Purple Pressure Plates"},
    {0x01CD3, "Green Pressure Plates"},
    {0x01D3F, "Blue Pressure Plates"},
    {0x01E59, "Entry Door Right"},
    {0x01E5A, "Entry Door Left"},
    {0x021AE, "Erasers and Shapers 5"},
    {0x021AF, "Erasers and Shapers 4"},
    {0x021B0, "Erasers and Shapers 3"},
    {0x021B3, "Erasers and Shapers 1"},
    {0x021B4, "Erasers and Shapers 2"},
    {0x021B5, "Erasers and Stars 1"},
    {0x021B6, "Erasers and Stars 2"},
    {0x021B7, "Erasers and Stars 3"},
    {0x021BB, "Erasers and Stars 4"},
    {0x021D5, "Ramp Activation Shapers"},
    {0x021D7, "Mountainside Shortcut"},
    {0x02886, "Door 2"},
    {0x0288C, "Door 1"},
    {0x032F5, "Laser"},
    {0x032F7, "Apple Tree 4"},
    {0x032FF, "Apple Tree 5"},
    {0x03317, "Back Laser"},
    {0x0339E, "Vault Box"},
    {0x033D4, "Vault"},
    {0x033EA, "Yellow Pressure Plates"},
    {0x0343A, "Melting 3"},
    {0x03481, "Vault Box"},
    {0x034D4, "Ramp Activation Stars"},
    {0x034E3, "Soundproof Dots"},
    {0x034E4, "Soundproof Waves"},
    {0x034EC, "Triangle"},
    {0x034F4, "Triangle"},
    {0x03505, "Gate Close"},
    {0x03535, "Vault Box"},
    {0x03542, "Vault Box"},
    {0x03545, "Mountain Video"},
    {0x03549, "Challenge Video"},
    {0x0354E, "Jungle Video"},
    {0x0354F, "Shipwreck Video"},
    {0x03552, "Desert Video"},
    {0x03553, "Tutorial Video"},
    {0x0356B, "Vault Box"},
    {0x03608, "Laser"},
    {0x0360D, "Laser"},
    {0x0360E, "Front Laser"},
    {0x03612, "Quarry Laser"},
    {0x03613, "Laser"},
    {0x03615, "Laser"},
    {0x03616, "Laser"},
    {0x0361B, "Tower Shortcut"},
    {0x03629, "Gate Open"},
    {0x03675, "Upper Lift Control"},
    {0x03676, "Upper Ramp Control"},
    {0x03677, "Stairs Control"},
    {0x03678, "Lower Ramp Contol"},
    {0x03679, "Lower Lift Control"},
    {0x0367C, "Control Room 1"},
    {0x03686, "Upper Row 7"},
    {0x03702, "Vault Box"},
    {0x03713, "Shortcut"},
    {0x037FF, "Drawbridge Control"},
    {0x0383A, "Right Pillar 1"},
    {0x0383D, "Left Pillar 1"},
    {0x0383F, "Left Pillar 2"},
    {0x03852, "Ramp Angle Control"},
    {0x03858, "Ramp Position Control"},
    {0x03859, "Left Pillar 3"},
    {0x039B4, "Theater Catwalk"},
    {0x03C08, "RGB Stars"},
    {0x03C0C, "RGB Stones"},
    {0x04CA4, "Optional Door 2"},
    {0x04D18, "Flood 1"},
    {0x079DF, "Triple"},
    {0x09D9B, "Bonsai"},
    {0x09D9F, "Advanced 1"},
    {0x09DA1, "Advanced 2"},
    {0x09DA2, "Advanced 3"},
    {0x09DA6, "Surface 5"},
    {0x09DAF, "Advanced 4"},
    {0x09DB1, "Erasers and Stars 6"},
    {0x09DB3, "Erasers Shapers and Stars 1"},
    {0x09DB4, "Erasers Shapers and Stars 2"},
    {0x09DB5, "Erasers and Stars 5"},
    {0x09DB8, "Summon Boat"},
    {0x09DD5, "Challenge Pillar"},
    {0x09DE0, "Laser"},
    {0x09E39, "Purple Pathway"},
    {0x09E49, "Shadows Shortcut"},
    {0x09E56, "Right Pillar 2"},
    {0x09E57, "Entry Gate 1"},
    {0x09E5A, "Right Pillar 3"},
    {0x09E69, "Green 4"},
    {0x09E6B, "Orange 7"},
    {0x09E6C, "Orange 5"},
    {0x09E6F, "Orange 6"},
    {0x09E71, "Green 2"},
    {0x09E72, "Green 3"},
    {0x09E73, "Orange 1"},
    {0x09E75, "Orange 2"},
    {0x09E78, "Orange 3"},
    {0x09E79, "Orange 4"},
    {0x09E7A, "Green 1"},
    {0x09E7B, "Green 5"},
    {0x09E85, "Town Shortcut"},
    {0x09E86, "Blue Pathway"},
    {0x09EAD, "Purple 1"},
    {0x09EAF, "Purple 2"},
    {0x09ED8, "Orange Pathway"},
    {0x09EEB, "Elevator"},
    {0x09EFF, "Far Left Floor"},
    {0x09F01, "Far Right Floor"},
    {0x09F6E, "Blue 3"},
    {0x09F7D, "Tutorial 1"},
    {0x09F7F, "Laser Box"},
    {0x09F82, "Tutorial 4"},
    {0x09F86, "Surface 8 Control"},
    {0x09F8E, "Near Right Floor"},
    {0x09F92, "Surface 3"},
    {0x09F94, "Surface 8"},
    {0x09F98, "Laser Redirect Control"},
    {0x09FA0, "Surface 3 Control"},
    {0x09FAA, "Lightswitch"},
    {0x09FC1, "Near Left Floor"},
    {0x09FCC, "Multipanel 1"},
    {0x09FCE, "Multipanel 2"},
    {0x09FCF, "Multipanel 3"},
    {0x09FD0, "Multipanel 4"},
    {0x09FD1, "Multipanel 5"},
    {0x09FD2, "Multipanel 6"},
    {0x09FD3, "Rainbow 1"},
    {0x09FD4, "Rainbow 2"},
    {0x09FD6, "Rainbow 3"},
    {0x09FD7, "Rainbow 4"},
    {0x09FD8, "Rainbow 5"},
    {0x09FDA, "Giant Floor"},
    {0x09FDC, "Tutorial 2"},
    {0x09FF7, "Tutorial 3"},
    {0x09FF8, "Tutorial 5"},
    {0x09FFF, "Final Left Concave"},
    {0x0A010, "Glass 1"},
    {0x0A015, "Final Far Control"},
    {0x0A01B, "Glass 2"},
    {0x0A01F, "Glass 3"},
    {0x0A02D, "Light 3"},
    {0x0A036, "Surface 4"},
    {0x0A049, "Surface 6"},
    {0x0A053, "Surface 7"},
    {0x0A054, "Summon Boat"},
    {0x0A079, "Elevator"},
    {0x0A099, "Glass Door"},
    {0x0A0C8, "Orange Crate"},
    {0x0A15C, "Final Left Convex"},
    {0x0A15F, "Final Near"},
    {0x0A168, "Sun Exit"},
    {0x0A16B, "Green Dots 1"},
    {0x0A16E, "Challenge Entrance"},
    {0x0A171, "Optional Door 1"},
    {0x0A182, "Door 3"},
    {0x0A249, "Pond Exit Door"},
    {0x0A2CE, "Green Dots 2"},
    {0x0A2D7, "Green Dots 3"},
    {0x0A2DD, "Green Dots 4"},
    {0x0A2EA, "Green Dots 5"},
    {0x0A332, "Record Start"},
    {0x0A3A8, "Yellow Reset"},
    {0x0A3AD, "Blue Reset"},
    {0x0A3B2, "Back Right"},
    {0x0A3B5, "Back Left"},
    {0x0A3B9, "Purple Reset"},
    {0x0A3BB, "Green Reset"},
    {0x0A3CB, "Erasers Shapers and Stars 3"},
    {0x0A3CC, "Erasers Shapers and Stars 4"},
    {0x0A3D0, "Erasers Shapers and Stars 5"},
    {0x0A8DC, "Tutorial 5"},
    {0x0A8E0, "Tutorial 8"},
    {0x0AC74, "Tutorial 6"},
    {0x0AC7A, "Tutorial 7"},
    {0x0C335, "Pillar"},
    {0x0C339, "Surface Door"},
    {0x0C373, "Patio Floor"},
    {0x0CC7B, "Vault"},
    {0x15ADD, "Vault"},
    {0x17BDF, "Second Purple 5"},
    {0x17C02, "Laser Shortcut 2"},
    {0x17C05, "Laser Shortcut 1"},
    {0x17C09, "Entry Gate 2"},
    {0x17C0A, "Island Control 1"},
    {0x17C0D, "Red Shortcut 1"},
    {0x17C0E, "Red Shortcut 2"},
    {0x17C2E, "Entry Door"},
    {0x17C31, "Final Transparent"},
    {0x17C34, "Perspective"},
    {0x17C42, "Discard"},
    {0x17C71, "Rooftop Discard"},
    {0x17C95, "Summon Boat"},
    {0x17CA4, "Laser"},
    {0x17CA6, "Summon Boat"},
    {0x17CAA, "Courtyard Gate"},
    {0x17CAB, "Pop-up Wall"},
    {0x17CAC, "Stairs Shortcut Door"},
    {0x17CBC, "Interior Door Control"},
    {0x17CC4, "Elevator Control"},
    {0x17CC8, "Summon Boat"},
    {0x17CDF, "Summon Boat"},
    {0x17CE3, "Right Orange 4"},
    {0x17CE4, "First Purple 3"},
    {0x17CE7, "Discard"},
    {0x17CF0, "Discard"},
    {0x17CF2, "Waterfall Shortcut"},
    {0x17CF7, "Theater Discard"},
    {0x17CFB, "Discard"},
    {0x17D01, "Orange Crate Discard"},
    {0x17D02, "Windmill Control"},
    {0x17D27, "Discard"},
    {0x17D28, "Discard"},
    {0x17D2D, "First Purple 4"},
    {0x17D6C, "First Purple 5"},
    {0x17D72, "Yellow 1"},
    {0x17D74, "Yellow 3"},
    {0x17D88, "Right Orange 1"},
    {0x17D8C, "Right Orange 3"},
    {0x17D8E, "Right Orange 9"},
    {0x17D8F, "Yellow 2"},
    {0x17D91, "Second Purple 6"},
    {0x17D97, "Second Purple 4"},
    {0x17D99, "Second Purple 2"},
    {0x17D9B, "Second Purple 1"},
    {0x17D9C, "Yellow 7"},
    {0x17D9E, "Yellow 5"},
    {0x17DA2, "Right Orange 12"},
    {0x17DAA, "Second Purple 3"},
    {0x17DAC, "Yellow 4"},
    {0x17DAE, "Left Orange 13"},
    {0x17DB0, "Left Orange 14"},
    {0x17DB1, "Right Orange 11"},
    {0x17DB2, "Right Orange 6"},
    {0x17DB3, "Left Orange 1"},
    {0x17DB4, "Right Orange 2"},
    {0x17DB5, "Left Orange 2"},
    {0x17DB6, "Left Orange 3"},
    {0x17DB7, "Right Orange 10"},
    {0x17DB8, "Left Orange 7"},
    {0x17DB9, "Yellow 6"},
    {0x17DC0, "Left Orange 4"},
    {0x17DC2, "Yellow 8"},
    {0x17DC4, "Yellow 9"},
    {0x17DC6, "Second Purple 7"},
    {0x17DC7, "First Purple 2"},
    {0x17DC8, "First Purple 1"},
    {0x17DCA, "Right Orange 8"},
    {0x17DCC, "Right Orange 7"},
    {0x17DCD, "Right Orange 5"},
    {0x17DD1, "Left Orange 9"},
    {0x17DD7, "Left Orange 5"},
    {0x17DD9, "Left Orange 6"},
    {0x17DDB, "Left Orange 15"},
    {0x17DDC, "Left Orange 8"},
    {0x17DDE, "Left Orange 10"},
    {0x17DE3, "Left Orange 11"},
    {0x17DEC, "Left Orange 12"},
    {0x17E07, "Island Control 2"},
    {0x17E2B, "Floodgate Control"},
    {0x17E3C, "Green 1"},
    {0x17E4D, "Green 2"},
    {0x17E4F, "Green 3"},
    {0x17E52, "Green 4"},
    {0x17E5B, "Green 5"},
    {0x17E5F, "Green 6"},
    {0x17E61, "Green 7"},
    {0x17E63, "Ultraviolet 1"},
    {0x17E67, "Ultraviolet 2"},
    {0x17ECA, "Flood 5"},
    {0x17F5F, "Windmill Door"},
    {0x17F89, "Theater Entrance"},
    {0x17F93, "Discard"},
    {0x17F9B, "Discard"},
    {0x17FA0, "Laser Discard"},
    {0x17FA2, "Secret Door"},
    {0x17FA9, "Green Bridge Discard"},
    {0x17FB9, "Green Dots 6"},
    {0x18076, "Flood Exit"},
    {0x181A9, "Tutorial 14"},
    {0x181AB, "Flood 3"},
    {0x181F5, "Rotating Bridge Control"},
    {0x18313, "Pond 5"},
    {0x1831B, "Flood Control Raise Near Right"},
    {0x1831C, "Flood Control Lower Near Right"},
    {0x1831D, "Flood Control Raise Far Right"},
    {0x1831E, "Flood Control Lower Far Right"},
    {0x18488, "Underwater Sliding Bridge Control"},
    {0x18590, "Transparent"},
    {0x193A6, "Interior 4"},
    {0x193A7, "Interior 1"},
    {0x193AA, "Interior 2"},
    {0x193AB, "Interior 3"},
    {0x19650, "Laser"},
    {0x196E2, "Avoid 3"},
    {0x196F8, "Avoid 7"},
    {0x1972A, "Avoid 4"},
    {0x1972F, "Avoid 8"},
    {0x19771, "Tutorial 4"},
    {0x19797, "Follow 1"},
    {0x1979A, "Follow 2"},
    {0x197E0, "Follow 3"},
    {0x197E5, "Follow 5"},
    {0x197E8, "Follow 4"},
    {0x19806, "Avoid 6"},
    {0x19809, "Avoid 5"},
    {0x198B5, "Tutorial 1"},
    {0x198BD, "Tutorial 2"},
    {0x198BF, "Tutorial 3"},
    {0x1C260, "Flood Control Lower Near Left"},
    {0x1C2B1, "Flood Control Raise Near Left"},
    {0x1C2DF, "Flood Control Lower Far Left"},
    {0x1C2F3, "Flood Control Raise Far Left"},
    {0x1C319, "Right Pillar"},
    {0x1C31A, "Left Pillar"},
    {0x1C33F, "Avoid 2"},
    {0x1C349, "Door 2"},
    {0x2700B, "Exterior Door Control"},
    {0x275ED, "EP Door"},
    {0x275FA, "Hook Control"},
    {0x27732, "Theater Shortcut"},
    {0x2773D, "Desert Shortcut"},
    {0x288AA, "Perspective 4"},
    {0x288EA, "Perspective 1"},
    {0x288FC, "Perspective 2"},
    {0x28938, "Apple Tree"},
    {0x2896A, "Bridge"},
    {0x28998, "Green Door"},
    {0x2899C, "25 Dots 1"},
    {0x289E7, "Perspective 3"},
    {0x28A0D, "Church Stars"},
    {0x28A33, "25 Dots 2"},
    {0x28A69, "Lattice"},
    {0x28A79, "Maze"},
    {0x28ABF, "25 Dots 3"},
    {0x28AC0, "25 Dots 4"},
    {0x28AC1, "25 Dots 5"},
    {0x28AC7, "Blue 1"},
    {0x28AC8, "Blue 2"},
    {0x28ACA, "Blue 3"},
    {0x28ACB, "Blue 4"},
    {0x28ACC, "Blue 5"},
    {0x28AD9, "Eraser"},
    {0x28AE3, "Wire"},
    {0x28B39, "Red Hexagonal"},
    {0x2FAF6, "Postgame Vault Box"},
    {0x32962, "Swamp"},
    {0x32966, "Treehouse"},
    {0x334D5, "Blue Right Far 2"},
    {0x334D8, "RGB Light Control"},
    {0x334DB, "Outer Door Control"},
    {0x334DC, "Inner Door Control"},
    {0x334E1, "Secret Door Control"},
    {0x335AB, "In Elevator Control"},
    {0x335AC, "Upper Elevator Control"},
    {0x33638, "Lightswitch"},
    {0x3369D, "Lower Elevator Control"},
    {0x337FA, "Shortcut"},
    {0x33961, "Right Pillar 4"},
    {0x339BB, "Left Pillar 4"},
    {0x33AB2, "Corona Exit"},
    {0x33AF5, "Blue 1"},
    {0x33AF7, "Blue 2"},
    {0x34BC5, "Open Ultraviolet"},
    {0x34BC6, "Close Ultraviolet"},
    {0x34C7F, "Boat Speed"},
    {0x34D96, "Boat Map"},
    {0x38663, "Shortcut Snipe"},
    {0x386FA, "Avoid 1"},
    {0x3C113, "Open Door"},
    {0x3C114, "Open Door"},
    {0x3C124, "Erasers and Stars 7"},
    {0x3C125, "Control Room 2"},
    {0x3C12B, "Discard"},
    {0x3C12D, "Upper Row 6"},
    {0x3D9A6, "Close Door"},
    {0x3D9A7, "Close Door"},
    {0x3D9A8, "Activate Elevator"},
    {0x3D9A9, "Launch Elevator"},
    {0x3D9AA, "Activate Elevator"},
  };
  Dictionary<int, string> macroSplits = new Dictionary<int, string>{
    {0x032F6, "Town"},
    {0x0354A, "Theater"},
    {0x03609, "Desert"},
    {0x0360E, "Symmetry"},
    {0x0360F, "Keep"},
    {0x03614, "Treehouse"},
    {0x03616, "Swamp"},
    {0x03617, "Jungle"},
    {0x0362A, "Tutorial"},
    {0x09E7C, "Mountain Floor 1"},
    {0x09EEC, "Mountain Floor 2"},
    {0x0A07A, "Bunker Elevator"},
    {0x0A333, "Under the Mountain"},
    {0x17CA5, "Monastery"},
    {0x19651, "Shadows"},
    {0x1C31A, "Challenge"},
    {0x22107, "523 +135 +6"},
    {0x33A21, "Eclipse"},
    {0x34D97, "Boat to Swamp"},
    {0x3D9AA, "Wonkavator"},
  };

  string splitsStart = @"<?xml version=""1.0"" encoding=""UTF-8""?>
<Run version=""1.7.0"">
  <GameIcon><![CDATA[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]]></GameIcon>
  <GameName>The Witness</GameName>
  <CategoryName />
  <Metadata>
    <Run id="""" />
    <Platform usesEmulator=""False""></Platform>
    <Region>
    </Region>
    <Variables />
  </Metadata>
  <Offset>00:00:00</Offset>
  <AttemptCount>0</AttemptCount>
  <AttemptHistory />
  <Segments>";
  string splits = "";
  string splitsEnd = @"  </Segments>
  <AutoSplitterSettings>
    <CustomSettings>
      <Setting id=""Split on environmental patterns"" type=""bool"">True</Setting>
      <Setting id=""Split on all panels (solving and non-solving)"" type=""bool"">True</Setting>
    </CustomSettings>
  </AutoSplitterSettings>
</Run>";

  var panelCounts = new Dictionary<string, int>();
  vars.epStates = new Dictionary<int, MemoryWatcher<int>>();
  foreach (var pair in epNames) {
    int id = pair.Key;
    vars.epStates[id] = new MemoryWatcher<int>(createPointer(id, epOffset));
    vars.epStates[id].Update(game);
  }

  System.IO.Directory.CreateDirectory(vars.OUTPUT_FOLDER);

  vars.onPanelExited = (Func<int, int, bool>)((int panel, int state) => {
    var copyFrom = vars.INPUT_FOLDER + "/0x";
    var copyTo = vars.OUTPUT_FOLDER + "/";
    string name = "ERROR";
    if (panelNames.ContainsKey(panel-1)) {
      name = panelNames[panel-1];
    } else if (epNames.ContainsKey(panel)) {
      name = epNames[panel] + " EP";
    } else if (audioLogNames.ContainsKey(panel-1)) {
      name = audioLogNames[panel-1] + " Audio Log";
    }
    string suffix = "";
    int length = createPointer(panel, segmentOffset).Deref<int>(game);
    int otherLength;
    double target;
    double curr;

    switch(panel) {
    case 0x0060A: // Swamp Sliding Bridge Control
    case 0x18489: // Swamp Sliding Bridge Control (Underwater)
      target = createPointer(0x0061B, doorTarget).Deref<float>(game);
      if (target == 0) {
        suffix = "_l";
        name += " Left";
      } else if (target == 1) {
        suffix = "_r";
        name += " Right";
      }
      break;
    case 0x00816: // Theater Control
      if (length == 13) {
        panel = 0x03554;
        name = "Tutorial Video";
      } else if (length == 11) {
        panel = 0x03553;
        name = "Desert Video";
      } else if (length == 27) {
        panel = 0x0354F;
        name = "Jungle Video";
      } else if (length == 25) {
        panel = 0x0354A;
        name = "Challenge Video";
      } else if (length == 22) {
        panel = 0x03550;
        name = "Shipwreck Video";
      } else if (length == 18) {
        panel = 0x03546;
        name = "Mountain Video";
      }
      break;
    case 0x019E8: // Keep Hedges 3
      if (vars.playerX.Current > 40.0) suffix = "_far";
      break;
    case 0x01A10: // Keep Hedges 4
      if (vars.playerX.Current > 44.0) suffix = "_far";
      break;
    case 0x01A55: // Glass Factory Entry
      if (vars.playerX.Current < -180.0) suffix = "_far";
      break;
    case 0x01BEA: // Keep Purple
      if (length == 19) suffix = "_ep"; // EP solution
      if (length == 0) suffix = "_ep_half"; // EP first half, triggered by purple reset
      break;
    case 0x01CD4: // Keep Green
      if (splits.Contains("Green Reset")) suffix = "_ep"; // EP solution
      break;
    case 0x01D40: // Keep Blue
      if (vars.playerX.Current > 45.0) suffix = "_ep1"; // Ending on the left side
      if (vars.playerX.Current < 45.0) suffix = "_ep2"; // Ending on the right side
      break;
    case 0x033EB: // Keep Yellow
      if (length == 26) suffix = "_ep"; // EP solution
      break;
    case 0x0354A: // Theater Challenge Vault
      suffix = "_eclipse";
      break;
    case 0x0354F: // Theater Jungle Vault
      suffix = "_church";
      break;
    case 0x03554: // Theater Tutorial Vault
      if (length <= 8) suffix = "_window_and_door";
      if (length > 8) suffix = "_catwalk";
      break;
    case 0x0361C: // Keep Tower Shortcut
      if (vars.playerY.Current > 180.0) suffix = "_far";
      break;
    case 0x0362A: // Tutorial gate
      if (length == 17) panel = 0x0362A;
      if (length == 29) panel = 0x03506;
      break;
    case 0x03676: // Mill Lift Control (Room)
    case 0x0367A: // Mill Lift Control (Ground)
      target = createPointer(0x21BB, doorTarget).Deref<float>(game);
      if (target == 0) suffix = "_d";
      if (target == 1) suffix = "_u";
      break;
    case 0x03677: // Mill Ramp Control (Room)
    case 0x03679: // Mill Ramp Control (Ground)
      target = createPointer(0x383A, doorTarget).Deref<float>(game);
      if (target == 0) suffix = "_d";
      if (target == 1) suffix = "_u";
      break;
    case 0x03678: // Mill Stairs Control
      if (vars.playerZ.Current < 4.0) {
        suffix += "_far";
        name = "Stairs Snipe";
      }
      break;
    case 0x03800: // Treehouse Drawbridge Control
      if (length == 20) suffix = "_d";
      if (length == 10) suffix = "_u";
      break;
    case 0x03853: // Boathouse Ramp Angle Control
      target = createPointer(0x17C6B, doorTarget).Deref<float>(game);
      if (target == 0) suffix = "_d";
      if (target == 1) suffix = "_u";
      break;
    case 0x03859: // Boathouse Ramp Position Control
      target = createPointer(0x17F03, doorTarget).Deref<float>(game);
      target = Math.Round(target, 1);
      if (target == 0.0) suffix = "_6";
      if (target == 0.2) suffix = "_5";
      if (target == 0.4) suffix = "_4";
      if (target == 0.6) suffix = "_3";
      if (target == 0.8) suffix = "_2";
      if (target == 1.0) suffix = "_1";
      break;
    case 0x03C09: // RGB Stars
    case 0x03C0D: // RGB Stones
      suffix = vars.lightColor;
      break;
    case 0x079E0: // Town Triple
      if (length == 17) suffix = "_1";
      if (length == 19) suffix = "_2";
      if (length == 15) suffix = "_3";
      break;
    case 0x09D9C: // Monastery Bonzai
      double dx = vars.playerX.Current - 19.355;
      double dy = vars.playerY.Current + 30.178;
      double ang = Math.Atan(dx / dy) + (dy > 0 ? 3*Math.PI/2 : Math.PI/2);
      if (0.9 < ang && ang < 2.6) suffix = "_back";
      if (5.7 < ang || ang < 0.9) suffix = "_left";
      if (4.1 < ang && ang < 5.7) suffix = "_front";
      if (2.6 < ang && ang < 4.1) suffix = "_right";
      break;
    case 0x09E3A: // Mountain Purple Pathway
      if (length == 29 || length == 31 || length == 33 || length == 35) suffix = "_1";
      if (length == 23) suffix = "_2";
      break;
    case 0x09E87: // Mountain Blue Pathway
      otherLength = createPointer(0x09ED9, segmentOffset).Deref<int>(game);
      if (length == 18 && otherLength == 0) suffix = "_1";
      if (length == 8 && otherLength == 10) suffix = "_2";
      if (length == 11 && otherLength == 10) suffix = "_3";
      if (splits.Contains("Mountain Elevator Up")) suffix = "_4"; // After elevator
      if (length == 4 && otherLength == 14) suffix = "_5";
      break;
    case 0x09ED9: // Mountain Orange Pathway
      otherLength = createPointer(0x09E87, segmentOffset).Deref<int>(game);
      if (length == 10 && otherLength == 18) suffix = "_1";
      if (length == 10 && otherLength == 8) suffix = "_2";
      if (length == 14 && otherLength == 8) suffix = "_3";
      if (length == 15 && otherLength == 4) suffix = "_4";
      break;
    case 0x09EEC: // Mountain Elevator
      target = createPointer(0x09EED, doorTarget).Deref<float>(game);
      if (target == 0) {
        suffix = "_u";
        name += " Up";
      }
      if (target == 1) {
        suffix = "_d";
        name += " Down";
      }
      break;
    case 0x09F80: // Mountaintop Box
      if (length == 14) {
        suffix = "_7";
        name = "7 " + name;
      } else if (length == 23) {
        suffix = "_11";
        name = "11 " + name;
      }
      break;
    case 0x09F99: // Desert Laser Redirect
      target = createPointer(0x09FA3, doorTarget).Deref<float>(game);
      target = Math.Round(target, 3);
      target = (target + 1.0) % 1.0;
      if (target == 0.750) suffix = "_2";
      if (target == 0.583) suffix = "_1";
      if (vars.playerY.Current > -20.0) suffix += "_far";
      break;
    case 0x09FCD:
    case 0x09FCF:
    case 0x09FD0:
    case 0x09FD1:
    case 0x09FD2:
    case 0x09FD3:
      // Mountain Multipanel
      if (vars.multiCount == 0) panel = 0x09FCD;
      if (vars.multiCount == 1) panel = 0x09FCF;
      if (vars.multiCount == 2) panel = 0x09FD0;
      if (vars.multiCount == 3) panel = 0x09FD1;
      if (vars.multiCount == 4) panel = 0x09FD2;
      if (vars.multiCount == 5) panel = 0x09FD3;
      vars.multiCount++;
      name += ' ' + vars.multiCount.ToString();
      break;
    case 0x0A07A: // Bunker Elevator
      if (state == 2) {
        suffix = "_bad";
      } else {
        if (length == 10) suffix = "_1";
        // if (length == 16) suffix = "_2";
        if (length == 12) suffix = "_3";
        if (length == 18) suffix = "_4";
        if (length == 16) suffix = "_5";
        if (length == 26) suffix = "_6";
      }
      break;
    case 0x0A3B6: // Tutorial Back Left
      if (length == 15) suffix = "_1";
      if (length == 25) suffix = "";
      break;
    case 0x0C374: // Tutorial Flowers
      if (state == 1) suffix = "";
      if (state == 2) suffix = "_ep";
      break;
    case 0x17C0B: // Swamp Island Control
      if (vars.swampIslandCount == 0) suffix = "_1";
      if (vars.swampIslandCount == 1) suffix = "_2";
      vars.swampIslandCount++;
      break;
    case 0x17C35: // Mountaintop Crazyhorse
      if (length == 18) suffix = "_l_r";
      if (length == 22 || length == 20) suffix = "_r_l";
      if (length == 19 || length == 21 || length == 23 || length == 25) suffix = "_b_f";
      break;
    case 0x17CE4: // Right Orange Bridge Pivot 1
      target = createPointer(0x0362D, bridgeTargetA).Deref<float>(game);
      if (target == 1) {
        suffix = "_l";
        name += " Left";
      } else if (target == 0) {
        suffix = "_f";
        name += " Straight";
      } else if (target == -1) {
        suffix = "_r";
        name += " Right";
      }
      if (vars.playerX.Current < 110) suffix += "_far";
      break;
    case 0x17CF1: // Mill Discard
      if (vars.playerX.Current > -50) suffix = "_far";
      break;
    case 0x17D29: // Shipwreck Discard
      if (vars.playerY.Current > 210) suffix = "_far";
      break;
    case 0x17DB8: // Right Orange Bridge Pivot 2
      target = createPointer(0x0362D, bridgeTargetB).Deref<float>(game);
      if (target == 1) {
        suffix = "_l";
        name += " Left";
      } else if (target == 0) {
        suffix = "_f";
        name += " Straight";
      } else if (target == -1) {
        suffix = "_r";
        name += " Right";
      }
      break;
    case 0x17DD2: // Left Orange Bridge Pivot
      target = createPointer(0x03782, bridgeTargetA).Deref<float>(game);
      if (target == 1) {
        suffix = "_l";
        name += " Left";
      } else if (target == 0) {
        suffix = "_f";
        name += " Straight";
      } else if (target == -1) {
        suffix = "_r";
        name += " Right";
      }
      break;
    case 0x17E2C: // Swamp Floodgate Control
      target = createPointer(0x17E75, doorTarget).Deref<float>(game); // Near Bridge
      if (target == 1) {
        suffix = "_r";
      } else {
        target = createPointer(0x1802D, doorTarget).Deref<float>(game); // Far Bridge
        if (target == 1) suffix = "_l";
        if (target == 0) suffix = "_b";
      }
      break;
    case 0x17E53: // Green Bridge Pivot
      target = createPointer(0x17E33, bridgeTargetA).Deref<float>(game);
      if (target == 1) {
        suffix = "_l";
        name += " Left";
      } else if (target == 0) {
        suffix = "_f";
        name += " Straight";
      } else if (target == -1) {
        suffix = "_r";
        name += " Right";
      }
      break;
    case 0x17FA1: // Treehouse Laser Discard
      if (vars.playerX.Current > 115) suffix = "_far"; // All Discarded Panels snipe
      else if (vars.playerX.Current > 105) suffix = "_near"; // 100% snipe
      break;
    case 0x17FAA: // Treehouse Green Bridge Discard
      if (vars.playerX.Current < 125) suffix = "_far";
      break;
    case 0x181F6: // Swamp Rotating Bridge Control
      curr = createPointer(0x005A3, doorCurrent).Deref<float>(game);
      target = createPointer(0x005A3, doorTarget).Deref<float>(game);
      string prefix = "";
      if (curr > target) {
        suffix = "_cw";
        prefix = "CW";
      } else if (curr < target) {
        suffix = "_ccw";
        prefix = "CCW";
      }
      if (curr == target) return false;
      target = (target + 1.0) % 1.0;
      if (target == 0) {
        suffix = "_r_b" + suffix;
        prefix += " Red/Black";
      } else if (target == 0.25) {
        suffix = "_p_r" + suffix;
        prefix += " Purple/Red";
      } else if (target == 0.5) {
        suffix = "_u_p" + suffix;
        prefix += " Blue/Purple";
      } else if (target == 0.75) {
        suffix = "_b_u" + suffix;
        prefix += " Black/Blue";
      }
      name = prefix + " " + name;
      break;
    case 0x275FB: // Boathouse Claw Control
      target = createPointer(0x2762D, doorTarget).Deref<float>(game);
      target = Math.Round(target, 1);
      if (target == 0.0) suffix = "_1";
      if (target == 0.2) suffix = "_2";
      if (target == 0.4) suffix = "_3";
      if (target == 0.6) suffix = "_4";
      if (target == 0.8) suffix = "_5";
      if (target == 1.0) suffix = "_6";
      break;
    case 0x2896B: // Town Bridge Control
      if (length == 11) suffix = "_0";
      if (length == 16) suffix = "_1";
      if (length == 20) suffix = "_2";
      break;
    case 0x334D9: // Town RGB Control
      if (length == 15) {
        suffix = "_g";
        name += " Green";
        vars.lightColor = "_g";
      } else if (length == 11) {
        suffix = "_r";
        name += " Red";
        vars.lightColor = "_r";
      }
      break;
    case 0x335AC: // UTM In-Elevator Control
    case 0x335AD: // UTM Upper Elevator Control
    case 0x3369E: // UTM Lower Elevator Control
      if (vars.playerZ.Current > 0.0f) {
        suffix = "_far";
      } else {
        target = createPointer(0x38ACC, doorTarget).Deref<float>(game);
        if (target == 0) suffix = "_u";
        if (target == 1) suffix = "_d";
      }
      break;
    case 0x34D97: // Boat Map
      Thread.Sleep(2000); // Wait 2s for the boat to stop
      length = createPointer(0x31, boatLength).Deref<int>(game);
      int source = 0;
      for (int i=0; i<length; i++) {
        var waypoint = (new DeepPointer(basePointer, 0x18, 0x30*8, waypointOffset, i*4)).Deref<int>(game);
        if (waypoint != -1) {
          source = waypoint;
          break;
        }
      }
      if ((338 <= source && source <= 342) ||
          (117 <= source && source <= 123)) {
        for (int i=0; i<length; i++) {
          var waypoint = (new DeepPointer(basePointer, 0x18, 0x30*8, waypointOffset, i*4)).Deref<int>(game);
          if (waypoint == 150) {
            suffix = "_quarry_swamp_100";
            break;
          }
          if (waypoint == 250) {
            suffix = "_quarry_swamp";
            break;
          }
        }
        name = "Boat to Swamp";
      }
      if ((154 <= source && source <= 167) ||
          (272 <= source && source <= 277)) {
        suffix = "_sgEP_quarry";
        name = "Boat to Quarry";
      }
      if (120 <= source && source <= 130) {
        suffix = "_suEP_swamp";
        name = "Boat to Swamp";
      }
      if ((377 <= source && source <= 381) ||
          (168 <= source && source <= 171)) {
        if (length < 20) {
          suffix = "_swamp_QS";
          name = "Quickstop at Treehouse";
        } else { // Couch EP
          suffix = "_treehouse_quarry";
          name = "Boat to Quarry";
        }
      }
      if ((192 <= source && source <= 195) ||
          (365 <= source && source <= 369)) {
        suffix = "_swamp_jungle";
        name = "Boat to Jungle";
      }
      // Enter post-game
      if (358 <= source && source <= 362) {
        suffix = "_jungle_swamp";
        name = "Boat to Swamp";
      }
      if (100 <= source && source <= 110) {
        suffix = "_ymEP_symm";
        name = "Boat to Symmetry";
      }
      if (8 <= source && source <= 16) {
        suffix = "_trEP_jungle";
        name = "Boat to Jungle";
      }
      if ((328 <= source && source <= 337) ||
          (390 <= source && source <= 394)) {
        suffix = "_lsEP_quarry";
        name = "Boat to Quarry";
      }
      if (82 <= source && source <= 94) {
        suffix = "_dEP_jungle";
        name = "Boat to Jungle";
      }
      break;
    case 0x34C80: // Boat Speed
      return false;
    case 0x38664: // Boathouse Shortcut (snipe)
      if (Math.Round(vars.playerX.Current, 1) == -61.8
       && Math.Round(vars.playerY.Current, 1) == 159.8) {
        suffix = "_far";
      }
      break;
    case 0x3C114: // Open Wonkavator Doors (L)
    case 0x3C115: // Open Wonkavator Doors (R)
      if (vars.playerX.Current > 215.0) suffix = "_far";
      break;
    case 0x3D9A7: // Close Wonkavator Doors (L)
    case 0x3D9A8: // Close Wonkavator Doors (R)
      if (vars.playerX.Current > 215.0) suffix = "_far";
      break;
    }

    if (macroSplits.ContainsKey(panel)) {
      name = "{" + macroSplits[panel] + "}" + name;
      macroSplits.Remove(panel);
    } else if (panel == 0x34D97 && (suffix == "_quarry_swamp" || suffix == "_quarry_swamp_100")) {
      name = "{Boat to Swamp}";
      if (macroSplits.ContainsKey(panel)) macroSplits.Remove(panel);
    } else {
      name = "-" + name;
    }
    if (panelCounts.ContainsKey(panel + "_" + name)) {
      panelCounts[panel + "_" + name]++;
      name += " (" + panelCounts[panel + "_" + name] + ")";
    } else {
      panelCounts[panel + "_" + name] = 1;
    }
    if (state != 2) {
      splits += "<Segment><Name>" + name + "</Name><SplitTimes /><BestSegmentTime /><SegmentHistory /></Segment>\r\n";
      System.IO.File.WriteAllText(copyTo + "_splits.lss", splitsStart + splits + splitsEnd);
    }

    print((panel-1).ToString("X").PadLeft(5, '0') + suffix + " " + name);

    copyFrom += (panel-1).ToString("X").PadLeft(5, '0') + suffix;
    copyTo += vars.nextId.ToString().PadLeft(5, '0');
    try {
      File.Copy(copyFrom + ".png", copyTo + ".png", true);
    } catch (System.IO.FileNotFoundException) {
      print("File not found: " + copyFrom);
      File.Create(copyTo + "_0x" + (panel-1).ToString("X").PadLeft(5, '0') + ".png");
    }
    vars.nextId++;

    // Keep Purple Reset -> Add first half of solve
    if (panel == 0x0A3BA) vars.onPanelExited(0x01BEA, 1);

    return true;
  });

  vars.initDone = true;
}

update {
  if (!vars.initDone) return;
  // Don't run if the game is loading / paused
  vars.time.Update(game);
  if (vars.time.Current <= vars.time.Old) return false;
  vars.puzzle.Update(game);
  vars.playerX.Update(game);
  vars.playerY.Update(game);
  vars.playerZ.Update(game);
  vars.audioLog.Update(game);
  vars.keepWatchers.UpdateAll(game);

  // Started a new panel
  if (vars.puzzle.Old == 0 && vars.puzzle.Current != 0) {
    vars.setActivePanel(vars.puzzle.Current);
    return;
  }
  // Exited a panel (or EP)
  if (vars.puzzle.Old != 0 && vars.puzzle.Current == 0) {
    foreach (var pair in vars.epStates) {
      if (pair.Value.Current == 0) {
        pair.Value.Update(game);
        if (pair.Value.Current == 1) {
          vars.onPanelExited(pair.Key, 1);
          return;
        }
      }
    }
  }

  for (int i=0; i<vars.keepWatchers.Count; i++) {
    var panel = vars.keepWatchers[i];
    if (panel.Old == 0 && panel.Current == 1) {
      vars.onPanelExited(vars.keepWalkOns[i], 1);
      return;
    }
  }

  if (vars.audioLog.Old == 0 && vars.audioLog.Current != 0) {
    if (!vars.audioLogs.Contains(vars.audioLog.Current)) {
      vars.onPanelExited(vars.audioLog.Current, 1);
      vars.audioLogs.Add(vars.audioLog.Current);
    }
  }

  if (vars.activePanel == 0) return;
  // States:
  // 0: Unsolved
  // 1: Solved correctly
  // 2: Solved incorrectly
  // 3: Exited
  // 4: Pending negation
  // 5: Floor Meta Subpanel error
  int state = vars.activePanelPointer.Deref<int>(game);
  if (state == 0 || state == 4) return;
  if (state == 1) {
    vars.onPanelExited(vars.activePanel, state);
  }
  // Theater panel + Challenge start
  if (state == 3 && (vars.activePanel == 0x00816 || vars.activePanel == 0x0A333)) {
    vars.onPanelExited(vars.activePanel, state);
  }
  // Bunker Elevator + Tutorial Flowers
  if (state == 2 && (vars.activePanel == 0x0A07A || vars.activePanel == 0x0C374)) {
    vars.onPanelExited(vars.activePanel, state);
  }

  vars.activePanel = 0;
  vars.activePanelPointer = null;
}
