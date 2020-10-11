state("Sausage") {}

startup {
  settings.Add("Start when entering levels", true);
  settings.Add("Reset when exiting levels without winning", true);
  settings.Add("Split when exiting levels", true);
}

init {
  foreach (var module in modules) {
    if (module.ModuleName.ToLower() == "unityplayer.dll") {
      vars.inOverworld = new MemoryWatcher<bool>(new DeepPointer(module.BaseAddress + 0x15AE938, 0x48, 0xB8, 0x80, 0x18, 0x184));
      vars.won = new MemoryWatcher<bool>(new DeepPointer(module.BaseAddress + 0x15AE938, 0x48, 0xB8, 0x80, 0x3BC));
      vars.playerX = new MemoryWatcher<int>(new DeepPointer(module.BaseAddress + 0x1547668, 0x58, 0x98, 0x40, 0x18, 0x100, 0xD8));
      vars.playerY = new MemoryWatcher<int>(new DeepPointer(module.BaseAddress + 0x1547668, 0x58, 0x98, 0x40, 0x18, 0x100, 0xDC));
      vars.playerZ = new MemoryWatcher<int>(new DeepPointer(module.BaseAddress + 0x1547668, 0x58, 0x98, 0x40, 0x18, 0x100, 0xE0));
      vars.playerDir = new MemoryWatcher<int>(new DeepPointer(module.BaseAddress + 0x1547668, 0x58, 0x98, 0x40, 0x18, 0x100, 0xF4));
      vars.exitX = new MemoryWatcher<int>(new DeepPointer(module.BaseAddress + 0x15AE938, 0x48, 0xB8, 0x80, 0x18, 0x194));
      vars.exitY = new MemoryWatcher<int>(new DeepPointer(module.BaseAddress + 0x15AE938, 0x48, 0xB8, 0x80, 0x18, 0x198));
      vars.exitZ = new MemoryWatcher<int>(new DeepPointer(module.BaseAddress + 0x15AE938, 0x48, 0xB8, 0x80, 0x18, 0x19C));
      vars.exitDir = new MemoryWatcher<int>(new DeepPointer(module.BaseAddress + 0x15AE938, 0x48, 0xB8, 0x80, 0x18, 0x1A0));
      break;
    }
  }
}

update {
  vars.inOverworld.Update(game);
  vars.won.Update(game);
  vars.playerX.Update(game);
  vars.playerY.Update(game);
  vars.playerZ.Update(game);
  vars.playerDir.Update(game);
  vars.exitX.Update(game);
  vars.exitY.Update(game);
  vars.exitZ.Update(game);
  vars.exitDir.Update(game);
}

start {
  if (vars.inOverworld.Old && !vars.inOverworld.Current) {
    if (settings["Start when entering levels"]) return true;
  }
}

reset {
  if (!vars.inOverworld.Old && vars.inOverworld.Current) {
    // If we exited a level BUT:
    // - Have not yet won
    // - Are not on the exit tile
    // - Are not facing the right way,
    // It is not actually a victory!
    if (!vars.won.Old ||
        vars.playerX.Current != vars.exitX.Current ||
        vars.playerY.Current != vars.exitY.Current ||
        vars.playerZ.Current != vars.exitZ.Current ||
        vars.playerDir.Current != vars.exitDir.Current) {
      print("" + vars.won.Old);
      print(vars.playerX.Current + " " + vars.exitX.Current);
      print(vars.playerY.Current + " " + vars.exitY.Current);
      print(vars.playerZ.Current + " " + vars.exitZ.Current);
      print(vars.playerDir.Current + " " + vars.exitDir.Current);
      if (settings["Reset when exiting levels without winning"]) return true;
    }
  }
}

split {
  if (!vars.inOverworld.Old && vars.inOverworld.Current) {
    if (settings["Split when exiting levels"]) return true;
  }
}