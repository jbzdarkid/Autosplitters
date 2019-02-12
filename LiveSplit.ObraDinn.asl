state("ObraDinn") {}

startup {
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
      settings.Add(chapters[chapter], false, chapters[chapter], "sceneSplits");
    }
    settings.Add(splitName, true, "Part " + part, chapters[chapter]);
    part++;
  }
}

init {
  IntPtr ptr = IntPtr.Zero;
  foreach (var page in game.MemoryPages()) {
    var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
    ptr = scanner.Scan(new SigScanTarget(22, // Targeting byte 22
      "83 C4 10", // add esp, 10
      "83 EC 0C", // sub esp, 0C
      "89 45 FC", // mov [ebp-4], eax
      "50", // push eax
      "E8 34000000" // call ???
    ));
    if (ptr != IntPtr.Zero) {
      break;
    }
  }
  if (ptr == IntPtr.Zero) {
    throw new Exception("Couldn't find active scene");
  }
  int root = (int)((long)game.ReadValue<int>(ptr) - (long)(modules.First().BaseAddress));
  vars.gameStart = new MemoryWatcher<int>(new DeepPointer(root, 0x24));
  vars.sceneName = new StringWatcher(new DeepPointer(root, 0x24, 0x8, 0xC, 0xC), 100);
  vars.state = new MemoryWatcher<int>(new DeepPointer(root, 0x24, 0x8, 0x1C));
  vars.time = new MemoryWatcher<float>(new DeepPointer(root, 0x24, 0x8, 0x20));
  vars.sceneTime = new MemoryWatcher<float>(new DeepPointer(root, 0x24, 0x8, 0x24));
  vars.letter = new MemoryWatcher<float>(new DeepPointer(0x103F878, 0x1C, 0x8+0xA8));

  vars.watchers = new MemoryWatcherList() {
    vars.gameStart,
    vars.sceneName,
    vars.state,
    vars.time,
    vars.sceneTime,
    vars.letter
  };
  vars.completedChapters = new HashSet<string>();
}

update {
  vars.watchers.UpdateAll(game);
}

start {
  vars.completedChapters.Clear();
  // Not the best, since it will start on load game too
  return vars.gameStart.Changed;
}

isLoading {
  return true;
}

gameTime {
  return TimeSpan.FromSeconds(vars.time.Current);
}

split {
  if (settings["oneYearLater"]) {
    if (vars.state.Old == 2 && vars.state.Current == 3) return true;
  }
  // Any% completion
  if (vars.letter.Old == 225 && vars.letter.Current == 247.5) return true;

  if (vars.completedChapters.Contains(vars.sceneName.Old)) continue

  // Most splits are upon returning to the boat
  if (vars.sceneTime.Old != vars.sceneTime.Current) {
    vars.completedChapters.Add(vars.sceneName.Old);
    return settings[vars.sceneName.Old];
  }

  // If that split didn't occur, then wait until the scene name changes.
  // This applies to ch6 & ch7.
  if (vars.sceneName.Old != vars.sceneName.Current) {
    vars.completedChapters.Add(vars.sceneName.Old);
    return settings[vars.sceneName.Old];
  }
}