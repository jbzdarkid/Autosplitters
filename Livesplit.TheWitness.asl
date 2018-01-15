state("witness64_d3d11", "newer") {
  double gameTime   : 0x62A020, 0x1B8;
  int currentPuzzle : 0x62A450, 0x10, 0xAC;
  bool gameLoading  : 0x62AD40;
  int gamePaused    : 0x62CFF0;
  int activeItem    : 0x62CEAC;
  bool solveMode    : 0x0;
}

state("witness64_d3d11", "current") {
  double gameTime   : 0x5D1188, 0x1C8;
  int currentPuzzle : 0x5D14A0, 0x10, 0x9C;
  bool gameLoading  : 0x5D1C60;
  int gamePaused    : 0x5D3EF4;
  int activeItem    : 0x5D411C;
  bool solveMode    : 0x5D418E;
}

state("witness64_d3d11", "older") {
  double gameTime   : 0x5AC858, 0x1C8;
  int currentPuzzle : 0x5ACB58, 0x10, 0x9C;
  bool gameLoading  : 0x5AD280;
  int gamePaused    : 0x5AF148;
  int activeItem    : 0x5AF42C;
  bool solveMode    : 0x5AF49E;
}

// TODO: Remove the grossness with i%4, maybe use current puzzle?
// TODO: Fix challenge garbage

startup {
  settings.Add("———General———", false);
  settings.Add("Split on lasers", true);
  settings.Add("Split on panels", false);
  settings.Add("Split on environmental puzzles", false);
  settings.Add("Split on non-counted panels", false);
  settings.Add("Split on audio logs", false);
  settings.Add("———Panels———", false);
  settings.Add("Split on first panel", false);
  settings.Add("Split on tutorial door", true);
  settings.Add("Split on starting the boat", false);
  settings.Add("Split on greenhouse elevator", false);
  settings.Add("Don't split on greenhouse laser", false);
  settings.Add("Split on mountain elevator", false);
  settings.Add("Split on challenge start", false);
  settings.Add("Split on left challenge pillar", false);
  settings.Add("Split on right challenge pillar", false);
  settings.Add("Split on final elevator", true);
  settings.Add("———Environmentals———", false);
  settings.Add("Split on eclipse environmental start", true);
  settings.Add("Split on eclipse environmental end", true);
  settings.Add("Split on thundercloud environmental", true);
}

init {
  int baseOffset = 0x0;
  if (modules.First().ModuleMemorySize == 74444800) {
    version = "newer";
    baseOffset = 0x62A020;
  }
  if (modules.First().ModuleMemorySize == 73990144) {
    version = "current";
    baseOffset = 0x5D1180;
  }
  if (modules.First().ModuleMemorySize == 76779520) {
    version = "older";
    baseOffset = 0x5AC850;
  }

  vars.startOffset = 0.0;
  vars.frame = 0;

  List<int> obelisks = new List<int> {
    0x00097, // Treehouse
    0x00263, // Monastery
    0x00359, // Desert
    0x00367, // Mountain
    0x0A16C, // Town
    0x22073, // Shadows
  };
  vars.obeliskWatchers = new List<MemoryWatcher>();
  foreach (int obelisk in obelisks) {
    vars.obeliskWatchers.Add(new MemoryWatcher<int>(new DeepPointer(baseOffset, 0x18, obelisk*8, 0xE8)));
  }

  List<int> lasers = new List<int>{
    0x032F5, // Town
    0x03608, // Desert
    0x0360D, // Symmetry
    0x0360E, // Keep
    0x03612, // Quarry
    0x03613, // Treehouse
    0x03615, // Swamp
    0x03616, // Jungle
    0x09DE0, // Bunker
    0x17CA4, // Monastery
    0x19650, // Shadows
  };

  // Panels which are solved multiple times in a normal run
  List<int> multiPanels = new List<int>{
    0x00609, 0x00815, 0x01BE9, 0x01D3F, 0x03620, 0x03629, 0x03675, 0x03852,
    0x03858, 0x079DF, 0x09D9B, 0x09E39, 0x09E86, 0x09ED8, 0x09EEB, 0x09F7F,
    0x09F98, 0x0A079, 0x0A3B5, 0x17C0A, 0x17C34, 0x17CE3, 0x17DB7, 0x17DD1,
    0x17E2B, 0x181F5, 0x2896A, 0x334D8, 0x335AB, 0x34D96,
  };

  // Triple panels in Challenge - Solves awarded when completing 
  vars.triplePanels = new List<int>{
    0x00C80, 0x00CA1, 0x00CB9, 0x00C22, 0x00C59, 0x00C68
  };
  
  /* Removed:
    0x03505 - Tutorial Door Close
    0x03676, 0x03678, 0x3679 - Extra Mill Ramp controls
    0x34c7f - Boat Speed Panel
    0x18488 - Underwater Swamp Bridge Control
    0x17E07 - Second Swamp 3x3 Control
    0x04CB3, 0x04CB5, 0x04CB6 - Challenge Timer Panels
  */
  List<int> panels = new List<int>{
    0x00001, 0x00002, 0x00004, 0x00005, 0x00006, 0x00007, 0x00008, 0x00009,
    0x0000a, 0x0001b, 0x0001c, 0x0001d, 0x0001e, 0x0001f, 0x00020, 0x00021,
    0x00022, 0x00023, 0x00024, 0x00025, 0x00026, 0x00027, 0x00028, 0x00029,
    0x00037, 0x00038, 0x0003b, 0x00055, 0x00059, 0x0005c, 0x0005d, 0x0005e,
    0x0005f, 0x00060, 0x00061, 0x00062, 0x00064, 0x00065, 0x0006a, 0x0006b,
    0x0006c, 0x0006d, 0x0006f, 0x00070, 0x00071, 0x00072, 0x00073, 0x00075,
    0x00076, 0x00077, 0x00079, 0x0007c, 0x0007e, 0x00081, 0x00082, 0x00083,
    0x00084, 0x00086, 0x00087, 0x00089, 0x0008a, 0x0008b, 0x0008c, 0x0008d,
    0x0008f, 0x000b0, 0x00139, 0x00143, 0x00182, 0x00190, 0x00262, 0x0026d,
    0x0026e, 0x0026f, 0x00290, 0x00293, 0x00295, 0x002a6, 0x002c2, 0x002c4,
    0x002c6, 0x002c7, 0x00390, 0x003b2, 0x003e8, 0x00422, 0x0042d, 0x00469,
    0x00472, 0x00474, 0x0048f, 0x0051f, 0x00524, 0x00553, 0x00557, 0x00558,
    0x00567, 0x0056e, 0x0056f, 0x00596, 0x005f1, 0x00609, 0x00620, 0x00698,
    0x006e3, 0x006fe, 0x0070e, 0x0070f, 0x00767, 0x0078d, 0x0087d, 0x0088e,
    0x008b8, 0x008bb, 0x00973, 0x0097b, 0x0097d, 0x0097e, 0x0097f, 0x00982,
    0x00983, 0x00984, 0x00985, 0x00986, 0x00987, 0x0098f, 0x00990, 0x00994,
    0x00995, 0x00996, 0x00998, 0x00999, 0x0099d, 0x009a0, 0x009a1, 0x009a4,
    0x009a6, 0x009ab, 0x009ad, 0x009ae, 0x009af, 0x009b8, 0x009f5, 0x00a15,
    0x00a1e, 0x00a52, 0x00a57, 0x00a5b, 0x00a61, 0x00a64, 0x00a68, 0x00a72,
    0x00afb, 0x00b10, 0x00b53, 0x00b71, 0x00b8d, 0x00baf, 0x00bf3, 0x00c09,
    0x00c2e, 0x00c3f, 0x00c41, 0x00c72, 0x00C80, 0x00CA1, 0x00CB9, 0x00C22,
    0x00C59, 0x00C68, 0x00c92, 0x00cd4, 0x00cdb, 0x00e0c, 0x00e3a, 0x00ff8,
    0x010ca, 0x0117a, 0x01205, 0x0129d, 0x012c9, 0x012d7, 0x013e6, 0x0146c,
    0x01489, 0x0148a, 0x014b2, 0x014d1, 0x014d2, 0x014d4, 0x014d9, 0x014e7,
    0x014e8, 0x014e9, 0x018a0, 0x018af, 0x01983, 0x01987, 0x019dc, 0x019e7,
    0x01a0d, 0x01a0f, 0x01a31, 0x01a54, 0x01be9, 0x01cd3, 0x01d3f, 0x01e59,
    0x01e5a, 0x021ae, 0x021af, 0x021b0, 0x021b3, 0x021b4, 0x021b5, 0x021b6,
    0x021b7, 0x021bb, 0x021d5, 0x021d7, 0x02886, 0x0288c, 0x032f7, 0x032ff,
    0x03317, 0x033d4, 0x033ea, 0x0343a, 0x034d4, 0x034e3, 0x034e4, 0x034ec,
    0x034f4, 0x03545, 0x03549, 0x0354e, 0x0354f, 0x03552, 0x03553, 0x0360e,
    0x03612, 0x03629, 0x03675, 0x03677, 0x0367c, 0x03686, 0x037ff, 0x0383a,
    0x0383d, 0x0383f, 0x03852, 0x03858, 0x03859, 0x039b4, 0x03c08, 0x03c0c,
    0x04ca4, 0x04d18, 0x079df, 0x09d9b, 0x09d9f, 0x09da1, 0x09da2, 0x09da6,
    0x09daf, 0x09db1, 0x09db3, 0x09db4, 0x09db5, 0x09dd5, 0x09e39, 0x09e56,
    0x09e57, 0x09e5a, 0x09e69, 0x09e6b, 0x09e6c, 0x09e6f, 0x09e71, 0x09e72,
    0x09e73, 0x09e75, 0x09e78, 0x09e79, 0x09e7a, 0x09e7b, 0x09e85, 0x09e86,
    0x09ead, 0x09eaf, 0x09ed8, 0x09eeb, 0x09eff, 0x09f01, 0x09f6e, 0x09f7d,
    0x09f7f, 0x09f82, 0x09f8e, 0x09f92, 0x09f94, 0x09fc1, 0x09fcc, 0x09fce,
    0x09fcf, 0x09fd0, 0x09fd1, 0x09fd2, 0x09fd3, 0x09fd4, 0x09fd6, 0x09fd7,
    0x09fd8, 0x09fda, 0x09fdc, 0x09ff7, 0x09ff8, 0x09fff, 0x0a010, 0x0a01b,
    0x0a01f, 0x0a02d, 0x0a036, 0x0a049, 0x0a053, 0x0a079, 0x0a0c8, 0x0a15c,
    0x0a15f, 0x0a168, 0x0a16b, 0x0a16e, 0x0a171, 0x0a182, 0x0a2ce, 0x0a2d7,
    0x0a2dd, 0x0a2ea, 0x0a3b2, 0x0a332, 0x0a3b5, 0x0a3cb, 0x0a3cc, 0x0a3d0,
    0x0a8dc, 0x0a8e0, 0x0ac74, 0x0ac7a, 0x0c335, 0x0c373, 0x0cc7b, 0x15add,
    0x17bdf, 0x17c02, 0x17c05, 0x17c09, 0x17c0a, 0x17c0d, 0x17c0e, 0x17c2e,
    0x17c31, 0x17c34, 0x17c42, 0x17c71, 0x17caa, 0x17cc4, 0x17ce3, 0x17ce4,
    0x17ce7, 0x17cf0, 0x17cf2, 0x17cf7, 0x17cfb, 0x17d01, 0x17d02, 0x17d27,
    0x17d28, 0x17d2d, 0x17d6c, 0x17d72, 0x17d74, 0x17d88, 0x17d8c, 0x17d8e,
    0x17d8f, 0x17d91, 0x17d97, 0x17d99, 0x17d9b, 0x17d9c, 0x17d9e, 0x17da2,
    0x17daa, 0x17dac, 0x17dae, 0x17db0, 0x17db1, 0x17db2, 0x17db3, 0x17db4,
    0x17db5, 0x17db6, 0x17db7, 0x17db8, 0x17db9, 0x17dc0, 0x17dc2, 0x17dc4,
    0x17dc6, 0x17dc7, 0x17dc8, 0x17dca, 0x17dcc, 0x17dcd, 0x17dd1, 0x17dd7,
    0x17dd9, 0x17ddb, 0x17ddc, 0x17dde, 0x17de3, 0x17dec, 0x17e2b, 0x17e3c,
    0x17e4d, 0x17e4f, 0x17e52, 0x17e5b, 0x17e5f, 0x17e61, 0x17e63, 0x17e67,
    0x17eca, 0x17f5f, 0x17f89, 0x17f93, 0x17f9b, 0x17fa0, 0x17fa2, 0x17fa9,
    0x17fb9, 0x18076, 0x181a9, 0x181ab, 0x181f5, 0x18313, 0x18590, 0x193a6,
    0x193a7, 0x193aa, 0x193ab, 0x19650, 0x196e2, 0x196f8, 0x1972a, 0x1972f,
    0x19771, 0x19797, 0x1979a, 0x197e0, 0x197e5, 0x197e8, 0x19806, 0x19809,
    0x198b5, 0x198bd, 0x198bf, 0x1c319, 0x1c31a, 0x1c33f, 0x1c349, 0x275fa,
    0x288aa, 0x288ea, 0x288fc, 0x28938, 0x2896a, 0x28998, 0x2899c, 0x289e7,
    0x28a0d, 0x28a33, 0x28a69, 0x28a79, 0x28abf, 0x28ac0, 0x28ac1, 0x28ac7,
    0x28ac8, 0x28aca, 0x28acb, 0x28acc, 0x28ad9, 0x28ae3, 0x28b39, 0x32962,
    0x32966, 0x334d5, 0x334d8, 0x335ab, 0x335ac, 0x3369d, 0x33961, 0x339bb,
    0x33ab2, 0x33af5, 0x33af7, 0x34d96, 0x386fa, 0x3c124, 0x3c125, 0x3c12b,
    0x3c12d, 0x3d9a9
  };

  List<int> nonPanels = new List<int>{
    0x0339E, 0x03481, 0x03535, 0x03542, 0x0356B, 0x0361B, 0x03702, 0x03713,
    0x09DB8, 0x09E49, 0x09F86, 0x09F98, 0x09FA0, 0x09FAA, 0x0A015, 0x0A054,
    0x0A099, 0x0A249, 0x0A3A8, 0x0A3B9, 0x0A3BB, 0x0A3AD, 0x0C339, 0x17C95,
    0x17CA6, 0x17CAB, 0x17CAC, 0x17CC8, 0x17CDF, 0x1831B, 0x1831C, 0x2700B,
    0x275ED, 0x27732, 0x2773D, 0x2FAF6, 0x334DB, 0x334E1, 0x337FA, 0x34BC5,
    0x34BC6, 0x38663
  };

  vars.panelPointers = new Dictionary<int, DeepPointer>();
  vars.panelValues = new Dictionary<int, bool>();
  if (settings["Split on first panel"]) {
    vars.panelValues[0x00064] = false;
  }
  if (settings["Split on final elevator"]) {
    vars.panelValues[0x3D9A9] = false;
  }
  if (settings["Split on tutorial door"]) {
    vars.panelValues[0x03629] = false;
  }
  if (settings["Split on starting the boat"]) {
    vars.panelValues[0x34D96] = false;
  }
  if (settings["Split on greenhouse elevator"]) {
    vars.panelValues[0x0A079] = false;
  }
  if (settings["Split on mountain elevator"]) {
    vars.panelValues[0x09EEB] = false;
  }
  if (settings["Split on challenge start"]) {
    vars.panelValues[0x0A332] = false;
  }
  if (settings["Split on left challenge pillar"]) {
    vars.panelValues[0x1C31A] = false;
  }
  if (settings["Split on right challenge pillar"]) {
    vars.panelValues[0x1C319] = false;
  }
  if (settings["Split on lasers"]) {
    foreach(int laser in lasers) {
      vars.panelValues[laser] = false;
    }
  }
  if (settings["Don't split on greenhouse laser"]) {
    if (vars.panelValues.ContainsKey(0x09DE0)) {
      vars.panelValues.Remove(0x09DE0);
    }
  }
  if (settings["Split on panels"]) {
    foreach(int panel in panels) {
      vars.panelValues[panel] = false;
    }
  }
  if (settings["Split on non-counted panels"]) {
    foreach(int panel in nonPanels) {
      vars.panelValues[panel] = false;
    }
  }
  foreach(int panel in vars.panelValues.Keys) {
    int offset = 0x2A0; // True once the panel has been solved. Remains true after.
    if (version == "newer") offset = 0x298; // ???    
    // If the user wants to split on every puzzle, then we need to re-split on a chosen few which will be solved multiple times.
    if (settings["Split on panels"] && multiPanels.Contains(panel)) {
      offset = 0x29E; // True once the panel is completed. Becomes false if it is unsolved.
    }
    vars.panelPointers[panel] = new DeepPointer(baseOffset+0x8, 0x18, panel*8, offset);
  }
  foreach(int panel in vars.panelPointers.Keys) {
    vars.panelValues[panel] = vars.panelPointers[panel].Deref<bool>(game);
  }
}

update {
  //print("0x64: "+(new DeepPointer(0x5D1180 + 0x8, 0x18, 0x64*8, 0x29E)).Deref<bool>(game) + " " + (new DeepPointer(0x5D1180 + 0x8, 0x18, 0x64*8, 0x2A0)).Deref<bool>(game));
  //print(""+vars.panelPointers[0x64].Deref<bool>(game));
  if (old.currentPuzzle == 0 && current.currentPuzzle != 0) {
    print("Started solving: "+current.currentPuzzle);
    var tmp = new DeepPointer(0x5D1180, 0x18, (current.currentPuzzle-1)*8, 0x29E);
    bool isCompleted = tmp.Deref<bool>(game);
    print("Panel was completed: " + isCompleted);
  }
  if (old.currentPuzzle != 0 && current.currentPuzzle == 0) {
    print("Stopped solving: "+old.currentPuzzle);
    var tmp = new DeepPointer(0x5D1180, 0x18, (current.currentPuzzle-1)*8, 0x2A0);
    bool isSolved = tmp.Deref<bool>(game);
    print("Panel was solved: " + isSolved);
  }
}

gameTime {
  return TimeSpan.FromSeconds(current.gameTime - vars.startOffset);
}

reset {
  // Low IGT and time goes backwards, runner has reset
  if (current.gameTime < 10.0 && old.gameTime - current.gameTime > 1.0) {
    vars.startOffset = 0.0;
    return true;
  }
  // Game time jumps by >10s, runner has loaded a save
  if (Math.Abs(current.gameTime - old.gameTime) > 10.0) {
    vars.startOffset = 0.0;
    return true;
  }
}

start {
  // Don't start the game beyond a certain point
  if (current.gameTime > 20.0) {
    return false;
  }
  // Game was paused, settings presumably being set
  if (current.gamePaused != 0 && old.gamePaused == 0) {
    vars.startOffset = current.gameTime;
    return false;
  }
  // Game unpauses, and is not restarting
  if (current.gamePaused == 0 && old.gamePaused != 0 && !current.gameLoading) {
    return true;
  }
}

split {
  if (settings["Split on eclipse environmental start"]) {
    if (old.currentPuzzle == 0 && current.currentPuzzle == 0x339B9) {
      return true;
    }
  }
  if (!settings["Split on environmental puzzles"]) {
    if (settings["Split on eclipse environmental end"]) {
      if (old.currentPuzzle == 0x339B9 && current.currentPuzzle == 0) {
        return true; // Stopped (not necessarily completed)
      }
    }
    if (settings["Split on thundercloud environmental"]) {
      if (old.currentPuzzle == 0x28B9B && current.currentPuzzle == 0) {
        return true; // Stopped (not necessarily completed)
      }
    }
  }
  if (current.gameTime <= old.gameTime) {
    return false; // Don't allow splits while game is loading / stuttering
  }
  if (settings["Split on audio logs"]) {
    if (current.activeItem != 0 && old.solveMode && !current.solveMode) {
      return true;
    }
  }
  if (settings["Split on environmental puzzles"]) {
    foreach (MemoryWatcher<int> obeliskWatcher in vars.obeliskWatchers) {
      obeliskWatcher.Update(game);
      if (obeliskWatcher.Current > obeliskWatcher.Old) {
        print("Split for an environmental puzzle");
        return true;
      }
    }
  }
  vars.frame++;
  foreach(int panel in vars.panelValues.Keys) {
    if (panel%4 != vars.frame%4) continue;
    if (vars.panelValues[panel] == true) {
      if (vars.panelPointers[panel].Deref<bool>(game) == false) {
        // Panel was solved, but isn't now: update value and do nothing
        vars.panelValues[panel] = false;
        return false;
      }
    } else {
      if (vars.panelPointers[panel].Deref<bool>(game) == true) {
        // Panel is solved, but wasn't before: update value and split
        vars.panelValues[panel] = true;
        // Except for the triple puzzle in challenge:
        // If the challenge is done (both pillars solved), then don't split.
        if (vars.triplePanels.Contains(panel) && vars.panelValues[0x1C31A] && vars.panelValues[0x1C319]) {
          print("Not splitting for challenge triple 0x"+panel.ToString("X"));
          return false;
        }
        print("Split for panel 0x"+panel.ToString("X"));
        return true;
      }
    }
  }
}
