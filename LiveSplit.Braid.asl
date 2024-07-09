state("braid", "steam") {
  int world      : 0x1F718C;
  int level      : 0x1F7190;
  byte flagPole  : 0x1F942C;
  int gameFrames : 0x1F9434;
}

state("braid", "standalone") {
  int world      : 0x1F110C;
  int level      : 0x1F1110;
  byte flagPole  : 0x1F33AC;
  int gameFrames : 0x1F33B4;
}

state("braid", "kanban55") {
  int world      : 0x18B93C;
  int level      : 0x18B940;
  byte flagPole  : 0x18DBDC;
  int gameFrames : 0x18DBE4;
}

state("braid64_d3d11_final", "anniversary") {
  int world      : 0x4584C8;
  int level      : 0x4584CC;
  byte flagPole  : 0x45B89C;
  int gameFrames : 0x45B8A4;
}

startup {
  settings.Add("Split when returning to the house", true);
  settings.Add("Split when touching a flagpole", false);

  settings.Add("Split when completing and exiting a puzzle level", false);
  settings.Add("Split when initially collecting a piece", false);

  settings.Add("Split when exiting The Cloud Bridge after collecting 2 pieces", false);
  settings.Add("Split when exiting Leap of Faith after collecting 1 piece", false);
  settings.Add("Split when exiting Lair in World 3", false);
  settings.Add("Split when entering the Braid level", false);
  settings.Add("Split when exiting the Braid level", false);
  settings.Add("Split when exiting lobby levels", false);
  settings.Add("Split when exiting the house", false);

  vars.logFilePath = Directory.GetCurrentDirectory() + "\\autosplitter_braid.log";
  vars.log = (Action<string>)((string logLine) => {
    print(logLine);
    string time = System.DateTime.Now.ToString("dd/MM/yy hh:mm:ss:fff");
    System.IO.File.AppendAllText(vars.logFilePath, time + ": " + logLine + "\r\n");
  });
  try {
    vars.log("Autosplitter loaded");
  } catch (System.IO.FileNotFoundException e) {
    System.IO.File.Create(vars.logFilePath);
    vars.log("Autosplitter loaded, log file created");
  }
}

init {
  vars.piecesBase = 0x0; // location of first piece minus 0x338
  switch (modules.First().ModuleMemorySize) {
  case 7663616:
    version = "steam";
    vars.piecesBase = 0x1F829C;
    vars.log("Using steam version");
    break;
  case 7639040:
    version = "standalone";
    vars.piecesBase = 0x1F221C;
    vars.log("Using standalone version");
    break;
  case 7229440:
    version = "kanban55";
    vars.piecesBase = 0x18CA4C;
    vars.log("Using kanban55 version");
    break;
  case 12275712:
    version = "anniversary";
    vars.piecesBase = 0x459F88;
    vars.log("Using anniversary version");
    break;
  default:
    throw new Exception("Unknown version: " + modules.First().ModuleMemorySize);
  }

  // IDs are in display order in the top left
  vars.pieceMap = new Dictionary<string, List<int>> { // Name : List of piece indices
    {"0-0", new List<int>()}, // House
    {"0-1", new List<int>()}, // World 1 lobby
    {"0-2", new List<int>()}, // World 2 lobby
    {"0-3", new List<int>()}, // World 3 lobby
    {"0-4", new List<int>()}, // World 4 lobby
    {"0-5", new List<int>()}, // World 5 lobby
    {"0-6", new List<int>()}, // World 6 lobby
    {"0-8", new List<int>()}, // Epilogue

    {"1-4", new List<int>()},
    {"1-3", new List<int>()},
    {"1-2", new List<int>()},
    {"1-1", new List<int>()}, // Braid

    {"2-1", new List<int>{6, 5, 1}}, // Three Easy Pieces
    {"2-2", new List<int>{9, 10, 4, 2}}, // The Cloud Bridge
    {"2-3", new List<int>{8}}, // Hunt!
    {"2-4", new List<int>{11, 12, 7, 3}}, // Leap of Faith

    {"3-1", new List<int>{}}, // The Pit
    {"3-2", new List<int>{2}}, // There and Back Again
    {"3-3", new List<int>{4, 6}}, // Phase
    {"3-4", new List<int>{12, 7}}, // The Ground Beneath Her Feet
    {"3-5", new List<int>{8, 1}}, // Tight Channels
    {"3-6", new List<int>{3, 9, 10}}, // Irreversible
    {"3-7", new List<int>{}}, // Lair
    {"3-8", new List<int>{5, 11}}, // A Tingling

    {"4-1", new List<int>{}}, // The Pit
    {"4-2", new List<int>{5, 6, 9}}, // Jumpman
    {"4-3", new List<int>{12, 10}}, // Just Out of Reach
    {"4-4", new List<int>{7}}, // Hunt!
    {"4-5", new List<int>{3, 8}}, // Movement by Degrees
    {"4-6", new List<int>{4, 1}}, // Movement, Amplified
    {"4-7", new List<int>{11, 2}}, // Fickle Companion

    {"5-1", new List<int>{5}}, // The Pit
    {"5-2", new List<int>{4, 9}}, // So Distant
    {"5-3", new List<int>{2, 12}}, // [unnamed]
    {"5-4", new List<int>{7, 8, 1}}, // Crossing the Gap
    {"5-5", new List<int>{3, 10}}, // Window of Opportunity
    {"5-6", new List<int>{11}}, // Lair
    {"5-7", new List<int>{6}}, // Fragile Companion

    {"6-1", new List<int>{}}, // The Pit?
    {"6-2", new List<int>{11}}, // There and Back Again
    {"6-3", new List<int>{8, 10}}, // Phase?
    {"6-4", new List<int>{4, 12, 1}}, // Cascade
    {"6-5", new List<int>{3, 9}}, // Impassable Foliage
    {"6-6", new List<int>{5, 2, 6}}, // Elevator Action
    {"6-7", new List<int>{7}}, // In Another Castle

  };
  vars.completedLevels = new Dictionary<string, bool>(); // Name : completion
  foreach (string level in vars.pieceMap.Keys) vars.completedLevels[level] = false;
  vars.collectedPieces = new Dictionary<int, bool>(); // ID : state
  vars.currentPieces = new Dictionary<int, DeepPointer>(); // ID : pointer

  for (int world=2; world<=6; world++) {
    for (int piece=1; piece<=12; piece++) {
      vars.collectedPieces[vars.piecesBase + (0x18C * world) + (0x20 * piece)] = false;
    }
  }
  vars.log("Finished initializing");
}

isLoading {
  return true; // Disable gameTime approximation
}

gameTime {
  return TimeSpan.FromSeconds(current.gameFrames/60.0);
}

start {
  if (old.gameFrames == 0 && current.gameFrames > 0) {
    var pieces = new List<int>(vars.collectedPieces.Keys);
    foreach (int piece in pieces) {
      vars.collectedPieces[piece] = false;
    }
    var worlds = new List<string>(vars.completedLevels.Keys);
    foreach (string world in worlds) {
      vars.completedLevels[world] = false;
    }
    vars.log("Started a new run");
    return true;
  }
}

reset {
  if (old.gameFrames > 0 && current.gameFrames == 0) {
    vars.log("Resetting run");
    return true;
  }
}

split {
  if (old.world != current.world || old.level != current.level) {
    string oldName = old.world + "-" + old.level;
    string currentName = current.world + "-" + current.level;
    vars.log("Changed from " + oldName + " to " + currentName);

    int missingPieces = 0;
    foreach (int piece in vars.currentPieces.Keys) {
      if (vars.collectedPieces[piece] == false) {
        missingPieces++;
      }
    }
    vars.log(oldName + " still has " + missingPieces + " missing pieces");

    // Prepare for the next level
    vars.currentPieces.Clear();
    // Kanban55 bug: 3-8 -> 3-0 -> 0-0 (but 3-0 is not a valid level)
    if (vars.pieceMap.ContainsKey(currentName)) {
      foreach (var puzzleId in vars.pieceMap[currentName]) {
        int address = vars.piecesBase + (0x18C * current.world) + (0x20 * puzzleId);
        vars.currentPieces[address] = new DeepPointer(address);
      }
    }

    if (vars.completedLevels.ContainsKey(oldName)) {
      vars.log("Level completion state: " + vars.completedLevels[oldName]);

      // Ensure that we don't try to split for a level again. This value will
      // be reset to false if a piece is collected in the level.
      if (vars.completedLevels[oldName] == false) {
        vars.log("Completed " + oldName);
        vars.completedLevels[oldName] = true;

        if (oldName == "0-8" && currentName == "0-0") {
          vars.log("Exited the epilogue");
          return true;
        }
        if (old.world != 0 && currentName == "0-0") {
          vars.log("Returned to house");
          return settings["Split when returning to the house"];
        }
        if (oldName == "1-2" && currentName == "1-1") {
          vars.log("Entered Braid");
          return settings["Split when entering the Braid level"];
        }
        if (oldName == "1-1" && currentName == "0-8") {
          vars.log("Exited Braid");
          return settings["Split when exiting the Braid level"];
        }
        if (oldName == "3-7" && currentName == "3-8") {
          vars.log("Exited W3 Lair");
          return settings["Split when exiting Lair in World 3"];
        }
        // missingPieces was computed above, before we cleared vars.curentPieces
        if (oldName == "2-2" && missingPieces == 2) {
          vars.log("Exited Cloud Bridge (2 missing pieces)");
          return settings["Split when exiting The Cloud Bridge after collecting 2 pieces"];
        }
        if (oldName == "2-4" && missingPieces == 3) {
          vars.log("Exited Leap of Faith (3 missing pieces)");
          return settings["Split when exiting Leap of Faith after collecting 1 piece"];
        }
        if (oldName == "0-0") {
          vars.completedLevels[oldName] = false;
          vars.log("Exited the house");
          return settings["Split when exiting the house"];
        }
        if (old.world == 0) {
          vars.log("Exited the lobby");
          return settings["Split when exiting lobby levels"];
        }
        if (missingPieces == 0) {
          vars.log("Completed a puzzle level (0 missing pieces)");
          return settings["Split when completing and exiting a puzzle level"];
        }
      }
    }
  }

  // This is actually speed_run_sound_flags, and it seems to be used as well while solving the meta-puzzles,
  // so ensure that we're actually in an end-of-world level
  if ((old.flagPole & 0x01) == 0x00 && (current.flagPole & 0x01) == 0x01) {
    string currentName = current.world + "-" + current.level;
    if (currentName == "2-4" ||
        currentName == "3-8" ||
        currentName == "4-7" ||
        currentName == "5-7" ||
        currentName == "6-7") {
      vars.log("Touched a flagpole");
      return settings["Split when touching a flagpole"];
    }
  }

  foreach (int piece in vars.currentPieces.Keys) {
    if (vars.collectedPieces[piece] == false) {
      if (vars.currentPieces[piece].Deref<bool>(game) == true) {
        vars.log("Collected piece 0x" + piece.ToString("X") + " in level " + current.level);
        vars.collectedPieces[piece] = true;
        // Collected a piece so the world is not complete yet
        vars.completedLevels[current.world + "-" + current.level] = false;
        return settings["Split when initially collecting a piece"];
      }
    }
  }
}