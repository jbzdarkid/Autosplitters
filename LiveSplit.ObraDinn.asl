state("ObraDinn") {}

startup {
  vars.logFilePath = Directory.GetCurrentDirectory() + "\\autosplitter_obradinn.log";
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

  var splitNames = new List<string>() {
    "d000-stow-m00-seag",
    "d000-stow-m01-stowaway",
    "d010-cold-m00-seac",
    "d010-cold-m01-sea4",
    "d010-cold-m02-cow",
    "d020-shel-m00-pass2",
    "d020-shel-m02-pass9",
    "d020-shel-m03-top6",
    "d030-laun-m00-top7",
    "d030-laun-m01-seae",
    "d030-laun-m02-stewm2",
    "d030-laun-m03-pass6",
    "d030-laun-m04-pass7",
    "d030-laun-m05-mate2",
    "d040-merm-m00-pass8",
    "d040-merm-m01-cook",
    "d040-merm-m02-sea8",
    "d040-merm-m03-sea6",
    "d050-ride-m00-top1",
    "d050-ride-m01-top9",
    "d050-ride-m02-carpmate",
    "d050-ride-m03-surgeonmate",
    "d050-ride-m04-mid3",
    "d050-ride-m05-butcher",
    "d050-ride-m06-stewship",
    "d050-ride-m07-carp",
    "d060-krak-m00-sea3",
    "d060-krak-m01-pass5",
    "d060-krak-m02-sea7",
    "d060-krak-m03-gunner",
    "d060-krak-m04-stewm3",
    "d060-krak-m05-mid1",
    "d060-krak-m06-top3",
    "d060-krak-m07-pass1",
    "d070-save-m00-stewcap",
    "d070-save-m01-mermaid3",
    "d070-save-m02-mermaid2",
    "d070-save-m03-mate3",
    "d070-save-m04-monkey",
    "d080-esca-m00-bosun",
    "d080-esca-m01-stewm1",
    "d080-esca-m02-top2",
    "d080-esca-m03-gunnermate",
    "d080-esca-m04-mate4",
    "d080-esca-m05-mid2",
    "d090-fate-m00-mate1",
    "d090-fate-m01-seab",
    "d090-fate-m02-topa",
    "d090-fate-m03-captain",
  };

  var chapters = new List<string>() {
    "Loose Cargo",
    "A Bitter Cold",
    "Murder",
    "The Calling",
    "Unholy Captives",
    "Soldiers of the Sea",
    "The Doom",
    "Bargain",
    "Escape",
    "The End",
  };

  settings.Add("oneYearLater", false, "Split at the start of the \"One Year Later\" cutscene");
  settings.Add("sceneSplits", false, "Split when completing scenes");

  int chapter = -1;
  int part = 1;
  foreach (var splitName in splitNames) {
    var splitChapter = (int)(splitName[2] - '0');
    if (splitChapter != chapter) {
      chapter = splitChapter;
      part = 1;
      settings.Add(chapters[chapter], true, chapters[chapter], "sceneSplits");
    }
    settings.Add(splitName, true, "Part " + part, chapters[chapter]);
    part++;
  }
}

init {
  IntPtr saveDataPtr = IntPtr.Zero;
  foreach (var page in game.MemoryPages()) {
    var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
    if (saveDataPtr == IntPtr.Zero) {
      saveDataPtr = scanner.Scan(new SigScanTarget(0x16, // Targeting byte 22 (hex 0x16)
        "83 C4 10", // add esp, 10
        "83 EC 0C", // sub esp, 0C
        "89 45 FC", // mov [ebp-4], eax
        "50", // push eax
        "E8 34000000" // call ???
      ));
    }
  }
  if (saveDataPtr == IntPtr.Zero) throw new Exception("Couldn't find saveData");

  // SaveData.it (static singleton)
  int saveData = (int)((long)game.ReadValue<int>(saveDataPtr) - (long)(modules.First().BaseAddress));
  // SaveData.data.general.lastVisitedMomentId
  vars.lastVisitedMoment = new StringWatcher(new DeepPointer(saveData, 0x24, 0x8, 0xC, 0xC), 100);
  // SaveData.data.general.era
  vars.state = new MemoryWatcher<int>(new DeepPointer(saveData, 0x24, 0x8, 0x1C));
  // SaveData.data.general.playTime
  vars.time = new MemoryWatcher<float>(new DeepPointer(saveData, 0x24, 0x8, 0x20));
  // SaveData.data.general.lastVisitedMomentExitPlayTime
  vars.lastMomentExitTime = new MemoryWatcher<float>(new DeepPointer(saveData, 0x24, 0x8, 0x24));

  vars.gameStart = new MemoryWatcher<int>(new DeepPointer(saveData, 0x24));
  vars.letter = new MemoryWatcher<float>(new DeepPointer(0x103F878, 0x1C, 0x8+0xA8));

  vars.watchers = new MemoryWatcherList() {
    vars.gameStart,
    vars.lastVisitedMoment,
    vars.state,
    vars.time,
    vars.lastMomentExitTime,
    vars.letter,
  };

  // Manual tracking for these because the game doesn't reset this data between attempts.
  vars.currentMoment = null;
  vars.completedMoments = new HashSet<string>();
}

update {
  vars.watchers.UpdateAll(game);
}

start {
  if (vars.gameStart.Changed) {
    vars.currentMoment = null;
    vars.completedMoments.Clear();
    return true;
  }
}

isLoading {
  return true;
}

gameTime {
  return TimeSpan.FromSeconds(vars.time.Current);
}

split {
  if (vars.state.Old != vars.state.Current) vars.log("Era changed from " + vars.state.Old + " to " + vars.state.Current);
  if (settings["oneYearLater"]) {
    if (vars.state.Old == 2 && vars.state.Current == 3) return true;
  }
  // Any% completion
  if (vars.letter.Old == 225 && vars.letter.Current == 247.5) return true;

  // If the 'last exited moment' time changes, then we must've exited a moment.
  if (vars.lastMomentExitTime.Old != vars.lastMomentExitTime.Current) {
    // Update the 'current moment' in case we reset during the first moment and we didn't get a lastVisitedMoment change
    if (vars.currentMoment == null) {
      vars.log("Current moment was null, updating to " + vars.lastVisitedMoment.Current);
      vars.currentMoment = vars.lastVisitedMoment.Current;
    }

    // Update the 'previous moment' for future comparisons
    if (vars.completedMoments.Contains(vars.currentMoment)) {
      vars.log("lastMomentExitTime changed, but we have already completed moment " + vars.currentMoment);
      return false;
    }

    vars.log("lastMomentExitTime changed, we must have exited a moment, splitting for current moment " + vars.currentMoment);
    vars.completedMoments.Add(vars.currentMoment);
    return settings[vars.currentMoment];
  }

  if (vars.lastVisitedMoment.Old != vars.lastVisitedMoment.Current) {
    bool shouldSplit = false;
    if (vars.currentMoment != null && !vars.completedMoments.Contains(vars.currentMoment)) {
      vars.log("We had not already completed moment " + vars.currentMoment + ", splitting for it now");
      vars.completedMoments.Add(vars.currentMoment);

      // This is primarily for ch4 and ch7 which have corpses which are 'only accessible from another corpse'
      shouldSplit = settings[vars.currentMoment];
    }

    vars.log("Entered moment " + vars.lastVisitedMoment.Current + ", previous moment was " + vars.currentMoment);
    vars.currentMoment = vars.lastVisitedMoment.Current;
    return shouldSplit;
  }
}