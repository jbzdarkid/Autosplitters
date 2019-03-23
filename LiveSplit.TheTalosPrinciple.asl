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
  
  vars.startRegex = new System.Text.RegularExpressions.Regex(@"^Started simulation on '(.*?)'");
}

init {
  var page = modules.First();
  var gameDir = Path.GetDirectoryName(page.FileName);
  var scanner = new SignatureScanner(game, page.BaseAddress, page.ModuleMemorySize);
  var ptr = IntPtr.Zero;
  vars.foundPointers = false;

  string logPath;
  if (game.Is64Bit()) {
    logPath = gameDir.TrimEnd("\\Bin\\x64".ToCharArray());
  } else {
    logPath = gameDir.TrimEnd("\\Bin".ToCharArray());
  }
  logPath += "\\Log\\" + game.ProcessName + ".log";
  vars.log("Using log path: '" + logPath + "'");

  if (game.Is64Bit()) {
    ptr = scanner.Scan(new SigScanTarget(3, // Targeting byte 3
      "44 39 25 ????????", // cmp [Talos.exe+target], r12d
      "48 8B F9"           // mov rdi, rcx
    ));
    if (ptr == IntPtr.Zero) {
      vars.log("Could not find x64 cheatFlags!");
      return false;
    }
    int relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;
    vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(
      game.ReadValue<int>(ptr) + relativePosition
    ));

    ptr = scanner.Scan(new SigScanTarget(3, // Targeting byte 3
      "48 8B 0D ????????", // mov rcx, [Talos.exe+offset]
      "48 8B 11",          // mov rdx, [rcx]
      "FF 92 B0000000"     // call qword ptr [rdx+B0]
    ));
    if (ptr == IntPtr.Zero) {
      vars.log("Could not find x64 isLoading!");
      return false;
    }
    relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;
    vars.isLoading = new MemoryWatcher<int>(new DeepPointer(
      game.ReadValue<int>(ptr) + relativePosition,
      0x10, 0x208 // Doesn't seem to change
    ));
  } else { // game.Is64Bit() == false
    ptr = scanner.Scan(new SigScanTarget(3, // Targeting byte 3
      "75 08",       // jne 8
      "A1 ????????", // mov eax, [Talos.exe+target]
      "5E"           // pop esi
    ));
    if (ptr == IntPtr.Zero) {
      vars.log("Could not find x86 cheatFlags!");
      return false;
    }
    vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(
      game.ReadValue<int>(ptr) - (int)page.BaseAddress
    ));

    ptr = scanner.Scan(new SigScanTarget(2, // Taregetting byte 2
      "8B 0D ????????", // mov ecx,[Talos.exe+target]
      "8B 11",          // mov edx,[ecx]
      "FF 52 58"        // call dword ptr [edx+58]
    ));
    if (ptr == IntPtr.Zero) {
      vars.log("Could not find x86 isLoading!");
      return false;
    }
    vars.isLoading = new MemoryWatcher<int>(new DeepPointer(
      game.ReadValue<int>(ptr) - (int)page.BaseAddress,
      0x08, 0x1C8 // Doesn't seem to change
    ));
    // x86 settings change pointer:
    // 5E 5D C2 0400 C7 05 ???????? 01000000
  }
  vars.foundPointers = true;

  try { // Wipe the log file to clear out messages from last time
    FileStream fs = new FileStream(logPath, FileMode.Open, FileAccess.Write, FileShare.ReadWrite);
    fs.SetLength(0);
    fs.Close();
  } catch {} // May fail if file doesn't exist.
  vars.reader = new StreamReader(new FileStream(logPath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite));
}

exit {
  timer.IsGameTimePaused = true;
}

update {
  if (vars.foundPointers == null) return false;
  while (true) {
    vars.line = vars.reader.ReadLine();
    if (vars.line == null) return false; // If no line was read, don't run any other blocks.
    //if (vars.line.Substring(9, 3) == "ERR") continue;
    // This looks a little weird but it avoids creating a new string like a substring
    if (vars.line.IndexOf("ERR", 9, 3) == 9) continue; // Filter out error-level logging, as it can be spammy when bots get stuck
    break;
  }
  vars.line = vars.line.Substring(16); // Removes the date and log level from the line

  vars.cheatFlags.Update(game);
  vars.isLoading.Update(game);
}

start {
  Action<string> startGame = (string world) => {
    vars.currentWorld = world;
    vars.lastSigil = "";
    vars.lastLines = 0;
    vars.graySigils = 0;
    vars.adminEnding = false;
    vars.introCutscene = false;
    timer.IsGameTimePaused = true;
  };

  var match = vars.startRegex.Match(vars.line);
  if (match.Success) {
    if (vars.cheatFlags.Current != 0) {
      vars.log("Cheats are currently active: " + vars.cheatFlags.Current);
      if (settings["Don't start the run if cheats are active"]) {
        vars.log("Not starting the run because of cheats");
        return false;
      }
    }

    string world = match.Groups[1].Value;
    if (world.Contains("Cloud_1_01.wld") || world.Contains("DLC_01_Intro.wld")) {
      vars.log("Started a new run from standard starting world with cutscene:");
      vars.log(world);
      startGame(world);
      vars.introCutscene = true;
      return true;
    } else if (world.Contains("Demo.wld") || world.Contains("Bonus_PrototypeLobby.wld")) {
      vars.log("Started a new run from standard starting world without cutscene:");
      // We'll start the timer later
    } else if (settings["Start the run in any world"] && !world.Contains("Menu")) {
      vars.log("Started a new run from non-standard starting world, assuming no cutscene:");
    } else {
      return false;
    }
    
    vars.log(world);
    startGame(world);
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
