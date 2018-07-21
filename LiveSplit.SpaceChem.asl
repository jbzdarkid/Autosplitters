state("SpaceChem") {}

startup {
  settings.Add("Split on level completion", true);
}

init {
  IntPtr ptr = IntPtr.Zero;
  vars.cycleCount = null;
  foreach (var page in game.MemoryPages()) {
    var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);

    ptr = scanner.Scan(new SigScanTarget(4, // Targeting byte 4
      "FF D0",          // call eax
      "FF 05 ????????", // inc [target]
      "8B 3D ????????"  // mov edi, [???]
    ));
    if (ptr != IntPtr.Zero) {
      int tmp = game.ReadValue<int>(ptr) - (int)game.Modules[0].BaseAddress;
      print(tmp.ToString("X"));
      vars.state = new MemoryWatcher<int>(new DeepPointer(tmp-8));
      vars.cycleFraction = new MemoryWatcher<float>(new DeepPointer(tmp-4));
      vars.cycleCount = new MemoryWatcher<int>(new DeepPointer(tmp));
    }
  }
  if (vars.cycleCount == null) {
    // Thread.Sleep(100);
    throw new Exception("Sigscans failed!");
  }
}

update {
  vars.state.Update(game);
  vars.cycleFraction.Update(game);
  vars.cycleCount.Update(game);
}

split {
  if (vars.cycleCount.Old > 0 && vars.cycleCount.Current == 0) {
    print("---------");
    print(vars.state.Old + " " + vars.state.Current);
    print(vars.cycleFraction.Old + " " + vars.cycleFraction.Current);
    print(vars.cycleCount.Old + " " + vars.cycleCount.Current);
    // return settings["Split on level completion"];
  }
}