state("Parallax") {
  // float copyPlayerX : 0xA31220, 0x238;
  // float copyPlayerY : 0xA31220, 0x23C;
  // float copyPlayerZ : 0xA31220, 0x240;
  // int actions       : 0xA30BA4, 0x30, 0x0, 0x1DC, 0x5C, 0x20;
  int levelId       : 0xA01428;
}

startup {
  settings.Add("Split on chapter completion", true);
  settings.Add("Split on level completion", false);
  vars.gameTime = null;

  //    | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8
  // ---+---+---+---+---+---+---+---+---
  //  A | 14| 32| 16| 26| 19|  3| 13|  4
  //  B | 20|  9| 11| 17| 27| 30| 21|  8
  //  C |  5| 34| 28| 25| 33| 24| 29| 18
  //  D | 23| 31| 10|  6|  7| 22| 15| 12
  vars.levels = new List<string>(){
    "  ", "  ", "Main Menu", "A6", "A8", "C1", "D4", "D5", "B8", "B2",
    "D3", "B3", "D8", "A7", "A1", "D7", "A3", "B4", "C8", "A5",
    "B1", "B7", "D6", "D1", "C6", "C4", "A4", "B5", "C3", "C7",
    "B6", "D2", "A2", "C5", "C2"
  };
}

init {
  vars.gameTime = null;

  // 0x3e99999a (0.3f) = Paused
  // 0x00000000 (0.0f) = End of level / score screen
  // 0x3F800000 (1.0f) = Playing
  vars.fadeOut = null;

  foreach (var module in modules) {
    if (module.ModuleName.ToLower() == "mono.dll") {
      vars.fadeOut = new MemoryWatcher<float>(new DeepPointer(module.BaseAddress + 0x1F20AC, 0xA8, 0xF8));
      break;
    }
  }
}

update {
  if (old.levelId != current.levelId) {
    print("Changed from " + vars.levels[old.levelId] + " to " + vars.levels[current.levelId]);
  }

  // gameTime hasn't been found yet, and we're in a valid level
  if (vars.gameTime == null && current.levelId > 2) {
    var scan = new SigScanTarget(5,
      "D9 C9", // fxch st(1)
      "DE C1", // faddp
      "B8 ????????" // mov eax, [target]
    );

    foreach (var page in game.MemoryPages()) {
      var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
      var ptr = scanner.Scan(scan);
      if (ptr != IntPtr.Zero) {
        vars.gameTime = new MemoryWatcher<float>(game.ReadPointer(ptr));
        print("Found game time at 0x" + ptr.ToString("X"));
      }
    }
  }

  if (vars.gameTime != null) vars.gameTime.Update(game);
  vars.fadeOut.Update(game);
}

isLoading {
  return true; // Disable gameTime approximation
}

gameTime {
  if (vars.gameTime != null) {
    return TimeSpan.FromSeconds(vars.gameTime.Current);
  }
}

start {
  if (vars.gameTime != null) {
    if (vars.gameTime.Old == 0 && vars.gameTime.Current > 0) {
      print("gameTime is valid and no longer zero -- run started");
      return true;
    }
  }
}

reset {
  if (old.levelId > 2 && current.levelId <= 2) {
    print("Returned to main menu, resetting");
    return true;
  }
}

split {
  // Finished a level
  if (vars.fadeOut.Old == 1.0f && vars.fadeOut.Current == 0.0f) {
    string level = vars.levels[current.levelId];
    print("Completed level " + level);
    if (level == "D8") {
      print("Beat the game!");
      return true;
    }
    if (level == "A8" || level == "B8" || level == "C8") {
      if (settings["Split on chapter completion"]) return true;
    }
    if (settings["Split on level completion"]) return true;
  }
}
