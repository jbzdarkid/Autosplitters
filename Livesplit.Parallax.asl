state("Parallax") {
  float copyPlayerX : 0xA31220, 0x238;
  float copyPlayerY : 0xA31220, 0x23C;
  float copyPlayerZ : 0xA31220, 0x240;
  int actions       : 0xA30BA4, 0x30, 0x0, 0x1DC, 0x5C, 0x20;
  int level         : 0xA01428;
}

startup {
  settings.Add("Split on chapter completion", true);
  settings.Add("Split on level completion", false);
}

init {
  var igtTarget = new SigScanTarget(0, "D9C9 DEC1 B8 ????????");
  vars.gameTime = null;
  foreach (var page in game.MemoryPages(true)) {
    var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
    var ptr = IntPtr.Zero;
    ptr = scanner.Scan(igtTarget);
    if (ptr != IntPtr.Zero) {
      vars.gameTime = new MemoryWatcher<float>(game.ReadPointer(ptr+5));
      print("Found game time at 0x"+ptr.ToString("X"));
    }
  }
  if (vars.gameTime == null) {
    // Waiting for the game to have booted up. This is a pretty ugly work
    // around, but we don't really know when the game is booted,
    // so to reduce the amount of searching we are doing, we sleep a bit
    // between every attempt.
    Thread.Sleep(1000);
    throw new Exception();
  }
}

update {
  vars.gameTime.Update(game);
}

isLoading {
  return true; // Disable gameTime approximation
}

gameTime {
  return TimeSpan.FromSeconds(vars.gameTime.Current);
}

start {
  return vars.gameTime.Old == 0 && vars.gameTime.Current > 0;
}

reset {
  return vars.gameTime.Old > 0 && vars.gameTime.Current == 0;
}

split {
  // A: 14, 32, 16, 26, 19, 3, 13, 4
  // B: 20, 9, 11, 17, 27, 30, 21, 8
  // C: 5, 34, 28, 25, 33, 24, 29, 18
  // D: 23, 31, 10, 6, 7, 22, 15, 12
  if (old.level != current.level) {
    if (old.level == 12) {
      return true; // End of game
    }
    if (old.level == 4 || old.level == 8 || old.level == 18) {
      return settings["Split on chapter completion"];
    }
    if (old.level == 2) {
      return false; // Exiting lobby
    }
    return settings["Split on level completion"];
  }
}
