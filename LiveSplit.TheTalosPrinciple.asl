state("Talos") {}
state("Talos_Unrestricted") {}
state("Talos_VR") {}

// TODO: Splitter doesn't restart when resetting from a terminal? Confirmed, but what to do about it?
//   This might be fixed now.
// TODO: "Split when returning to nexus" triggered in A5? Can't reproduce, logs were non-verbose. Will be fixed if/when I change to pointers instead of logging
// TODO: currentWorld isn't reset on stop run -- this might cause issues (somehow)

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

  settings.CurrentDefaultParent = null;
  settings.Add("bug2", false, "Additional logging for Ninja bug, where splits were completely missed");

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

  // Stored in translation_DLC_01_Road_To_Gehenna.txt
  vars.gehennaVictory = new List<string>{
    // TermDlg.DLC_18UploadTerminal.Ln0210.0.option.GoodLuckEveryone
    "USER: Good luck everyone", // English
    "USER: 各位祝你們好運", // Traditional Chinese
    "USER: Bonne chance à tous", // French
    "USER: Viel Glück", // German
    "USER: Suerte a todos.", // Spanish
    "USER: Всем удачи", // Russian
    "USER: Buona fortuna a tutti", // Italian
    "USER: Powodzenia wszystkim", // Polish
    "USER: Hodně štěstí všem", // Czech
    "USER: İyi şanslar millet", // Turkish
    // TermDlg.DLC_18UploadTerminal.Ln0211.0.option.RememberMe
    "USER: Remember me", // English
    "USER: 不要忘了我", // Traditional Chinese
    "USER: Ne m'oubliez pas", // French
    "USER: Denkt an mich", // German
    "USER: Recuérdame.", // Spanish
    "USER: Помните меня", // Russian
    "USER: Ricordatemi", // Italian
    "USER: Pamiętajcie o mnie", // Polish
    "USER: Pamatujte si na mě", // Czech
    "USER: Beni unutmayın", // Turkish
    // TermDlg.DLC_18UploadTerminal.Ln0212.0.option.ForgiveMe
    "USER: Forgive me", // English
    "USER: 原諒我", // Traditional Chinese
    "USER: Pardonnez-moi", // French
    "USER: Vergebt mir", // German
    "USER: Perdóname.", // Spanish
    "USER: Простите меня", // Russian
    "USER: Perdonatemi", // Italian
    "USER: Wybaczcie mi", // Polish
    "USER: Odpusťte mi", // Czech
    "USER: Beni affedin", // Turkish
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
  vars.log("Game directory: '" + gameDir + "'");

  var index = gameDir.LastIndexOf("\\Bin");
  var logPath = gameDir.Substring(0, index + 1) + "Log/" + game.ProcessName + ".log";
  vars.log("Computed log path: '" + logPath + "'");

  // To find the cheats pointer:
  // Open console (F1), and set cht_bEnableCheats = 1234
  // Search for a 4 byte with value 1234
  // Set cheats to 2345
  // Search for a 4 byte with value 2345
  // Add the green address, then look at its value. It should say Talos.exe+AAAAAAAA
  // You resulting pointer is (AAAAAAAA)

  // To find the loading pointer:
  // (x64) AOB scan for 48 83 B9 ?? ?? 00 00 00 41 8B F9
  // You should see cmp qword ptr [rcx + 0000AAAA], 00
  // (x86) AOB scan for 8B F1 83 BE ?? ?? 00 00 00 74 32 80 3D
  // You should see cmp dword ptr [esi + 0000AAAA], 00
  // Make a note of AAAA
  // (x64) AOB scan for 48 83 EC ?? 48 8B 49 10 48 85 C9 74 17
  // Set a breakpoint on the scan line: mov rcx, [rcx + BB]
  // (x86) AOB scan for 8B 49 08 83 EC 08
  // Set a breakpoint on the scan line: mov ecx, [ecx + BB]
  // Add address for ECX/RCX
  // Pointer scan for that address
  // Sort by offset 2
  // Find the Talos.exe+CCCCCCCC which has a single offset of 0
  // Your resulting pointer is (CCCCCCCC, BB, AAAA)
  // Moddable base values have always been exactly 0x3000 less so far, best to check again just in case though

  vars.cheatFlags = null;
  vars.isLoading = null;
  switch (page.ModuleMemorySize) {
    case 42323968:
      version = "461288 x64"; // Xbox & Epic Games Store
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x1E76DB8));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x1E5A690, 0x10, 0x1F8));
      break;
    case 41943040:
      version = "440323 x64";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x1E1CB88));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x1E00470, 0x10, 0x1F8));
      break;
    case 41930752:
      version = "429074 x64";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x1E19B38));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x1DFD450, 0x10, 0x1F8));
      break;
    case 35561472:
      version = "326589 x64";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x17C3670));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x17981D0, 0x10, 0x208));
      break;
    case 34160640:
      version = "301136 x64";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x1673BC0));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x16488F0, 0x10, 0x208));
      break;
    case 24354816:
      version = "252786 x64";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x1507868));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x14FF960, 0x10, 0x208));
      break;

    case 24506368:
      version = "326589 x86";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x1273F48));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x12540E8, 0x8, 0x1C8));
      break;
    case 23699456:
      version = "301136 x86";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x11AF758));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x118FA48, 0x8, 0x1C8));
      break;
    case 19664896:
      version = "252786 x86";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x11C6884));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x11C09C4, 0x8, 0x1C8));
      break;
    case 19648512:
      version = "248828 x86";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x11C28A4));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x11BC9E4, 0x8, 0x1C8));
      break;
    case 19599360:
      version = "243520/244371 x86";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x11B7724));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x11B1864, 0x8, 0x1C8));
      break;
    case 19681280:
      version = "226087 x86";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x11CC724));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x11C6B44, 0x8, 0x1C8));
      break;

    case 41926656:
      version = "440323 x64 Moddable";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x1E19B88));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x1DFD470, 0x10, 0x1F8));
      break;
    case 35549184:
      version = "326589 x64 Moddable";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x17C0670));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x17951D0, 0x10, 0x208));
      break;
    case 34148352:
      version = "301136 x64 Moddable";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x1673BC0));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x16458F0, 0x10, 0x208));
      break;
    case 24334336:
      version = "252786 x64 Moddable";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x1502848));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x14FA940, 0x10, 0x208));
      break;

    case 24494080:
      version = "326589 x86 Moddable";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x1270F48));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x12510E8, 0x8, 0x1C8));
      break;
    case 23687168:
      version = "301136 x86 Moddable";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x11AC758));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x118CA48, 0x8, 0x1C8));
      break;
    case 19652608:
      version = "252786 x86 Moddable";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x11C3884));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x11BD9C4, 0x8, 0x1C8));
      break;
    case 19636224:
      version = "248828 x86 Moddable";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x11BF8A4));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x11B99E4, 0x8, 0x1C8));
      break;
    case 19587072:
      version = "243520/244371 x86 Moddable";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x11B4724));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x11AE864, 0x8, 0x1C8));
      break;
    case 19668992:
      version = "226087 x86 Moddable";
      vars.cheatFlags = new MemoryWatcher<int>(new DeepPointer(0x11C9724));
      vars.isLoading = new MemoryWatcher<int>(new DeepPointer(0x11C3B44, 0x8, 0x1C8));
      break;

    default:
      version = "Unknown " + modules.First().ModuleMemorySize;
      break;
  }
  vars.log("Using game version: " + version);

  if (File.Exists(logPath)) {
    try { // Wipe the log file to clear out messages from last time
      FileStream fs = new FileStream(logPath, FileMode.Open, FileAccess.Write, FileShare.ReadWrite);
      fs.SetLength(0);
      fs.Close();
    } catch {} // May fail if file doesn't exist.
    vars.reader = new StreamReader(new FileStream(logPath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite));
  } else {
    vars.log("No log file found at computed log path, automatic start, stop, and splits will not work. Loading should still work if the timer is started manually.");
    // Set defaults for the rest of the script. The split block will not run, but the isLoading block will.
    vars.reader = null;
    vars.line = null;
  }
}

exit {
  timer.IsGameTimePaused = true;
  vars.reader = null; // Free the lock on the talos logfile, so folders can be renamed/etc
}

update {
  while (vars.reader != null) {
    vars.line = vars.reader.ReadLine();
    if (vars.line == null || vars.line.Length < 16) return false; // If no line was read, don't run any other blocks.
    if (vars.line.Substring(9, 3) == "ERR") continue; // Filter out error-level logging, as it can be spammy when bots get stuck
    break;
  }
  // Removes the date and log level from the line
  if (vars.line != null) vars.line = vars.line.Substring(16);

  if (vars.cheatFlags != null) vars.cheatFlags.Update(game);
  if (vars.isLoading != null) vars.isLoading.Update(game);
}

start {
  if (vars.line == null) return false; // If there is no logfile, don't run this block.

  var match = vars.startRegex.Match(vars.line);
  if (!match.Success) return false;
  var world = match.Groups[1].Value;
  // Main menu and settings count as 'worlds', ignore them
  if (world.Contains("Menu")) return false;

  if (vars.cheatFlags != null && vars.cheatFlags.Current != 0) {
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
  vars.graySigils = 0;
  timer.IsGameTimePaused = true;
  return true;
}

reset {
  if (vars.line == null) return false; // If there is no logfile, don't run this block.
  
  if (vars.line == "Saving talos progress upon game stop." ||
    vars.line == "Saving game progress upon game stop.") {
    vars.log("Stopped run because the game was stopped.");
    return true; // Unique line printed only when you stop the game / stop moddable
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
  if (vars.line == null) return false; // If there is no logfile, don't run this block.

  if (vars.line.StartsWith("Changing over to")) { // Initial level change (for the purpose of splitting)
    var mapName = vars.line.Substring(17);
    if (mapName == vars.currentWorld) {
      vars.log("Restarted checkpoint in world " + mapName);
      return false; // Ensure 'restart checkpoint' doesn't trigger map change
    }
    if (settings["Split on return to Nexus or DLC Hub"] &&
      (mapName.EndsWith("Nexus.wld") ||
       mapName.EndsWith("DLC_01_Hub.wld"))) {
      vars.log("Returned to Nexus/Hub from " + vars.currentWorld);
      return true;
    }
    if (settings["(Custom/DLC) Split on any world transition"]) {
      vars.log("Initial load for world change from " + mapName + " to " + vars.currentWorld);
      return true;
    }
  }

  if (vars.line.StartsWith("Started simulation on")) { // Map changes (for the purpose of current world)
    var mapName = vars.line.Substring(23);
    mapName = mapName.Substring(0, mapName.IndexOf("'"));
    vars.log("Changed worlds from " + vars.currentWorld + " to " + mapName);
    vars.currentWorld = mapName;
  }

  // Sigil, robot, and star collection
  string sigil = null;
  if (vars.line.StartsWith("Backup and Save Talos Progress: tetromino")) {
    sigil = vars.line.Substring(43, 4);
  } else if (vars.line.StartsWith("Tetromino ")) {
    sigil = vars.line.Substring(10, 4);
  }

  if (settings["bug2"]) {
    if (sigil != null) {
      vars.log("NinjaBug 7/8/2019: " + vars.line + " " + sigil);
      vars.log("\t" + vars.lastSigil);
    }
  }

  if (sigil != null && sigil != vars.lastSigil) {
    vars.lastSigil = sigil;
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
    if (puzzle.StartsWith("DLC_01_Secret") || puzzle.StartsWith("DLC_01_Hub")) {
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
    if (vars.gehennaVictory.Contains(vars.line)) {
      vars.log("Gehenna game completed.");
      return true;
    }
  }
}
