state("Talos") {}
state("Talos_Unrestricted") {}
state("Talos_VR") {}

// TODO: Splitter doesn't restart when resetting from a terminal? Confirmed, but what to do about it?
// TODO: "Split when returning to nexus" triggered in A5? Can't reproduce, logs were non-verbose. Will be fixed if/when I change to pointers instead of logging

startup {
  // Commonly used, defaults to true
  settings.Add("Don't start the run if cheats are active", true);
  settings.Add("Split on return to Nexus or DLC Hub", true);
  settings.Add("Split on item unlocks", true);
  settings.Add("Split on star collection in the Nexus", true);

  settings.Add("Split on Nexus green world doors", true);
  settings.Add("Split on Nexus red tower doors", false);
  settings.Add("Split on the Nexus gray Floor 6 door", false);
  settings.Add("Split on Nexus gold star doors", false); // (mostly) unused by the community

  // Less commonly used, but still sees some use
  settings.Add("Split on tetromino collection or DLC robot collection", false);
  settings.Add("Split on star collection", false);
  settings.Add("Split on exiting any terminal", false);

  // Rarely used
  settings.Add("Split on Community% ending", false); // Community% completion -- mostly unused
  settings.Add("Split when exiting Floor 5", false);
  settings.Add("Start the run in any world", false);
  settings.Add("(Custom/DLC) Split when solving any arranger", false);
  settings.Add("(Custom/DLC) Split on any world transition", false);

  settings.Add("worldsplits", true, "Don't split on sigil collections in these worlds:");
  settings.CurrentDefaultParent = "worldsplits";
  settings.Add("worldsplits-A4", false, "A4");
  settings.Add("worldsplits-A6", false, "A6");
  settings.Add("worldsplits-B1", false, "B1");
  settings.Add("worldsplits-B3", false, "B3");
  settings.Add("worldsplits-B4", false, "B4");
  settings.Add("worldsplits-B6", false, "B6");
  settings.Add("worldsplits-B8", false, "B8");

  vars.logFilePath = Directory.GetCurrentDirectory() + "\\autosplitter_talos.log";
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

  // In case the splitter is loaded while a run is ongoing
  vars.introCutscene = false;
  vars.isLoading = null;
  vars.currentWorld = "";

  // Stored in translation_All.txt as TermDlg.Endings.GatesCommand
  vars.eternalizeStrings = new List<string>{
    "USER: /eternalize", // English, French, Japanese, Simplified Chinese, Traditional Chinese
    "USER: /eternare", // Italian
    "USER: /eternizar", // Spanish, Portuguese
    "USER: /prenesi u vječnost", // Croatian
    "USER: /uwiecznienie", // Polish
    "USER: /verewigen", // German
    "USER: /увековечить", // Russian
    "USER: /영생 부여" // Korean
  };

  // Stored in translation_All.txt as TermDlg.Endings.Tower_Command
  vars.transcendenceStrings = new List<string>{
    "USER: /prijeđi", // Croatian
    "USER: /transcend", // English, French, Japanese, Simplified Chinese, Traditional Chinese
    "USER: /transcendencja", // Polish
    "USER: /transcender", // Portuguese
    "USER: /transcendere", // Italian
    "USER: /transzendieren", // German
    "USER: /trascender", // Spanish
    "USER: /переступить", // Russian
    "USER: /초월", // Korean
  };

  vars.startRegex = new System.Text.RegularExpressions.Regex("^Started simulation on '(.*?)'");
  // Level name, hasIntroCutscene
  vars.knownStartingWorlds = new Dictionary<string, bool> {
    {"Content/Talos/Levels/Cloud_1_01.wld", true}, // Talos
    {"Content/Talos/Levels/DLC_01_Intro.wld", true}, // Gehenna
    {"Content/Talos/Levels/Demo.wld", false}, // Demo
    {"Content/Talos/Levels/Demo_Simple.wld", false}, // Short Demo
    {"Content/Talos/Levels/Bonus_PrototypeLobby.wld", false}, // Prototype

    {"Content/Talos/Levels/DATA_backup/DATA_backup.wld", false}, // Data Backup
    {"Content/Talos/Levels/ExploitCollector/ExploitCollector.wld", false}, // Exploit Collector
    {"Content/Talos/Levels/OnTopOfAll/OnTopOfAll.wld", false}, // On Top of All
    {"Content/Talos/Levels/Only Puzzles 2/01-The Pyramid.wld", false}, // Only Puzzles 2
    {"Content/Talos/Levels/Only Puzzles/Test1.wld", false}, // Only Puzzles
    {"Content/Talos/Levels/Orbital/Orbital_Main.wld", false}, // Orbital
    {"Content/Talos/Levels/query.wld", false}, // Query
    {"Content/Talos/Levels/Limbo/Limbo.wld", false}, // Question Mark
    {"Content/Talos/Levels/Rnm2/sky.wld", false}, // Ranamo Puzzles 2
    {"Content/Talos/Levels/Ranamo/hub.wld", false}, // Ranamo Puzzles
    {"Content/Talos/Levels/Randomizer/Cloud_1_01.wld", true}, // Randomizer
    {"Content/Talos/Levels/Rebirth/Intro.wld", false}, // Rebirth
    {"Content/Talos/Levels/Crystal/Room.wld", false}, // Schrodinger's Cat
    {"Content/Talos/Levels/TutorialLevel/TutorialLevel.wld", false}, // Simple Tutorial Level
    {"Content/Talos/Levels/Simplicity/Simplicity_Main.wld", false}, // Simplicity
    {"Content/Talos/Levels/Xana/Episode1/Map01.wld", false}, // Sornukiz
    {"Content/Talos/Levels/StepByStep/StepByStep.wld", false}, // Step By Step
    {"Content/Experiments/World.wld", false}, // Strange Machine in Medieval
    {"Content/Talos/Levels/The Day After/Intro.wld", false}, // The Day After
    {"Content/Talos/Levels/JP_TheFlood/JPTF1.wld", false}, // The Flood
    {"Content/Talos/Levels/TFD/TFD_01.wld", false}, // The Fourth Dimension
    {"Content/Talos/Levels/Z_HolyDays/HD_Cloud_Xmas.wld", false}, // The Holy Days
    {"Content/Talos/Levels/TheOnlyPuzzle/TheOnlyPuzzle_00.wld", false} // This is The Only Puzzle
  };
}

init {
  var page = modules.First();
  var gameDir = Path.GetDirectoryName(page.FileName);

  string logPath;
  if (game.Is64Bit()) {
    logPath = gameDir.TrimEnd("\\Bin\\x64".ToCharArray());
  } else {
    logPath = gameDir.TrimEnd("\\Bin".ToCharArray());
  }
  logPath += "\\Log\\" + game.ProcessName + ".log";
  vars.log("Using log path: '" + logPath + "'");

  // To find the loading pointer:
  // (x64) AOB scan for C7 81 8C010000 01000000 48 8B
  // (x86) AOB scan for C7 86 74010000 01000000 85 C9
  // Start a new game.
  // Set a breakpoint
  // Add Address for ESI (x86) or RCX (x64)
  // Pointer scan for that address
  // Sort by Offset 4
  // Find the Talos.exe+??? which has offsets 8, 0 (x86) or 10, 0 (x64)
  // That ??? is the base value for the loading pointer. Other offsets are unchanged.
  // Moddable base values have always been exactly 0x3000 less so far, best to check again just in case though

  switch (page.ModuleMemorySize) {
    // TODO: 429074
    case 35561472:
      version = "326589 x64";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x17C3670));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x17981D0, 0x10, 0x208));
      break;
    case 35549184:
      version = "326589 x64 Moddable";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x17C0670));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x17951D0, 0x10, 0x208));
      break;
    case 24506368:
      version = "326589 x86";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x1273F48));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x12540E8, 0x8, 0x1C8));
      break;
    case 24494080:
      version = "326589 x86 Moddable";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x1270F48));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x12510E8, 0x8, 0x1C8));
      break;

    case 34160640:
      version = "301136 x64";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x1673BC0));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x16488F0, 0x10, 0x208));
      break;
    case 34148352:
      version = "301136 x64 Moddable";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x1673BC0));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x16458F0, 0x10, 0x208));
      break;
    case 23699456:
      version = "301136 x86";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x11AF758));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x118FA48, 0x8, 0x1C8));
      break;
    case 23687168:
      version = "301136 x86 Moddable";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x11AC758));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x118CA48, 0x8, 0x1C8));
      break;

    case 19599360:
      version = "243520/244371 x86";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x11B7724));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x11B1864, 0x10, 0x208));
      break;
    case 19587072:
      version = "243520/244371 x86 Moddable";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x11B4724));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x11AE864, 0x10, 0x208));
      break;

    case 19681280:
      version = "226087 x86";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x11CC724));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x11C6B44, 0x8, 0x1C8));
      break;
    case 19668992:
      version = "226087 x86 Moddable";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x11C9724));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x11C3B44, 0x8, 0x1C8));
      break;

    default:
      version = "Unknown";
      vars.log("ModuleMemorySize = " + modules.First().ModuleMemorySize);
      break;
  }
  vars.log("Using game version: " + version);

  try { // Wipe the log file to clear out messages from last time
    FileStream fs = new FileStream(logPath, FileMode.Open, FileAccess.Write, FileShare.ReadWrite);
    fs.SetLength(0);
    fs.Close();
  } catch {} // May fail if file doesn't exist.
  vars.reader = new StreamReader(new FileStream(logPath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite));
}

exit {
  timer.IsGameTimePaused = true;
  vars.reader = null; // Free the lock on the talos logfile, so folders can be renamed/etc
}

update {
  if (version == "unknown") return false;
  while (true) {
    vars.line = vars.reader.ReadLine();
    if (vars.line == null) return false; // If no line was read, don't run any other blocks.
    if (vars.line.Substring(9, 3) == "ERR") continue; // Filter out error-level logging, as it can be spammy when bots get stuck
    break;
  }
  vars.line = vars.line.Substring(16); // Removes the date and log level from the line

  vars.cheatFlags.Update(game);
  vars.isLoading.Update(game);
}

start {
  var match = vars.startRegex.Match(vars.line);
  if (match.Success) {
    var world = match.Groups[1].Value;
    // Main menu and settings count as 'worlds', ignore them
    if (world.Contains("Menu")) return false;

    if (vars.cheatFlags.Current != 0) {
      vars.log("Cheats are currently active: " + vars.cheatFlags.Current);
      if (settings["Don't start the run if cheats are active"]) {
        vars.log("Not starting the run because of cheats");
        return false;
      }
    }

    if (vars.knownStartingWorlds.ContainsKey(world)) {
      vars.introCutscene = vars.knownStartingWorlds[world];
    } else if (!settings["Start the run in any world"]) {
      return false;
    }
    vars.log("Started a new run in " + world);

    vars.currentWorld = world;
    vars.lastSigil = "";
    vars.lastLines = 0;
    vars.graySigils = 0;
    vars.adminEnding = false;
    timer.IsGameTimePaused = true;
    return true;
  }
}

reset {
  if (vars.line == "Saving talos progress upon game stop.") {
    vars.log("Stopped run because the game was stopped.");
    return true; // Unique line printed only when you stop the game
  }
}

isLoading {
  if (vars.introCutscene && vars.line == "Save Talos Progress: delayed request") {
    vars.log("Intro cutscene was skipped or ended normally, starting timer.");
    vars.introCutscene = false;
  }
  // Pause the timer during the intro cutscene
  if (vars.introCutscene) return true;
  // Game is loading (restart checkpoint, level transition)
  if (vars.isLoading != null && vars.isLoading.Current != 0) return true;
  return false;
}

split {
  if (vars.line.StartsWith("Changing over to")) { // Map changes
    var mapName = vars.line.Substring(17);
    if (mapName == vars.currentWorld) {
      return false; // Ensure 'restart checkpoint' doesn't trigger map change
    }
    vars.log("Changed worlds from "+vars.currentWorld+" to "+mapName);
    vars.currentWorld = mapName;
    if (settings["Split on return to Nexus or DLC Hub"] &&
      (mapName.EndsWith("Nexus.wld") ||
       mapName.EndsWith("DLC_01_Hub.wld"))) {
      return true;
    }
    if (settings["(Custom/DLC) Split on any world transition"]) {
      return true;
    }
  }
  if (vars.line.StartsWith("Picked:")) { // Sigil/Robot and star collection
    var sigil = vars.line.Substring(8);
    if (sigil == vars.lastSigil) {
      return false; // DLC Double-split prevention
    } else {
      vars.lastSigil = sigil;
    }
    vars.log("Collected sigil " + sigil + " in world " + vars.currentWorld);
    if (settings["worldsplits-A4"] && vars.currentWorld.EndsWith("Cloud_1_04.wld")) {
      vars.log("Not splitting for a collection in A4, per setting.");
      return false;
    }
    if (settings["worldsplits-A6"] && vars.currentWorld.EndsWith("Cloud_1_06.wld")) {
      vars.log("Not splitting for a collection in A6, per setting.");
      return false;
    }
    if (settings["worldsplits-B1"] && vars.currentWorld.EndsWith("Cloud_2_01.wld")) {
      vars.log("Not splitting for a collection in B1, per setting.");
      return false;
    }
    if (settings["worldsplits-B3"] && vars.currentWorld.EndsWith("Cloud_2_03.wld")) {
      vars.log("Not splitting for a collection in B3, per setting.");
      return false;
    }
    if (settings["worldsplits-B4"] && vars.currentWorld.EndsWith("Cloud_2_04.wld")) {
      vars.log("Not splitting for a collection in B4, per setting.");
      return false;
    }
    if (settings["worldsplits-B6"] && vars.currentWorld.EndsWith("Cloud_2_06.wld")) {
      vars.log("Not splitting for a collection in B6, per setting.");
      return false;
    }
    if (settings["worldsplits-B8"] && vars.currentWorld.EndsWith("Cloud_2_08.wld")) {
      vars.log("Not splitting for a collection in B8, per setting.");
      return false;
    }
    if (sigil.StartsWith("E")) {
      vars.graySigils++;
      vars.log("Collected gray sigil #" + vars.graySigils);
      if (vars.graySigils == 9 && settings["Split on Community% ending"]) {
        return true;
      }
    }
    if (sigil.StartsWith("**")) {
      if (settings["Split on star collection"]) {
        return true;
      } else {
        if (vars.currentWorld.EndsWith("Nexus.wld")) {
          return settings["Split on star collection in the Nexus"];
        }
      }
    } else {
      return settings["Split on tetromino collection or DLC robot collection"];
    }
  }

  // Arranger puzzles
  if (vars.line.StartsWith("Puzzle \"") && vars.line.Contains("\" solved")) {
    var puzzle = vars.line.Substring(8);
    vars.log("Solved puzzle: " + puzzle);
    if (puzzle.StartsWith("Mechanic")) {
      return settings["Split on item unlocks"];
    }
    if (puzzle.StartsWith("Door") && settings["Split on Nexus green world doors"]) {
      return true; // Working around a custom arranger called 'Door_Dome'
    }
    if (puzzle.StartsWith("SecretDoor")) {
      return settings["Split on Nexus gold star doors"];
    }
    if (puzzle.StartsWith("Nexus")) {
      return settings["Split on Nexus red tower doors"];
    }
    if (puzzle.StartsWith("AlternativeEding")) {
      return settings["Split on the Nexus gray Floor 6 door"];
    }
    if (puzzle.StartsWith("DLC_01_Secret")) {
      return settings["(Custom/DLC) Split when solving any arranger"];
    }
    if (puzzle.StartsWith("DLC_01_Hub")) {
      vars.adminEnding = true; // Admin puzzle door solved, so the Admin is saved.
      return settings["(Custom/DLC) Split when solving any arranger"];
    }
    // If it's not one of the main game/DLC strings, then it must be a custom campaign
    return settings["(Custom/DLC) Split when solving any arranger"];
  }

  // Miscellaneous
  if (vars.line == "Save Talos Progress: exited terminal") {
    vars.log("User exited terminal");
    return settings["Split on exiting any terminal"];
  }
  if (vars.currentWorld.EndsWith("Islands_03.wld")) {
    // There are various "tombstone messages", so consider any message as ending the run
    if (vars.line.StartsWith("USER:")) {
      vars.log("Game completed via Messenger ending.");
      return true;
    }
  }
  if (vars.currentWorld.EndsWith("Nexus.wld")) {
    if (vars.line == "Elohim speaks: Elohim-063_Nexus_Ascent_01") {
      vars.log("User exits floor 5 and starts ascending the tower");
      return settings["Split when exiting Floor 5"];
    }
    if (vars.transcendenceStrings.Contains(vars.line)) {
      vars.log("Game completed via Transcendence ending.");
      return true;
    }
    if (vars.eternalizeStrings.Contains(vars.line)) {
      vars.log("Game completed via Eternalize ending.");
      return true;
    }
  }
  if (vars.currentWorld.EndsWith("DLC_01_Hub.wld")) {
    if (vars.line == "Save Talos Progress: entered terminal") {
      vars.lastLines = 0;
    }
    if (vars.line.StartsWith("USER:")) {
      vars.lastLines++;
      if (vars.adminEnding) {
        // If admin is saved, it takes 5 lines to end the game
        return (vars.lastLines == 5);
      } else {
        // In all other endings, game ends on the 4th dialogue
        return (vars.lastLines == 4);
      }
    }
  }
}
