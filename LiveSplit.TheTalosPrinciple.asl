state("Talos") {}
// TODO: Splitter doesn't restart when resetting from a terminal? Confirmed, but what to do about it?
// https://www.twitch.tv/videos/217795611?t=01h20m20s
// TODO: "Split when returning to nexus" triggered in A5? https://www.twitch.tv/videos/217795611?t=01h24m27s
// TODO: Extra worlds splits -> Should have a subcategory for these
// TODO: Spanish version of "USER: /eternalize" is USER: /eternizar

startup {
  // Commonly used, defaults to true
  settings.Add("Don't start the run if cheats are active", true);
  settings.Add("Split on return to Nexus or DLC Hub", true);
  settings.Add("Split on tetromino tower doors", true);
  settings.Add("Split on item unlocks", true);
  settings.Add("Split on star collection in the Nexus", true);

  // Less commonly used, but still sees some use
  settings.Add("Split on tetromino collection or DLC robot collection", false);
  settings.Add("Split on star collection", false);
  settings.Add("Split on tetromino world doors", false);
  settings.Add("Split on exiting any terminal", false);

  // Rarely used
  settings.Add("Split on tetromino star doors", false); // (mostly) unused by the community
  settings.Add("Split on Community% ending", false); // Community% completion -- mostly unused
  settings.Add("Split when exiting Floor 5", false);
  settings.Add("Don't split on tetromino collection in A6", false);
  settings.Add("Don't split on tetromino collection in B4", false);
  settings.Add("Don't split on tetromino collection in B6", false);
  settings.Add("Don't split on tetromino collection in B8", false);
  settings.Add("Start the run in any world", false);
  settings.Add("(Custom/DLC) Split when solving any arranger", false);
  settings.Add("(Custom/DLC) Split on any world transition", false);

}

init {
  var gameDir = Path.GetDirectoryName(modules.First().FileName);
  var logPath = "";
  
  var page = modules.First();
  var scanner = new SignatureScanner(game, page.BaseAddress, page.ModuleMemorySize);
  var ptr = IntPtr.Zero;
  vars.foundPointers = false;
  
  if (game.Is64Bit()) {
    logPath = gameDir.TrimEnd("\\Bin\\x64".ToCharArray()) + "\\Log\\Talos.log";

    ptr = scanner.Scan(new SigScanTarget(3, // Targeting byte 3
      "44 39 25 ????????", // cmp [Talos.exe+target], r12d
      "48 8B F9"           // mov rdi, rcx
    ));
    if (ptr == IntPtr.Zero) {
      print("Could not find x64 cheatFlags!");
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
      print("Could not find x64 isLoading!");
      return false; 
    }
    relativePosition = (int)((long)ptr - (long)page.BaseAddress) + 4;
    vars.isLoading = new MemoryWatcher<int>(new DeepPointer(
      game.ReadValue<int>(ptr) + relativePosition,
      0x10, 0x208 // Doesn't seem to change
    ));
  } else { // game.Is64Bit() == false
    logPath = gameDir.TrimEnd("\\Bin".ToCharArray()) + "\\Log\\Talos.log";

    ptr = scanner.Scan(new SigScanTarget(2, // Targeting byte 2
      "83 3D ???????? 00", // cmp dword ptr [Talos.exe+target]
      "53",                // push ebx
      "56",                // push esi
      "8B D9 C7",          // mov ebx, ecx
      "45 FC 00000000"     // mov [ebp-04], 0
    ));
    if (ptr == IntPtr.Zero) {
      print("Could not find x86 cheatFlags!");
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
      print("Could not find x86 isLoading!");
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
  vars.line = vars.reader.ReadLine();
  if (vars.line == null) return false; // If no line was read, don't run any other blocks.
  vars.line = vars.line.Substring(16); // Removes the date and log level from the line
  
  vars.cheatFlags.Update(game);
  vars.isLoading.Update(game);
}

start {
  if (settings["Don't start the run if cheats are active"] &&
    vars.cheatFlags.Current != 0) {
    print("Not starting the run because of cheat flags: "+vars.cheatFlags.Current);
    return false;
  }
  // Only start for A1 / Gehenna Intro, since restore backup / continue should mostly be on other worlds.
  if (vars.line.StartsWith("Started simulation on 'Content/Talos/Levels/Cloud_1_01.wld'") ||
    vars.line.StartsWith("Started simulation on 'Content/Talos/Levels/DLC_01_Intro.wld'")) {
    print("Started a new run from a normal starting world.");
    vars.currentWorld = "[Initial World]"; // Not parsing this because it's hard
    vars.lastSigil = "";
    vars.lastLines = 0;
    vars.adminEnding = false;
    vars.introCutscene = true;
    timer.IsGameTimePaused = true;
    return true;
  }
  
  if (settings["Start the run in any world"] &&
    vars.line.StartsWith("Started simulation on '")) {
    print("Started a new run from a non-normal starting world.");
    vars.currentWorld = "[Initial World]"; // Not parsing this because it's hard
    vars.lastSigil = "";
    vars.lastLines = 0;
    vars.adminEnding = false;
    vars.introCutscene = false; // Don't wait for an intro cutscene for custom starts
    timer.IsGameTimePaused = true;
    return true;
  }
}

reset {
  if (vars.line == "Saving talos progress upon game stop.") {
    print("Stopped run because the game was exited.");
    return true; // Unique line printed only when you stop the game
  }
}

isLoading {
  if (vars.introCutscene && vars.line == "Save Talos Progress: delayed request") {
    print("Intro cutscene was skipped or ended normally, starting timer.");
    vars.introCutscene = false;
  }
  // Pause the timer during the intro cutscene
  if (vars.introCutscene) return true;
  // Game is loading (restart checkpoint, level transition)
  if (vars.isLoading.Current != 0) return true;
  return false;
}

split {
  if (vars.line.StartsWith("Changing over to")) { // Map changes
    var mapName = vars.line.Substring(17);
    if (mapName == vars.currentWorld) {
      return false; // Ensure 'restart checkpoint' doesn't trigger map change
    }
    print("Changed worlds from "+vars.currentWorld+" to "+mapName);
    vars.currentWorld = mapName;
    if (settings["Split on return to Nexus or DLC Hub"] &&
      (mapName == "Content/Talos/Levels/Nexus.wld" ||
       mapName == "Content/Talos/Levels/DLC_01_Hub.wld")) {
      return true;
    }
    if (mapName == "Content/Talos/Levels/Cloud_3_08.wld") {
      vars.cStarSigils = 0;
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
    print("Collected sigil " + sigil + " in world " + vars.currentWorld);
    if (vars.currentWorld == "Content/Talos/Levels/Cloud_3_08.wld") {
      vars.cStarSigils++;
      print("Collected " + vars.cStarSigils + " in C*");
      if (vars.cStarSigils == 3 && settings["Split on Community% ending"]) {
        return true;
      }
    }
    if (sigil.StartsWith("**")) {
      if (settings["Split on star collection"]) {
        return true;
      } else {
        if (vars.currentWorld == "Content/Talos/Levels/Nexus.wld") {
          return settings["Split on star collection in the Nexus"];
        }
      }
    } else {
      if (settings["Don't split on tetromino collection in A6"] &&
        vars.currentWorld == "Content/Talos/Levels/Cloud_1_06.wld") {
        print("Not splitting for a collection in A6, per setting.");
        return false;
      }
      if (settings["Don't split on tetromino collection in B4"] &&
        vars.currentWorld == "Content/Talos/Levels/Cloud_2_04.wld") {
        print("Not splitting for a collection in B4, per setting.");
        return false;
      }
      if (settings["Don't split on tetromino collection in B6"] &&
        vars.currentWorld == "Content/Talos/Levels/Cloud_2_06.wld") {
        print("Not splitting for a collection in B6, per setting.");
        return false;
      }
      if (settings["Don't split on tetromino collection in B8"] &&
        vars.currentWorld == "Content/Talos/Levels/Cloud_2_08.wld") {
        print("Not splitting for a collection in B8, per setting.");
        return false;
      }
      return settings["Split on tetromino collection or DLC robot collection"];
    }
  }

  // Arranger puzzles
  if (vars.line.StartsWith("Puzzle \"") && vars.line.Contains("\" solved")) {
    var puzzle = vars.line.Substring(8);
    print("Solved puzzle: " + puzzle);
    if (puzzle.StartsWith("Mechanic")) {
      return settings["Split on item unlocks"];
    }
    if (puzzle.StartsWith("Door") && settings["Split on tetromino world doors"]) {
      return true; // Working around a custom arranger called 'Door_Dome'
    }
    if (puzzle.StartsWith("SecretDoor")) {
      return settings["Split on tetromino star doors"];
    }
    if (puzzle.StartsWith("Nexus")) {
      return settings["Split on tetromino tower doors"];
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
    print("User exited terminal");
    return settings["Split on exiting any terminal"];
  }
  if (vars.currentWorld == "Content/Talos/Levels/Islands_03.wld") {
    if (vars.line.StartsWith("USER:")) { // Line differs in languages, not the prefix
      print("Game completed via Messenger ending.");
      return true;
    }
  }
  if (vars.currentWorld == "Content/Talos/Levels/Nexus.wld") {
    if (vars.line == "Elohim speaks: Elohim-063_Nexus_Ascent_01") {
      print("User exits floor 5 and starts ascending the tower");
      return settings["Split when exiting Floor 5"];
    }
    if (vars.line == "USER: /transcend") {
      print("Game completed via Transcendence ending.");
      return true;
    }
    if (vars.line == "USER: /eternalize") {
      print("Game completed via Eternalize ending.");
      return true;
    }
  }
  if (vars.currentWorld == "Content/Talos/Levels/DLC_01_Hub.wld") {
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