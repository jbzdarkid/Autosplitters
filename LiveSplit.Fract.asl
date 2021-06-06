state("FRACTOSC") {
  float x: 0x9E1920, 0x238;
  float y: 0x9E1920, 0x23C;
  float z: 0x9E1920, 0x240;
}

startup {
}

init {
  Func<double, double, double, bool> between = (double lower, double middle, double upper) => {
    return (Math.Min(lower, upper) <= middle && middle <= Math.Max(lower, upper));
  };

  Func<double, double, double, double, double, double, Func<bool>> square = (double x1, double y1, double z1, double x2, double y2, double z2) => {
    var min = Math.Min(Math.Min(Math.Abs(x2-x1), Math.Abs(y2-y1)), Math.Abs(z2-z1));
    string target;
    if (min == Math.Abs(x2 - x1)) target = "x";
    else if (min == Math.Abs(y2 - y1)) target = "y";
    else target = "z";
    return (() => {
      if (target == "x") {
        if (!between(vars.old.x, (x1 + x2)/2, current.x)) return false;
      } else {
        if (!between(x1, current.x, x2) || !between(x1, vars.old.x, x2)) return false;
      }
      if (target == "y") {
        if (!between(vars.old.y, (y1 + y2)/2, current.y)) return false;
      } else {
        if (!between(y1, current.y, y2) || !between(y1, vars.old.y, y2)) return false;
      }
      if (target == "z") {
        if (!between(vars.old.z, (z1 + z2)/2, current.z)) return false;
      } else {
        if (!between(z1, current.z, z2) || !between(z1, vars.old.z, z2)) return false;
      }
      return true;
    });
  };

  vars.splits = new Dictionary<string, Func<bool>>{
    {"studioExit", square(
      5.489, -15.403, -4.327,
      -4.909, 4.403, -4.475
    )}, {"tutorialDone", square( // Didn't work
      85.774, -822.648, 204.984,
      149.108, -822.654, 160.223
    )}, {"bass1", square(
      -143.101, 3.16, 484.833,
      -152.591, 32.99, 505.101
    )}, {"bass2", square(
      -187.784, 3.691, 641.21,
      -192.443, 33.554, 623.363
    )}, {"bass3", square(
      159.195, -27.609, 644.952,
      157.242, 0.445, 664.487
    )}, {"bass4", square(
      113.626, 37.658, 406.275,
      123.104, 66.79, 421.835
    )}, {"bassEnd", square(
      -35.16, 41.285, 627.181,
      -26.796, 34.251, 633.87
    )}, {"lead1", square(
      106.211, 223.863, -128.216,
      117.201, 223.863, -106.351
    )}, {"lead2", square(
      133.84, 327.629, -428.231,
      115.537, 327.629, -408.465
    )}, {"lead3", square( // Didn't work
      -163.043, 460.608, -298.165,
      -136.828, 460.608, -302.246
    )}, {"lead4", square( // Didn't work
      -442.263, 500.519, -319.351,
      -444.338, 500.519, -348.371
    )}, {"leadEnd", square( // Kinda late
      78.016, 122.948, -278.734,
      60.929, 39.091, -380.641
    // TODO: Move to the exit point. Much more consistent.
    )}, {"pad1", square( // Didn't work
      571.442, 74.726, -469.789,
      571.144, 95.487, -539.296
    // TODO: Move this to somewhere along the path to the sequencer
    )}, {"pad2", square(
      523.796, 50.355, -223.098,
      511.3, 74.126, -226.527
    )}, {"pad3", square(
      774.142, 110.247, -103.692,
      751.806, 132.289, -103.674
    // TODO: Pad4?


    // TODO: Move this to somewhere along the path to the sequencer
    )}, {"padEnd", square(
      188.875, -10.946, -69.611,
      184.158, 10.398, -82.773
    )}
  };
}

update {
  // Old is otherwise not accessible outside of update/split blocks
  vars.old = old;
}

split {
  foreach (var split in vars.splits) {
    if (split.Value()) {
      // vars.splits.Remove(split.Key);
      print("Splitting for " + split.Key);
      return true;
    }
  }
//  if (vars.tutorial()) {
//    print("Tutorial");
//    return true;
//  }
//  if (vars.tutorial2()) {
//    print("Tutorial2");
//    return true;
//  }
}


// startup {
//   vars.checkpoints = new Dictionary<int, string>{
//     {0x7C33C, "Red 0"},
//     {0x71F7A, "Red 1"},
//     {0x7081C, "Red 2"},
//     {0x75D4C, "Red 3"},
//     {0x801DE, "Red 4"},
//
//     {0x7EF38, "Green 0"},
//     {0x7F5DE, "Green 1"},
//     {0x7F6B0, "Green 2"},
//     {0x75A36, "Green 3"},
//     {0x72F4A, "Green 4"},
//     {0x7B742, "Green 5"},
//
//     {0x755CA, "Yellow 0"},
//     {0x73F86, "Yellow 1"},
//     {0x7A466, "Yellow 2"},
//     {0x6F0D0, "Yellow 3"},
//     {0x7EF12, "Yellow 4"},
//
//     {0x8CBCA, "Studio"},
//     {0x8C21A, "Studio 2"},
//
//     // Tutorial hub
//     {0xF60CA, "Midair Hub"},
//     {0x79DD4, "Hub"},
//     // Endgame hub
//   };
// }
//
// init {
//   foreach (LiveSplit.UI.Components.IComponent component in timer.Layout.Components) {
//     if (component.GetType().Name == "TextComponent") {
//       vars.tc = component;
//       vars.tcs = vars.tc.Settings;
//     }
//   }
//
//   foreach (var page in game.MemoryPages()) {
//     var scanner = new SignatureScanner(game, page.BaseAddress, (int)page.RegionSize);
//     IntPtr ptr = scanner.Scan(new SigScanTarget(5, // Targeting byte 5
//       "85 C0",       // test eax, eax
//       "74 13",       // je 0x13
//       "B8 ????????", // mov eax, target
//       "89 38"        // mov [eax], edi
//     ));
//     if (ptr != IntPtr.Zero) {
//       vars.checkpoint = new MemoryWatcher<int>(new DeepPointer(
//         game.ReadValue<int>(ptr) - (int)modules.First().BaseAddress,
//         0x8
//       ));
//       break;
//     }
//   }
// }
//
// start {
//   if (vars.checkpoint.Old == 0 && vars.checkpoint.Current != 0) {
//     print(vars.checkpoint.Old.ToString("X") + " -> " + vars.checkpoint.Current.ToString("X"));
//     return true;
//   }
// }
//
// update {
//   vars.checkpoint.Update(game);
// }
//
// split {
//   if (vars.checkpoint.Changed) {
//     print(vars.checkpoint.Old.ToString("X") + " -> " + vars.checkpoint.Current.ToString("X"));
//     vars.tcs.Text1 = vars.checkpoint.Old.ToString("X");
//     vars.tcs.Text2 = vars.checkpoint.Current.ToString("X");
//     return true;
//   }
// }
