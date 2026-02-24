state("HOB") {}

startup {
  // Relative to Livesplit.exe
  vars.logFilePath = Directory.GetCurrentDirectory() + "\\autosplitter_hob.log";
  vars.log = (Action<string>)((string logLine) => {
    print(logLine);
    string time = System.DateTime.Now.ToString("dd/MM/yy hh:mm:ss.fff");
    // AppendAllText will create the file if it doesn't exist.
    System.IO.File.AppendAllText(vars.logFilePath, time + ": " + logLine + "\r\n");
  });

  vars.levels = new Dictionary<string, string> {
    { "shortName", "/path/to/full/level/name.dat" },
  };
  vars.splits = new Dictionary<string, List<string>>();

  var addSetting = (Action<string, string, string, string, string>)((string settingId, string name, string fromLevel, string toLevel, string tooltip) => {
    settings.Add(settingId, false, name);
    settings.SetToolTip(settingId, tooltip);
    if (!vars.levels.ContainsKey(fromLevel)) throw new Exception(fromLevel + " is not a valid level name");
    if (!vars.levels.ContainsKey(toLevel)) throw new Exception(toLevel + " is not a valid level name");

    string splitsKey = fromLevel + "." + toLevel;
    List<string> splitsValue;
    if (!vars.splits.TryGetValue(splitsKey, out splitsValue)) {
      splitsValue = new List<string>();
      vars.splits[splitsKey] = splitsValue;
    }
    splitsValue.Add(settingId);
  });

  settings.Add("all_levels", false, "Split when changing levels");
  settings.Add("anyNoFPSSplits", true, "Any% No FPS Abuse");
  settings.CurrentDefaultParent = "anyNoFPSSplits";

  addSetting("sword",    "Exit Forge",                "SWORD_CAVE",        "OVERWORLD",             "Exiting the forge after getting the sword");

  // Note: We'll also need to intersperse other settings from any%, e.g. corruptions
}

init {
  vars.log("Running signature scans...");

  IntPtr ptr;
  foreach (var page in game.MemoryPages()) {
    var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);

    // TODO: I need to pull stuff from the trainer (and latest CE stuff)
    ptr = scanner.Scan(new SigScanTarget(36,
      "38 00", // cmp byte ptr [eax], al
      "8B C8", // mov ecx, eax
      "BA 03 00 00 00" // mov edx, 3 ; ThreadPriority.AboveNormal
    ));
    if (ptr != IntPtr.Zero) fezGame = game.ReadValue<int>(ptr) - (int)modules.First().BaseAddress;
  }
  if (fezGame == 0) {
    vars.log("Couldn't find FezGame.fez!");
    throw new Exception("Couldn't find FezGame.fez!");
  } else if (speedrunIsLive == 0 || timerBase == 0) {
    vars.log("Couldn't find speedrunIsLive / timerBase!");
    throw new Exception("Couldn't find speedrunIsLive / timerBase!");
  }

  vars.gomezAction = new MemoryWatcher<int>(new DeepPointer(fezGame, 0x70, 0x6C, 0x70));
  // set up the rest of the MemoryWatchers here.
  vars.watchers = new MemoryWatcherList { vars.speedrunIsLive, vars.timerElapsed, vars.timerStart, vars.timerEnabled, vars.gomezAction, vars.levelWatcher };
  vars.log("Found all sigscans, ready for start of run");

  vars.level = null;

  // I should just use another MemoryWatcher here. No reason to get fancy.
  vars.playerPos = relativePosition + game.ReadValue<int>(ptr);
  vars.CloseToPoint = (Func<float, float, float, bool>) ((float x, float y, float z) => {
    var playerX = new DeepPointer(vars.playerPos + 0x00).Deref<float>(game);
    var playerY = new DeepPointer(vars.playerPos + 0x04).Deref<float>(game);
    var playerZ = new DeepPointer(vars.playerPos + 0x08).Deref<float>(game);

    // The player is "close to a point" if they're within 5 units (25 = 5^2)
    var distanceToPlayer = (x - vars.hobX.Current) * (x - vars.hobX.Current) +
                           (y - vars.hobY.Current) * (y - vars.hobY.Current) +
                           (z - vars.hobZ.Current) * (z - vars.hobZ.Current);
    return distanceToPlayer < 25.0f;
  });

  vars.deathCount = 0;
  vars.updateText = false;
  vars.tcs = null;
  if (settings["deathcount"]) {
    foreach (LiveSplit.UI.Components.IComponent component in timer.Layout.Components) {
      if (component.GetType().Name == "TextComponent") {
        vars.tcs = component.Settings;
        vars.updateText = true;
        vars.log("Found text component at " + component);
        break;
      }
    }
  }
}

update {
  vars.watchers.UpdateAll(game);
  if (vars.tcs != null && (vars.updateText || old.deathCount != current.deathCount)) {
    vars.tcs.Text1 = "Deaths:";
    vars.tcs.Text2 = vars.deathCount.ToString();
  }
}

start {
  // idk, some kind of start trigger. Maybe I can use moveset for this, maybe not.
  if (vars.CloseToPoint(0, 0, 0) && something) {
    vars.log("Starting run");
    vars.deathCount = 0;
    vars.level = "overworld";
    return true;
  }
}

reset {
  // I'm not sure how to detect this, exactly? Maybe I can look for "player returned to the starting area"?
  if (vars.CloseToPoint(0, 0, 0) && something) {
    vars.log("Reset run");
    return true;
  }
}

split {
  string oldLevel = vars.level;
  string newLevel = vars.levelWatcher.Current;
  if (oldLevel != newLevel && vars.levels.ContainsKey(newLevel)) {
    // TODO: Look up levels here, somehow? I guess in our big level dict... use TryGetValue?
    vars.log("Changed level from " + oldLevel + " to " + newLevel);
    vars.level = newLevel;

    if (settings["all_levels"]) return true; // TODO: probably don't support this for hob.
    List<string> settingIds;
    if (vars.splits.TryGetValue(oldLevel + "." + newLevel, out settingIds)) {
      vars.log("Transition from " + oldLevel + " to " + newLevel + " found in splits dictionary");
      foreach (string settingId in settingIds) {
        vars.log("Setting " + settingId + " is " + settings[settingId]);
        if (settings[settingId]) return true;
      }
    }
  }
  // Death moveset should be simpler here... I need to check that 'falling into void' triggers that as well, if not use HP = 0.
  if (vars.gomezAction.Changed) {
    if (vars.gomezAction.Current == 0x25) {
      vars.deathCount++;
    }
  }
}
